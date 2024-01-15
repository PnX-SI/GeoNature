from geonature.utils.env import db, ma
from marshmallow import EXCLUDE

from utils_flask_sqla.schema import SmartRelationshipsMixin

from geonature.core.imports.models import Destination
from geonature.core.gn_commons.schemas import ModuleSchema


class DestinationSchema(SmartRelationshipsMixin, ma.SQLAlchemyAutoSchema):
    class Meta:
        model = Destination
        include_fk = True
        load_instance = True
        sqla_session = db.session

    module = ma.Nested(ModuleSchema)