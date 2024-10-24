from geonature.utils.env import db, ma
from marshmallow import EXCLUDE

from utils_flask_sqla.schema import SmartRelationshipsMixin

from geonature.core.imports.models import Destination, FieldMapping, MappingTemplate
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

    destination = ma.Nested(DestinationSchema)
    cruved = fields.Dict()
    values = fields.Dict()
