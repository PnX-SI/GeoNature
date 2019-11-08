'''
   Spécification du schéma toml des paramètres de configurations
   La classe doit impérativement s'appeller GnModuleSchemaConf
   Fichier spécifiant les types des paramètres et leurs valeurs par défaut
   Fichier à ne pas modifier. Paramètres surcouchables dans config/config_gn_module.tml
'''

from marshmallow import Schema, fields


class GnModuleSchemaConf(Schema):
    ID_LIST_HABITAT = fields.Integer(missing=1)
    OBSERVER_AS_TXT = fields.Integer(missing=False)
