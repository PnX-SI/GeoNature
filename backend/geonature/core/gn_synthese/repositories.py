from datetime import datetime

import sqlalchemy as sa

from flask import request
from shapely.geometry import asShape
from shapely.wkt import loads
from geoalchemy2.shape import from_shape
from sqlalchemy import func, between, or_, and_
from sqlalchemy.orm import aliased

from geonature.utils.env import DB
from geonature.utils.utilsgeometry import circle_from_point
from geonature.core.taxonomie.models import Taxref, CorTaxonAttribut, BibNoms
from geonature.core.gn_synthese.models import (
    Synthese, CorRoleSynthese, TSources, CorRoleSynthese,
    CorAreaSynthese
)
from geonature.core.gn_meta.models import TDatasets, TAcquisitionFramework
from geonature.utils.errors import GeonatureApiError


def filter_query_with_cruved(q, user, allowed_datasets):
    """
    Filter the query with the cruved authorization of a user
    """
    if user.tag_object_code in ('1', '2'):
        # TODO: outerjoin que en dev, join normal en prod
        q = q.outerjoin(CorRoleSynthese, CorRoleSynthese.id_synthese == Synthese.id_synthese)
        user_fullname1 = user.nom_role + ' ' + user.prenom_role + '%'
        user_fullname2 = user.prenom_role + ' ' + user.nom_role + '%'
        ors_filter = [
            Synthese.observers.ilike(user_fullname1),
            Synthese.observers.ilike(user_fullname2),
            CorRoleSynthese.id_role == user.id_role
        ]
        if user.tag_object_code == '1':
            q = q.filter(sa.or_(*ors_filter))
        elif user.tag_object_code == '2':
            ors_filter.append(
                Synthese.id_dataset.in_(allowed_datasets)
            )
            q = q.filter(sa.or_(*ors_filter))
    return q

def filter_taxonomy(q, filters):
    """
    Filters the query with taxonomic attributes
    Parameters:
        - q (SQLAchemyQuery): an SQLAchemy query
        - filters (dict): a dict of filter
    Returns:
        -Tuple: the SQLAlchemy query and the filter dictionnary
    """
    if 'cd_ref' in filters:
        sub_query_synonym = DB.session.query(
            Taxref.cd_nom
            ).filter(
                Taxref.cd_ref.in_(filters.pop('cd_ref'))
            ).subquery('sub_query_synonym')
        q = q.filter(Synthese.cd_nom.in_(sub_query_synonym))
    
    aliased_cor_taxon_attr = {}
    for colname, value in filters.items():
        if colname.startswith('taxhub_attribut'):
            taxhub_id_attr = colname[16:]
            aliased_cor_taxon_attr[taxhub_id_attr] = aliased(CorTaxonAttribut)
            q = q.join(
                aliased_cor_taxon_attr[taxhub_id_attr],
                and_(
                    aliased_cor_taxon_attr[taxhub_id_attr].id_attribut == taxhub_id_attr, 
                    aliased_cor_taxon_attr[taxhub_id_attr].cd_ref == Taxref.cd_ref
                )
            ).filter(
                aliased_cor_taxon_attr[taxhub_id_attr].valeur_attribut.in_(value)
            )
            join_on_bibnoms = True
    
    # remove attributes taxhub from filters
    filters = {colname: value for colname, value in filters.items() if not colname.startswith('taxhub_attribut')}
    return q, filters


def filter_query_all_filters(q, filters, user, allowed_datasets):
    """
    Return a query filtered with the cruved and all
    the filters available in the synthese form
    parameters:
        - q (SQLAchemyQuery): an SQLAchemy query
        - filters (dict): a dict of filter
        - user (TRoles): a user object from TRoles
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
    q = filter_query_with_cruved(q, user, allowed_datasets)

    if 'observers' in filters:
        q = q.filter(Synthese.observers.ilike('%'+filters.pop('observers')[0]+'%'))

    if 'date_min' in filters:
        q = q.filter(Synthese.date_min >= filters.pop('date_min')[0])

    if 'date_max' in filters:
        q = q.filter(Synthese.date_min <= filters.pop('date_max')[0])

    if 'id_acquisition_frameworks' in filters:
        q = q.join(
            TAcquisitionFramework,
            TDatasets.id_dataset == TAcquisitionFramework.id_acquisition_framework
        )
        q = q.filter(TAcquisitionFramework.id_acquisition_framework.in_(filters.pop('id_acquisition_frameworks')))

    if 'municipalities' in filters:
        q = q.filter(
            Synthese.id_municipality.in_(
                [com for com in filters['municipalities']]
            )
        )
        filters.pop('municipalities')

    if 'geoIntersection' in filters:
        # Insersect with the geom send from the map
        geom_wkt = loads(filters['geoIntersection'][0])
        # if the geom is a circle
        if 'radius' in filters:
            radius = filters.pop('radius')[0]
            geom_wkt = circle_from_point(geom_wkt, radius)
        geom_wkb = from_shape(geom_wkt, srid=4326)
        q = q.filter(Synthese.the_geom_4326.ST_Intersects(geom_wkb))
        filters.pop('geoIntersection')

    if 'period_start' in filters and 'period_end' in filters:
        period_start = filters.pop('period_min')[0]
        period_end = filters.pop('period_max')[0]
        q = q.filter(or_(
            func.gn_commons.is_in_period(
                func.date(Synthese.date_min),
                func.to_date(period_start, 'DD-MM'),
                func.to_date(period_end, 'DD-MM')
            ),
            func.gn_commons.is_in_period(
                func.date(Synthese.date_max),
                func.to_date(period_start, 'DD-MM'),
                func.to_date(period_end, 'DD-MM')
            )
        ))

    q, filters = filter_taxonomy(q, filters)

    # generic filters
    for colname, value in filters.items():
        if colname.startswith('area'):
            q = q.join(
                CorAreaSynthese,
                CorAreaSynthese.id_synthese == Synthese.id_synthese
            )
            q = q.filter(CorAreaSynthese.id_area.in_(
                [a['id_area'] for a in value]
            ))
        else:
            col = getattr(Synthese.__table__.columns, colname)
            q = q.filter(col.in_(value))

    return q
