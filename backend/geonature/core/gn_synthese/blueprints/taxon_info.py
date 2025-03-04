from warnings import warn

from flask import Blueprint, g, jsonify, request

from geonature import app
from geonature.utils.env import db

from geonature.core.gn_commons.models import TMedias
from geonature.core.gn_meta.models import TDatasets
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.decorators import login_required
from geonature.core.gn_synthese.models import (
    CorAreaSynthese,
    Synthese,
    VColorAreaTaxon,
    CorObserverSynthese,
)
from geonature.core.gn_commons.models import TMedias
from geonature.core.gn_synthese.utils.taxon_sheet import TaxonSheetUtils, SortOrder
from pypnusershub.db import User
from geonature.core.gn_synthese.utils.orm import is_already_joined
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery
from apptax.taxonomie.models import Taxref, VMTaxrefListForautocomplete
from ref_geo.models import BibAreasTypes, LAreas
from utils_flask_sqla.generic import GenericTable
from utils_flask_sqla.response import json_resp


from sqlalchemy import desc, distinct, func, select, join, exists
from sqlalchemy.orm import Query
from werkzeug.exceptions import BadRequest

taxon_info_routes = Blueprint("synthese_taxon_info", __name__)


@taxon_info_routes.route("/taxa_distribution", methods=["GET"])
@login_required
def get_taxa_distribution():
    """
    Get taxa distribution for a given dataset or acquisition framework
    and grouped by a certain taxa rank
    """

    id_dataset = request.args.get("id_dataset")
    id_af = request.args.get("id_af")
    id_source = request.args.get("id_source")

    rank = request.args.get("taxa_rank", "regne")

    try:
        rank = getattr(Taxref.__table__.columns, rank)
    except AttributeError:
        raise BadRequest("Rank does not exist")

    query = (
        select(func.count(func.distinct(Synthese.cd_nom)), rank)
        .select_from(Synthese)
        .outerjoin(Taxref, Taxref.cd_nom == Synthese.cd_nom)
    )

    if id_dataset:
        query = query.where(Synthese.id_dataset == id_dataset)

    elif id_af:
        query = query.outerjoin(TDatasets, TDatasets.id_dataset == Synthese.id_dataset).where(
            TDatasets.id_acquisition_framework == id_af
        )
    # User can add id_source filter along with id_dataset or id_af
    if id_source is not None:
        query = query.where(Synthese.id_source == id_source)

    data = db.session.execute(query.group_by(rank)).all()
    return jsonify([{"count": d[0], "group": d[1]} for d in data])


@taxon_info_routes.route("/color_taxon", methods=["GET"])
@login_required
def get_color_taxon():
    """Get color of taxon in areas (vue synthese.v_color_taxon_area).

    .. :quickref: Synthese;

    :query str code_area_type: Type area code (ref_geo.bib_areas_types.type_code)
    :query int id_area: Id of area (ref_geo.l_areas.id_area)
    :query int cd_nom: taxon code (taxonomie.taxref.cd_nom)
    Those three parameters can be multiples
    :returns: Array<dict<VColorAreaTaxon>>
    """
    params = request.args
    limit = int(params.get("limit", 100))
    page = params.get("page", 1, int)

    if "offset" in request.args:
        warn(
            "offset is deprecated, please use page for pagination (start at 1)", DeprecationWarning
        )
        page = (int(request.args["offset"]) / limit) + 1
    id_areas_type = params.getlist("code_area_type")
    cd_noms = params.getlist("cd_nom")
    id_areas = params.getlist("id_area")

    query = select(VColorAreaTaxon)
    if len(id_areas_type) > 0:
        query = query.join(LAreas, LAreas.id_area == VColorAreaTaxon.id_area).join(
            BibAreasTypes, BibAreasTypes.id_type == LAreas.id_type
        )
        query = query.where(BibAreasTypes.type_code.in_(tuple(id_areas_type)))
    if len(id_areas) > 0:
        # check if the join already done on l_areas
        if not is_already_joined(LAreas, query):
            query = query.join(LAreas, LAreas.id_area == VColorAreaTaxon.id_area)
        query = query.where(LAreas.id_area.in_(tuple(id_areas)))
    query = query.order_by(VColorAreaTaxon.cd_nom).order_by(VColorAreaTaxon.id_area)
    if len(cd_noms) > 0:
        query = query.where(VColorAreaTaxon.cd_nom.in_(tuple(cd_noms)))
    results = db.paginate(query, page=page, per_page=limit, error_out=False)

    return jsonify([d.as_dict() for d in results.items])


@taxon_info_routes.route("/taxons_autocomplete", methods=["GET"])
@login_required
@json_resp
def get_autocomplete_taxons_synthese():
    """Autocomplete taxon for web search (based on all taxon in Synthese).

    .. :quickref: Synthese;

    The request use trigram algorithm to get relevent results

    :query str search_name: the search name (use sql ilike statement and puts "%" for spaces)
    :query str regne: filter with kingdom
    :query str group2_inpn : filter with INPN group 2
    """
    search_name = request.args.get("search_name", "")
    query = (
        select(
            VMTaxrefListForautocomplete,
            func.similarity(VMTaxrefListForautocomplete.unaccent_search_name, search_name).label(
                "idx_trgm"
            ),
        )
        .distinct()
        .join(Synthese, Synthese.cd_nom == VMTaxrefListForautocomplete.cd_nom)
    )
    search_name = search_name.replace(" ", "%")
    query = query.where(
        VMTaxrefListForautocomplete.unaccent_search_name.ilike(
            func.unaccent("%" + search_name + "%")
        )
    )
    regne = request.args.get("regne")
    if regne:
        query = query.where(VMTaxrefListForautocomplete.regne == regne)

    group2_inpn = request.args.get("group2_inpn")
    if group2_inpn:
        query = query.where(VMTaxrefListForautocomplete.group2_inpn == group2_inpn)

    # FIXME : won't work now
    # query = query.order_by(
    #     desc(VMTaxrefListForautocomplete.cd_nom == VMTaxrefListForautocomplete.cd_ref)
    # )
    limit = request.args.get("limit", 20)
    data = db.session.execute(
        query.order_by(
            desc("idx_trgm"),
        ).limit(limit)
    ).all()
    return [d[0].as_dict() for d in data]


@taxon_info_routes.route("/taxons_tree", methods=["GET"])
@login_required
@json_resp
def get_taxon_tree():
    """Get taxon tree.

    .. :quickref: Synthese;
    """
    taxon_tree_table = GenericTable(
        tableName="v_tree_taxons_synthese", schemaName="gn_synthese", engine=db.engine
    )
    data = db.session.execute(select(taxon_tree_table.tableDef)).all()
    return [taxon_tree_table.as_dict(datum) for datum in data]


## ############################################################################
## TAXON SHEET ROUTES
## ############################################################################


@taxon_info_routes.route("/taxon_medias/<int:cd_ref>", methods=["GET"])
@login_required
@permissions.check_cruved_scope("R", module_code="SYNTHESE")
@json_resp
def taxon_medias(cd_ref):
    per_page = request.args.get("per_page", 10, int)
    page = request.args.get("page", 1, int)

    query = select(TMedias).join(Synthese.medias).order_by(TMedias.meta_create_date.desc())

    # Use taxon_sheet_utils
    taxref_cd_nom_list = TaxonSheetUtils.get_cd_nom_list_from_cd_ref(cd_ref)
    query = query.where(Synthese.cd_nom.in_(taxref_cd_nom_list))

    pagination = db.paginate(query, page=page, per_page=per_page)
    return {
        "total": pagination.total,
        "page": pagination.page,
        "per_page": pagination.per_page,
        "items": [media.as_dict() for media in pagination.items],
    }


if app.config["SYNTHESE"]["ENABLE_TAXON_SHEETS"]:

    @taxon_info_routes.route("/taxon_stats/<int:cd_ref>", methods=["GET"])
    @permissions.check_cruved_scope("R", get_scope=True, module_code="SYNTHESE")
    @json_resp
    def taxon_stats(scope, cd_ref):
        """Return stats for a specific taxon"""

        area_type = request.args.get("area_type")

        if not area_type:
            raise BadRequest("Missing area_type parameter")

        if not TaxonSheetUtils.is_valid_area_type(area_type):
            raise BadRequest("Invalid area_type parameter")

        areas_subquery = TaxonSheetUtils.get_area_subquery(area_type)
        taxref_cd_nom_list = TaxonSheetUtils.get_cd_nom_list_from_cd_ref(cd_ref)

        # Main query to fetch stats
        query = (
            select(
                func.count(distinct(Synthese.id_synthese)).label("observation_count"),
                func.count(distinct(Synthese.observers)).label("observer_count"),
                func.count(distinct(areas_subquery.c.id_area)).label("area_count"),
                func.min(Synthese.altitude_min).label("altitude_min"),
                func.max(Synthese.altitude_max).label("altitude_max"),
                func.min(Synthese.date_min).label("date_min"),
                func.max(Synthese.date_max).label("date_max"),
            )
            .select_from(
                join(
                    Synthese,
                    CorAreaSynthese,
                    Synthese.id_synthese == CorAreaSynthese.id_synthese,
                )
                .join(areas_subquery, CorAreaSynthese.id_area == areas_subquery.c.id_area)
                .join(LAreas, CorAreaSynthese.id_area == LAreas.id_area)
                .join(BibAreasTypes, LAreas.id_type == BibAreasTypes.id_type)
            )
            .where(Synthese.cd_nom.in_(taxref_cd_nom_list))
        )

        synthese_query = TaxonSheetUtils.get_synthese_query_with_scope(g.current_user, scope, query)
        result = db.session.execute(synthese_query)
        synthese_stats = result.fetchone()

        data = {
            "cd_ref": cd_ref,
            "observation_count": synthese_stats["observation_count"],
            "observer_count": synthese_stats["observer_count"],
            "area_count": synthese_stats["area_count"],
            "altitude_min": synthese_stats["altitude_min"],
            "altitude_max": synthese_stats["altitude_max"],
            "date_min": synthese_stats["date_min"],
            "date_max": synthese_stats["date_max"],
        }

        return data


if app.config["SYNTHESE"]["TAXON_SHEET"]["ENABLE_TAB_OBSERVERS"]:

    @taxon_info_routes.route("/taxon_observers/<int:cd_ref>", methods=["GET"])
    @permissions.check_cruved_scope("R", get_scope=True, module_code="SYNTHESE")
    def taxon_observers(scope, cd_ref):
        per_page = request.args.get("per_page", 10, int)
        page = request.args.get("page", 1, int)
        sort_by = request.args.get("sort_by", "observer")
        sort_order = request.args.get("sort_order", SortOrder.ASC, SortOrder)
        field_separators = request.args.get(
            "field_separators", app.config["SYNTHESE"]["FIELD_OBSERVERS_SEPARATORS"]
        )
        # Handle sorting
        if sort_by not in ["observer", "date_min", "date_max", "observation_count", "media_count"]:
            raise BadRequest(f"The sort_by column {sort_by} is not defined")

        taxref_cd_nom_list = TaxonSheetUtils.get_cd_nom_list_from_cd_ref(cd_ref)

        field_separators_as_regexp = rf"[{''.join(field_separators)}]+"

        query = (
            db.session.query(
                func.lower(
                    func.trim(
                        func.regexp_split_to_table(Synthese.observers, field_separators_as_regexp)
                    )
                ).label("observer"),
                func.min(Synthese.date_min).label("date_min"),
                func.max(Synthese.date_max).label("date_max"),
                func.count(Synthese.id_synthese).label("observation_count"),
                func.count(TMedias.id_media).label("media_count"),
            )
            .group_by("observer")
            .outerjoin(Synthese.medias)
            .where(Synthese.cd_nom.in_(taxref_cd_nom_list))
        )
        query = TaxonSheetUtils.get_synthese_query_with_scope(g.current_user, scope, query)
        query = TaxonSheetUtils.update_query_with_sorting(query, sort_by, sort_order)
        results = TaxonSheetUtils.paginate(query, page, per_page)

        return jsonify(
            {
                "items": results.items,
                "total": results.total,
                "per_page": per_page,
                "page": page,
            }
        )
