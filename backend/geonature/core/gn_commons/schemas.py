from geonature.utils.env import MA 
from geonature.core.gn_commons.models import TModules

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