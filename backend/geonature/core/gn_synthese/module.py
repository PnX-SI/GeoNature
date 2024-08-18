from geonature.core.gn_commons.models import TModules

from .imports.actions import SyntheseImportActions


class SyntheseModule(TModules):
    __mapper_args__ = {"polymorphic_identity": "synthese"}
    __import_actions__ = SyntheseImportActions

    def generate_input_url_for_dataset(self, dataset):
        return f"/import/synthese/process/upload?datasetId={dataset.id_dataset}"

    generate_input_url_for_dataset.label = "Importer des occurrences de taxons"
