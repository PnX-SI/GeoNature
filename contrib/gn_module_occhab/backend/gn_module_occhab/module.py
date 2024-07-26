from geonature.core.gn_commons.models import TModules

from .imports import OcchabImportMixin


class OcchabModule(TModules, OcchabImportMixin):
    __mapper_args__ = {"polymorphic_identity": "occhab"}

    def generate_input_url_for_dataset(self, dataset):
        return f"/import/occhab/process/upload?datasetId={dataset.id_dataset}"

    generate_input_url_for_dataset.label = "Importer des habitats"
