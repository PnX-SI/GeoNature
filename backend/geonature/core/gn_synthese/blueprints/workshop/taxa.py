from flask import request, g, jsonify
from sqlalchemy import select, func, distinct
from utils_flask_sqla.generic import GenericTable

from geonature.core.gn_permissions.decorators import permissions_required
from geonature.core.gn_synthese.models import VSyntheseForWebApp
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery
from geonature.utils.env import DB, db


@permissions_required("E", module_code="SYNTHESE")
def taxa(permissions):
    taxon_view = GenericTable(
        tableName="v_synthese_taxon_for_export_view",
        schemaName="gn_synthese",
        engine=DB.engine,
    )
    columns = taxon_view.tableDef.columns

    # Test de conformité de la vue v_synthese_for_export_view
    try:
        assert hasattr(taxon_view.tableDef.columns, "cd_ref")
    except AssertionError as e:
        return (
            {
                "msg": """
                        View v_synthese_taxon_for_export_view
                        must have a cd_ref column \n
                        trace: {}
                        """.format(
                    str(e)
                )
            },
            500,
        )

    parameters = request.json or {}
    per_page = parameters.pop("per_page", None)
    page = parameters.pop("page", None)

    taxon_columns = [
        VSyntheseForWebApp.classe,
        VSyntheseForWebApp.famille,
        VSyntheseForWebApp.group1_inpn,
        VSyntheseForWebApp.group2_inpn,
        VSyntheseForWebApp.group3_inpn,
        VSyntheseForWebApp.id_rang,
        VSyntheseForWebApp.ordre,
        VSyntheseForWebApp.phylum,
        VSyntheseForWebApp.regne,
    ]
    sub_query = select(
        VSyntheseForWebApp.cd_ref,
        func.count(distinct(VSyntheseForWebApp.id_synthese)).label("nb_obs"),
        func.min(VSyntheseForWebApp.date_min).label("date_min"),
        func.max(VSyntheseForWebApp.date_max).label("date_max"),
        *taxon_columns,
    ).group_by(
        VSyntheseForWebApp.cd_ref,
        *taxon_columns,
    )

    synthese_query_class = SyntheseQuery(
        VSyntheseForWebApp,
        sub_query,
        parameters,
    )
    synthese_query_class.filter_query_all_filters(g.current_user, permissions)

    query = synthese_query_class.query
    if per_page and page:
        return jsonify(db.paginate(select=query, page=page, per_page=per_page, error_out=False))
    return db.session.execute(query).all()
