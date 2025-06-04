import datetime
from geonature.core.gn_permissions.decorators import permissions_required
from flask import request, current_app, g, jsonify
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery
from utils_flask_sqla.generic import GenericTable
from geonature.core.gn_synthese.models import (
    CorAreaSynthese,
    Synthese,
    VSyntheseForWebApp,
    TReport,
)
import sqlalchemy as sa
from geonature.utils.env import db


@permissions_required("R", module_code="SYNTHESE")
def datasets(permissions):
    """
    Retrieve number of observations per datasets from the VSyntheseForWebApp table with associated metadata.

    This function handles the retrieval of distinct datasets based on the provided parameters
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

    metadata_view = GenericTable(
        tableName="v_metadata_for_export",
        schemaName="gn_synthese",
        engine=db.engine,
    )

    # Test de conformité de la vue v_metadata_for_export
    try:
        assert hasattr(metadata_view.tableDef.columns, "jdd_id")
    except AssertionError as e:
        return (
            {
                "msg": """
                        View v_metadata_for_export
                        must have a jdd_id column \n
                        trace: {}
                        """.format(
                    str(e)
                )
            },
            500,
        )

    query = sa.select(sa.func.distinct(VSyntheseForWebApp.id_dataset), metadata_view.tableDef)

    synthese_query_class = SyntheseQuery(
        VSyntheseForWebApp,
        query,
        parameters,
    )
    synthese_query_class.add_join(
        metadata_view.tableDef,
        getattr(
            metadata_view.tableDef.columns,
            current_app.config["SYNTHESE"]["EXPORT_METADATA_ID_DATASET_COL"],
        ),
        VSyntheseForWebApp.id_dataset,
    )

    # Filter query with permissions (scope, sensitivity, ...)
    synthese_query_class.filter_query_all_filters(g.current_user, permissions)
    query = synthese_query_class.build_query()
    if per_page and page:
        return jsonify(db.paginate(select=query, page=page, per_page=per_page, error_out=False))
    return db.session.execute(query).all()
