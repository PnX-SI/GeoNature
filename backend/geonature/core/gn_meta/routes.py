import json
from flask import Blueprint

from sqlalchemy import or_
from sqlalchemy.sql import text

from geonature.utils.env import DB

from geonature.core.gn_meta.models import (
    TPrograms, TDatasets, TParameters,
    CorDatasetsActor, TAcquisitionFramework,
    CorAcquisitionFrameworkActor
)
from pypnusershub import routes as fnauth
from geonature.utils.utilssqlalchemy import json_resp
from geonature.utils.utilsrequests import return_or_404
from geonature.core.gn_meta import mtd_utils

routes = Blueprint('gn_meta', __name__)


@routes.route('/list/programs', methods=['GET'])
@json_resp
def get_programs_list():
    q = DB.session.query(TPrograms)
    data = q.all()

    return return_or_404([
        d.as_dict(columns=('id_program', 'program_desc')) for d in data
    ])


@routes.route('/programs', methods=['GET'])
@json_resp
def get_programs():
    q = DB.session.query(TPrograms)
    data = q.all()

    return return_or_404([n.as_dict(False) for n in data])


@routes.route('/programswithdatasets', methods=['GET'])
@json_resp
def get_programsWithDatasets():
    q = DB.session.query(TPrograms)
    data = q.all()

    return return_or_404([n.as_dict(False) for n in data])


@routes.route('/list/datasets', methods=['GET'])
@json_resp
def get_datasets_list():
    q = DB.session.query(TDatasets)
    data = q.all()

    return return_or_404([
            d.as_dict(columns=('id_dataset', 'dataset_name')) for d in data
    ])


@routes.route('/datasets', methods=['GET'])
@fnauth.check_auth_cruved('R', True)
@json_resp
def get_datasets(info_role):
    """
        Retourne la liste des datasets

    """
    q = DB.session.query(TDatasets)
    if int(info_role.tag_object_code) <= 2:
        q = q.join(
            CorDatasetsActor,
            CorDatasetsActor.id_dataset == TDatasets.id_dataset
        ).filter(
            or_(
                CorDatasetsActor.id_organism == info_role.id_organisme,
                CorDatasetsActor.id_role == info_role.id_role
            )
        )
    data = q.all()

    return return_or_404([d.as_dict(True) for d in data])


@routes.route('/list/parameters', methods=['GET'])
@json_resp
def get_parameters_list():
    q = DB.session.query(TParameters)
    data = q.all()

    return return_or_404([d.as_dict() for d in data])


@routes.route('/parameters/<param_name>', methods=['GET'])
@routes.route('/parameters/<param_name>/<int:id_org>', methods=['GET'])
@json_resp
def get_one_parameter(param_name, id_org=None):
    q = DB.session.query(TParameters)
    q = q.filter(TParameters.parameter_name == param_name)
    if id_org:
        q = q.filter(TParameters.id_organism == id_org)

    data = q.all()
    return return_or_404([d.as_dict() for d in data])


def get_cd_nomenclature(id_type, cd_nomenclature):
    query = 'SELECT ref_nomenclatures.get_id_nomenclature(:id_type, :cd_n)'
    result = DB.engine.execute(
        text(query),
        id_type=id_type,
        cd_n=cd_nomenclature
    ).first()
    value = None
    if len(result) >= 1:
        value = result[0]
    return value


@routes.route('/aquisition_framework_mtd/<uuid_af>', methods=['POST'])
@json_resp
def post_acquisition_framwork_mtd(uuid=None, id_user=None, id_organism=None):
    """ Post an acquisition framwork from MTD XML"""
    xml_af = mtd_utils.get_acquisition_framework(uuid)

    if xml_af:
        acquisition_framwork = mtd_utils.parse_acquisition_framwork_xml(xml_af)
        new_af = TAcquisitionFramework(**acquisition_framwork)
        actor = CorAcquisitionFrameworkActor(
            id_role=id_user,
            id_nomenclature_actor_role=393
        )
        new_af.cor_af_actor.append(actor)
        if id_organism:
            organism = CorAcquisitionFrameworkActor(
                id_role=id_organism,
                id_nomenclature_actor_role=393
            )
            new_af.cor_af_actor.append(actor)
        # check if exist
        id_acquisition_framework = TAcquisitionFramework.get_id(uuid)
        if id_acquisition_framework:
            new_af.id_acquisition_framework = id_acquisition_framework
            DB.session.merge(new_af)
        else:
            DB.session.add(new_af)
            DB.session.commit()
        return new_af.as_dict()

    return {'message': 'Not found'}, 404


@routes.route('/dataset_mtd/<id_user>', methods=['POST'])
@routes.route('/dataset_mtd/<id_user>/<id_organism>', methods=['POST'])
@json_resp
def post_jdd_from_user_id(id_user=None, id_organism=None):
    """ Post a jdd from the mtd XML"""
    xml_jdd = mtd_utils.get_jdd_by_user_id(id_user)

    if xml_jdd:
        dataset_list = mtd_utils.parse_jdd_xml(xml_jdd)
        dataset_list_model = []
        for ds in dataset_list:
            new_af = post_acquisition_framwork_mtd(
                uuid=ds['uuid_acquisition_framework'],
                id_user=id_user,
                id_organism=id_organism
            )
            new_af = new_af.get_data()
            new_af = json.loads(new_af.decode('utf-8'))
            ds['id_acquisition_framework'] = new_af['id_acquisition_framework'][0]

            ds.pop('uuid_acquisition_framework')
            print('LAAAAAA')
            print(ds['unique_dataset_id'])
            # get the id of the dataset to check if exists
            id_dataset = TDatasets.get_id(ds['unique_dataset_id'])
            ds['id_dataset'] = id_dataset

            dataset = TDatasets(**ds)

            # id_role in cor_dataset_actor
            actor = CorDatasetsActor(
                id_role=id_user,
                id_nomenclature_actor_role=393
            )
            dataset.cor_datasets_actor.append(actor)
            # id_organism in cor_dataset_actor
            if id_organism:
                actor = CorDatasetsActor(
                    id_organism=id_organism,
                    id_nomenclature_actor_role=393
                )
                dataset.cor_datasets_actor.append(actor)

            dataset_list_model.append(dataset)
            if id_dataset:
                DB.session.merge(dataset)
            else:
                DB.session.add(dataset)

            DB.session.commit()
            DB.session.flush()

        return [d.as_dict() for d in dataset_list_model]
    return {'message': 'Not found'}, 404


#  Private fonction
def get_allowed_datasets(user):
    """ return all dataset id allowed for a user"""
    q = DB.session.query(
        CorDatasetsActor,
        CorDatasetsActor.id_dataset
    ).filter(
        or_(
            CorDatasetsActor.id_organism == user.id_organisme,
            CorDatasetsActor.id_role == user.id_role
        )
    )
    try:
        return [d.id_dataset for d in q.all()]
    except Exception:
        DB.session.rollback()
        raise
