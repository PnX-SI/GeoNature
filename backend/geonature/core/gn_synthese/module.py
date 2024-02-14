from geonature.core.gn_commons.models import TModules
from geonature.core.gn_synthese.imports import (
    check_transient_data,
    import_data_to_synthese,
    remove_data_from_synthese,
)


class SyntheseModule(TModules):
    __mapper_args__ = {"polymorphic_identity": "synthese"}

    def generate_input_url_for_dataset(self, dataset):
        return f"/import/synthese/process/upload?datasetId={dataset.id_dataset}"

    generate_input_url_for_dataset.label = "Importer des occurrences de taxons"

    _imports_ = {
        "check_transient_data": check_transient_data,
        "import_data_to_destination": import_data_to_synthese,
        "remove_data_from_destination": remove_data_from_synthese,
        "statistics_labels": [
            {"key": "taxa_count", "value": "Nombre de taxons importés"},
        ],
    }
