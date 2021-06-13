"""
Default columns for the export in synthese
"""

DEFAULT_EXPORT_COLUMNS = [
    "date_debut",
    "date_fin",
    "heure_debut",
    "heure_fin",
    "cd_nom",
    "cd_ref",
    "nom_valide",
    "nom_vernaculaire",
    "nom_cite",
    "regne",
    "group1_inpn",
    "group2_inpn",
    "classe",
    "ordre",
    "famille",
    "rang_taxo",
    "nombre_min",
    "nombre_max",
    "alti_min",
    "alti_max",
    "prof_min",
    "prof_max",
    "observateurs",
    "determinateur",
    "communes",
    "x_centroid_4326",
    "y_centroid_4326",
    "geometrie_wkt_4326",
    "nom_lieu",
    "comment_releve",
    "comment_occurrence",
    "validateur",
    "niveau_validation",
    "date_validation",
    "comment_validation",
    "preuve_numerique_url",
    "preuve_non_numerique",
    "jdd_nom",
    "jdd_uuid",
    "jdd_id",
    "ca_nom",
    "ca_uuid",
    "ca_id",
    "cd_habref",
    "cd_habitat",
    "nom_habitat",
    "precision_geographique",
    "nature_objet_geo",
    "type_regroupement",
    "methode_regroupement",
    "technique_observation",
    "biologique_statut",
    "etat_biologique",
    "biogeographique_statut",
    "naturalite",
    "preuve_existante",
    "niveau_precision_diffusion",
    "stade_vie",
    "sexe",
    "objet_denombrement",
    "type_denombrement",
    "niveau_sensibilite",
    "statut_observation",
    "floutage_dee",
    "statut_source",
    "type_info_geo",
    "methode_determination",
    "comportement",
    "reference_biblio",
    "id_synthese",
    "id_origine",
    "uuid_perm_sinp",
    "uuid_perm_grp_sinp",
    "date_creation",
    "date_modification",
    "champs_additionnels"
]


#
DEFAULT_COLUMNS_API_SYNTHESE = [
    "id_synthese",
    "date_min",
    "observers",
    "nom_valide",
    "dataset_name",
]

# Colonnes renvoyer par l'API synthese qui sont obligatoires pour que les fonctionnalites
#  front fonctionnent
MANDATORY_COLUMNS = ["entity_source_pk_value", "url_source", "cd_nom"]

# CONFIG MAP-LIST
DEFAULT_LIST_COLUMN = [
    {"prop": "nom_vern_or_lb_nom", "name": "Taxon", "max_width": 200},
    {"prop": "date_min", "name": "Date obs", "max_width": 100},
    {"prop": "dataset_name", "name": "JDD", "max_width": 200},
    {"prop": "observers", "name": "observateur", "max_width": 200},
]
