from flask import current_app, request
from shapely.wkt import loads
from geoalchemy2.shape import from_shape
from sqlalchemy import func, or_, and_
from sqlalchemy.orm import aliased

from geonature.utils.env import DB
from geonature.utils.utilsgeometry import circle_from_point
from geonature.core.taxonomie.models import Taxref, CorTaxonAttribut, TaxrefLR
from geonature.core.gn_synthese.models import (
    Synthese,
    CorObserverSynthese,
    TSources,
    CorAreaSynthese,
    TDatasets,
)
from geonature.core.gn_meta.models import TAcquisitionFramework, CorDatasetActor
from geonature.utils.errors import GeonatureApiError


def filter_query_with_cruved(
    model,
    q,
    user,
    id_synthese_column="id_synthese",
    id_dataset_column="id_dataset",
    observers_column="observers",
    id_digitiser_column="id_digitiser",
    with_generic_table=False,
):
    """
    Filter the query with the cruved authorization of a user

    Returns: 
        - A SQLA Query object
    """
    # if with geniric table , the column are located in model.columns, else in model
    if with_generic_table:
        model_temp = model.columns
    else:
        model_temp = model
    allowed_datasets = TDatasets.get_user_datasets(user)
    # get the mandatory column
    try:
        model_id_syn_col = getattr(model_temp, id_synthese_column)
        model_id_dataset_column = getattr(model_temp, id_dataset_column)
        model_observers_column = getattr(model_temp, observers_column)
        model_id_digitiser_column = getattr(model_temp, id_digitiser_column)
    except AttributeError as e:
        raise GeonatureApiError(
            """the {model} table     does not have a column {e}
             If you change the {model} table, please edit your synthese config (cf EXPORT_***_COL)
            """.format(
                e=e, model=model
            )
        )

    if user.value_filter in ("1", "2"):
        q = q.outerjoin(
            CorObserverSynthese, CorObserverSynthese.id_synthese == model_id_syn_col
        )
        ors_filters = [
            CorObserverSynthese.id_role == user.id_role,
            model_id_digitiser_column == user.id_role,
        ]
        if current_app.config["SYNTHESE"]["CRUVED_SEARCH_WITH_OBSERVER_AS_TXT"]:
            user_fullname1 = user.nom_role + " " + user.prenom_role + "%"
            user_fullname2 = user.prenom_role + " " + user.nom_role + "%"
            ors_filters.append(model_observers_column.ilike(user_fullname1))
            ors_filters.append(model_observers_column.ilike(user_fullname2))

        if user.value_filter == "1":
            q = q.filter(or_(*ors_filters))
        elif user.value_filter == "2":
            ors_filters.append(model_id_dataset_column.in_(allowed_datasets))
            q = q.filter(or_(*ors_filters))
    return q


def filter_taxonomy(model, q, filters):
    """
    Filters the query with taxonomic attributes
    Parameters:
        - q (SQLAchemyQuery): an SQLAchemy query
        - filters (dict): a dict of filter
    Returns:
        -Tuple: the SQLAlchemy query and the filter dictionnary
    """
    if "cd_ref" in filters:
        sub_query_synonym = (
            DB.session.query(Taxref.cd_nom)
            .filter(Taxref.cd_ref.in_(filters.pop("cd_ref")))
            .subquery("sub_query_synonym")
        )
        q = q.filter(model.cd_nom.in_(sub_query_synonym))
    if "taxonomy_group2_inpn" in filters:
        q = q.filter(Taxref.group2_inpn.in_(filters.pop("taxonomy_group2_inpn")))

    if "taxonomy_id_hab" in filters:
        q = q.filter(Taxref.id_habitat.in_(filters.pop("taxonomy_id_hab")))

    if "taxonomy_lr" in filters:
        sub_query_lr = (
            DB.session.query(TaxrefLR.cd_nom)
            .filter(TaxrefLR.id_categorie_france.in_(filters.pop("taxonomy_lr")))
            .subquery("sub_query_lr")
        )
        # est-ce qu'il faut pas filtrer sur le cd_ ref ?
        # quid des protection définit à rang superieur de la saisie ?
        q = q.filter(model.cd_nom.in_(sub_query_lr))

    aliased_cor_taxon_attr = {}
    join_on_taxref = False
    for colname, value in filters.items():
        if colname.startswith("taxhub_attribut"):
            if not join_on_taxref:
                q = q.join(Taxref, Taxref.cd_nom == model.cd_nom)
                join_on_taxref = True
            taxhub_id_attr = colname[16:]
            aliased_cor_taxon_attr[taxhub_id_attr] = aliased(CorTaxonAttribut)
            q = q.join(
                aliased_cor_taxon_attr[taxhub_id_attr],
                and_(
                    aliased_cor_taxon_attr[taxhub_id_attr].id_attribut
                    == taxhub_id_attr,
                    aliased_cor_taxon_attr[taxhub_id_attr].cd_ref
                    == func.taxonomie.find_cdref(model.cd_nom),
                ),
            ).filter(aliased_cor_taxon_attr[taxhub_id_attr].valeur_attribut.in_(value))
            join_on_bibnoms = True

    # remove attributes taxhub from filters
    filters = {
        colname: value
        for colname, value in filters.items()
        if not colname.startswith("taxhub_attribut")
    }
    return q, filters


def filter_query_all_filters(model, q, filters, user):
    """
    Return a query filtered with the cruved and all
    the filters available in the synthese form
    parameters:
        - q (SQLAchemyQuery): an SQLAchemy query
        - filters (dict): a dict of filter
        - user (User): a user object from User
        - allowed datasets (List<int>): an array of ID dataset where the users have autorization

    """
    q = filter_query_with_cruved(model, q, user)

    if "observers" in filters:
        q = q.filter(model.observers.ilike("%" + filters.pop("observers")[0] + "%"))

    if "id_organism" in filters:
        id_datasets = (
            DB.session.query(CorDatasetActor.id_dataset)
            .filter(CorDatasetActor.id_organism.in_(filters.pop("id_organism")))
            .all()
        )
        formated_datasets = [d[0] for d in id_datasets]
        q = q.filter(model.id_dataset.in_(formated_datasets))

    if "date_min" in filters:
        q = q.filter(model.date_min >= filters.pop("date_min")[0])

    if "date_max" in filters:
        q = q.filter(model.date_min <= filters.pop("date_max")[0])

    if "id_acquisition_framework" in filters:
        q = q.join(
            TAcquisitionFramework,
            model.id_acquisition_framework
            == TAcquisitionFramework.id_acquisition_framework,
        )
        q = q.filter(
            TAcquisitionFramework.id_acquisition_framework.in_(
                filters.pop("id_acquisition_frameworks")
            )
        )

    if "geoIntersection" in filters:
        # Insersect with the geom send from the map
        ors = []
        for str_wkt in filters["geoIntersection"]:
            # if the geom is a circle
            if "radius" in filters:
                radius = filters.pop("radius")[0]
                wkt = loads(str_wkt)
                wkt = circle_from_point(wkt, float(radius))
            else:
                wkt = loads(str_wkt)
            geom_wkb = from_shape(wkt, srid=4326)
            ors.append(model.the_geom_4326.ST_Intersects(geom_wkb))

        q = q.filter(or_(*ors))
        filters.pop("geoIntersection")

    if "period_start" in filters and "period_end" in filters:
        period_start = filters.pop("period_start")[0]
        period_end = filters.pop("period_end")[0]
        q = q.filter(
            or_(
                func.gn_commons.is_in_period(
                    func.date(model.date_min),
                    func.to_date(period_start, "DD-MM"),
                    func.to_date(period_end, "DD-MM"),
                ),
                func.gn_commons.is_in_period(
                    func.date(model.date_max),
                    func.to_date(period_start, "DD-MM"),
                    func.to_date(period_end, "DD-MM"),
                ),
            )
        )
    q, filters = filter_taxonomy(model, q, filters)

    # generic filters
    join_on_cor_area = False
    for colname, value in filters.items():
        if colname.startswith("area"):
            if not join_on_cor_area:
                q = q.join(
                    CorAreaSynthese, CorAreaSynthese.id_synthese == model.id_synthese
                )
            q = q.filter(CorAreaSynthese.id_area.in_(value))
            join_on_cor_area = True
        else:
            col = getattr(model.__table__.columns, colname)
            q = q.filter(col.in_(value))
    return q
