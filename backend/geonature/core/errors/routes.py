

from flask import current_app

from geonature.utils.env import DB

from geonature.utils.utilssqlalchemy import json_resp

@current_app.errorhandler(500)
@json_resp
def internal_error(error):  # pylint: disable=W0613
    DB.session.rollback()
    return {'message': 'internal server error'}, 500
