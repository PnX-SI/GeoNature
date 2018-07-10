import json
import logging
from flask import Blueprint, current_app, request

from sqlalchemy import or_
from sqlalchemy.sql import text

from geonature.utils.env import DB

from geonature.core.gn_meta.models import (
    TDatasets,
    CorDatasetActor, TAcquisitionFramework,
    CorAcquisitionFrameworkActor
)
from geonature.core.gn_commons.models import TParameters
from pypnusershub import routes as fnauth
from geonature.utils.utilssqlalchemy import json_resp
from geonature.core.gn_meta import mtd_utils
from geonature.utils.errors import GeonatureApiError

routes = Blueprint('gn_meta', __name__)

# get the root logger
log = logging.getLogger()
gunicorn_error_logger = logging.getLogger('gunicorn.error')


@routes.route('/list/datasets', methods=['GET'])
@json_resp
def get_datasets_list():
    q = DB.session.query(TDatasets)
    data = q.all()

    return [
        d.as_dict(columns=('id_dataset', 'dataset_name')) for d in data
    ]


@routes.route('/datasets', methods=['GET'])
@fnauth.check_auth_cruved('R', True)
@json_resp
def get_datasets(info_role):
    """
        Retourne la liste des datasets

    """
    if current_app.config['CAS']['CAS_AUTHENTIFICATION']:
        # synchronise the CA and JDD from the MTD WS
        try:
            mtd_utils.post_jdd_from_user(
                id_user=info_role.id_role,
                id_organism=info_role.id_organisme
            )
        except Exception as e:
            gunicorn_error_logger.info(e)
            log.error(e)

    q = DB.session.query(TDatasets)
    if info_role.tag_object_code == '2':
        q = q.join(
            CorDatasetActor,
            CorDatasetActor.id_dataset == TDatasets.id_dataset
        )
        # if organism is None => do not filter on id_organism even if level = 2
        if info_role.id_organisme is None:
            q = q.filter(
                CorDatasetActor.id_role == info_role.id_role
            )
        else:
            q = q.filter(
                or_(
                    CorDatasetActor.id_organism == info_role.id_organisme,
                    CorDatasetActor.id_role == info_role.id_role
                )
            )
    elif info_role.tag_object_code == '1':
        q = q.join(
            CorDatasetActor,
            CorDatasetActor.id_dataset == TDatasets.id_dataset
        ).filter(
            CorDatasetActor.id_role == info_role.id_role
        )
    data = q.all()

    return [d.as_dict(True) for d in data]

@routes.route('/dataset/<id_dataset>', methods=['GET'])
@json_resp
def get_dataset(id_dataset):
    """
    Retourne un JDD à partir de son ID
    """
    data = DB.session.query(TDatasets).get(id_dataset)
    cor = data.cor_dataset_actor
    dataset = data.as_dict(True)
    print(dataset)
    organisms = []
    for c in cor:
        if c.organism:
            organisms.append(c.organism.as_dict())
        else:
            organisms.append(None)
    i=0
    for o in organisms:
        dataset['cor_dataset_actor'][i]['organism'] = o
        i = i +1
    print(dataset)
    return dataset


@routes.route('/dataset', methods=['POST'])
@json_resp
def post_dataset():
    data = dict(request.get_json())
    cor_dataset_actor = data.pop('cor_dataset_actor')

    dataset = TDatasets(**data)

    for cor in cor_dataset_actor:
        dataset.cor_dataset_actor.append(CorDatasetActor(**cor))
    
    DB.session.add(dataset)
    DB.session.commit()
    return dataset.as_dict(True)

@routes.route('/acquisition_frameworks', methods=['GET'])
@json_resp
def get_acquisition_frameworks():
    """
    Retourne tous les cadres d'acquisition
    """
    data = DB.session.query(TAcquisitionFramework).all()
    return [af.as_dict(True) for af in data]

@routes.route('/acquisition_framework/<id_acquisition_framework>', methods=['GET'])
@json_resp
def get_acquisition_framework(id_acquisition_framework):
    """
    Retourn un cadre d'acquisition à partir de son ID
    """
    af = DB.session.query(TAcquisitionFramework).get(id_acquisition_framework)
    if af:
        return af.as_dict()
    return None

@routes.route('/acquisition_framework', methods=['POST'])
@json_resp
def post_acquisition_framework():   
    data = dict(request.get_json())

    cor_af_actor = data.pop('cor_af_actor')

    af = TAcquisitionFramework(**data)

    for cor in cor_af_actor:
        af.cor_af_actor.append(cor_af_actor(**cor))
    
    DB.session.add(af)
    DB.session.commit()
    return af.as_dict()


# @routes.route('/list/parameters', methods=['GET'])
# @json_resp
# def get_parameters_list():
#     q = DB.session.query(TParameters)
#     data = q.all()

#     return [d.as_dict() for d in data]


# @routes.route('/parameters/<param_name>', methods=['GET'])
# @routes.route('/parameters/<param_name>/<int:id_org>', methods=['GET'])
# @json_resp
# def get_one_parameter(param_name, id_org=None):
#     q = DB.session.query(TParameters)
#     q = q.filter(TParameters.parameter_name == param_name)
#     if id_org:
#         q = q.filter(TParameters.id_organism == id_org)

#     data = q.all()
#     return [d.as_dict() for d in data]


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
def post_acquisition_framework_mtd(uuid=None, id_user=None, id_organism=None):
    """ Post an acquisition framwork from MTD XML"""
    return mtd_utils.post_acquisition_framework(
        uuid=uuid,
        id_user=id_user,
        id_organism=id_organism
    )


@routes.route('/dataset_mtd/<id_user>', methods=['POST'])
@routes.route('/dataset_mtd/<id_user>/<id_organism>', methods=['POST'])
@json_resp
def post_jdd_from_user_id(id_user=None, id_organism=None):
    """ Post a jdd from the mtd XML"""
    return mtd_utils.post_jdd_from_user(
        id_user=id_user,
        id_organism=id_organism
    )
