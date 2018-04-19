'''
   Spécification du schéma toml des paramètres de configurations
'''

from marshmallow import Schema, fields


class GnModuleSchemaConf(Schema):
    export_view_name = fields.String(missing='ViewExportDLB')
    export_geom_columns_name = fields.String(missing="geom_4326")
    export_id_column_name = fields.String(missing="permId")
    export_columns = fields.List(fields.String(), missing=list())
    export_srid = fields.Integer(missing=4326)

