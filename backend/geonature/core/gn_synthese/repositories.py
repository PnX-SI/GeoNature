import sqlalchemy as sa

from geonature.core.gn_synthese.models import Synthese, CorRoleSynthese
from geonature.core.gn_meta.models import TDatasets


def filter_query_with_cruved(q, user, allowed_datasets):
    """
    Filter the query with the cruved authorization of a user
    """
    if user.tag_object_code in ('1', '2'):
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
