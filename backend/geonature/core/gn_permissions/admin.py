from flask import has_app_context, Markup
from flask_admin.contrib.sqla import ModelView
from flask_admin.contrib.sqla.filters import FilterEqual

from geonature.utils.env import db
from geonature.core.admin.admin import admin
from geonature.core.admin.utils import CruvedProtectedMixin, DynamicOptionsMixin
from geonature.core.gn_permissions.models import (
    PermObject,
    PermAction,
    PermScope,
    Permission,
    PermissionAvailable,
)
from geonature.core.gn_commons.models.base import TModules

from pypnusershub.db.models import User


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


class RoleFilter(DynamicOptionsMixin, FilterEqual):
    def get_dynamic_options(self, view):
        if has_app_context():
            yield from [(u.id_role, u.nom_complet) for u in User.query.all()]


class ModuleFilter(DynamicOptionsMixin, FilterEqual):
    def get_dynamic_options(self, view):
        if has_app_context():
            yield from [(m.id_module, m.module_code) for m in TModules.query.all()]


class ObjectFilter(DynamicOptionsMixin, FilterEqual):
    def get_dynamic_options(self, view):
        if has_app_context():
            yield from [(o.id_object, o.code_object) for o in PermObject.query.all()]


class ActionFilter(DynamicOptionsMixin, FilterEqual):
    def get_dynamic_options(self, view):
        if has_app_context():
            yield from [(a.id_action, a.code_action) for a in PermAction.query.all()]


class ScopeFilter(DynamicOptionsMixin, FilterEqual):
    def apply(self, query, value, alias=None):
        column = self.get_column(alias)
        if value:
            return query.filter(column == value)
        else:
            return query.filter(column.is_(None))

    def get_dynamic_options(self, view):
        if has_app_context():
            yield (None, "Sans restriction")
            yield from [(a.value, a.label) for a in PermScope.query.all()]


def filters_formatter(v, c, m, p):
    filters = []
    if m.scope:
        filters.append(m.scope.label)
    if m.sensitivity_filter:
        filters.append("Données non sensibles")
    return Markup("<ul>" + "".join(["<li>{}</li>".format(f) for f in filters]) + "</ul>")


class PermissionAdmin(CruvedProtectedMixin, ModelView):
    module_code = "ADMIN"
    object_code = "PERMISSIONS"

    column_list = ("role", "module", "object", "action", "label", "filters")
    column_labels = {
        "role": "Rôle",
        "filters": "Restriction(s)",
        "object": "Objet",
        "role.identifiant": "identifiant du rôle",
        "role.nom_complet": "nom du rôle",
        "availability": "Permission disponible",
        "sensitivity_filter": "Exclure les données sensibles",
    }
    column_searchable_list = ("role.identifiant", "role.nom_complet")
    column_formatters = {
        "role": lambda v, c, m, p: Markup("<b>{}</b>".format(Markup.escape(m.role.nom_role)))
        if m.role.groupe
        else m.role.nom_complet,
        "module": lambda v, c, m, p: m.module.module_code,
        "object": lambda v, c, m, p: m.object.code_object,
        "label": lambda v, c, m, p: m.availability.label if m.availability else None,
        "filters": filters_formatter,
    }
    column_filters = (
        RoleFilter(column=Permission.id_role, name="Rôle"),
        ModuleFilter(column=Permission.id_module, name="Module"),
        ObjectFilter(column=Permission.id_object, name="Objet"),
        ActionFilter(column=Permission.id_action, name="Action"),
        ScopeFilter(column=Permission.scope_value, name="Scope"),
    )
    named_filter_urls = True
    column_sortable_list = (
        ("role", "role.nom_complet"),
        ("module", "module.module_code"),
        ("object", "object.code_object"),
        ("action", "action.code_action"),
    )
    column_default_sort = [
        ("role.nom_complet", True),
        ("module.module_code", True),
        ("object.code_object", True),
        ("action.code_action", True),
    ]
    form_columns = ("role", "module", "object", "action", "scope", "sensitivity_filter")


class PermissionAvailableAdmin(CruvedProtectedMixin, ModelView):
    module_code = "ADMIN"
    object_code = "PERMISSIONS"

    column_labels = {
        "scope": "Portée",
        "object": "Objet",
        "scope_filter": "Filtre appartenance",
        "sensitivity_filter": "Filtre sensibilité",
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
