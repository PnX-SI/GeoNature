'''
   Spécification du schéma toml des paramètres de configurations
   La classe doit impérativement s'appeller GnModuleSchemaConf
   Fichier spécifiant les types des paramètres et leurs valeurs par défaut
   Fichier à ne pas modifier. Paramètres surcouchables dans config/config_gn_module.tml
'''

from marshmallow import Schema, fields


class FormConfig(Schema):
    date_min = fields.Boolean(missing=True)
    date_max = fields.Boolean(missing=True)
    depth_min = fields.Boolean(missing=True)
    depth_max = fields.Boolean(missing=True)
    altitude_min = fields.Boolean(missing=True)
    altitude_max = fields.Boolean(missing=True)
    exposure = fields.Boolean(missing=True)
    area = fields.Boolean(missing=True)
    area_surface_calculation = fields.Boolean(missing=True)
    geographic_object = fields.Boolean(missing=True)
    comment = fields.Boolean(missing=True)
    determination_type = fields.Boolean(missing=True)
    collection_technique = fields.Boolean(missing=True)
    technical_precision = fields.Boolean(missing=True)
    determiner = fields.Boolean(missing=True)
    recovery_percentage = fields.Boolean(missing=False)
    abundance = fields.Boolean(missing=True)
    community_interest = fields.Boolean(missing=True)


class GnModuleSchemaConf(Schema):
    ID_LIST_HABITAT = fields.Integer(missing=1)
    OBSERVER_AS_TXT = fields.Integer(missing=False)
    OBSERVER_LIST_ID = fields.Integer(missing=1)
    formConfig = fields.Nested(FormConfig, missing=dict())
    EXPORT_FORMAT = fields.List(fields.String(), missing=[
                                'csv', 'geojson', 'shapefile'])
    NB_MAX_EXPORT = fields.Integer(missing=50000)
    NB_MAX_MAP_LIST = fields.Integer(missing=5000)
    EXPORT_COLUMS = fields.List(fields.String(), missing=[
        "identifiantStaSINP",
        "metadonneeId",
        "dSPublique",
        "dateDebut",
        "dateFin",
        "observateur",
        "methodeCalculSurface",
        "geometry",
        "natureObjetGeo",
        "identifiantHabSINP",
        "nomCite",
        "cdHab",
        "precisionTechnique"
    ])
