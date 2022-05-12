from urllib.parse import urljoin

import requests
from lxml import etree

from flask import current_app
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.sql import func

from geonature.utils.config import config
from geonature.utils.env import db
from geonature.core.gn_meta.models import (
    TAcquisitionFramework,
    TDatasets,
    CorAcquisitionFrameworkActor,
    CorDatasetActor,
)
from geonature.core.auth.routes import insert_user_and_org

from pypnusershub.db.models import User, Organisme

from .xml_parser import parse_acquisition_framework, parse_jdd_xml
from .mtd_utils import create_cor_object_actors, NOMENCLATURE_MAPPING


class MTDInstanceApi:
    af_path = "/mtd/cadre/export/xml/GetRecordsByInstanceId?id={ID_INSTANCE}"
    ds_path = "/mtd/cadre/jdd/export/xml/GetRecordsByInstanceId?id={ID_INSTANCE}"

    def __init__(self, api_endpoint, instance_id):
        self.api_endpoint = api_endpoint
        self.instance_id = instance_id

    def _get_xml(self, path):
        url = urljoin(self.api_endpoint, path)
        url = url.format(ID_INSTANCE=self.instance_id)
        response = requests.get(url)
        response.raise_for_status()
        return response.content

    def _get_af_xml(self):
        return self._get_xml(self.af_path)

    def get_af_list(self):
        xml = self._get_af_xml()
        root = etree.fromstring(xml)
        af_iter = root.iterfind(".//{http://inpn.mnhn.fr/mtd}CadreAcquisition")
        af_list = []
        for af in af_iter:
            af_list.append(parse_acquisition_framework(af))
        return af_list

    def _get_ds_xml(self):
        return self._get_xml(self.ds_path)

    def get_ds_list(self):
        xml = self._get_ds_xml()
        return parse_jdd_xml(xml)


class INPNCAS:
    base_url = config["CAS"]["CAS_USER_WS"]["BASE_URL"]
    user = config["CAS"]["CAS_USER_WS"]["ID"]
    password = config["CAS"]["CAS_USER_WS"]["PASSWORD"]
    id_search_path = "rechercheParId/{user_id}"

    @classmethod
    def _get_user_json(cls, user_id):
        url = urljoin(cls.base_url, cls.id_search_path)
        url = url.format(user_id=user_id)
        response = requests.get(url, auth=(cls.user, cls.password))
        return response.json()

    @classmethod
    def get_user(cls, user_id):
        return cls._get_user_json(user_id)


def add_unexisting_digitizer(id_digitizer):
    if not db.session.query(User.query.filter_by(id_role=id_digitizer).exists()).scalar():
        user = INPNCAS.get_user(id_digitizer)
        insert_user_and_org(user)


def add_or_update_organism(uuid, nom, email):
    statement = (
        pg_insert(Organisme)
        .values(
            uuid_organisme=uuid,
            nom_organisme=nom,
            email_organisme=email,
        )
        .on_conflict_do_update(
            index_elements=["uuid_organisme"],
            set_=dict(
                nom_organisme=nom,
                email_organisme=email,
            ),
        )
        .returning(Organisme.id_organisme)
    )
    return db.session.execute(statement).scalar()


def associate_actors(actors, CorActor, pk_name, pk_value):
    for actor in actors:
        if not actor["uuid_organism"]:
            continue
        with db.session.begin_nested():
            id_organism = add_or_update_organism(
                uuid=actor["uuid_organism"],
                nom=actor["organism"] or "",
                email=actor["email"],
            )
        statement = (
            pg_insert(CorActor)
            .values(
                id_organism=id_organism,
                id_nomenclature_actor_role=func.ref_nomenclatures.get_id_nomenclature(
                    "ROLE_ACTEUR", actor["actor_role"]
                ),
                **{pk_name: pk_value},
            )
            .on_conflict_do_nothing(
                index_elements=[pk_name, "id_organism", "id_nomenclature_actor_role"],
            )
        )
        db.session.execute(statement)


def sync_af_and_ds():
    cas_api = INPNCAS()
    mtd_api = MTDInstanceApi(config["MTD_API_ENDPOINT"], config["MTD"]["ID_INSTANCE_FILTER"])

    af_list = mtd_api.get_af_list()
    for af in af_list:
        with db.session.begin_nested():
            add_unexisting_digitizer(af["id_digitizer"])
        actors = af.pop("actors")
        statement = (
            pg_insert(TAcquisitionFramework)
            .values(**af)
            .on_conflict_do_update(index_elements=["unique_acquisition_framework_id"], set_=af)
            .returning(TAcquisitionFramework.id_acquisition_framework)
        )
        af_id = db.session.execute(statement).scalar()
        af = TAcquisitionFramework.query.get(af_id)
        associate_actors(
            actors,
            CorAcquisitionFrameworkActor,
            "id_acquisition_framework",
            af.id_acquisition_framework,
        )
        # TODO: remove actors removed from MTD
    db.session.commit()

    ds_list = mtd_api.get_ds_list()
    for ds in ds_list:
        with db.session.begin_nested():
            add_unexisting_digitizer(ds["id_digitizer"])
        actors = ds.pop("actors")
        af_uuid = ds.pop("uuid_acquisition_framework")
        af = TAcquisitionFramework.query.filter_by(unique_acquisition_framework_id=af_uuid).first()
        if af is None:
            continue
        ds["id_acquisition_framework"] = af.id_acquisition_framework
        ds = {
            k: func.ref_nomenclatures.get_id_nomenclature(NOMENCLATURE_MAPPING[k], v)
            if k.startswith("id_nomenclature")
            else v
            for k, v in ds.items()
            if v is not None
        }
        statement = (
            pg_insert(TDatasets)
            .values(**ds)
            .on_conflict_do_update(index_elements=["unique_dataset_id"], set_=ds)
        )
        db.session.execute(statement)
        ds = TDatasets.query.filter_by(unique_dataset_id=ds["unique_dataset_id"]).first()
        associate_actors(actors, CorDatasetActor, "id_dataset", ds.id_dataset)
    db.session.commit()
