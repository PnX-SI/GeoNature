from warnings import warn

from flask import Blueprint, g, jsonify, request

from geonature import app
from geonature.utils.env import db, DB

from geonature.core.gn_commons.models import TMedias

from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.decorators import login_required
from geonature.core.gn_synthese.models import (
    CorAreaSynthese,
    Synthese,
    CorObserverSynthese,
)
from geonature.core.gn_commons.models import TMedias
from geonature.core.gn_synthese.utils.observer_sheet import ObserverSheetUtils
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery

from ref_geo.models import BibAreasTypes, LAreas
from utils_flask_sqla.response import json_resp


from sqlalchemy import distinct, func, select
from werkzeug.exceptions import BadRequest

observer_info_routes = Blueprint("synthese_observer_info", __name__)

if app.config["SYNTHESE"]["ENABLE_OBSERVER_SHEETS"]:

    @observer_info_routes.route("/observer_stats/<int:id_role>", methods=["GET"])
    @permissions.check_cruved_scope("R", get_scope=True, module_code="SYNTHESE")
    @json_resp
    def observer_stats(scope, id_role):
        """Return stats for a specific taxon"""

        # Handle area type
        area_type = request.args.get("area_type")

        if not area_type:
            raise BadRequest("Missing area_type parameter")

        # Ensure area_type is valid
        valid_area_type = (
            db.session.query(BibAreasTypes.type_code)
            .distinct()
            .filter(BibAreasTypes.type_code == area_type)
            .scalar()
        )
        if not valid_area_type:
            raise BadRequest("Invalid area_type")

        # Subquery to fetch areas based on area_type
        areas_subquery = (
            select(LAreas.id_area)
            .where(LAreas.id_type == BibAreasTypes.id_type, BibAreasTypes.type_code == area_type)
            .alias("areas")
        )

        # Observer subquery
        observer_subquery = ObserverSheetUtils.get_observers_subquery(id_role)

        # Main query to fetch stats
        query = (
            select(
                [
                    func.count(distinct(Synthese.id_synthese)).label("observation_count"),
                    func.count(distinct(Synthese.cd_nom)).label("taxa_count"),
                    func.count(distinct(areas_subquery.c.id_area)).label("area_count"),
                    func.min(Synthese.date_min).label("date_min"),
                    func.max(Synthese.date_max).label("date_max"),
                ]
            )
            .select_from(Synthese)
            .join(observer_subquery, observer_subquery.c.id_synthese == Synthese.id_synthese)
            # Area
            .join(
                CorAreaSynthese,
                Synthese.id_synthese == CorAreaSynthese.id_synthese,
            )
            .join(areas_subquery, CorAreaSynthese.id_area == areas_subquery.c.id_area)
            .join(LAreas, CorAreaSynthese.id_area == LAreas.id_area)
            .join(BibAreasTypes, LAreas.id_type == BibAreasTypes.id_type)
        )

        synthese_query_obj = SyntheseQuery(Synthese, query, {})
        synthese_query_obj.filter_query_with_cruved(g.current_user, scope)
        result = DB.session.execute(synthese_query_obj.query)
        synthese_stats = result.fetchone()

        data = {
            "id_role": id_role,
            "observation_count": synthese_stats["observation_count"],
            "taxa_count": synthese_stats["taxa_count"],
            "area_count": synthese_stats["area_count"],
            "date_min": synthese_stats["date_min"],
            "date_max": synthese_stats["date_max"],
        }

        return data

    @observer_info_routes.route("/observer_medias/<int:id_role>", methods=["GET"])
    @login_required
    @permissions.check_cruved_scope("R", get_scope=True, module_code="SYNTHESE")
    @json_resp
    def observer_medias(scope, id_role):
        per_page = request.args.get("per_page", 10, int)
        page = request.args.get("page", 1, int)

        observer_subquery = ObserverSheetUtils.get_observers_subquery(id_role)
        query = (
            select(TMedias)
            .select_from(Synthese)
            .join(Synthese.medias)
            .join(CorObserverSynthese, Synthese.id_synthese == CorObserverSynthese.id_synthese)
            .order_by(TMedias.meta_create_date.desc())
            .join(observer_subquery, observer_subquery.c.id_synthese == Synthese.id_synthese)
        )

        synthese_query_obj = SyntheseQuery(Synthese, query, {})
        synthese_query_obj.filter_query_with_cruved(g.current_user, scope)

        pagination = DB.paginate(synthese_query_obj.query, page=page, per_page=per_page)
        return {
            "total": pagination.total,
            "page": pagination.page,
            "per_page": pagination.per_page,
            "items": [media.as_dict() for media in pagination.items],
        }
