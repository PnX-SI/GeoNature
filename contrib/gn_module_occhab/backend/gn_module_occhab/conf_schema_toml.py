"""
Spécification du schéma toml des paramètres de configurations
La classe doit impérativement s'appeller GnModuleSchemaConf
Fichier spécifiant les types des paramètres et leurs valeurs par défaut
Fichier à ne pas modifier. Paramètres surcouchables dans config/config_gn_module.tml
"""

from marshmallow import Schema, fields


class FormConfig(Schema):
    date_min = fields.Boolean(load_default=True)
    date_max = fields.Boolean(load_default=True)
    depth_min = fields.Boolean(load_default=True)
    depth_max = fields.Boolean(load_default=True)
    altitude_min = fields.Boolean(load_default=True)
    altitude_max = fields.Boolean(load_default=True)
    exposure = fields.Boolean(load_default=True)
    area = fields.Boolean(load_default=True)
    area_surface_calculation = fields.Boolean(load_default=True)
    geographic_object = fields.Boolean(load_default=True)
    comment = fields.Boolean(load_default=True)
    determination_type = fields.Boolean(load_default=True)
    collection_technique = fields.Boolean(load_default=True)
    technical_precision = fields.Boolean(load_default=True)
    determiner = fields.Boolean(load_default=True)
    recovery_percentage = fields.Boolean(load_default=False)
    abundance = fields.Boolean(load_default=True)
    community_interest = fields.Boolean(load_default=True)


class GnModuleSchemaConf(Schema):
    ID_LIST_HABITAT = fields.Integer(load_default=None)
    OBSERVER_AS_TXT = fields.Boolean(load_default=False)
    OBSERVER_LIST_ID = fields.Integer(load_default=1)
    formConfig = fields.Nested(FormConfig, load_default=FormConfig().load({}))
    # Formats d'export disponibles ["csv", "geojson", "shapefile", "gpkg"]
    EXPORT_FORMAT = fields.List(fields.String(), load_default=["csv", "geojson", "shapefile"])
    NB_MAX_EXPORT = fields.Integer(load_default=50000)
    NB_MAX_MAP_LIST = fields.Integer(load_default=5000)
    EXPORT_COLUMS = fields.List(
        fields.String(),
        load_default=[
            "uuid_station",
            "uuid_jdd",
            "date_debut",
            "date_fin",
            "observateurs",
            "methode_calcul_surface",
            "geometry",
            "surface",
            "altitude_min",
            "altitude_max",
            "exposition",
            "nature_objet_geo",
            "uuid_habitat",
            "nom_cite",
            "cd_hab",
            "precision_technique",
        ],
    )
