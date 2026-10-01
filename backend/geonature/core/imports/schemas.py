from geonature.utils.env import db, ma

from utils_flask_sqla.schema import SmartRelationshipsMixin

from geonature.core.imports.models import Destination, MappingTemplate, TImports
from pypnusershub.schemas import UserSchemaFull
from geonature.core.gn_commons.schemas import ModuleSchema
from marshmallow import fields


class DestinationSchema(SmartRelationshipsMixin, ma.SQLAlchemyAutoSchema):
    class Meta:
        model = Destination
        include_fk = True
        load_instance = True
        sqla_session = db.session

    module = ma.Nested(ModuleSchema)


class MappingSchema(ma.SQLAlchemyAutoSchema):
    class Meta:
        model = MappingTemplate
        include_fk = True
        load_instance = True
        sqla_session = db.session

    cruved = fields.Dict()
    values = fields.Dict()
    owners = fields.List(fields.Nested(UserSchemaFull(only=["identifiant"])))


class ImportSchema(ma.SQLAlchemyAutoSchema):
    class Meta:
        model = TImports
        include_fk = True
        load_instance = True
        sqla_session = db.session
        exclude = ("source_file", "errors_count")
