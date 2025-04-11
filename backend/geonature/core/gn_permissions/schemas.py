from marshmallow import fields, validates_schema, EXCLUDE

from geonature.utils.env import db, ma
from geonature.core.gn_permissions.models import PermObject


class PermObjectSchema(ma.SQLAlchemyAutoSchema):
    class Meta:
        model = PermObject
        include_fk = True
