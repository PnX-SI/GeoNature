from flask import request, g, jsonify
from sqlalchemy import select, distinct

from apptax.taxonomie.models import (
    Taxref,
    TaxrefBdcStatutCorTextValues,
    TaxrefBdcStatutTaxon,
    TaxrefBdcStatutText,
    TaxrefBdcStatutType,
    TaxrefBdcStatutValues,
    bdc_statut_cor_text_area,
)
from geonature.core.gn_permissions.decorators import permissions_required
from geonature.core.gn_synthese.models import VSyntheseForWebApp, CorAreaSynthese
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery
from geonature.utils.env import db


@permissions_required("E", module_code="SYNTHESE")
def status(permissions):
    filters = request.json if request.is_json else {}
    per_page = filters.pop("per_page", None)
    page = filters.pop("page", None)

    # Initalize the select object
    query = select(
        distinct(VSyntheseForWebApp.cd_nom).label("cd_nom"),
        Taxref.cd_ref,
        Taxref.nom_complet,
        Taxref.nom_vern,
        TaxrefBdcStatutTaxon.rq_statut,
        TaxrefBdcStatutType.regroupement_type,
        TaxrefBdcStatutType.lb_type_statut,
        TaxrefBdcStatutText.cd_sig,
        TaxrefBdcStatutText.full_citation,
        TaxrefBdcStatutText.doc_url,
        TaxrefBdcStatutValues.code_statut,
        TaxrefBdcStatutValues.label_statut,
    )
    # Initialize SyntheseQuery class
    synthese_query = SyntheseQuery(VSyntheseForWebApp, query, filters)

    # Filter query with permissions
    synthese_query.filter_query_all_filters(g.current_user, permissions)

    # Add join
    synthese_query.add_join(Taxref, Taxref.cd_nom, VSyntheseForWebApp.cd_nom)
    synthese_query.add_join(
        CorAreaSynthese,
        CorAreaSynthese.id_synthese,
        VSyntheseForWebApp.id_synthese,
    )
    synthese_query.add_join(
        bdc_statut_cor_text_area, bdc_statut_cor_text_area.c.id_area, CorAreaSynthese.id_area
    )
    synthese_query.add_join(TaxrefBdcStatutTaxon, TaxrefBdcStatutTaxon.cd_ref, Taxref.cd_ref)
    synthese_query.add_join(
        TaxrefBdcStatutCorTextValues,
        TaxrefBdcStatutCorTextValues.id_value_text,
        TaxrefBdcStatutTaxon.id_value_text,
    )
    synthese_query.add_join_multiple_cond(
        TaxrefBdcStatutText,
        [
            TaxrefBdcStatutText.id_text == TaxrefBdcStatutCorTextValues.id_text,
            TaxrefBdcStatutText.id_text == bdc_statut_cor_text_area.c.id_text,
        ],
    )
    synthese_query.add_join(
        TaxrefBdcStatutType,
        TaxrefBdcStatutType.cd_type_statut,
        TaxrefBdcStatutText.cd_type_statut,
    )
    synthese_query.add_join(
        TaxrefBdcStatutValues,
        TaxrefBdcStatutValues.id_value,
        TaxrefBdcStatutCorTextValues.id_value,
    )

    # Build query
    query = synthese_query.build_query()

    # Set enable status texts filter
    query = query.where(TaxrefBdcStatutText.enable == True)

    if per_page and page:
        return jsonify(db.paginate(select=query, page=page, per_page=per_page, error_out=False))
    return db.session.execute(query).all()
