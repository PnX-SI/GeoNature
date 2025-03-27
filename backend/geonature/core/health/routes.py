from flask import Blueprint

routes = Blueprint("health", __name__)


def check_all_dependencies():
    """
    check TODO :
    - connection to DB is OK
    - REDIS connection is OK
    """
    return True


@routes.route("/healthz", methods=["GET"])
def health_check():
    if check_all_dependencies():
        return "OK", 200
    else:
        return "Service Unavailable", 500
