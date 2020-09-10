import datetime
import json

from flask import current_app
from lxml import etree as ET

namespace = current_app.config["XML_NAMESPACE"]

_xml_parser = ET.XMLParser(ns_clean=True, recover=True, encoding="utf-8")


def get_tag_content(parent, tag_name, default_value=None):
    """
    Return the content of a xml tag
    Check if the node exist or return a default value
    Params:
        parent (etree Element): the parent where find the tag
        tag_name (str): the name of the tag
        default_value (any): the default value f the tag doesn't exist
    Return
        any: the tag content or the default value
    """
    tag = parent.find(namespace + tag_name)
    if tag is not None:
        if tag.text and len(tag.text) > 0:
            return tag.text
    return default_value

    return tag.text if tag is not None else default_value


def parse_actors_xml(actors):
    actor_list = []
    if actors is not None:
        for actor_type_node in actors:
            print(actor_type_node)
            name = get_tag_content(actor_type_node, "nomPrenom")
            actor_role = get_tag_content(actor_type_node, "roleActeur")
            uuid_organism = get_tag_content(actor_type_node, "idOrganisme")
            organism = get_tag_content(actor_type_node, "organisme")

            actor_list.append(
                {
                    "name": name,
                    "uuid_organism": uuid_organism,
                    "organism": organism,
                    "actor_role": actor_role,
                }
            )

    return actor_list


def parse_acquisition_framwork_xml(xml):
    """
        Parse an xml of AF from a string
        Return: 
            dict: a dict of the parsed xml 
    """
    root = ET.fromstring(xml, parser=_xml_parser)
    ca = root.find(".//" + namespace + "CadreAcquisition")
    ca_uuid = get_tag_content(ca, "identifiantCadre")
    ca_name = get_tag_content(ca, "libelle")
    ca_desc = get_tag_content(ca, "description", default_value="")
    ca_start_date = get_tag_content(
        ca, "dateLancement", default_value=datetime.datetime.now()
    )
    ca_end_date = get_tag_content(ca, "dateCloture")
    ca_id_digitizer = None
    attributs_additionnels_node = ca.find(namespace + "attributsAdditionnels")

    for attr in attributs_additionnels_node:
        if get_tag_content(attr, "nomAttribut") == "ID_CREATEUR":
            ca_id_digitizer = get_tag_content(attr, "valeurAttribut")

    principal_actor = parse_actors_xml(ca.find(namespace + "acteurPrincipal"))
    secondary_actors = parse_actors_xml(ca.find(namespace + "acteurAutre"))
    all_actors = principal_actor + secondary_actors

    return {
        "unique_acquisition_framework_id": ca_uuid,
        "acquisition_framework_name": ca_name,
        "acquisition_framework_desc": ca_desc,
        "acquisition_framework_start_date": ca_start_date,
        "acquisition_framework_end_date": ca_end_date,
        "id_digitizer": ca_id_digitizer,
        "actors": all_actors,
    }


def parse_jdd_xml(xml):
    """
        Parse an xml of datasets from a string
        Return: 
            list: a list of dict of the JDD in the xml
    """

    root = ET.fromstring(xml, parser=_xml_parser)
    jdd_list = []
    for jdd in root.findall(".//" + namespace + "JeuDeDonnees"):
        jdd_uuid = get_tag_content(jdd, "identifiantJdd")
        ca_uuid = get_tag_content(jdd, "identifiantCadre")

        dataset_name = get_tag_content(jdd, "libelle")
        dataset_shortname = get_tag_content(jdd, "libelleCourt")
        dataset_desc = get_tag_content(jdd, "description", default_value="")
        terrestrial_domain = get_tag_content(jdd, "domaineTerrestre")
        marine_domain = get_tag_content(jdd, "domaineMarin")
        data_type = get_tag_content(jdd, "typeDonnees")
        attributs_additionnels_node = jdd.find(namespace + "attributsAdditionnels")

        id_digitizer = None
        id_platform = None
        for attr in attributs_additionnels_node:
            if get_tag_content(attr, "nomAttribut") == "ID_CREATEUR":
                id_digitizer = get_tag_content(attr, "valeurAttribut")

            if get_tag_content(attr, "nomAttribut") == "ID_PLATEFORME":
                id_platform = get_tag_content(attr, "valeurAttribut")

        point_contact_jdd_actors = parse_actors_xml(
            jdd.find(namespace + "pointContactJdd")
        )

        point_contact_pf_actors = parse_actors_xml(
            jdd.find(namespace + "pointContactPF")
        )

        keywords = None

        all_actors = point_contact_pf_actors + point_contact_jdd_actors

        current_jdd = {
            "unique_dataset_id": jdd_uuid,
            "uuid_acquisition_framework": ca_uuid,
            "dataset_name": dataset_name,
            "dataset_shortname": dataset_shortname,
            "dataset_desc": dataset_desc,
            "keywords": keywords,
            "terrestrial_domain": json.loads(terrestrial_domain),
            "marine_domain": json.loads(marine_domain),
            "id_nomenclature_data_type": data_type,
            "id_digitizer": id_digitizer,
            "actors": all_actors,
        }

        required_platform_id = None  # Dummy value to test
        if not required_platform_id or id_platform == required_platform_id:
            jdd_list.append(current_jdd)
    return jdd_list
