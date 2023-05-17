from flask import url_for, has_app_context, Markup, request
from flask_admin.contrib.sqla import ModelView
from flask_admin.contrib.sqla.filters import FilterEqual
from sqlalchemy.orm import contains_eager, joinedload

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
from geonature.core.gn_permissions.tools import get_permissions
from geonature.core.gn_commons.models.base import TModules

from pypnusershub.db.models import User


### Filters


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


### Formatters


def filters_formatter(v, c, m, p):
    filters = []
    if m.scope:
        filters.append(m.scope.label)
    if m.sensitivity_filter:
        filters.append("Données non sensible")
    return Markup("<ul>" + "".join(["<li>{}</li>".format(f) for f in filters]) + "</ul>")


def modules_formatter(view, context, model, name):
    modules = [
        '<a href="{}">{}</a>'.format(
            url_for("tmodules.details_view", id=module.id_module),
            Markup.escape(module.module_code),
        )
        for module in model.modules
    ]
    return Markup(", ".join(modules))


def groups_formatter(view, context, model, name):
    groups = [
        '<a href="{}">{}</a>'.format(
            url_for("permissions/group.details_view", id=group.id_role), Markup.escape(group)
        )
        for group in model.groups
    ]
    return Markup(", ".join(groups))


def role_formatter(view, context, model, name):
    role = model.role
    if role.groupe:
        url = url_for("permissions/group.details_view", id=role.id_role)
        nom = "<b>{}</b>".format(Markup.escape(role.nom_role))
    else:
        url = url_for("permissions/user.details_view", id=role.id_role)
        nom = Markup.escape(role.nom_complet)
    return Markup('<a href="{}">{}</a>'.format(url, nom))


def permissions_formatter(view, context, model, name):
    available_permissions = (
        PermissionAvailable.query.join(PermissionAvailable.module)
        .join(PermissionAvailable.object)
        .join(PermissionAvailable.action)
        .options(
            contains_eager(PermissionAvailable.module),
            contains_eager(PermissionAvailable.object),
            contains_eager(PermissionAvailable.action),
        )
        .order_by(TModules.module_code, PermObject.id_object, PermAction.id_action)
        .all()
    )

    o = '<table class="table">'
    columns = ["Module", "Object", "Action", "Label"]
    if model.groupe:
        return_url = url_for("permissions/group.details_view", id=model.id_role)
        columns += ["Permissions"]
    else:
        return_url = url_for("permissions/user.details_view", id=model.id_role)
        columns += ["Permissions personnelles", "Permissions effectives"]
    o += "<thead><tr>" + "".join([f"<th>{col}</th>" for col in columns]) + "</tr></thead>"
    o += "<tbody>"
    for ap in available_permissions:
        own_permissions = list(
            filter(
                lambda p: p.module == ap.module
                and p.object == ap.object
                and p.action == ap.action,
                model.permissions,
            )
        )
        permissions = [(own_permissions, True)]
        if not model.groupe:
            effective_permissions = list(
                get_permissions(
                    id_role=model.id_role,
                    module_code=ap.module.module_code,
                    object_code=ap.object.code_object,
                    action_code=ap.action.code_action,
                )
            )
            permissions.append((effective_permissions, False))
        o += "<tr>"
        o += "".join(
            [
                f"<td>{col}</td>"
                for col in [
                    ap.module.module_code,
                    ap.object.code_object,
                    ap.action.code_action,
                    ap.label,
                ]
            ]
        )
        for perms, managable in permissions:
            o += "<td>"
            if perms:
                o += '<table class="table table-bordered table-sm" style="border-collapse: separate; border-spacing:0 8px;">'
                for perm in perms:
                    flts = perm.filters
                    o += "<tr>"
                    if not flts:
                        o += '<td class="table-success">'
                    else:
                        o += '<td class="table-info">'
                    o += """<div class="row"><div class="col">"""
                    if not flts:
                        o += """<i class="fa fa-check" aria-hidden="true"></i>"""
                    else:
                        o += "Restrictions :"
                        o += """<ul class="list-group">"""
                        for flt in flts:
                            o += f"""<li class="list-group-item">{flt}</li>"""
                        o += "</ul>"
                    o += """</div></div>"""
                    if managable:
                        o += """<div class="row"><div class="col text-right">"""
                        edit_url = url_for(
                            "permissions/permission.edit_view",
                            id=perm.id_permission,
                            url=return_url,
                        )
                        delete_url = url_for(
                            "permissions/permission.delete_view",
                            id=perm.id_permission,
                            url=return_url,
                        )
                        o += f"""<form method="post" action="{delete_url}">"""
                        if len(ap.filters) > 0:
                            o += (
                                f"""<a class="btn btn-primary btn-sm" href="{edit_url}">"""
                                """<i class="fa fa-pencil" aria-hidden="true"></i>"""
                                """</a>"""
                            )
                        o += (
                            """<button class="btn btn-danger btn-sm" onclick="return faHelpers.safeConfirm('Supprimer cette permission ?');">"""
                            """<i class="fa fa-trash" aria-hidden="true"></i>"""
                            "</button>"
                            "</form>"
                        )
                        o += """</div></div>"""
                    o += "</td></tr>"
                o += "</table>"
            if managable and (not perms or len(ap.filters) > 1):
                add_url = url_for(
                    "permissions/permission.create_view",
                    id_role=model.id_role,
                    module_code=ap.module.module_code,
                    code_object=ap.object.code_object,
                    code_action=ap.action.code_action,
                    url=return_url,
                )
                o += (
                    f"""<a class="btn btn-success btn-sm float-right" href="{add_url}">"""
                    """<i class="fa fa-plus" aria-hidden="true"></i>"""
                    """</a>"""
                )
            o += "</td>"
        o += "</tr>"
    o += "</tbody>"
    o += "</table>"
    return Markup(o)


def permissions_count_formatter(view, context, model, name):
    url = url_for("permissions/permission.index_view", flt1_rle_equals=model.id_role)
    return Markup(f'<a href="{url}">{len(model.permissions)}</a>')


### ModelViews


class ObjectAdmin(CruvedProtectedMixin, ModelView):
    module_code = "ADMIN"
    object_code = "PERMISSIONS"

    column_list = ("code_object", "description_object", "modules")
    column_labels = {
        "code_object": "Code",
        "description_object": "Description",
    }
    column_default_sort = "id_object"
    column_formatters = {
        "modules": modules_formatter,
    }

    can_create = False
    can_edit = False
    can_delete = False


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
        "role": role_formatter,
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
    form_columns = ("role", "availability", "scope", "sensitivity_filter")

    def get_query(self):
        return super().get_query().join(Permission.availability)

    def create_form(self):
        form = super().create_form()
        if "id_role" in request.args:
            form.role.data = User.query.get(request.args.get("id_role", type=int))
        if {"module_code", "code_object", "code_action"}.issubset(request.args.keys()):
            form.availability.data = (
                PermissionAvailable.query.join(PermissionAvailable.module)
                .join(PermissionAvailable.object)
                .join(PermissionAvailable.action)
                .filter(
                    TModules.module_code == request.args.get("module_code"),
                    PermObject.code_object == request.args.get("code_object"),
                    PermAction.code_action == request.args.get("code_action"),
                )
                .one_or_none()
            )
        return form


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


class RolePermAdmin(CruvedProtectedMixin, ModelView):
    module_code = "ADMIN"
    object_code = "PERMISSIONS"

    can_create = False
    can_edit = False
    can_delete = False
    can_export = False
    can_view_details = True

    column_select_related_list = ("permissions",)
    column_labels = {
        "nom_role": "Nom",
        "prenom_role": "Prénom",
        "groups": "Groupes",
        "permissions": "Permissions",
        "permissions_count": "Nombre de permissions",
    }
    column_formatters = {
        "groups": groups_formatter,
        "permissions_count": permissions_count_formatter,
    }
    column_formatters_detail = {
        "groups": groups_formatter,
        "permissions": permissions_formatter,
        "permissions_count": permissions_count_formatter,
    }


class GroupPermAdmin(RolePermAdmin):
    column_list = (
        "nom_role",
        "permissions_count",
    )
    column_details_list = ("nom_role", "permissions_count", "permissions")

    def get_query(self):
        # TODO: filter_by_app
        return super().get_query().filter_by(groupe=True)


class UserPermAdmin(RolePermAdmin):
    column_list = (
        "identifiant",
        "nom_role",
        "prenom_role",
        "groups",
        "permissions_count",
    )
    column_labels = {
        **RolePermAdmin.column_labels,
        "permissions_count": "Nombre de permissions non héritées",
    }
    column_details_list = (
        "identifiant",
        "nom_role",
        "prenom_role",
        "groups",
        "permissions_count",
        "permissions",
    )

    def get_query(self):
        # TODO: filter_by_app
        return super().get_query().filter_by(groupe=False)


admin.add_view(
    GroupPermAdmin(
        User,
        db.session,
        name="Groupes",
        category="Permissions",
        endpoint="permissions/group",
    )
)


admin.add_view(
    UserPermAdmin(
        User,
        db.session,
        name="Utilisateurs",
        category="Permissions",
        endpoint="permissions/user",
    )
)


admin.add_view(
    ObjectAdmin(
        PermObject,
        db.session,
        name="Objets",
        category="Permissions",
        endpoint="permissions/object",
    )
)


admin.add_view(
    PermissionAdmin(
        Permission,
        db.session,
        name="Toutes les permissions",
        category="Permissions",
        endpoint="permissions/permission",
    )
)


admin.add_view(
    PermissionAvailableAdmin(
        PermissionAvailable,
        db.session,
        name="Permissions disponibles",
        category="Permissions",
        endpoint="permissions/availablepermission",
    )
)
