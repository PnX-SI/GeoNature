import datetime

from xml.etree import ElementTree as ET

from geonature.utils import utilsrequests
from flask import current_app

namespace = current_app.config['XML_NAMESPACE']
api_endpoint = current_app.config['MTD_API_ENDPOINT']


def get_acquisition_framework(uuid_af):
    url = "{}/cadre/export/xml/GetRecordById?id={}"
    r = utilsrequests.get(url.format(api_endpoint, uuid_af))
    if r.status_code == 200:
        return r.content
    return None


def parse_acquisition_framwork_xml(xml):
    root = ET.fromstring(xml)
    for ca in root.findall('.//' + namespace + 'CadreAcquisition'):
        ca_uuid = ca.find(namespace + 'identifiantCadre').text
        ca_name = ca.find(namespace + 'libelle').text
        ca_desc = ca.find(namespace + 'description')
        ca_desc = ca_desc.text if ca_desc else ''
        ca_start_date = ca.find('.//' + namespace + 'dateLancement')
        ca_start_date = ca_start_date.text if ca_start_date else datetime.datetime.now()
        ca_end_date = ca.find('.//' + namespace + 'dateCloture')
        ca_end_date = ca_end_date.text if ca_end_date else None

        return {
            'unique_acquisition_framework_id': ca_uuid,
            'acquisition_framework_name': ca_name,
            'acquisition_framework_desc': ca_desc,
            'acquisition_framework_start_date': ca_start_date,
            'acquisition_framework_end_date': ca_end_date
        }


def get_jdd_by_user_id(id_user):
    """ return the jdd(s) created by a user from the MTD web service
        params:
            - id:  id_user from CAS
        return: a XML """
    url = "{}/cadre/jdd/export/xml/GetRecordsByUserId?id={}"
    r = utilsrequests.get(url.format(api_endpoint, str(id_user)))
    if r.status_code == 200:
        return r.content
    return None


def parse_jdd_xml(xml):
    """ parse an mtd xml, return a list of datasets"""

    root = ET.fromstring(xml)
    jdd_list = []
    for jdd in root.findall(".//" + namespace + 'JeuDeDonnees'):
        jdd_uuid = jdd.find(namespace + 'identifiantJdd').text
        ca_uuid = jdd.find(namespace + 'identifiantCadre').text

        dataset_name = jdd.find(namespace + 'libelle').text
        dataset_shortname = jdd.find(namespace + 'libelleCourt').text
        dataset_desc = jdd.find(namespace + 'description')
        dataset_desc = dataset_desc.text if dataset_desc else ''

        terrestrial_domain = jdd.find(namespace + 'domaineTerrestre')
        terrestrial_domain = terrestrial_domain.text if terrestrial_domain else False

        marine_domain = jdd.find(namespace + 'domaineMarin')
        marine_domain = marine_domain.text if marine_domain else False

        current_jdd = {
            'unique_dataset_id': jdd_uuid,
            'uuid_acquisition_framework': ca_uuid,
            'dataset_name': dataset_name,
            'dataset_shortname': dataset_shortname,
            'dataset_desc': dataset_desc,
            'terrestrial_domain': terrestrial_domain,
            'marine_domain': marine_domain
        }

        jdd_list.append(current_jdd)
    return jdd_list
