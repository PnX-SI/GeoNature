from marshmallow import pre_load, fields

from pypnnomenclature.schemas import NomenclatureSchema
from pypnusershub.schemas import UserSchema
from geonature.utils.env import MA 
from geonature.core.gn_commons.models import TModules, TMedias, TValidations

class ModuleSchema(MA.SQLAlchemyAutoSchema):
    class Meta:
        model = TModules
        load_instance = True
        exclude = (
            "module_picto",
            "module_desc",
            "module_group",
            "module_path",
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
        validation_label = fields.Nested(
            NomenclatureSchema,
            dump_only=True
        )
        validator_role = MA.Nested(
            UserSchema, 
            dump_only=True
        )