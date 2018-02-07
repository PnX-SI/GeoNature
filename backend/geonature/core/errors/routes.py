

from flask import current_app, jsonify

from geonature.utils.env import DB

from geonature.utils.utilssqlalchemy import json_resp
from geonature.utils.errors import GeonatureApiError


@current_app.errorhandler(500)
@json_resp
def internal_error(error):  # pylint: disable=W0613
    DB.session.rollback()
    return {'message': 'internal server error'}, 500


@current_app.errorhandler(GeonatureApiError)
def geonature_api_error(error):
    response = jsonify(error.to_dict())
    response.status_code = error.status_code
    return response