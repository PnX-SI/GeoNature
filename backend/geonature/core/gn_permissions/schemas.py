import sqlalchemy as sa
from marshmallow import validate, validates
from marshmallow.exceptions import ValidationError
from marshmallow_sqlalchemy.fields import Nested

from geonature.utils.env import db, ma
from geonature.core.gn_permissions.models import (
    Permission,
    PermAction,
    PermObject,
    PermissionAvailable,
)

from pypnusershub.schemas import UserSchema
from ref_geo.schemas import AreaSchema
from apptax.taxonomie.schemas import TaxrefSchema
from utils_flask_sqla.schema import SmartRelationshipsMixin


class PermActionSchema(ma.SQLAlchemyAutoSchema):
    class Meta:
        model = PermAction
        include_fk = True


class PermObjectSchema(ma.SQLAlchemyAutoSchema):
    class Meta:
        model = PermObject
        include_fk = True


class PermissionSchema(SmartRelationshipsMixin, ma.SQLAlchemyAutoSchema):
    """
    Marchmallow-sqlalchemy behavior is to search object in database,
    and if not found, to create a new one. As this schema is not means to create
    any related object, nested fields are dump only (use the FK to set the value).
    For m2m fields, as it is not possible to load the FK which is in another table,
    we let the user provide m2m models PK, but we have validation hooks which verify
    that related models exists and have not been created by marchmallow-sqlalchemy.
    """

    class Meta:
        model = Permission
        include_fk = True
        load_instance = True
        sqla_session = db.session
        dump_only = ("role", "action", "module", "object")

    role = Nested(UserSchema)
    action = Nested(PermActionSchema)
    module = Nested("ModuleSchema")
    object = Nested(PermObjectSchema)

    scope_value = ma.auto_field(validate=validate.Range(min=0, max=3), strict=True)
    areas_filter = Nested(AreaSchema, many=True)
    taxons_filter = Nested(TaxrefSchema, many=True)

    @validates("areas_filter")
    def validate_areas_filter(self, data, **kwargs):
        errors = {}
        for i, area in enumerate(data):
            if not area or not sa.inspect(area).persistent:
                errors[i] = "Area does not exist"
        if errors:
            raise ValidationError(errors, field_name="areas_filter")
        return data

    @validates("taxons_filter")
    def validate_taxons_filter(self, data, **kwargs):
        errors = {}
        for i, taxon in enumerate(data):
            if not taxon or not sa.inspect(taxon).persistent:
                errors[i] = "Taxon does not exist"
        if errors:
            raise ValidationError(errors, field_name="taxons_filter")
        return data


class PermissionAvailableSchema(SmartRelationshipsMixin, ma.SQLAlchemyAutoSchema):
    class Meta:
        model = PermissionAvailable
        include_fk = True
        load_instance = True
        sqla_session = db.session

    action = Nested(PermActionSchema)
    module = Nested("ModuleSchema")
    object = Nested(PermObjectSchema)
