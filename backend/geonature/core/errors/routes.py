import logging
from urllib.parse import urlparse

from flask import current_app, jsonify, Response, request, json, redirect
from werkzeug.exceptions import Unauthorized, HTTPException
from werkzeug.urls import url_encode

from pypnusershub.db.tools import InsufficientRightsError
from sqlalchemy.exc import SQLAlchemyError

from utils_flask_sqla.response import json_resp
from utils_flask_sqla.errors import UtilsSqlaError

from geonature.utils.env import DB
from geonature.utils.errors import GeonatureApiError


log = logging.getLogger(__name__)
gunicorn_error_logger = logging.getLogger("gunicorn.error")


@current_app.errorhandler(500)
@json_resp
def internal_error(error):  # pylint: disable=W0613
    gunicorn_error_logger.error(error)
    return {"message": "internal server error"}, 500


@current_app.errorhandler(SQLAlchemyError)
@json_resp
def sqlalchemy_error(error):  # pylint: disable=W0613
    gunicorn_error_logger.error(error)
    return {"message": "internal server error"}, 500


@current_app.errorhandler(GeonatureApiError)
def geonature_api_error(error):
    gunicorn_error_logger.error(error.to_dict())
    response = jsonify(error.to_dict())
    response.status_code = error.status_code
    return response


@current_app.errorhandler(UtilsSqlaError)
def utils_flask_sql_error(error):
    gunicorn_error_logger.error(error.to_dict())
    response = jsonify(error.to_dict())
    response.status_code = error.status_code
    return response


@current_app.errorhandler(InsufficientRightsError)
def geonature_insuffisant_rights_error(error):
    gunicorn_error_logger.error(error)
    response = jsonify(str(error))
    response.status_code = 403
    return response


@current_app.errorhandler(Unauthorized)
def handle_unauthenticated_request(e):
    if request.accept_mimetypes.best == 'application/json':
        response = e.get_response()
        response.data = json.dumps({
            'code': e.code,
            'name': e.name,
            'description': e.description,
        })
        response.content_type = 'application/json'
        return response
    else:
        base_url = current_app.config['URL_APPLICATION']
        login_path = '/#/login'  # FIXME: move in config
        api_endpoint = current_app.config['API_ENDPOINT']
        url_application = current_app.config['URL_APPLICATION']
        if urlparse(api_endpoint).netloc == urlparse(url_application).netloc:
            next_url = request.full_path
        else:
            next_url = request.url
        query_string = url_encode({'next': next_url})
        return redirect(f'{base_url}{login_path}?{query_string}')


@current_app.errorhandler(HTTPException)
def handle_exception(e):
    response = e.get_response()
    if request.accept_mimetypes.best == 'application/json':
        response.data = json.dumps({
            'code': e.code,
            'name': e.name,
            'description': e.description,
        })
        response.content_type = 'application/json'
    return response
