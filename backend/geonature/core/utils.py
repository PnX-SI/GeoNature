'''
GeoNature core utils
'''

from pypnusershub.db.tools import InsufficientRightsError
from geonature.core.gn_meta.models import TDatasets
from geonature.core.users.models import UserRigth
from geonature.utils.env import DB


class ReleveCruvedAutorization(DB.Model):
    """
        Classe abstraite permettant d'ajout des méthodes
        de controle d'accès à la donnée en fonction
        des droits associés à un utilisateur
        La classe enfant doit avoir les attributs suivant dans son constructeur:
        - observers
        - dataset
        - id_digitiser
        - id_dataset
        A définir en tant que "synonymes" si les attributs sont différents
    """
    __abstract__ = True

    def user_is_observer_or_digitiser(self, user):
        observers = [d.id_role for d in self.observers]
        return user.id_role == self.id_digitiser or user.id_role in observers

    def user_is_in_dataset_actor(self, user):
        return self.id_dataset in TDatasets.get_user_datasets(user)

    def user_is_allowed_to(self, user, level):
        """
            Fonction permettant de dire si un utilisateur
            peu ou non agir sur une donnée
        """
        # Si l'utilisateur n'a pas de droit d'accès aux données
        if level == "0" or level not in ("1", "2", "3"):
            return False

        # Si l'utilisateur à le droit d'accéder à toutes les données
        if level == "3":
            return True

        # Si l'utilisateur est propriétaire de la données
        if self.user_is_observer_or_digitiser(user):
            return True

        # Si l'utilisateur appartient à un organisme
        # qui a un droit sur la données et
        # que son niveau d'accès est 2 ou 3
        if self.user_is_in_dataset_actor(user) and level in ("2", "3"):
            return True
        return False

    def check_if_allowed(self, info_role, action, level_scope):
        """
            Return the releve if the user is allowed
            params:
                info_role: object from Permission
        """
        user = UserRigth(
            id_role=info_role.id_role,
            value_filter=level_scope,
            code_action=action,
            id_organisme=info_role.id_organisme,
        )
        if self.user_is_allowed_to(user, user.value_filter):
            return self

        raise InsufficientRightsError(
            ('User "{}" cannot "{}" this current releve').format(
                user.id_role, user.code_action
            ),
            403,
        )

    def get_releve_cruved(self, user, user_cruved):
        """
        Return the user's cruved for a Releve instance.
        Use in the map-list interface to allow or not an action
        params:
            - user : a TRole object
            - user_cruved: object return by cruved_for_user_in_app(user)
        """
        return {
            action: self.user_is_allowed_to(user, level)
            for action, level in user_cruved.items()
        }
