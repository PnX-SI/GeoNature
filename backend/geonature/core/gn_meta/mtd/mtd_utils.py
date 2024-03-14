import logging
import json
from copy import copy
from flask import current_app

from sqlalchemy import select, exists
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
from pypnusershub.db.models import Organisme as BibOrganismes, User
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
    af = (
        DB.session.execute(
            select(TAcquisitionFramework).filter_by(unique_acquisition_framework_id=af_uuid)
        )
        .unique()
        .scalar_one_or_none()
    )

    if af is None:
        return

    ds["id_acquisition_framework"] = af.id_acquisition_framework
    ds = {
        field: (
            func.ref_nomenclatures.get_id_nomenclature(NOMENCLATURE_MAPPING[field], value)
            if field.startswith("id_nomenclature")
            else value
        )
        for field, value in ds.items()
        if value is not None
    }

    ds_exists = DB.session.scalar(
        exists()
        .where(
            TDatasets.unique_dataset_id == ds["unique_dataset_id"],
        )
        .select()
    )

    statement = (
        pg_insert(TDatasets)
        .values(**ds)
        .on_conflict_do_nothing(index_elements=["unique_dataset_id"])
    )
    if ds_exists:
        statement = (
            update(TDatasets)
            .where(TDatasets.unique_dataset_id == ds["unique_dataset_id"])
            .values(**ds)
        )
    DB.session.execute(statement)

    dataset = DB.session.scalars(
        select(TDatasets).filter_by(unique_dataset_id=ds["unique_dataset_id"])
    ).first()

    # Associate dataset to the modules if new dataset
    if not ds_exists:
        associate_dataset_modules(dataset)

    return dataset


def sync_af(af):
    """Will update a given AF (Acquisition Framework) if already exists in database according to UUID, else update the AF.

    Parameters
    ----------
    af : dict
        AF infos.

    Returns
    -------
    TAcquisitionFramework
        The updated or inserted acquisition framework.
    """
    af_uuid = af["unique_acquisition_framework_id"]
    af_exists = DB.session.scalar(
        exists().where(TAcquisitionFramework.unique_acquisition_framework_id == af_uuid).select()
    )

    # Update statement if AF already exists in DB else insert statement
    statement = (
        update(TAcquisitionFramework)
        .where(TAcquisitionFramework.unique_acquisition_framework_id == af_uuid)
        .values(af)
        .returning(TAcquisitionFramework)
    )
    if not af_exists:
        statement = (
            pg_insert(TAcquisitionFramework)
            .values(**af)
            .on_conflict_do_nothing(index_elements=["unique_acquisition_framework_id"])
            .returning(TAcquisitionFramework)
        )

    return DB.session.scalar(statement)


def add_or_update_organism(uuid, nom, email):
    """
    Create or update organism if UUID not exists in DB.

    :param uuid: uniq organism uuid
    :param nom: org name
    :param email: org email
    """
    # Test if actor already exists to avoid nextVal increase
    org_exist = DB.session.scalar(exists().where(BibOrganismes.uuid_organisme == uuid).select())

    if org_exist:
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

    Parameters
    ----------
    actors : list
        list of actors
    CorActor : db.Model
        table model
    pk_name : str
        pk attribute name
    pk_value : str
        pk value
    """
    for actor in actors:
        id_organism = None
        uuid_organism = actor["uuid_organism"]
        if uuid_organism:
            with DB.session.begin_nested():
                # create or update organisme
                id_organism = add_or_update_organism(
                    uuid=uuid_organism,
                    nom=actor["organism"] if actor["orgnanism"] else "",
                    email=actor["email"],
                )
        values = dict(
            id_nomenclature_actor_role=func.ref_nomenclatures.get_id_nomenclature(
                "ROLE_ACTEUR", actor["actor_role"]
            ),
            **{pk_name: pk_value},
        )
        if not id_organism:
            values["id_role"] = DB.session.scalar(
                select(User.id_role).filter_by(email=actor["email"])
            )
        else:
            values["id_organism"] = id_organism
        statement = (
            pg_insert(CorActor)
            .values(**values)
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
        DB.session.scalars(
            select(TModules).where(
                TModules.module_code.in_(current_app.config["MTD"]["JDD_MODULE_CODE_ASSOCIATION"])
            )
        ).all()
    )
