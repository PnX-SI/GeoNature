# gn_module_occhab/statistics.py

from sqlalchemy import func, select

from geonature.utils.env import db
from gn_module_occhab.models import OccurenceHabitat, Station


def get_dataset_nb_observations(id_dataset):
    """
    Retourne le nombre d'occurrences d'habitats pour un JDD donné.
    Utilisé pour alimenter la colonne "Nombre de données" dans les listes JDD / CA.
    """
    return db.session.scalar(
        select(func.count(OccurenceHabitat.id_habitat))
        .join(OccurenceHabitat.station)
        .where(Station.id_dataset == id_dataset)
    )
