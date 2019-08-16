"""
   Spécification du schéma toml des paramètres de configurations
"""

from marshmallow import Schema, fields

#
DEFAULT_COLUMNS_API_VALIDATION = [
    "validation_auto",
    "id_nomenclature_valid_status",
    "id_synthese",
    "date_min",
    "observers",
    "nom_valide",
    "dataset_name",
    "validation_date",
]

# Colonnes renvoyees par l'API synthese qui sont obligatoires pour que les fonctionnalités
#  front fonctionnent
MANDATORY_COLUMNS = [
    "entity_source_pk_value",
    "url_source",
    "cd_nom",
    "meta_update_date",
    "cd_nomenclature_validation_status",
    "mnemonique",
    "label_default",
    "unique_id_sinp",
]

# CONFIG MAP-LIST
DEFAULT_LIST_COLUMN = [
    {"prop": "id_nomenclature_valid_status", "name": "", "max_width": 40},
    {"prop": "nom_vern_or_lb_nom", "name": "Taxon", "max_width": 150},
    {"prop": "date_min", "name": "Date obs.", "max_width": 100},
    {"prop": "dataset_name", "name": "Jeu de donnees", "max_width": 200},
    {"prop": "observers", "name": "Observateur", "max_width": 200},
]

# cd_nomenclature_valid_status used for validation module only use for color style
STATUS_INFO = {
    "0": {"cat": "notassessed", "color": "#FFFFFF"},  #  en attente de validation
    "1": {"cat": "assessable", "color": "#8BC34A"},  # certain tres problable
    "2": {"cat": "assessable", "color": "#CDDC39"},  # probable
    "3": {"cat": "assessable", "color": "#FF9800"},  # Douteux
    "4": {"cat": "assessable", "color": "#FF5722"},  # invalide
    "5": {"cat": "notassessed", "color": "#BDBDBD"},  # non réalisable
    "6": {"cat": "notassessable", "color": "#FFFFFF"},  # inconnu
}

MAP_POINT_STYLE = {
    "originStyle": {"color": "#1976D2", "fill": True, "fillOpacity": 0, "weight": 3},
    "selectedStyle": {
        "color": "#1976D2",
        "fill": True,
        "fillColor": "#1976D2",
        "fillOpacity": 0.5,
        "weight": 3,
    },
}

ICON_FOR_AUTOMATIC_VALIDATION = "computer"

ZOOM_SINGLE_POINT = 12

id_for_enAttenteDeValidation = 465

DISPLAY_TAXON_TREE = True

ID_ATTRIBUT_TAXHUB = [1, 2]

AREA_FILTERS = [{"label": "Communes", "id_type": 25}]


class GnModuleSchemaConf(Schema):
    MANDATORY_COLUMNS = fields.List(fields.String(), missing=MANDATORY_COLUMNS)
    STATUS_INFO = fields.Dict(fields.Dict(), missing=STATUS_INFO)
    COLUMNS_API_VALIDATION_WEB_APP = fields.List(
        fields.String, missing=DEFAULT_COLUMNS_API_VALIDATION
    )
    LIST_COLUMNS_FRONTEND = fields.List(fields.Dict, missing=DEFAULT_LIST_COLUMN)
    NB_MAX_OBS_MAP = fields.Integer(missing=5000)
    MAP_POINT_STYLE = fields.Dict(fields.Dict(), missing=MAP_POINT_STYLE)
    ICON_FOR_AUTOMATIC_VALIDATION = fields.String(missing=ICON_FOR_AUTOMATIC_VALIDATION)
    ZOOM_SINGLE_POINT = fields.Integer(missing=ZOOM_SINGLE_POINT)
    id_for_enAttenteDeValidation = fields.Integer(missing=id_for_enAttenteDeValidation)
    DISPLAY_TAXON_TREE = fields.Boolean(missing=True)
    ID_ATTRIBUT_TAXHUB = fields.List(fields.Integer, missing=ID_ATTRIBUT_TAXHUB)
    AREA_FILTERS = fields.List(fields.Dict, missing=AREA_FILTERS)
