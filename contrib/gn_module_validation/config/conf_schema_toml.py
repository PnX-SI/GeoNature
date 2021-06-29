"""
   Spécification du schéma toml des paramètres de configurations
"""

from marshmallow import Schema, fields


# Colonnes renvoyees par l'API synthese qui sont obligatoires pour que les fonctionnalités
#  front fonctionnent
MANDATORY_COLUMNS = [
    {"column_name": "id_nomenclature_valid_status", "column_label": ""},
    {"column_name": "id_synthese", "column_label": "id_synthese"},
    {"column_name": "entity_source_pk_value", "column_label": "entity_source_pk_value"},
    {"column_name": "validation_auto", "column_label": "validation_auto"},
    {"column_name": "cd_nom", "column_label": "cd_nom"},
    {"column_name": "meta_update_date", "column_label": "meta_update_date"},
    {"column_name": "cd_nomenclature_validation_status", "column_label": "cd_nomenclature_validation_status"},
    {"column_name": "mnemonique", "column_label": "mnemonique"},
    {"column_name": "label_default", "column_label": "label_default"},
    {"column_name": "unique_id_sinp", "column_label": "unique_id_sinp"},
    {"column_name": "geojson", "column_label": "geojson"},
    {"column_name": "nom_vern", "column_label": "nom_vern"},
    {"column_name": "lb_nom", "column_label": "lb_nom"},
    {"column_name": "validation_date", "column_label": "Date de validation"},
]


COLUMN_LIST = [
    {"column_name": "id_nomenclature_valid_status", "column_label": "", "max_width": 40},
    {"column_name": "nom_vern_or_lb_nom", "column_label": "Taxon", "min_width": 250},
    {"column_name": "date_min", "column_label": "Date obs.", "min_width": 100},
    {"column_name": "dataset_name", "column_label": "Jeu de donnees", "min_width": 100},
    {"column_name": "observers", "column_label": "Observateur", "min_width": 100},
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
MAIL_BODY = """La donnée en date du ${ d.date_min } relative au taxon ${ d.nom_vern } - ${ d.nom_valide } pose question.\n\r
Merci de contacter la personne en charge de la validation. 
\n\rCommunes : ${ d.communes }
Médias : ${ d.medias }\n\r
Lien vers l'observation: ${ d.data_link }
"""
MAIL_SUBJECT = "[GeoNature Validation] Donnée du ${ d.date_min } - ${ d.nom_vern } - ${ d.nom_valide }"

class ColumnSchema(Schema):
    column_name = fields.Str(required=True)
    column_label = fields.Str()
    max_width = fields.Integer()
    min_width = fields.Integer()
    func = fields.Str()
    id_nomenclature_field = fields.Str()


class GnModuleSchemaConf(Schema):
    MANDATORY_COLUMNS = fields.List(fields.Nested(ColumnSchema), missing=MANDATORY_COLUMNS)
    STATUS_INFO = fields.Dict(fields.Dict(), missing=STATUS_INFO)
    NB_MAX_OBS_MAP = fields.Integer(missing=5000)
    MAP_POINT_STYLE = fields.Dict(fields.Dict(), missing=MAP_POINT_STYLE)
    ICON_FOR_AUTOMATIC_VALIDATION = fields.String(missing=ICON_FOR_AUTOMATIC_VALIDATION)
    ZOOM_SINGLE_POINT = fields.Integer(missing=ZOOM_SINGLE_POINT)
    id_for_enAttenteDeValidation = fields.Integer(missing=id_for_enAttenteDeValidation)
    DISPLAY_TAXON_TREE = fields.Boolean(missing=True)
    ID_ATTRIBUT_TAXHUB = fields.List(fields.Integer, missing=ID_ATTRIBUT_TAXHUB)
    AREA_FILTERS = fields.List(fields.Dict, missing=AREA_FILTERS)
    MAIL_BODY = fields.String(missing=MAIL_BODY)
    MAIL_SUBJECT = fields.String(missing=MAIL_SUBJECT)
    COLUMN_LIST = fields.List(fields.Nested(ColumnSchema), missing=COLUMN_LIST)