# gn_module_occhab/statistics.py

from sqlalchemy import func, select

from geonature.utils.env import db
from geonature.core.gn_meta.utils import AbstractMetadataStatistics
from geonature.core.gn_meta.models import TAcquisitionFramework
from gn_module_occhab.models import OccurenceHabitat, Station


class MetadataStatistics(AbstractMetadataStatistics):
    def get_dataset_nb_observations(id_dataset):
        """
        Retourne le nombre d'occurrences d'habitats pour un JDD donné.
        """
        return db.session.scalar(
            select(func.count(OccurenceHabitat.id_habitat))
            .join(OccurenceHabitat.station)
            .where(Station.id_dataset == id_dataset)
        )

    def get_acquisition_framework_nb_observations(id_acquisition_framework):
        """
        Retourne le nombre d'occurrences d'habitats pour un CA donné.
        """
        return db.session.scalar(
            select(func.count(OccurenceHabitat.id_habitat))
            .join(OccurenceHabitat.station)
            .join(
                TAcquisitionFramework,
                Station.id_dataset == TAcquisitionFramework.id_acquisition_framework,
            )
            .where(TAcquisitionFramework.id_acquisition_framework == id_acquisition_framework)
        )
