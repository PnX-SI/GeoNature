from flask import Blueprint, jsonify, request

from geonature.core.gn_permissions.decorators import login_required
from geonature.core.gn_synthese.models import DefaultsNomenclaturesValue, TSources
from geonature.core.gn_synthese.schemas import SourceSchema
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

    data = db.session.scalars(select(TSources)).all()
    return SourceSchema(many=True).dump(data)


@other_routes.route("/defaultsNomenclatures", methods=["GET"])
@login_required
def getDefaultsNomenclatures():
    """Get default nomenclatures

    .. :quickref: Synthese;

    :query str group2_inpn:
    :query str regne:
    :query int organism:
    """
    group2_inpn = request.args.get("group2_inpn", "0")
    regne = request.args.get("regne", "0")
    organism = int(request.args.get("organism", 0))
    types = request.args.getlist("mnemonique_type")

    query = select(
        func.distinct(DefaultsNomenclaturesValue.mnemonique_type),
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
