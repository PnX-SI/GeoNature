import logging
import json
from copy import copy
import pprint
from typing import Literal, Union
from flask import current_app

from sqlalchemy import select, exists
from sqlalchemy.exc import SQLAlchemyError, IntegrityError
from sqlalchemy.sql import func, update

from sqlalchemy.dialects.postgresql import insert as pg_insert

from geonature.utils.env import DB, db
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
    "cd_nomenclature_data_type": "DATA_TYP",
    "cd_nomenclature_dataset_objectif": "JDD_OBJECTIFS",
    "cd_nomenclature_data_origin": "DS_PUBLIQUE",
    "cd_nomenclature_source_status": "STATUT_SOURCE",
}

# get the root logger
# log = logging.getLogger()
logger = logging.getLogger("MTD_SYNC")


def sync_ds(ds, cd_nomenclatures):
    """
    Will create or update a given DS according to UUID.
    Only process DS if dataset's cd_nomenclatures exists in ref_normenclatures.t_nomenclatures.

    :param ds: <dict> DS infos
    :param cd_nomenclatures: <array> cd_nomenclature from ref_normenclatures.t_nomenclatures
    """

    uuid_ds = ds["unique_dataset_id"]
    name_ds = ds["dataset_name"]

    logger.debug("MTD - PROCESSING DS WITH UUID '%s' AND NAME '%s'" % (uuid_ds, name_ds))

    if not ds["cd_nomenclature_data_origin"]:
        ds["cd_nomenclature_data_origin"] = "NSP"

    # FIXME: the following temporary fix was added due to possible differences in referential of nomenclatures values between INPN and GeoNature
    #     should be fixed by ensuring that the two referentials are identical, at least for instances that integrates with INPN and thus rely on MTD synchronization from INPN Métadonnées: GINCO and DEPOBIO instances.
    ds_cd_nomenclature_data_origin = ds["cd_nomenclature_data_origin"]
    if ds_cd_nomenclature_data_origin not in cd_nomenclatures:
        logger.warning(
            f"MTD - Nomenclature with code '{ds_cd_nomenclature_data_origin}' not found in database - SKIPPING SYNCHRONIZATION OF DATASET WITH UUID '{uuid_ds}' AND NAME '{name_ds}'"
        )
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
        logger.warning(
            f"MTD - AF with UUID '{af_uuid}' not found in database - SKIPPING SYNCHRONIZATION OF DATASET WITH UUID '{uuid_ds}' AND NAME '{name_ds}'"
        )
        return

    ds["id_acquisition_framework"] = af.id_acquisition_framework
    ds = {
        field.replace("cd_nomenclature", "id_nomenclature"): (
            func.ref_nomenclatures.get_id_nomenclature(NOMENCLATURE_MAPPING[field], value)
            if field.startswith("cd_nomenclature")
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
    # TODO: handle case where af_uuid is None ; as will raise an error at database level when executing the statement below ;
    #   af_uuid being None, i.e. af UUID is missing, could be due to no UUID specified in `<ca:identifiantCadre/>` tag in the XML file
    #   Solutions - if UUID is missing:
    #       - Just pass the sync of the AF
    #       - Generate a UUID for the AF
    af_uuid = af["unique_acquisition_framework_id"]

    if not af_uuid:
        logger.warning(
            f"No UUID provided for the AF with UUID '{af_uuid}' - SKIPPING SYNCHRONIZATION FOR THIS AF."
        )
        return None

    af_exists = DB.session.scalar(
        exists().where(TAcquisitionFramework.unique_acquisition_framework_id == af_uuid).select()
    )

    # Update statement if AF already exists in DB else insert statement
    statement = (
        update(TAcquisitionFramework)
        .where(TAcquisitionFramework.unique_acquisition_framework_id == af_uuid)
        .values(**af)
    )
    if not af_exists:
        statement = (
            pg_insert(TAcquisitionFramework)
            .values(**af)
            .on_conflict_do_nothing(index_elements=["unique_acquisition_framework_id"])
        )
    DB.session.execute(statement)

    acquisition_framework = DB.session.scalars(
        select(TAcquisitionFramework).filter_by(unique_acquisition_framework_id=af_uuid)
    ).first()

    return acquisition_framework


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


def associate_actors(
    actors,
    CorActor: Union[CorAcquisitionFrameworkActor, CorDatasetActor],
    pk_name: Literal["id_acquisition_framework", "id_dataset"],
    pk_value: str,
    uuid_mtd: str,
):
    """
    Associate actors with either a given :
    - Acquisition framework - writing to the table `gn_meta.cor_acquisition_framework_actor`.
    - Dataset - writing to the table `gn_meta.cor_dataset_actor`.

    Parameters
    ----------
    actors : list
        list of actors
    CorActor : CorAcquisitionFrameworkActor | CorDatasetActor
        the SQLAlchemy model corresponding to the destination table
    pk_name : Literal['id_acquisition_framework', 'id_dataset']
        pk attribute name:
        - 'id_acquisition_framework' for AF
        - 'id_dataset' for DS
    pk_value : str
        pk value: ID of the AF or DS
    uuid_mtd : str
        UUID of the AF or DS
    """
    type_mtd = "AF" if pk_name == "id_acquisition_framework" else "DS"
    for actor in actors:
        id_organism = None
        uuid_organism = actor["uuid_organism"]
        # TODO: choose whether to add or update an organism with no UUID specified
        #   - add or update it using organism name only - field `organism`
        if uuid_organism:
            with DB.session.begin_nested():
                # create or update organisme
                # FIXME: prevent update of organism email from actor email ! Several actors may be associated to the same organism and still have different mails !
                id_organism = add_or_update_organism(
                    uuid=uuid_organism,
                    nom=actor["organism"] if actor["organism"] else "",
                    email=actor["email"],
                )
        # else:
        #     # Create a new organism in database from organism name
        #     #   /!\ Do not use actor email as organism email - create the organism with a name only and generating a new UUID
        #     raise NotImplementedError(
        #         f"Creation of new organism, if no UUID provided for the organism actor, not implemented yet."
        #     )
        values = dict(
            id_nomenclature_actor_role=func.ref_nomenclatures.get_id_nomenclature(
                "ROLE_ACTEUR", actor["actor_role"]
            ),
            **{pk_name: pk_value},
        )
        # TODO: choose wether to:
        #   - (retained) Try to associate to an organism first and then to a user
        #   - Try to associate to a user first and then to an organism
        if id_organism:
            values["id_organism"] = id_organism
        # TODO: handle case where no user is retrieved for the actor email:
        #   - (retained) Just do not try to associate the actor with the metadata
        #   - Try to retrieve and id_organism from the organism name - field `organism`
        #   - Try to retrieve and id_organism from the actor email considered as an organism email - field `email`
        #   - Try to insert a new user from the actor name - field `name` - and possibly also email - field `email`
        else:
            id_user_from_email = DB.session.scalar(
                select(User.id_role).filter_by(email=actor["email"]).where(User.groupe.is_(False))
            )
            if id_user_from_email:
                values["id_role"] = id_user_from_email
            else:
                # TODO: if actor role is "Contact Principal" ; id_nomenclature_actor_role = ? ; then a new user is created with a UUID and an ID only, but with no name nor email
                #   the metadata is then associated with this new user
                raise NotImplementedError(
                    f"If actor role is 'Contact Principal': creation of a new user, if no organism retrieved nor known user from email retrieved, not implemented yet."
                )
                logger.warning(
                    f"MTD - actor association impossible for {type_mtd} with UUID '{uuid_mtd}' because no id_organism nor id_role could be retrieved - with the following actor information:\n"
                    + format_str_dict_actor_for_logging(actor)
                )
                continue
        try:
            statement = (
                pg_insert(CorActor)
                .values(**values)
                .on_conflict_do_nothing(
                    index_elements=[
                        pk_name,
                        "id_organism" if id_organism else "id_role",
                        "id_nomenclature_actor_role",
                    ],
                )
            )
            DB.session.execute(statement)
        except IntegrityError as I:
            db.session.rollback()
            logger.error(
                f"MTD - DB INTEGRITY ERROR - actor association failed for {type_mtd} with UUID '{uuid_mtd}' and following actor information:\n"
                + format_sqlalchemy_error_for_logging(I)
                + format_str_dict_actor_for_logging(actor)
            )


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


def format_sqlalchemy_error_for_logging(error: SQLAlchemyError):
    """
    Format SQLAlchemy error information in a nice way for MTD logging

    Parameters
    ----------
    error : SQLAlchemyError
        the SQLAlchemy error

    Returns
    -------
    str
        formatted error information
    """
    indented_original_error_message = str(error.orig).replace("\n", "\n\t")

    formatted_error_message = "".join(
        [
            f"\t{indented_original_error_message}",
            f"SQL QUERY:  {error.statement}\n",
            f"\tSQL PARAMS:  {error.params}\n",
        ]
    )

    return formatted_error_message


def format_str_dict_actor_for_logging(actor: dict):
    """
    Format actor information in a nice way for MTD logging

    Parameters
    ----------
    actor : dict
        actor information: actor_role, email, name, organism, uuid_organism, ...

    Returns
    -------
    str
        formatted actor information
    """
    formatted_str_dict_actor = "\tACTOR:\n\t\t" + pprint.pformat(actor).replace(
        "\n", "\n\t\t"
    ).rstrip("\t")

    return formatted_str_dict_actor
