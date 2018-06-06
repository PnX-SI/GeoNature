import json
import logging
from flask import Blueprint, current_app

from sqlalchemy import or_
from sqlalchemy.sql import text

from geonature.utils.env import DB

from geonature.core.gn_meta.models import (
    TDatasets, TParameters,
    CorDatasetsActor, TAcquisitionFramework,
    CorAcquisitionFrameworkActor
)
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
            CorDatasetsActor,
            CorDatasetsActor.id_dataset == TDatasets.id_dataset
        )
        # if organism is None => do not filter on id_organism even if level = 2
        if info_role.id_organisme is None:
            q = q.filter(
                CorDatasetsActor.id_role == info_role.id_role
            )
        else:
            q = q.filter(
                or_(
                    CorDatasetsActor.id_organism == info_role.id_organisme,
                    CorDatasetsActor.id_role == info_role.id_role
                )
            )
    elif info_role.tag_object_code == '1':
        q = q.join(
            CorDatasetsActor,
            CorDatasetsActor.id_dataset == TDatasets.id_dataset
        ).filter(
            CorDatasetsActor.id_role == info_role.id_role
        )

    data = q.all()

    return [d.as_dict(True) for d in data]


@routes.route('/list/parameters', methods=['GET'])
@json_resp
def get_parameters_list():
    q = DB.session.query(TParameters)
    data = q.all()

    return [d.as_dict() for d in data]


@routes.route('/parameters/<param_name>', methods=['GET'])
@routes.route('/parameters/<param_name>/<int:id_org>', methods=['GET'])
@json_resp
def get_one_parameter(param_name, id_org=None):
    q = DB.session.query(TParameters)
    q = q.filter(TParameters.parameter_name == param_name)
    if id_org:
        q = q.filter(TParameters.id_organism == id_org)

    data = q.all()
    return [d.as_dict() for d in data]



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
