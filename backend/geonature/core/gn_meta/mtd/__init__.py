import logging
import time
from urllib.parse import urljoin
from lxml import etree
import requests

from geonature.core.auth.routes import insert_user_and_org
from geonature.core.gn_meta.models import (
    CorAcquisitionFrameworkActor,
    CorDatasetActor,
    TAcquisitionFramework,
)
from geonature.utils.config import config
from geonature.utils.env import db

from pypnnomenclature.models import TNomenclatures
from pypnusershub.db.models import User
from sqlalchemy import func, select

from .mtd_utils import associate_actors, sync_af, sync_ds
from .xml_parser import (
    parse_single_acquisition_framework_xml,
    parse_jdd_xml,
    parse_acquisition_frameworks_xml,
)

# create logger
logger = logging.getLogger("MTD_SYNC")
level_log_mtd_sync = config["MTD"]["SYNC_LOG_LEVEL"]
# config logger
logger.setLevel(level_log_mtd_sync)
handler = logging.StreamHandler()
formatter = logging.Formatter("%(asctime)s | %(levelname)s : %(message)s", "%Y-%m-%d %H:%M:%S")
handler.setFormatter(formatter)
logger.addHandler(handler)
# avoid logging output dupplication
logger.propagate = False

if level_log_mtd_sync == "DEBUG":
    from sqlalchemy import exists
    from geonature.core.gn_meta.models.datasets import TDatasets


class MTDInstanceApi:
    af_path = "/mtd/cadre/export/xml/GetRecordsByInstanceId?id={ID_INSTANCE}"
    ds_path = "/mtd/cadre/jdd/export/xml/GetRecordsByInstanceId?id={ID_INSTANCE}"
    # TODO: check if there are endpoints to retrieve metadata for a given user and instance, and not only a given user and whatever instance
    ds_user_path = "/mtd/cadre/jdd/export/xml/GetRecordsByUserId?id={ID_ROLE}"
    af_user_path = "/mtd/cadre/export/xml/GetRecordsByUserId?id={ID_ROLE}"
    single_af_path = "/mtd/cadre/export/xml/GetRecordById?id={ID_AF}"  # NOTE: `ID_AF` is actually an UUID and not an ID from the point of view of geonature database.

    # https://inpn.mnhn.fr/mtd/cadre/jdd/export/xml/GetRecordsByUserId?id=41542"
    def __init__(self, api_endpoint, instance_id, id_role=None):
        self.api_endpoint = api_endpoint
        self.instance_id = instance_id
        self.id_role = id_role

    def _get_xml_by_url(self, url):
        logger.debug("MTD - REQUEST : %s" % url)
        response = requests.get(url)
        response.raise_for_status()
        return response.content

    def _get_xml(self, path):
        url = urljoin(self.api_endpoint, path)
        url = url.format(ID_INSTANCE=self.instance_id)
        return self._get_xml_by_url(url)

    def _get_af_xml(self):
        return self._get_xml(self.af_path)

    def get_af_list(self) -> list:
        xml = self._get_af_xml()
        return parse_acquisition_frameworks_xml(xml)

    def _get_ds_xml(self):
        return self._get_xml(self.ds_path)

    def get_ds_list(self) -> list:
        xml = self._get_ds_xml()
        return parse_jdd_xml(xml)

    def get_ds_user_list(self):
        """
        Retrieve the list of of datasets (ds) for the user.

        Returns
        -------
        list
            A list of datasets (ds) for the user.
        """
        url = urljoin(self.api_endpoint, self.ds_user_path)
        url = url.format(ID_ROLE=self.id_role)
        try:
            xml = self._get_xml_by_url(url)
        except requests.HTTPError as http_error:
            error_code = http_error.response.status_code
            warning_message = f"""[HTTPError : {error_code}] for URL "{url}"."""
            if error_code == 404:
                warning_message = f"""{warning_message} > Probably no dataset found for the user with ID '{self.id_role}'"""
            logger.warning(warning_message)
            return []
        ds_list = parse_jdd_xml(xml)
        return ds_list

    def get_list_af_for_user(self):
        """
        Retrieve a list of acquisition frameworks (af) for the user.

        Returns
        -------
        list
            A list of acquisition frameworks for the user.
        """
        url = urljoin(self.api_endpoint, self.af_user_path).format(ID_ROLE=self.id_role)
        try:
            xml = self._get_xml_by_url(url)
        except requests.HTTPError as http_error:
            error_code = http_error.response.status_code
            warning_message = f"""[HTTPError : {error_code}] for URL "{url}"."""
            if error_code == 404:
                warning_message = f"""{warning_message} > Probably no acquisition framework found for the user with ID '{self.id_role}'"""
            logger.warning(warning_message)
            return []
        af_list = parse_acquisition_frameworks_xml(xml)
        return af_list

    def get_single_af(self, af_uuid):
        """
        Return a single acquistion framework based on its uuid.

        Parameters
        ----------
        af_uuid : str
            uuid of the acquisition framework

        Returns
        -------
        dict
            acquisition framework data
        """
        url = urljoin(self.api_endpoint, self.single_af_path)
        url = url.format(ID_AF=af_uuid)
        xml = self._get_xml_by_url(url)
        return parse_single_acquisition_framework_xml(xml)


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
    """
    Method to trigger global MTD sync.

    :param id_digitizer: as id role from meta info
    """
    if (
        not db.session.scalar(
            select(func.count("*")).select_from(User).filter_by(id_role=id_digitizer)
        )
        > 0
    ):
        # not fast - need perf optimization on user call
        user = INPNCAS.get_user(id_digitizer)
        # to avoid to create org
        if user.get("codeOrganisme"):
            user["codeOrganisme"] = None
        # insert or update user
        insert_user_and_org(user)


def process_af_and_ds(af_list, ds_list, id_role=None):
    """
    Synchro AF<array>, Synchro DS<array>

    :param af_list: list af
    :param ds_list: list ds
    :param id_role: use role id pass on user authent only
    """
    cas_api = INPNCAS()
    # read nomenclatures from DB to avoid errors if GN nomenclature is not the same
    list_cd_nomenclature = db.session.scalars(
        select(TNomenclatures.cd_nomenclature).distinct()
    ).all()
    logger.debug("MTD - PROCESS AF LIST")
    if level_log_mtd_sync == "DEBUG":
        nb_af = len(af_list)
        nb_ds = len(ds_list)
        logger.debug(f"Number of AF to process : {nb_af}")
        logger.debug(f"Number of DS to process : {nb_ds}")
        nb_updated_af = 0
        nb_updated_ds = 0
        nb_retrieved_new_af = 0
        nb_retrieved_new_ds = 0
    for af in af_list:
        actors = af.pop("actors")
        with db.session.begin_nested():
            start_add_user_time = time.time()
            add_unexisting_digitizer(af["id_digitizer"] if not id_role else id_role)
        if level_log_mtd_sync == "DEBUG":
            af_already_exists = db.session.scalar(
                exists()
                .where(
                    TAcquisitionFramework.unique_acquisition_framework_id
                    == af["unique_acquisition_framework_id"]
                )
                .select()
            )
        af = sync_af(af)
        # TODO: choose whether or not to commit retrieval of the AF before association of actors
        #   and possibly retrieve an AF without any actor associated to it
        # Commit here to retrieve the AF even if the association of actors that follows is to fail
        db.session.commit()
        # If the AF has not been retrieved, associated actors cannot be retrieved either
        #   and thus we continue to the next AF
        if af is not None:
            if level_log_mtd_sync == "DEBUG":
                if af_already_exists:
                    nb_updated_af += 1
                else:
                    nb_retrieved_new_af += 1
            associate_actors(
                actors,
                CorAcquisitionFrameworkActor,
                "id_acquisition_framework",
                af.id_acquisition_framework,
                af.unique_acquisition_framework_id,
            )
        # TODO: check the following TODO:
        # TODO: remove actors removed from MTD
    db.session.commit()
    logger.debug("MTD - PROCESS DS LIST")
    for ds in ds_list:
        actors = ds.pop("actors")
        # CREATE DIGITIZER
        with db.session.begin_nested():
            start_add_user_time = time.time()
            if not id_role:
                add_unexisting_digitizer(ds["id_digitizer"])
            else:
                add_unexisting_digitizer(id_role)
        if level_log_mtd_sync == "DEBUG":
            ds_already_exists = db.session.scalar(
                exists()
                .where(
                    TDatasets.unique_dataset_id == ds["unique_dataset_id"],
                )
                .select()
            )
        ds = sync_ds(ds, list_cd_nomenclature)
        # TODO: choose whether or not to commit retrieval of the DS before association of actors
        ##db.session.commit()
        if ds is not None:
            if level_log_mtd_sync == "DEBUG":
                if ds_already_exists:
                    nb_updated_ds += 1
                else:
                    nb_retrieved_new_ds += 1
            associate_actors(
                actors,
                CorDatasetActor,
                "id_dataset",
                ds.id_dataset,
                ds.unique_dataset_id,
            )

    db.session.commit()

    if level_log_mtd_sync == "DEBUG":
        nb_ds_not_retrieved_or_not_updated = nb_ds - nb_updated_ds - nb_retrieved_new_ds
        logger.debug(
            f"{nb_ds} DS processed : {nb_updated_ds} DS updated (including no change made) + {nb_retrieved_new_ds} new DS retrieved + {nb_ds_not_retrieved_or_not_updated} DS not retrieved or not updated"
        )
        nb_af_not_retrieved_or_not_updated = nb_af - nb_updated_af - nb_retrieved_new_af
        logger.debug(
            f"{nb_af} AF processed : {nb_updated_af} AF updated (including no change made) + {nb_retrieved_new_af} new AF retrieved + {nb_af_not_retrieved_or_not_updated} AF not retrieved or not updated"
        )


def sync_af_and_ds():
    """
    Method to trigger global MTD sync.
    """
    logger.info("MTD - SYNC GLOBAL : START")
    mtd_api = MTDInstanceApi(config["MTD_API_ENDPOINT"], config["MTD"]["ID_INSTANCE_FILTER"])

    af_list = mtd_api.get_af_list()

    ds_list = mtd_api.get_ds_list()

    # synchro a partir des listes
    process_af_and_ds(af_list, ds_list)
    logger.info("MTD - SYNC GLOBAL : FINISH")


def sync_af_and_ds_by_user(id_role, id_af=None):
    """
    Method to trigger MTD sync on user authentication.

    Parameters
    -----------
    id_role : int
        The ID of the role (group or user).
    id_af : str, optional
        The ID of an AF (Acquisition Framework).
    """

    logger.info("MTD - SYNC USER : START")

    # Create an instance of MTDInstanceApi
    mtd_api = MTDInstanceApi(
        config["MTD_API_ENDPOINT"], config["MTD"]["ID_INSTANCE_FILTER"], id_role
    )

    # Get the list of datasets (ds) for the user
    # NOTE: `mtd_api.get_ds_user_list()` tested and timed to about 7 seconds on the PROD instance 'GINCO Occtax' with id_role = 13829 > a user with a lot of metadata to be retrieved from 'INPN Métadonnées' to 'GINCO Occtax'
    ds_list = mtd_api.get_ds_user_list()

    if not id_af:
        # TODO: check the following commented section
        #   - Choose how to get the list of AF for the user, that will be retrieved
        # # Get the unique UUIDs of the acquisition frameworks for the user
        # set_user_af_uuids = {ds["uuid_acquisition_framework"] for ds in ds_list}
        # user_af_uuids = list(set_user_af_uuids)
        #
        # # TODO - voir avec INPN pourquoi les AF par user ne sont pas dans l'appel global des AF
        # # Ce code ne fonctionne pas pour cette raison -> AF manquants
        # # af_list = mtd_api.get_af_list()
        # # af_list = [af for af in af_list if af["unique_acquisition_framework_id"] in user_af_uuids]

        # Get the list of acquisition frameworks for the user
        # call INPN API for each AF to retrieve info
        af_list = mtd_api.get_list_af_for_user()
    else:
        # TODO: Check the following TODO
        # TODO: handle case where the AF ; corresponding to the provided `id_af` ; does not exist yet in the database
        #   this case should not happend from a user action because the only case where `id_af` is provided is for when the user click to unroll an AF in the module Metadata, in which case the AF already exists in the database.
        #   It would still be better to handle case where the AF does not exist in the database, and to first retrieve the AF from 'INPN Métadonnées' in this case
        uuid_af = TAcquisitionFramework.query.get(id_af).unique_acquisition_framework_id
        uuid_af = str(uuid_af).upper()

        # Get the acquisition framework for the specified UUID, thus a list of one element
        af_list = [mtd_api.get_single_af(uuid_af)]

        # Filter the datasets based on the specified UUID
        # TODO: check if there could be a difference for the AF between :
        #   - information displayed in the frontend page with the list of metadata
        #   - information retrieved from INPN MTD sync and committed to the database meanwhile
        #   If so, determine whether it is problematic ; and frontend content should be updated accordingly ; or not
        ds_list = [ds for ds in ds_list if ds["uuid_acquisition_framework"] == uuid_af]

    # Process the acquisition frameworks and datasets
    process_af_and_ds(af_list, ds_list, id_role)

    logger.info("MTD - SYNC USER : FINISH")
