from flask import Blueprint


obs_routes = Blueprint("observations", __name__)


@obs_routes.route("/")
def get_observations():
    return "Hello World ! "
