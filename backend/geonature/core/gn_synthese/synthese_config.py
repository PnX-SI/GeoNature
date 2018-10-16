"""
Default columns for the export in synthese
"""

DEFAULT_EXPORT_COLUMNS = {
    'id_synthese': 'idSyn',
    'unique_id_sinp': 'idUnique',
    'date_min': 'dateMin',
    'date_max': 'dateMax',
    'observers': 'observers',
    'altitude_min': 'altMin',
    'altitude_max': 'altMax',
    'count_min': "NbMin",
    'count_max': 'nbMax',
    'sample_number_proof': 'EchanPreuv',
    'digital_proof': 'PreuvNum',
    'non_digital_proof': 'PreuvNoNum',
    'comments': 'comment',
    'nat_obj_geo': 'natObjGeo',
    'grp_typ': 'methGrp',
    'obs_method': 'obsMeth',
    'obs_technique': 'obsTech',
    'bio_status': 'ocEtatBio',
    'bio_condition': 'ocStatBio',
    'naturalness': 'ocNat',
    'exist_proof': 'preuveOui',
    'valid_status': 'validStat',
    'diffusion_level': 'nivDiffusi',
    'life_stage': 'ocStade',
    'sex': 'ocSex',
    'obj_count': 'objDenbr',
    'type_count': 'typDenbr',
    'sensitivity': 'sensibilit',
    'observation_status': 'statutObs',
    'blurring': 'floutage',
    'source_status': 'statutSour',
    'info_geo_type': 'typeGeom',
    'determination_method': 'methDeterm',
    'dataset_name': 'JDD',
    'cd_nom': 'cdNom',
    'cd_ref': 'cdRef',
    'nom_valide': 'nomValide',
    'wkt': 'WKT'
}


#
DEFAULT_COLUMNS_API_SYNTHESE = [
    'id_synthese',
    'date_min',
    'observers',
    'nom_valide',
    'dataset_name'
]

# Colonnes renvoyer par l'API synthese qui sont obligatoires pour que les fonctionnalites
#  front fonctionnent
MANDATORY_COLUMNS = [
    'entity_source_pk_value',
    'url_source',
    'cd_nom'
]

# CONFIG MAP-LIST
DEFAULT_LIST_COLUMN = [
    {'prop': 'nom_vern_or_lb_nom', 'name': 'Taxon', 'max_width': 200},
    {'prop': 'date_min', 'name': 'Date obs', 'max_width': 100},
    {'prop': 'dataset_name', 'name': 'JDD', 'max_width': 200},
    {'prop': 'observers', 'name': 'observateur', 'max_width': 200}
]
