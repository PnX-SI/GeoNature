from flask import Blueprint, jsonify, request

from geonature.core.gn_permissions.decorators import login_required
from geonature.core.gn_synthese.models import DefaultsNomenclaturesValue, TSources
from geonature.utils.env import db

from sqlalchemy import distinct, func, select
from utils_flask_sqla.response import json_resp
from werkzeug.exceptions import NotFound

other_routes = Blueprint("synthese_other_routes", __name__)

@other_routes.route("/sources", methods=["GET"])
@login_required
@json_resp
def get_sources():
    """Get all sources.

    .. :quickref: Synthese;
    """
    q = select(TSources)
    data = db.session.scalars(q).all()
    return [n.as_dict() for n in data]


@other_routes.route("/defaultsNomenclatures", methods=["GET"])
@login_required
def getDefaultsNomenclatures():
    """Get default nomenclatures

    .. :quickref: Synthese;

    :query str group2_inpn:
    :query str regne:
    :query int organism:
    """
    params = request.args
    group2_inpn = "0"
    regne = "0"
    organism = 0
    if "group2_inpn" in params:
        group2_inpn = params["group2_inpn"]
    if "regne" in params:
        regne = params["regne"]
    if "organism" in params:
        organism = params["organism"]
    types = request.args.getlist("mnemonique_type")

    query = select(
        distinct(DefaultsNomenclaturesValue.mnemonique_type),
        func.gn_synthese.get_default_nomenclature_value(
            DefaultsNomenclaturesValue.mnemonique_type, organism, regne, group2_inpn
        ),
    )
    if len(types) > 0:
        query = query.where(DefaultsNomenclaturesValue.mnemonique_type.in_(tuple(types)))
    data = db.session.execute(query).all()
    if not data:
        raise NotFound
    return jsonify(dict(data))
