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
)
from geonature.core.gn_commons.models import TMedias
from geonature.core.gn_synthese.utils.observers import ObserversUtils
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery
from geonature.core.gn_synthese.utils.pagination_sorting import PaginationSortingUtils

from ref_geo.models import BibAreasTypes, LAreas
from utils_flask_sqla.response import json_resp


from sqlalchemy import distinct, func, select
from werkzeug.exceptions import BadRequest
from apptax.taxonomie.models import Taxref

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
        valid_area_type = db.session.scalar(
            select(BibAreasTypes.type_code)
            .where(BibAreasTypes.type_code == area_type)
            .distinct()
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
        observer_subquery = ObserversUtils.get_observers_subquery(id_role)

        # Main query to fetch stats
        query = (
            select(
                    func.count(distinct(Synthese.id_synthese)).label("observation_count"),
                    func.count(distinct(Synthese.cd_nom)).label("taxa_count"),
                    func.count(distinct(areas_subquery.c.id_area)).label("area_count"),
                    func.min(Synthese.date_min).label("date_min"),
                    func.max(Synthese.date_max).label("date_max"),
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

    if app.config["SYNTHESE"]["OBSERVER_SHEET"]["ENABLE_TAB_MEDIA"]:

        @observer_info_routes.route("/observer_medias/<int:id_role>", methods=["GET"])
        @login_required
        @permissions.check_cruved_scope("R", get_scope=True, module_code="SYNTHESE")
        @json_resp
        def observer_medias(scope, id_role):
            per_page = request.args.get("per_page", 10, int)
            page = request.args.get("page", 1, int)

            observer_subquery = ObserversUtils.get_observers_subquery(id_role)
            query = (
                select(TMedias)
                .select_from(Synthese)
                .join(Synthese.medias)
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

    if app.config["SYNTHESE"]["OBSERVER_SHEET"]["ENABLE_TAB_TAXA"]:

        @observer_info_routes.route("/observer_overview/<int:id_role>", methods=["GET"])
        @permissions.permissions_required("R", module_code="SYNTHESE")
        def observer_overview(permissions, id_role):
            per_page = request.args.get("per_page", 10, int)
            page = request.args.get("page", 1, int)
            sort_by = request.args.get("sort_by", "observation_count")
            sort_order = request.args.get(
                "sort_order",
                PaginationSortingUtils.SortOrder.DESC,
                PaginationSortingUtils.SortOrder,
            )

            observer_subquery = ObserversUtils.get_observers_subquery(id_role)
            query = (
                db.session.query(
                    Taxref.cd_nom,
                    func.coalesce(Taxref.nom_vern, Taxref.lb_nom, Taxref.nom_valide).label("nom"),
                    func.min(Synthese.date_min).label("date_min"),
                    func.max(Synthese.date_max).label("date_max"),
                    func.count(distinct(Synthese.id_synthese)).label("observation_count"),
                    func.count(distinct(Synthese.id_dataset)).label("dataset_count"),
                )
                # .select_from(Synthese)
                .join(Taxref, Taxref.cd_nom == Synthese.cd_nom)
                .join(observer_subquery, observer_subquery.c.id_synthese == Synthese.id_synthese)
                .group_by(Taxref.cd_nom, "nom")
            )

            synthese_query_obj = SyntheseQuery(Synthese, query, {})
            synthese_query_obj.filter_query_with_permissions(g.current_user, permissions)

            query = PaginationSortingUtils.update_query_with_sorting(query, sort_by, sort_order)
            results = PaginationSortingUtils.paginate(query, page, per_page)

            return jsonify(
                {
                    "items": results.items,
                    "total": results.total,
                    "per_page": per_page,
                    "page": page,
                }
            )
