from flask import Blueprint, jsonify, request

from geonature.core.gn_permissions.decorators import login_required
from geonature.core.gn_synthese.models import Synthese, SyntheseLogEntry
from geonature.utils.env import db

from sqlalchemy import func
from sqlalchemy.orm import load_only
from werkzeug.exceptions import BadRequest


from geonature.core.gn_synthese.blueprints import (
    reports_blueprint,
    synthese_routes,
    statistics_routes,
    taxon_info_routes,
    other_routes,
    export_routes,
)

routes = Blueprint("gn_synthese", __name__)

routes.register_blueprint(reports_blueprint, url_prefix="/reports")
routes.register_blueprint(synthese_routes, url_prefix="/")
routes.register_blueprint(statistics_routes, url_prefix="/")
routes.register_blueprint(taxon_info_routes, url_prefix="/")
routes.register_blueprint(other_routes, url_prefix="/")
routes.register_blueprint(export_routes, url_prefix="/")


@routes.route("/log", methods=["get"])
@login_required
def list_synthese_log_entries() -> dict:
    """Get log history from synthese

    Parameters
    ----------

    Returns
    -------
    dict
        log action list
    """
    # FIXME SQLA 2
    deletion_entries = SyntheseLogEntry.query.options(
        load_only(
            SyntheseLogEntry.id_synthese,
            SyntheseLogEntry.last_action,
            SyntheseLogEntry.meta_last_action_date,
        )
    )
    create_update_entries = Synthese.query.with_entities(
        Synthese.id_synthese,
        db.case(
            (Synthese.meta_create_date < Synthese.meta_update_date, "U"),
            else_="I",
        ).label("last_action"),
        func.coalesce(Synthese.meta_update_date, Synthese.meta_create_date).label(
            "meta_last_action_date"
        ),
    )
    query = deletion_entries.union(create_update_entries)

    # Filter
    try:
        query = query.filter_by_params(request.args)
    except ValueError as exc:
        raise BadRequest(*exc.args) from exc

    # Sort
    try:
        query = query.sort(request.args.getlist("sort"))
    except ValueError as exc:
        raise BadRequest(*exc.args) from exc

    # Paginate
    limit = request.args.get("limit", type=int, default=50)
    page = request.args.get("page", type=int, default=1)
    results = query.paginate(page=page, per_page=limit, error_out=False)

    return jsonify(
        {
            "items": [item.as_dict() for item in results.items],
            "total": results.total,
            "limit": limit,
            "page": page,
        }
    )
