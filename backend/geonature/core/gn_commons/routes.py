from flask import Blueprint, request

from geonature.core.gn_commons.models import TModules
from geonature.utils.env import DB
from geonature.utils.utilssqlalchemy import json_resp

routes = Blueprint('gn_commons', __name__)


@routes.route('/modules', methods=['GET'])
@json_resp
def get_modules():
    print('ENTER')
    data = DB.session.query(TModules).all()
    return [d.as_dict() for d in data]