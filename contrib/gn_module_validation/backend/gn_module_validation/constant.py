# Constants
MAX_PER_PAGE = 1000
DEFAULT_FIELDS = {
    "id_synthese",
    "unique_id_sinp",
    "entity_source_pk_value",
    "meta_update_date",
    "id_nomenclature_valid_status",
    "nomenclature_valid_status.cd_nomenclature",
    "nomenclature_valid_status.mnemonique",
    "nomenclature_valid_status.label_default",
    "last_validation.validation_date",
    "last_validation.validation_auto",
    "taxref.cd_nom",
    "taxref.nom_vern",
    "taxref.lb_nom",
    "taxref.nom_vern_or_lb_nom",
    "dataset.validable",
}
DEFAULT_PROFILE_FIELDS = {
    "profile.score",
    "profile.valid_phenology",
    "profile.valid_altitude",
    "profile.valid_distribution",
}
