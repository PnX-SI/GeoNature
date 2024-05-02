import logging
from marshmallow import Schema, pre_load, fields, EXCLUDE

from utils_flask_sqla.schema import SmartRelationshipsMixin

from pypnnomenclature.schemas import NomenclatureSchema, BibNomenclaturesTypesSchema

from pypnusershub.schemas import UserSchema
from geonature.utils.env import MA
from geonature.core.gn_commons.models import (
    TModules,
    TMedias,
    TValidations,
    TAdditionalFields,
    BibWidgets,
)
from geonature.core.gn_permissions.schemas import PermObjectSchema


log = logging.getLogger()


class ModuleSchema(MA.SQLAlchemyAutoSchema):
    class Meta:
        model = TModules
        load_instance = True
        exclude = (
            "module_picto",
            "module_desc",
            "module_group",
            "module_external_url",
            "module_target",
            "module_comment",
            "active_frontend",
            "active_backend",
            "module_doc_url",
            "module_order",
        )


class MediaSchema(MA.SQLAlchemyAutoSchema):
    class Meta:
        model = TMedias
        load_instance = True
        include_fk = True
        unknown = EXCLUDE

    meta_create_date = fields.DateTime(dump_only=True)
    meta_update_date = fields.DateTime(dump_only=True)

    @pre_load
    def make_media(self, data, **kwargs):
        if data.get("id_media") is None:
            data.pop("id_media", None)
        return data


class TValidationSchema(MA.SQLAlchemyAutoSchema):
    class Meta:
        model = TValidations
        load_instance = True
        include_fk = True

    validation_label = fields.Nested(NomenclatureSchema, dump_only=True)
    validator_role = MA.Nested(UserSchema, dump_only=True)


class BibWidgetSchema(MA.SQLAlchemyAutoSchema):
    class Meta:
        model = BibWidgets
        load_instance = True


class LabelValueDict(Schema):
    label = fields.Str()
    value = fields.Raw()


class CastableField(fields.Field):
    """
    A field which tries to cast the value to int or float before returning it.
    If the value is not castable, the default value is returned.
    """

    def _serialize(self, value, attr, obj, **kwargs):
        if value:
            try:
                value = float(value)
            except ValueError:
                log.warning("default value not castable to float")
            try:
                value = int(value)
            except ValueError:
                log.warning("default value not castable to int")
        return value


class TAdditionalFieldsSchema(SmartRelationshipsMixin, MA.SQLAlchemyAutoSchema):
    class Meta:
        model = TAdditionalFields
        load_instance = True

    default_value = CastableField(allow_none=True)

    modules = fields.Nested(ModuleSchema, many=True, dump_only=True)
    objects = fields.Nested(PermObjectSchema, many=True, dump_only=True)
    type_widget = fields.Nested(BibWidgetSchema, dump_only=True)
    datasets = fields.Nested("DatasetSchema", many=True, dump_only=True)
    bib_nomenclature_type = fields.Nested(BibNomenclaturesTypesSchema, dump_only=True)

    def load(self, data, *, many=None, **kwargs):

        if data["type_widget"].widget_name in (
            "select",
            "checkbox",
            "radio",
            "multiselect",
        ):
            LabelValueDict(many=True).load(data["field_values"])
        return super().load(data, many=many, unknown=EXCLUDE)
