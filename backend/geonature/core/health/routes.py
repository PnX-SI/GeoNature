from celery import Celery
from flask import Blueprint
from geonature.utils.env import db
import redis
from flask import current_app

routes = Blueprint("health", __name__)


def check_all_dependencies():
    """
    Check all dependencies are available.

    This function checks that the database and the redis server are available.

    Returns
    -------
    dict
       The value for each key is a boolean indicating if the connection is available or not.
    """
    check = {
        "database_connection": {"status": True, "message": "The database is available"},
        "redis_connection": {"status": True, "message": "The redis server is available"},
        "celery_worker": {"status": True, "message": "The celery worker is available"},
    }

    try:
        db.session.execute("SELECT 1")
    except Exception as e:
        check["database_connection"] = {
            "status": False,
            "message": f"The database is not available",
        }
    try:
        if "CELERY" in current_app.config:
            r = redis.from_url(current_app.config["CELERY"]["broker_url"])
            r.ping()
    except redis.ConnectionError:
        check["redis_connection"] = {
            "status": False,
            "message": "The redis server is not available",
        }

    if "CELERY" in current_app.config:
        if check["redis_connection"]["status"]:
            celery_app = Celery("geonature_test")
            celery_app.config_from_object(current_app.config["CELERY"])
            is_pytest = current_app.config["CELERY"].get("task_always_eager", False)
            if not is_pytest and not celery_app.control.inspect().active():
                check["celery_worker"] = {
                    "status": False,
                    "message": "The celery worker is not running",
                }
        else:
            check["celery_worker"] = {
                "status": False,
                "message": "The celery worker is not accessible because the redis server is not available",
            }
    return check


@routes.route("/healthz", methods=["GET"])
def health_check():
    services_status = [status_data["status"] for _, status_data in check_all_dependencies().items()]
    if all(services_status):
        return "OK", 200

    return "Service Unavailable", 500


@routes.route("/services_status", methods=["GET"])
def services_status():
    return {
        "services": [
            {
                "name": service_name,
                "status": "ONLINE" if service_status["status"] else "OFFLINE",
                "message": service_status["message"],
            }
            for service_name, service_status in check_all_dependencies().items()
        ]
    }
