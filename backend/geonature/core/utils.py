'''
GeoNature core utils
'''

from geonature.core.gn_meta.models import TDatasets
from pypnusershub.db.tools import InsufficientRightsError


class ReleveCruvedAutorization:
    """
        Classe abstraite permettant d'ajout des méthodes
        de controle d'accès à la donnée en fonction
        des droits associés à un utilisateur
        La classe enfant doit definit les attribut suivant dans son constructeur:
        - observer_rel
        - dataset_rel
        - id_digitiser_col
        - id_dataset_col
    """


def user_is_observer_or_digitiser(self, user):
    observers = [d.id_role for d in self.observer_rel]
    return user.id_role == self.id_digitiser_col or user.id_role in observers


def user_is_in_dataset_actor(self, user):
    return self.id_dataset_col in TDatasets.get_user_datasets(user)


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


def get_releve_if_allowed(self, user):
    """
        Return the releve if the user is allowed
        params:
            user: object from TRole
    """
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
