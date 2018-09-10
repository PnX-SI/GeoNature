"""
Default columns for the export in synthese
"""


#  EXPORT
DEFAULT_TAXONOMIC_COLUMNS = [
    'cd_nom',
    'cd_ref',
    'nom_valide'
]

DEFAULT_SYNTHESE_COLUMNS = [
    'id_synthese',
    'unique_id_sinp',
    'date_min',
    'date_max',
    'observers',
    'altitude_min',
    'altitude_max',
    'count_min',
    'count_max',
    'sample_number_proof',
    'digital_proof',
    'non_digital_proof',
    'comments'
]

DEFAULT_NOMENCLATURE_COLUMNS = [
    'nat_obj_geo',
    'grp_typ',
    'obs_method',
    'obs_technique',
    'bio_status',
    'bio_condition',
    'naturalness',
    'exist_proof',
    'valid_status',
    'diffusion_level',
    'life_stage',
    'sex',
    'obj_count',
    'type_count',
    'sensitivity',
    'observation_status',
    'blurring',
    'source_status',
    'info_geo_type',
    'determination_method'
]


# CONFIG MAP-LIST
DEFAULT_LIST_COLUMN = [
    {'prop': 'taxon.nom_valide', 'name': 'Taxon'},
    {'prop': 'date_min', 'name': 'Date obs'},
    {'prop': 'dataset.dataset_name', 'name': 'JDD'},
    {'prop': 'observers', 'name': 'observateur'}
]
