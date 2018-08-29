import sqlalchemy as sa
from flask import request
from shapely.geometry import asShape
from shapely.wkt import loads
from geoalchemy2.shape import from_shape

from geonature.utils.env import DB
from geonature.utils.utilsgeometry import circle_from_point
from geonature.core.gn_synthese.models import (
    Synthese, CorRoleSynthese, Taxref, TSources, CorRoleSynthese,
    CorAreaSynthese
)
from geonature.core.gn_meta.models import TDatasets, TAcquisitionFramework


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


def get_all_synthese(filters, user, allowed_datasets):
    """
    Return a query filtered with the cruved and all
    the filters available in the synthese form
    parameters:
        - filters: a dict of filter
        - user: a user object from TRoles
        - allowed datasets: an array of ID dataset where the users have autorization

    """
    q = (
        DB.session.query(Synthese, Taxref, TSources, TDatasets)
        .join(
            Taxref, Taxref.cd_nom == Synthese.cd_nom
        ).join(
            TSources, TSources.id_source == Synthese.id_source
        ).join(
            TDatasets, TDatasets.id_dataset == Synthese.id_dataset
        )
    )
    from geonature.core.users.models import UserRigth

    user = UserRigth(
        id_role=user.id_role,
        tag_object_code='3',
        tag_action_code="R",
        id_organisme=user.id_organisme,
        nom_role='Administrateur',
        prenom_role='test'
    )
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
        q = q.filter(Synthese.id_municipality.in_([com['insee_com'] for com in filters['municipalities']]))
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
    q = q.order_by(
        Synthese.date_min.desc()
    )
    return q
