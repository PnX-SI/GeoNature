import logging
import json
from copy import copy
from flask import current_app

from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.sql import func, update

from geonature.utils.config import config

from geonature.utils.errors import GeonatureApiError

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
from pypnusershub.db.models import User

from .xml_parser import parse_acquisition_framwork_xml, parse_jdd_xml
from .mtd_webservice import get_acquisition_framework, get_jdd_by_uuid

# from geonature.core.gn_meta.mtd import MTDInstanceApi

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

    :param af: <dict> DS infos
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
    return TDatasets.query.filter_by(unique_dataset_id=ds["unique_dataset_id"]).first()


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


def create_cor_object_actors(actors, new_object):
    """
    Create a new cor_dataset_actor/cor_acquisition_framework_actor object for the JDD/AF
    Input :
        actors (list) : List of all actors related to the JDD/AF
        new_object : JDD or AF
    """
    for act in actors:
        # person = None
        # id_person = None
        org = None
        id_organism = None

        # For the moment wo do not match the user with the actor provided by the XML -> only the organism

        # If the email of the contact Person was provided in the XML file, we try to link him to the t_role table
        # if act["email"]:
        #     # We first check if the Person's email exists in the t_role table
        #     person = (
        #         DB.session.query(User)
        #         .filter(User.email == act["email"])
        #         .first()
        #     )
        #     # If not, we create it as a new Person in the t_role table and get his ID back
        #     if not person:
        #         if act["uuid_organism"]:
        #             org = (
        #                 DB.session.query(BibOrganismes)
        #                 .filter(BibOrganismes.uuid_organisme == act["uuid_organism"])
        #                 .first()
        #             )
        #         person = {
        #             "id_role": None,
        #             "nom_role": act["name"],
        #             "email": act["email"],
        #         }
        #         if org:
        #             person['id_organisme'] = org.id_organisme
        #         resp = users.insert_role(person)
        #         id_person = json.loads(resp.data.decode('utf-8'))['id_role']
        #     else:
        #         id_person = person.id_role

        # If the informations about the Organism is provided, we try to link it to the bib_organismes table
        if act["uuid_organism"] or act["organism"]:
            # UUID in actually only present on JDD XML files
            # Filter on UUID is preferable if available since it avoids dupes based on name changes
            if act["uuid_organism"]:
                org = (
                    DB.session.query(BibOrganismes)
                    .filter(BibOrganismes.uuid_organisme == act["uuid_organism"])
                    .first()
                )
            else:
                org = (
                    DB.session.query(BibOrganismes)
                    .filter(BibOrganismes.nom_organisme == act["organism"])
                    .first()
                )
            # If no Organism was corresponding in the bib_organismes table, we add it
            if not org:
                org = BibOrganismes(
                    **{
                        "nom_organisme": act["organism"],
                        "uuid_organisme": act["uuid_organism"],
                    }
                )
                DB.session.add(org)
                DB.session.commit()
            id_organism = org.id_organisme

        # With at least the Person or the Organism was provided for the actor in the XML file,
        # we build the data for the correlation
        if id_organism:
            dict_cor = {
                "id_organism": id_organism,
                "id_nomenclature_actor_role": func.ref_nomenclatures.get_id_nomenclature(
                    "ROLE_ACTEUR", act["actor_role"]
                ),
            }

            # We finally build the correlation corresponding to the JDD/AF
            if isinstance(new_object, TAcquisitionFramework):
                if not any(
                    map(
                        lambda cafa: dict_cor["id_organism"] == cafa.id_organism
                        and act["actor_role"]
                        == cafa.id_nomenclature_actor_role.clauses.clauses[1].value,
                        new_object.cor_af_actor,
                    )
                ):
                    cor_actor = CorAcquisitionFrameworkActor(**dict_cor)
                    new_object.cor_af_actor.append(cor_actor)
            elif isinstance(new_object, TDatasets):
                if not any(
                    map(
                        lambda ca: dict_cor["id_organism"] == ca.id_organism
                        and act["actor_role"]
                        == ca.id_nomenclature_actor_role.clauses.clauses[1].value,
                        new_object.cor_dataset_actor,
                    )
                ):
                    cor_actor = CorDatasetActor(**dict_cor)
                    new_object.cor_dataset_actor.append(cor_actor)


def post_acquisition_framework(uuid=None):
    """
    Post an acquisition framwork from MTD XML
    Params:
        uuid (str): uuid of the acquisition framework
    """
    xml_af = None
    xml_af = get_acquisition_framework(uuid)

    if xml_af:
        acquisition_framwork = parse_acquisition_framwork_xml(xml_af)
        actors = acquisition_framwork.pop("actors")
        new_af = TAcquisitionFramework(**acquisition_framwork)
        id_acquisition_framework = TAcquisitionFramework.get_id(uuid)

        new_af = sync_af(id_acquisition_framework)

        associate_actors(
            actors, CorDatasetActor, "id_acquisition_framework", new_af.id_acquisition_framework
        )

        DB.session.commit()

        return new_af.as_dict()

    return {"message": "Not found"}, 404


def add_dataset_module(dataset):
    dataset.modules.extend(
        DB.session.query(TModules)
        .filter(TModules.module_code.in_(current_app.config["MTD"]["JDD_MODULE_CODE_ASSOCIATION"]))
        .all()
    )


def import_all_dataset_af_and_actors(table_name):
    file_handler = logging.FileHandler("/tmp/uuid_ca.txt")
    file_handler.setLevel(logging.CRITICAL)
    log.addHandler(file_handler)
    datasets = DB.engine.execute(f"SELECT * FROM {table_name}")
    for d in datasets:
        xml_jdd = get_jdd_by_uuid(str(d.unique_dataset_id))
        if xml_jdd:
            ds_list = parse_jdd_xml(xml_jdd)
            if ds_list:
                ds = ds_list[0]
                inpn_user = get_user_from_id_inpn_ws(ds["id_digitizer"])
                # get user info from id_digitizer
                if inpn_user:
                    # insert user id digitizer
                    insert_user_and_org(inpn_user)
                    actors = ds.pop("actors")
                    # prevent to not fetch, post or merge the same acquisition framework multiple times
                    new_af = post_acquisition_framework(
                        uuid=ds["uuid_acquisition_framework"],
                    )
                    # get the id from the uuid
                    ds["id_acquisition_framework"] = new_af["id_acquisition_framework"]
                    log.critical(str(new_af["id_acquisition_framework"]) + ",")
                    ds.pop("uuid_acquisition_framework")
                    # get the id of the dataset to check if exists
                    id_dataset = TDatasets.get_id(ds["unique_dataset_id"])
                    ds["id_dataset"] = id_dataset
                    # search nomenclature
                    ds_copy = copy(ds)
                    for key, value in ds_copy.items():
                        if key.startswith("id_nomenclature"):
                            if value is not None:
                                ds[key] = func.ref_nomenclatures.get_id_nomenclature(
                                    NOMENCLATURE_MAPPING.get(key), value
                                )
                            else:
                                ds.pop(key)

                    #  set validable = true
                    ds["validable"] = True
                    dataset = TDatasets(**ds)
                    # if the dataset already exist
                    if id_dataset:
                        # delete cor_ds_actor
                        dataset.id_dataset = id_dataset

                        delete_q = CorDatasetActor.__table__.delete().where(
                            CorDatasetActor.id_dataset == id_dataset
                        )
                        DB.session.execute(delete_q)
                        DB.session.commit()

                        # create the correlation links
                        create_cor_object_actors(actors, dataset)
                        add_dataset_module(dataset)
                        DB.session.merge(dataset)

                    # its a new DS
                    else:
                        # set the dataset as activ
                        dataset.active = True
                        # create the correlation links
                        create_cor_object_actors(actors, dataset)
                        add_dataset_module(dataset)
                        # Add the new DS
                        DB.session.add(dataset)
                    # try to commit
                    try:
                        DB.session.commit()
                    # TODO catch db error ?
                    except SQLAlchemyError as e:
                        error_msg = "Error posting a dataset\nTrace:\n{} \n\n ".format(e)
                        print(error_msg)
                else:
                    print("NO USER FOUND")
            else:
                "NO JDD IN XML ????"
        else:
            print("JDD NOT FOUND")
