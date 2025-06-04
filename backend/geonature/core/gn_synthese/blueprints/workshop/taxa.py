from flask import request, g, jsonify
from sqlalchemy import select, func, distinct

from geonature.core.gn_permissions.decorators import permissions_required
from geonature.core.gn_synthese.models import VSyntheseForWebApp
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery
from geonature.utils.env import db


@permissions_required("R", module_code="SYNTHESE")
def taxa(permissions):
    """
    Retrieve number of observations per taxa from the VSyntheseForWebApp table with associated metadata.

    This function handles the retrieval of distinct taxa based on the provided parameters
    and permissions. It ensures that the metadata view conforms to the expected structure
    and applies necessary filters based on user permissions.

    Results can be paginated using the `page` and `per_page` parameters.

    Parameters
    ----------
    permissions : list
        A list containing the permissions for the current user.
        These permissions are fetch using the `@permissions_required` decorator.

    """

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
