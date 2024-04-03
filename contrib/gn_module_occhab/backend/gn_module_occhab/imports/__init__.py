from .mixins import OcchabImportMixin



def get_imported_data_link(imprt):
    datalink = {}
    datalink["query_params"] = {"id_dataset": imprt.id_dataset, "id_import": imprt.id_import}
    datalink["module_url"] = f"/{imprt.destination.code}"
    return datalink
