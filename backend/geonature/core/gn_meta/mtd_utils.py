import datetime
import logging

from flask import current_app
from xml.etree import ElementTree as ET

from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.sql import func

from geonature.utils import utilsrequests
from geonature.utils.errors import GeonatureApiError

from geonature.utils.env import DB
from geonature.core.gn_meta.models import (
    TDatasets, CorDatasetActor,
    TAcquisitionFramework, CorAcquisitionFrameworkActor
)



namespace = current_app.config['XML_NAMESPACE']
api_endpoint = current_app.config['MTD_API_ENDPOINT']

# get the root logger
log = logging.getLogger()
gunicorn_error_logger = logging.getLogger('gunicorn.error')

def get_acquisition_framework(uuid_af):
    url = "{}/cadre/export/xml/GetRecordById?id={}"
    try:
        r = utilsrequests.get(url.format(api_endpoint, uuid_af))
    except AssertionError:
        raise GeonatureApiError(message="Error with the MTD Web Service while getting Acquisition Framwork")
    return r.content



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
    try:
        r = utilsrequests.get(url.format(api_endpoint, str(id_user)))
        assert r.status_code == 200
    except AssertionError:
        raise GeonatureApiError(message="Error with the MTD Web Service (JDD), status_code: {}".format(r.status_code))
    return r.content

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


def post_acquisition_framework(uuid=None, id_user=None, id_organism=None):
    """ Post an acquisition framwork from MTD XML"""
    xml_af = None
    xml_af = get_acquisition_framework(uuid)


    if xml_af:
        acquisition_framwork = parse_acquisition_framwork_xml(xml_af)
        new_af = TAcquisitionFramework(**acquisition_framwork)
        actor = CorAcquisitionFrameworkActor(
            id_role=id_user,
            id_nomenclature_actor_role=func.ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '1')
        )
        new_af.cor_af_actor.append(actor)
        if id_organism:
            organism = CorAcquisitionFrameworkActor(
                id_organism=id_organism,
                id_nomenclature_actor_role=func.ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '1')
            )
            new_af.cor_af_actor.append(organism)
        # check if exist
        id_acquisition_framework = TAcquisitionFramework.get_id(uuid)
        try:
            if id_acquisition_framework:
                new_af.id_acquisition_framework = id_acquisition_framework[0]
                DB.session.merge(new_af)
            else:
                DB.session.add(new_af)
                DB.session.commit()
        # TODO catch db error ?
        except SQLAlchemyError as e:
            DB.session.rollback()
            error_msg = """
                Error posting an aquisition framework {} \n\n Trace: \n {}
                """.format(uuid, e)
            log.error(error_msg)

        return new_af.as_dict()

    return {'message': 'Not found'}, 404


def post_jdd_from_user(id_user=None, id_organism=None):
    """ Post a jdd from the mtd XML"""
    xml_jdd = None
    xml_jdd = get_jdd_by_user_id(id_user)

    if xml_jdd:
        dataset_list = parse_jdd_xml(xml_jdd)
        dataset_list_model = []
        for ds in dataset_list:
            new_af = post_acquisition_framework(
                uuid=ds['uuid_acquisition_framework'],
                id_user=id_user,
                id_organism=id_organism
            )
            ds['id_acquisition_framework'] = new_af['id_acquisition_framework']

            ds.pop('uuid_acquisition_framework')
            # get the id of the dataset to check if exists
            id_dataset = TDatasets.get_id(ds['unique_dataset_id'])
            ds['id_dataset'] = id_dataset

            dataset = TDatasets(**ds)

            # id_role in cor_dataset_actor
            actor = CorDatasetActor(
                id_role=id_user,
                id_nomenclature_actor_role=func.ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '1')
            )
            dataset.cor_dataset_actor.append(actor)
            # id_organism in cor_dataset_actor
            if id_organism:
                actor = CorDatasetActor(
                    id_organism=id_organism,
                    id_nomenclature_actor_role=func.ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '1')
                )
                dataset.cor_dataset_actor.append(actor)

            dataset_list_model.append(dataset)
            try:
                if id_dataset:
                    DB.session.merge(dataset)
                else:
                    DB.session.add(dataset)
                DB.session.commit()
                DB.session.flush()
            # TODO catch db error ?
            except SQLAlchemyError as e:
                DB.session.rollback()
                error_msg = """
                Error posting JDD {} \n\n Trace: \n {}
                """.format(ds['unique_dataset_id'], e)
                log.error(error_msg)                
                raise GeonatureApiError(error_msg)

        return [d.as_dict() for d in dataset_list_model]
    return {'message': 'Not found'}, 404
