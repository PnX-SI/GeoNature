from marshmallow import pre_load

from geonature.utils.env import MA 
from geonature.core.gn_commons.models import TModules, TMedias

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

    @pre_load
    def make_media(self, data, **kwargs):
        if data.get("id_media") is None:
            data.pop("id_media", None)
        return data