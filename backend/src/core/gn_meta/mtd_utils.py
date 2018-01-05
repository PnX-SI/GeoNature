# coding: utf8

from xml.etree import ElementTree as ET
import requests

namespace = "{http://inpn.mnhn.fr/mtd}"

def get_acquisition_framework(uuid_af):
    try:
        r = requests.get("https://preprod-inpn.mnhn.fr/mtd/cadre/export/xml/GetRecordById?id="+uuid_af)
        assert r.status_code == 200
    except requests.exceptions.RequestException as e:
        raise
    except AssertionError:
        raise
    return r.content

def parse_acquisition_framwork_xml(xml):
    root = ET.fromstring(xml)
    for ca in root.findall('.//'+namespace+'CadreAcquisition'):
        ca_uuid = ca.find(namespace+'identifiantCadre').text
        ca_name = ca.find(namespace+'libelle').text
        ca_desc = ca.find(namespace+'description').text
        ca_start_date = ca.find('.//'+namespace+'dateLancement').text
        ca_end_date = ca.find('.//'+namespace+'dateCloture').text
        territory_level = ca.find(namespace+'niveauTerritorial').text
        type_financement = ca.find('.//'+namespace+'typeFinancement').text
        cible_ecologique = ca.find('.//'+namespace+'cibleEcologiqueOuGeologique').text
    
        return {
            'unique_acquisition_framework_id' : ca_uuid,
            'acquisition_framework_name' : ca_name,
            'acquisition_framework_desc' : ca_desc,
            'acquisition_framework_start_date' : ca_start_date,
            'acquisition_framework_end_date' : ca_end_date
        }


def get_jdd_by_user_id(id_user):
    """ return the jdd(s) created by a user from the MTD web service
        params:
            - id:  id_user from CAS
        return: a XML """
    try:
        r = requests.get("https://preprod-inpn.mnhn.fr/mtd/cadre/jdd/export/xml/GetRecordsByUserId?id="+str(id_user))
        assert r.status_code == 200
    except requests.exceptions.RequestException as e:
        raise
    except AssertionError:
        raise
    return r.content

def parse_jdd_xml(xml):
    """ parse an mtd xml, return a list of datasets"""
    
    root = ET.fromstring(xml)
    jdd_list = []
    for jdd in root.findall(".//"+namespace+'JeuDeDonnees'):
        jdd_uuid = jdd.find(namespace+'identifiantJdd').text
        ca_uuid = jdd.find(namespace+'identifiantCadre').text

        dataset_name = jdd.find(namespace+'libelle').text
        dataset_shortname = jdd.find(namespace+'libelleCourt').text
        dataset_desc = jdd.find(namespace+'description').text
        terrestrial_domain = jdd.find(namespace+'domaineTerrestre').text
        marine_domain = jdd.find(namespace+'domaineMarin').text

        current_jdd = {
            'unique_dataset_id': jdd_uuid,
            'uuid_acquisition_framework': ca_uuid,
            'dataset_name': dataset_name,
            'dataset_shortname': dataset_shortname,
            'dataset_desc': dataset_desc,
            'terrestrial_domain' : terrestrial_domain,
            'marine_domain': marine_domain,
            'id_program': 1,
        }

        jdd_list.append(current_jdd)
    return jdd_list