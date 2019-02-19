"""
Default columns for the export in synthese
"""

DEFAULT_EXPORT_COLUMNS = [
    "idSynthese",
    "permId",
    "permIdGrp",
    "dateDebut",
    "dateFin",
    "observer",
    "altMin",
    "altMax",
    "denbrMin",
    "denbrMax",
    "EchanPreuv",
    "PreuvNum",
    "PreuvNoNum",
    "obsCtx",
    "obsDescr",
    "ObjGeoTyp",
    "methGrp",
    "obsMeth",
    "ocEtatBio",
    "ocStatBio",
    "ocNat",
    "preuveOui",
    "validStat",
    "difNivPrec",
    "ocStade",
    "ocSex",
    "objDenbr",
    "denbrTyp",
    "sensiNiv",
    "statObs",
    "dEEFlou",
    "statSource",
    "typInfGeo",
    "methDeterm",
    "jddCode",
    "cdNom",
    "cdRef",
    "nomCite",
    "vTAXREF",
    "wkt",
    "lastAction",
    "validateur",
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
