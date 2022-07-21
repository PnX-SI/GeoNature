"""
   Spécification du schéma toml des paramètres de configurations
"""

from marshmallow import Schema, fields


COLUMN_LIST = [
    {
        "column_name": "nomenclature_valid_status.label_default",
        "column_label": "",
        "max_width": 40,
    },
    {"column_name": "taxref.nom_vern_or_lb_nom", "column_label": "Taxon", "min_width": 250},
    {"column_name": "date_min", "column_label": "Date obs.", "min_width": 100},
    {"column_name": "dataset.dataset_name", "column_label": "Jeu de donnees", "min_width": 100},
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

AREA_FILTERS = [{"label": "Communes", "type_code": "COM"}]
MAIL_BODY = """La donnée en date du ${ d.date_min } relative au taxon ${ d.nom_vern } - ${ d.nom_valide } pose question.\n\r
Merci de contacter la personne en charge de la validation. 
\n\rCommunes : ${ d.communes }
Médias : ${ d.medias }\n\r
Lien vers l'observation: ${ d.data_link }
"""
MAIL_SUBJECT = (
    "[GeoNature Validation] Donnée du ${ d.date_min } - ${ d.nom_vern } - ${ d.nom_valide }"
)


class ColumnSchema(Schema):
    column_name = fields.Str(required=True)
    column_label = fields.Str()
    max_width = fields.Integer()
    min_width = fields.Integer()
    func = fields.Str()
    id_nomenclature_field = fields.Str()


class GnModuleSchemaConf(Schema):
    STATUS_INFO = fields.Dict(fields.Dict(), load_default=STATUS_INFO)
    NB_MAX_OBS_MAP = fields.Integer(load_default=5000)
    MAP_POINT_STYLE = fields.Dict(fields.Dict(), load_default=MAP_POINT_STYLE)
    ICON_FOR_AUTOMATIC_VALIDATION = fields.String(load_default=ICON_FOR_AUTOMATIC_VALIDATION)
    ZOOM_SINGLE_POINT = fields.Integer(load_default=ZOOM_SINGLE_POINT)
    id_for_enAttenteDeValidation = fields.Integer(load_default=id_for_enAttenteDeValidation)
    DISPLAY_TAXON_TREE = fields.Boolean(load_default=True)
    ID_ATTRIBUT_TAXHUB = fields.List(fields.Integer, load_default=ID_ATTRIBUT_TAXHUB)
    AREA_FILTERS = fields.List(fields.Dict, load_default=AREA_FILTERS)
    MAIL_BODY = fields.String(load_default=MAIL_BODY)
    MAIL_SUBJECT = fields.String(load_default=MAIL_SUBJECT)
    COLUMN_LIST = fields.List(fields.Nested(ColumnSchema), load_default=COLUMN_LIST)
