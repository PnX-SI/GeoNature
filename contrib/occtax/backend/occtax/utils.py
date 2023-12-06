from flask import current_app
from urllib.parse import urljoin

# nomenclatures fields
counting_nomenclatures = [
    "id_nomenclature_life_stage",
    "id_nomenclature_sex",
    "id_nomenclature_obj_count",
    "id_nomenclature_type_count",
    "id_nomenclature_valid_status",
]

occ_nomenclatures = [
    "id_nomenclature_obs_technique",
    "id_nomenclature_bio_condition",
    "id_nomenclature_bio_status",
    "id_nomenclature_naturalness",
    "id_nomenclature_exist_proof",
    "id_nomenclature_observation_status",
    "id_nomenclature_blurring",
    "id_nomenclature_determination_method",
    "id_nomenclature_behaviour",
]

releve_nomenclatures = [
    "id_nomenclature_tech_collect_campanule",
    "id_nomenclature_grp_typ",
]


def get_nomenclature_filters(params):
    """
    return all the nomenclatures from query paramters
    filters by table
    """
    counting_filters = []
    occurrence_filters = []
    releve_filters = []

    for p in params:
        if p[:2] == "id":
            if p in counting_nomenclatures:
                counting_filters.append(p)
            elif p in occ_nomenclatures:
                occurrence_filters.append(p)
            elif p in releve_nomenclatures:
                releve_filters.append(p)
    return releve_filters, occurrence_filters, counting_filters


def as_dict_with_add_cols(
    export_view, row, additional_cols_key: str, addition_cols_to_export: list
):
    row_as_dict = export_view.as_dict(row)
    if current_app.config["OCCTAX"]["ADD_MEDIA_IN_EXPORT"]:
        row_as_dict["titreMedia"] = row.titreMedia
        row_as_dict["descMedia"] = row.descMedia
        if row.urlMedia:
            row_as_dict["urlMedia"] = (
                row.urlMedia
                if row.urlMedia.startswith("http")
                else urljoin(current_app.config["API_ENDPOINT"], row.urlMedia)
            )
        else:
            row_as_dict["urlMedia"] = ""
    additional_data = row_as_dict.get(additional_cols_key, {}) or {}
    for col_name in addition_cols_to_export:
        row_as_dict[col_name] = additional_data.get(col_name, "")
    return row_as_dict
