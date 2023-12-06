from pprint import pformat
from urllib.parse import urlparse
import sys

from flask import current_app, request, json, redirect
from werkzeug.exceptions import Unauthorized, InternalServerError, HTTPException, BadRequest
from urllib.parse import urlencode
from marshmallow.exceptions import ValidationError


# Unauthorized means disconnected
# (logged but not allowed to perform an action = Forbidden)
@current_app.errorhandler(Unauthorized)
def handle_unauthenticated_request(e):
    if request.accept_mimetypes.best == "application/json":
        response = e.get_response()
        response.data = json.dumps(
            {
                "code": e.code,
                "name": e.name,
                "description": e.description,
            }
        )
        response.content_type = "application/json"
        return response
    else:
        base_url = current_app.config["URL_APPLICATION"]
        login_path = "/#/login"  # FIXME: move in config
        api_endpoint = current_app.config["API_ENDPOINT"]
        url_application = current_app.config["URL_APPLICATION"]
        if urlparse(api_endpoint).netloc == urlparse(url_application).netloc:
            next_url = request.full_path
        else:
            next_url = request.url
        query_string = urlencode({"next": next_url})
        return redirect(f"{base_url}{login_path}?{query_string}")


@current_app.errorhandler(ValidationError)
def handle_validation_error(e):
    return handle_http_exception(
        BadRequest(description=pformat(e.messages)).with_traceback(sys.exc_info()[2])
    )


@current_app.errorhandler(HTTPException)
def handle_http_exception(e):
    response = e.get_response()
    if request.accept_mimetypes.best == "application/json":
        response.data = json.dumps(
            {
                "code": e.code,
                "name": e.name,
                "description": e.description,
                "request_id": request.environ["FLASK_REQUEST_ID"],
            }
        )
        response.content_type = "application/json"
    return response


@current_app.errorhandler(InternalServerError)
def handle_internal_server_error(e):
    # original excepion is set when the InternalServerError have been raised by catched
    # non-HTTP exception (PROPAGATE_EXCEPTIONS=False, default value when DEBUG=False)
    original = getattr(e, "original_exception", None)
    # the original exception may contains sensitive information (e.g. db pwd)
    # so we return it as description only in debug mode
    if original and current_app.debug:
        description = str(original)
    else:
        description = e.description
    response = e.get_response()
    if request.accept_mimetypes.best == "application/json":
        response.data = json.dumps(
            {
                "code": e.code,
                "name": e.name,
                "description": description,
                "request_id": request.environ["FLASK_REQUEST_ID"],
            }
        )
    return response


@current_app.errorhandler(Exception)
def handle_exception(e):
    if request.accept_mimetypes.best == "application/json":
        # exceptions are logged by flask when not handled or when re-raised.
        # as here we construct a json error response, we have to log the exception our-self.
        current_app.log_exception(sys.exc_info())
        # TODO: verify that sentry is able to collect these exceptions!
        server_error = InternalServerError(original_exception=e)
        return handle_internal_server_error(server_error)
    else:
        # If PROPAGATE_EXCEPTIONS=True (default value in debug mode),
        # this will produce a debug page with the full backtrace.
        # Otherwise, an InternalServerError will be produced by flask.
        raise e
