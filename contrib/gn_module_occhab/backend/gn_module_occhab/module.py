from geonature.core.gn_commons.models import TModules
from .imports.plot import distribution_plot
from .imports import (
    preprocess_transient_data,
    check_transient_data,
    import_data_to_occhab,
    remove_data_from_occhab,
)


class OcchabModule(TModules):
    __mapper_args__ = {"polymorphic_identity": "occhab"}

    def generate_input_url_for_dataset(self, dataset):
        return f"/import/occhab/process/upload?datasetId={dataset.id_dataset}"

    generate_input_url_for_dataset.label = "Importer des habitats"

    _imports_ = {
        "preprocess_transient_data": preprocess_transient_data,
        "check_transient_data": check_transient_data,
        "import_data_to_destination": import_data_to_occhab,
        "remove_data_from_destination": remove_data_from_occhab,
        "report_plot": distribution_plot,
        "statistics_labels": [
            {"key": "station_count", "value": "Nombre de stations importées"},
            {"key": "habitat_count", "value": "Nombre d’habitats importés"},
        ],
    }
