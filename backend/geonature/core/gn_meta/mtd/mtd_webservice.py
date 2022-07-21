from geonature.utils import utilsrequests
from geonature.utils.errors import GeonatureApiError
from geonature.utils.config import config

api_endpoint = config["MTD_API_ENDPOINT"]


def get_acquisition_framework(uuid_af):
    """
    Fetch a AF from the MTD WS with the uuid of the AD

    Parameters:
        - uuid_af (str): the uuid of the AF
    Returns:
        byte: the xml of the AF as byte
    """
    url = "{}/cadre/export/xml/GetRecordById?id={}"
    try:
        r = utilsrequests.get(url.format(api_endpoint, uuid_af))
    except AssertionError:
        raise GeonatureApiError(
            message="Error with the MTD Web Service while getting Acquisition Framwork"
        )
    return r.content


def get_jdd_by_user_id(id_user):
    """fetch the jdd(s) created by a user from the MTD web service
    Parameters:
        - id (int):  id_user from CAS
    Return:
        byte: a XML as byte
    """
    url = "{}/cadre/jdd/export/xml/GetRecordsByUserId?id={}"
    try:
        r = utilsrequests.get(url.format(api_endpoint, str(id_user)))
        assert r.status_code == 200
    except AssertionError:
        raise GeonatureApiError(
            message="Error with the MTD Web Service (JDD), status_code: {}".format(r.status_code)
        )
    return r.content


def get_jdd_by_uuid(uuid):
    ds_URL = f"{api_endpoint}/cadre/jdd/export/xml/GetRecordById?id={uuid.upper()}"
    try:
        r = utilsrequests.get(ds_URL)
        assert r.status_code == 200
    except AssertionError:
        print(f"NO JDD FOUND FOR UUID {uuid}")
    return r.content
