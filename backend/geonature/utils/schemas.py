from marshmallow import Schema, fields


class ManifestSchemaConf(Schema):
    package_format_version = fields.String(required=True)
    module_code = fields.String(required=True)
    module_version = fields.String(required=True)
    min_geonature_version = fields.String(required=True)
    max_geonature_version = fields.String(required=True)
    exclude_geonature_versions = fields.List(fields.String)


class ManifestSchemaProdConf(Schema):
    module_code = fields.String(required=True)
