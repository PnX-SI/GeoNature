from flask_admin.contrib.sqla import ModelView

from geonature.utils.env import db
from geonature.core.admin.admin import admin
from geonature.core.admin.utils import CruvedProtectedMixin
from geonature.core.gn_permissions.models import PermObject, Permission, PermissionAvailable


class ObjectAdmin(CruvedProtectedMixin, ModelView):
    module_code = "ADMIN"
    object_code = "PERMISSIONS"

    column_list = ("code_object", "description_object", "modules")
    column_labels = {
        "code_object": "Code",
        "description_object": "Description",
    }

    can_create = False
    can_edit = False
    can_delete = False


class PermissionAdmin(CruvedProtectedMixin, ModelView):
    module_code = "ADMIN"
    object_code = "PERMISSIONS"

    column_list = ("role", "module", "object", "action", "scope")
    column_labels = {
        "role": "Rôle",
        "scope": "Porté",
        "object": "Objet",
    }
    column_formatters = {
        "module": lambda v, c, m, p: m.module.module_code,
        "object": lambda v, c, m, p: m.object.code_object,
    }


class PermissionAvailableAdmin(CruvedProtectedMixin, ModelView):
    module_code = "ADMIN"
    object_code = "PERMISSIONS"

    column_labels = {
        "scope": "Portée",
        "object": "Objet",
        "scope_filter": "Filtre appartenance",
    }
    column_formatters = {
        "module": lambda v, c, m, p: m.module.module_code,
        "object": lambda v, c, m, p: m.object.code_object,
    }


admin.add_view(
    ObjectAdmin(
        PermObject,
        db.session,
        name="Objets",
        category="Permissions",
    )
)


admin.add_view(
    PermissionAdmin(
        Permission,
        db.session,
        name="Permissions",
        category="Permissions",
    )
)


admin.add_view(
    PermissionAvailableAdmin(
        PermissionAvailable,
        db.session,
        name="Permissions disponibles",
        category="Permissions",
    )
)
