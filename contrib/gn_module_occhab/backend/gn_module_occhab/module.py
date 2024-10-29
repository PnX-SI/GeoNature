from geonature.core.gn_commons.models import TModules

from .imports.actions import OcchabImportActions


class OcchabModule(TModules):
    __mapper_args__ = {"polymorphic_identity": "occhab"}
    __import_actions__ = OcchabImportActions

    def generate_input_url_for_dataset(self, dataset):
        return f"/import/occhab/process/upload?datasetId={dataset.id_dataset}"

    generate_input_url_for_dataset.label = "Importer des habitats"
