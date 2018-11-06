from flask import current_app, request
from shapely.wkt import loads
from geoalchemy2.shape import from_shape
from sqlalchemy import func, or_, and_
from sqlalchemy.orm import aliased

from geonature.utils.env import DB
from geonature.utils.utilsgeometry import circle_from_point
from geonature.core.taxonomie.models import Taxref, CorTaxonAttribut, TaxrefLR
from geonature.core.gn_synthese.models import (
    Synthese, CorObserverSynthese, TSources,
    CorAreaSynthese
)
from geonature.core.gn_meta.models import TDatasets, TAcquisitionFramework


def filter_query_with_cruved(model, q, user, allowed_datasets):
    """
    Filter the query with the cruved authorization of a user
    """
    if user.tag_object_code in ('1', '2'):
        q = q.outerjoin(CorObserverSynthese, CorObserverSynthese.id_synthese == model.id_synthese)
        ors_filters = [
            CorObserverSynthese.id_role == user.id_role,
            model.id_digitiser == user.id_role
        ]
        if current_app.config['SYNTHESE']['CRUVED_SEARCH_WITH_OBSERVER_AS_TXT']:
            user_fullname1 = user.nom_role + ' ' + user.prenom_role + '%'
            user_fullname2 = user.prenom_role + ' ' + user.nom_role + '%'
            ors_filters.append(model.observers.ilike(user_fullname1))
            ors_filters.append(model.observers.ilike(user_fullname2))

        if user.tag_object_code == '1':
            q = q.filter(or_(*ors_filters))
        elif user.tag_object_code == '2':
            ors_filters.append(
                model.id_dataset.in_(allowed_datasets)
            )
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
    if 'cd_ref' in filters:
        # find all cd_nom where cd_ref = filter['cd_ref']
        sub_query_synonym = DB.session.query(
            Taxref.cd_nom
        ).filter(
            Taxref.cd_ref.in_(filters.pop('cd_ref'))
        ).subquery('sub_query_synonym')
        q = q.filter(model.cd_nom.in_(sub_query_synonym))

    if 'taxonomy_group2_inpn' in filters:
        q = q.filter(Taxref.group2_inpn.in_(filters.pop('taxonomy_group2_inpn')))

    if 'taxonomy_id_hab' in filters:
        q = q.filter(Taxref.id_habitat.in_(filters.pop('taxonomy_id_hab')))

    if 'taxonomy_lr' in filters:
        sub_query_lr = DB.session.query(TaxrefLR.cd_nom).filter(
            TaxrefLR.id_categorie_france.in_(filters.pop('taxonomy_lr'))
        ).subquery('sub_query_lr')
        # est-ce qu'il faut pas filtrer sur le cd_ ref ?
        # quid des protection définit à rand superieur de la saisie ?
        q = q.filter(model.cd_nom.in_(sub_query_lr))

    aliased_cor_taxon_attr = {}
    join_on_taxref = False
    for colname, value in filters.items():
        if colname.startswith('taxhub_attribut'):
            if not join_on_taxref:
                q = q.join(Taxref, Taxref.cd_nom == model.cd_nom)
                join_on_taxref = True
            taxhub_id_attr = colname[16:]
            aliased_cor_taxon_attr[taxhub_id_attr] = aliased(CorTaxonAttribut)
            q = q.join(
                aliased_cor_taxon_attr[taxhub_id_attr],
                and_(
                    aliased_cor_taxon_attr[taxhub_id_attr].id_attribut == taxhub_id_attr,
                    aliased_cor_taxon_attr[taxhub_id_attr].cd_ref == func.taxonomie.find_cdref(model.cd_nom)
                )
            ).filter(
                aliased_cor_taxon_attr[taxhub_id_attr].valeur_attribut.in_(value)
            )
            join_on_bibnoms = True

    # remove attributes taxhub from filters
    filters = {colname: value for colname, value in filters.items() if not colname.startswith('taxhub_attribut')}
    return q, filters


def filter_query_all_filters(model, q, filters, user, allowed_datasets):
    """
    Return a query filtered with the cruved and all
    the filters available in the synthese form
    parameters:
        - q (SQLAchemyQuery): an SQLAchemy query
        - filters (dict): a dict of filter
        - user (User): a user object from User
        - allowed datasets (List<int>): an array of ID dataset where the users have autorization

    """

    # from geonature.core.users.models import UserRigth

    # user = UserRigth(
    #     id_role=user.id_role,
    #     tag_object_code='3',
    #     tag_action_code="R",
    #     id_organisme=user.id_organisme,
    #     nom_role='Administrateur',
    #     prenom_role='test'
    # )
    q = filter_query_with_cruved(model, q, user, allowed_datasets)

    if 'observers' in filters:
        q = q.filter(model.observers.ilike('%'+filters.pop('observers')[0]+'%'))

    if 'date_min' in filters:
        q = q.filter(model.date_min >= filters.pop('date_min')[0])

    if 'date_max' in filters:
        q = q.filter(model.date_min <= filters.pop('date_max')[0])

    if 'id_acquisition_frameworks' in filters:
        q = q.join(
            TAcquisitionFramework,
            model.id_acquisition_framework == TAcquisitionFramework.id_acquisition_framework
        )
        q = q.filter(TAcquisitionFramework.id_acquisition_framework.in_(filters.pop('id_acquisition_frameworks')))

    if 'municipalities' in filters:
        q = q.filter(
            model.id_municipality.in_(
                [com for com in filters['municipalities']]
            )
        )
        filters.pop('municipalities')

    if 'geoIntersection' in filters:
        # Insersect with the geom send from the map
        geom_wkt = loads(request.args['geoIntersection'])
        # if the geom is a circle
        if 'radius' in filters:
            radius = filters.pop('radius')[0]
            geom_wkt = circle_from_point(geom_wkt, float(radius))
        geom_wkb = from_shape(geom_wkt, srid=4326)
        q = q.filter(model.the_geom_4326.ST_Intersects(geom_wkb))
        filters.pop('geoIntersection')

    if 'period_start' in filters and 'period_end' in filters:
        period_start = filters.pop('period_start')[0]
        period_end = filters.pop('period_end')[0]
        q = q.filter(or_(
            func.gn_commons.is_in_period(
                func.date(model.date_min),
                func.to_date(period_start, 'DD-MM'),
                func.to_date(period_end, 'DD-MM')
            ),
            func.gn_commons.is_in_period(
                func.date(model.date_max),
                func.to_date(period_start, 'DD-MM'),
                func.to_date(period_end, 'DD-MM')
            )
        ))
    q, filters = filter_taxonomy(model, q, filters)

    # generic filters
    join_on_cor_area = False
    for colname, value in filters.items():
        if colname.startswith('area'):
            if not join_on_cor_area:
                q = q.join(
                    CorAreaSynthese,
                    CorAreaSynthese.id_synthese == model.id_synthese
                )
            q = q.filter(CorAreaSynthese.id_area.in_(value))
            join_on_cor_area = True
        else:
            col = getattr(model.__table__.columns, colname)
            q = q.filter(col.in_(value))
    return q
