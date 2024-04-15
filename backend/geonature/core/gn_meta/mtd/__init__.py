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
from .xml_parser import parse_acquisition_framework, parse_acquisition_framwork_xml, parse_jdd_xml

# create logger
logger = logging.getLogger("MTD_SYNC")
# config logger
logger.setLevel(config["MTD"]["SYNC_LOG_LEVEL"])
handler = logging.StreamHandler()
formatter = logging.Formatter("%(asctime)s | %(levelname)s : %(message)s", "%Y-%m-%d %H:%M:%S")
handler.setFormatter(formatter)
logger.addHandler(handler)
# avoid logging output dupplication
logger.propagate = False


class MTDInstanceApi:
    af_path = "/mtd/cadre/export/xml/GetRecordsByInstanceId?id={ID_INSTANCE}"
    ds_path = "/mtd/cadre/jdd/export/xml/GetRecordsByInstanceId?id={ID_INSTANCE}"
    ds_user_path = "/mtd/cadre/jdd/export/xml/GetRecordsByUserId?id={ID_ROLE}"
    af_user_path = "/mtd/cadre/export/xml/GetRecordsByUserId?id={ID_ROLE}"
    single_af_path = "/mtd/cadre/export/xml/GetRecordById?id={ID_AF}"

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

    def get_af_list(self):
        xml = self._get_af_xml()
        _xml_parser = etree.XMLParser(ns_clean=True, recover=True, encoding="utf-8")
        root = etree.fromstring(xml, parser=_xml_parser)
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
        except requests.HttpError as http_error:
            error_code = http_error.response.status_code
            warning_message = f"""[HttpError : {error_code}] for URL "{url}"."""
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
        except requests.HttpError as http_error:
            error_code = http_error.response.status_code
            warning_message = f"""[HttpError : {error_code}] for URL "{url}"."""
            if error_code == 404:
                warning_message = f"""{warning_message} > Probably no acquisition framework found for the user with ID '{self.id_role}'"""
            logger.warning(warning_message)
            return []
        _xml_parser = etree.XMLParser(ns_clean=True, recover=True, encoding="utf-8")
        root = etree.fromstring(xml, parser=_xml_parser)
        af_iter = root.findall(".//{http://inpn.mnhn.fr/mtd}CadreAcquisition")
        af_list = [parse_acquisition_framework(af) for af in af_iter]
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
        return parse_acquisition_framwork_xml(xml)


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
    user_add_total_time = 0
    logger.debug("MTD - PROCESS AF LIST")
    for af in af_list:
        actors = af.pop("actors")
        with db.session.begin_nested():
            start_add_user_time = time.time()
            add_unexisting_digitizer(af["id_digitizer"] if not id_role else id_role)
            user_add_total_time += time.time() - start_add_user_time
        af = sync_af(af)
        associate_actors(
            actors,
            CorAcquisitionFrameworkActor,
            "id_acquisition_framework",
            af.id_acquisition_framework,
        )
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
            user_add_total_time += time.time() - start_add_user_time
        ds = sync_ds(ds, list_cd_nomenclature)
        if ds is not None:
            associate_actors(actors, CorDatasetActor, "id_dataset", ds.id_dataset)

    user_add_total_time = round(user_add_total_time, 2)
    db.session.commit()


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

    Args:
        id_role (int): The ID of the role (group or user).
        id_af (str, optional): The ID of the AF (Acquisition Framework). Defaults to None.
    """

    logger.info("MTD - SYNC USER : START")

    # Create an instance of MTDInstanceApi
    mtd_api = MTDInstanceApi(
        config["MTD_API_ENDPOINT"], config["MTD"]["ID_INSTANCE_FILTER"], id_role
    )

    # Get the list of datasets (ds) for the user
    ds_list = mtd_api.get_ds_user_list()

    if not id_af:
        # Get the unique UUIDs of the acquisition frameworks for the user
        set_user_af_uuids = {ds["uuid_acquisition_framework"] for ds in ds_list}
        user_af_uuids = list(set_user_af_uuids)

        # TODO - voir avec INPN pourquoi les AF par user ne sont pas dans l'appel global des AF
        # Ce code ne fonctionne pas pour cette raison -> AF manquants
        # af_list = mtd_api.get_af_list()
        # af_list = [af for af in af_list if af["unique_acquisition_framework_id"] in user_af_uuids]

        # Get the list of acquisition frameworks for the user
        # call INPN API for each AF to retrieve info
        af_list = mtd_api.get_list_af_for_user()
    else:
        uuid_af = TAcquisitionFramework.query.get(id_af).unique_acquisition_framework_id
        uuid_af = str(uuid_af).upper()

        # Get the acquisition framework for the specified UUID, thus a list of one element
        af_list = [mtd_api.get_single_af(uuid_af)]

        # Filter the datasets based on the specified UUID
        ds_list = [ds for ds in ds_list if ds["uuid_acquisition_framework"] == uuid_af]

    # Process the acquisition frameworks and datasets
    process_af_and_ds(af_list, ds_list, id_role)

    logger.info("MTD - SYNC USER : FINISH")
