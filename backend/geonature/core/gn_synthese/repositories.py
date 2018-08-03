import sqlalchemy as sa

from geonature.core.gn_synthese.models import VSyntheseForWebAppBis, CorRoleSynthese
from geonature.core.gn_meta.models import TDatasets


def filter_query_with_cruved(q, user):
    """
    Filter the query with the cruved authorization of a user
    """
    if user.tag_object_code in ('1', '2'):
        q = q.join(
            CorRoleSynthese,
            CorRoleSynthese.id_synthese == VSyntheseForWebAppBis.id_synthese
        )
        print('form repo')
        print(user.nom_role)
        print(user.prenom_role)
        user_fullname1 = user.nom_role + ' ' + user.prenom_role
        user_fullname2 = user.prenom_role + ' ' + user.nom_role
        ors_filter = [
            VSyntheseForWebAppBis.observers.ilike(user_fullname1),
            VSyntheseForWebAppBis.observers.ilike(user_fullname2),
            CorRoleSynthese.id_role == user.id_role
        ]
        if user.tag_object_code == '1':
            q = q.filter(sa.or_(*ors_filter))
        elif user.tag_object_code == '2':
            users_dataset = TDatasets.get_user_datasets(user)
            ors_filter.append(
                VSyntheseForWebAppBis.id_dataset.in_(users_dataset)
            )
            q = q.filter(sa.or_(*ors_filter))
    return q
