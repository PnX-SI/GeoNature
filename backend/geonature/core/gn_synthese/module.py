from geonature.core.gn_commons.models import TModules

from geonature.core.gn_synthese.imports import SyntheseImportMixin


class SyntheseModule(TModules, SyntheseImportMixin):
    __mapper_args__ = {"polymorphic_identity": "synthese"}

    def generate_input_url_for_dataset(self, dataset):
        return f"/import/synthese/process/upload?datasetId={dataset.id_dataset}"

    generate_input_url_for_dataset.label = "Importer des occurrences de taxons"
