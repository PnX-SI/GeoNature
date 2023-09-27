import logging
import json
from copy import copy
from flask import current_app

from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.sql import func, update

from sqlalchemy.dialects.postgresql import insert as pg_insert

from geonature.utils.env import DB
from geonature.core.gn_meta.models import (
    TDatasets,
    CorDatasetActor,
    TAcquisitionFramework,
    CorAcquisitionFrameworkActor,
)
from geonature.core.gn_commons.models import TModules
from pypnusershub.db.models import Organisme as BibOrganismes
from geonature.core.users import routes as users
from geonature.core.auth.routes import insert_user_and_org, get_user_from_id_inpn_ws

from .xml_parser import parse_acquisition_framwork_xml, parse_jdd_xml
from .mtd_webservice import get_jdd_by_user_id, get_acquisition_framework, get_jdd_by_uuid

NOMENCLATURE_MAPPING = {
    "id_nomenclature_data_type": "DATA_TYP",
    "id_nomenclature_dataset_objectif": "JDD_OBJECTIFS",
    "id_nomenclature_data_origin": "DS_PUBLIQUE",
    "id_nomenclature_source_status": "STATUT_SOURCE",
}

# get the root logger
log = logging.getLogger()


def sync_ds(ds, cd_nomenclatures):
    """
    Will create or update a given DS according to UUID.
    Only process DS if dataset's cd_nomenclatures exists in ref_normenclatures.t_nomenclatures.

    :param ds: <dict> DS infos
    :param cd_nomenclatures: <array> cd_nomenclature from ref_normenclatures.t_nomenclatures
    """
    if ds["id_nomenclature_data_origin"] not in cd_nomenclatures:
        return

    # CONTROL AF
    af_uuid = ds.pop("uuid_acquisition_framework")
    af = TAcquisitionFramework.query.filter_by(unique_acquisition_framework_id=af_uuid).first()

    if af is None:
        return

    ds["id_acquisition_framework"] = af.id_acquisition_framework
    ds = {
        k: func.ref_nomenclatures.get_id_nomenclature(NOMENCLATURE_MAPPING[k], v)
        if k.startswith("id_nomenclature")
        else v
        for k, v in ds.items()
        if v is not None
    }

    ds_exists = (
        TDatasets.query.filter_by(unique_dataset_id=ds["unique_dataset_id"]).first() is not None
    )

    if ds_exists:
        statement = (
            update(TDatasets)
            .where(TDatasets.unique_dataset_id == ds["unique_dataset_id"])
            .values(**ds)
        )
    else:
        statement = (
            pg_insert(TDatasets)
            .values(**ds)
            .on_conflict_do_nothing(index_elements=["unique_dataset_id"])
        )
    DB.session.execute(statement)
    dataset = TDatasets.query.filter_by(unique_dataset_id=ds["unique_dataset_id"]).first()

    # Associate dataset to the modules if new dataset
    if not ds_exists:
        associate_dataset_modules(dataset)

    return dataset


def sync_af(af):
    """
    Will create or update a given AF according to UUID.

    :param af: dict AF infos
    """
    af_uuid = af["unique_acquisition_framework_id"]
    af_exists = (
        TAcquisitionFramework.query.filter_by(unique_acquisition_framework_id=af_uuid).first()
        is not None
    )
    if af_exists:
        # this avoid useless nextval sequence
        statement = (
            update(TAcquisitionFramework)
            .where(TAcquisitionFramework.unique_acquisition_framework_id == af_uuid)
            .values(af)
            .returning(TAcquisitionFramework.id_acquisition_framework)
        )
    else:
        statement = (
            pg_insert(TAcquisitionFramework)
            .values(**af)
            .on_conflict_do_nothing(index_elements=["unique_acquisition_framework_id"])
            .returning(TAcquisitionFramework.id_acquisition_framework)
        )
    af_id = DB.session.execute(statement).scalar()
    af = TAcquisitionFramework.query.get(af_id)
    return af


def add_or_update_organism(uuid, nom, email):
    """
    Create or update organism if UUID not exists in DB.

    :param uuid: uniq organism uuid
    :param nom: org name
    :param email: org email
    """
    # Test if actor already exists to avoid nextVal increase
    org = BibOrganismes.query.filter_by(uuid_organisme=uuid).first() is not None
    if org:
        statement = (
            update(BibOrganismes)
            .where(BibOrganismes.uuid_organisme == uuid)
            .values(
                dict(
                    nom_organisme=nom,
                    email_organisme=email,
                )
            )
            .returning(BibOrganismes.id_organisme)
        )
    else:
        statement = (
            pg_insert(BibOrganismes)
            .values(
                uuid_organisme=uuid,
                nom_organisme=nom,
                email_organisme=email,
            )
            .on_conflict_do_nothing(index_elements=["uuid_organisme"])
            .returning(BibOrganismes.id_organisme)
        )
    return DB.session.execute(statement).scalar()


def associate_actors(actors, CorActor, pk_name, pk_value):
    """
    Associate actor and DS or AF according to CorActor value.

    :param actors: list of actors
    :param CorActor: table model
    :param pk_name: pk attribute name
    :param pk_value: pk value
    """
    for actor in actors:
        if not actor["uuid_organism"]:
            continue
        # test if actor already exists
        with DB.session.begin_nested():
            # create or update organisme
            id_organism = add_or_update_organism(
                uuid=actor["uuid_organism"],
                nom=actor["organism"] or "",
                email=actor["email"],
            )
        # Test if actor already exists to avoid nextVal increase
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
        DB.session.execute(statement)


def associate_dataset_modules(dataset):
    """
    Associate a dataset to modules specified in [MTD][JDD_MODULE_CODE_ASSOCIATION] parameter (geonature config)

    :param dataset: <geonature.core.gn_meta.models.TDatasets> dataset (SQLAlchemy model object)
    """
    dataset.modules.extend(
        DB.session.query(TModules)
        .filter(TModules.module_code.in_(current_app.config["MTD"]["JDD_MODULE_CODE_ASSOCIATION"]))
        .all()
    )
