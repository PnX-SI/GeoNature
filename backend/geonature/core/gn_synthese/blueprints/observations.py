from flask import Blueprint, request

from .workshop.datasets import datasets
from .workshop.delete import delete_observation
from .workshop.geoms import geoms
from .workshop.put import update_observation
from .workshop.taxa import taxa
from .workshop.statuts import status
from .workshop.search import observations
from .workshop.get import observation
from .workshop.new import new


obs_routes = Blueprint("observations", __name__)


obs_routes.route("/datasets", methods=["POST"])(datasets)
obs_routes.route("/taxa", methods=["POST"])(taxa)
obs_routes.route("/status", methods=["POST"])(status)
obs_routes.route("/geoms", methods=["POST"])(geoms)
obs_routes.route("/search", methods=["POST"])(observations)
obs_routes.route("/", methods=["POST"])(new)


@obs_routes.route("/<int:id_synthese>", methods=["PUT", "GET", "DELETE"])
def observation(id_synthese):
    if request.method == "GET":
        return observation(id_synthese)
    if request.method == "PUT":
        return update_observation(id_synthese)
    if request.method == "DELETE":
        return delete_observation(id_synthese)
