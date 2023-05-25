from flask import url_for, has_app_context, Markup, request
from flask_admin.contrib.sqla import ModelView
from flask_admin.contrib.sqla.filters import FilterEqual
import sqlalchemy as sa
from flask_admin.contrib.sqla.tools import get_primary_key
from flask_admin.contrib.sqla.fields import QuerySelectField
from flask_admin.contrib.sqla.ajax import QueryAjaxModelLoader
from flask_admin.form.widgets import Select2Widget
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
    PermFilter,
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
            yield from [
                (m.id_module, m.module_code)
                for m in TModules.query.order_by(TModules.module_code).all()
            ]


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
        filters.append("Données non sensibles")
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
    available_permissions = PermissionAvailable.query.nice_order().all()

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
                if len(perms) > 1:
                    o += f"{len(perms)} permissions :"
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
                        o += """<ul class="list-group">"""
                        for flt_name in perm.availability.filters:
                            flt_field = Permission.filters_fields[flt_name]
                            flt = PermFilter(flt_name, getattr(perm, flt_field.name))
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


### Widgets


class OptionSelect2Widget(Select2Widget):
    @classmethod
    def render_option(cls, value, label, options):
        return super().render_option(value, label, options.pop("selected"), **options)


### Fields


class OptionQuerySelectField(QuerySelectField):
    """
    Overrides the QuerySelectField class from flask admin to allow
    other attributes on a select option.

    options_additional_values is added in form_args, it is a list of
    strings, each element is the name of the attribute in the model
    which will be added on the option
    """

    widget = OptionSelect2Widget()

    def __init__(self, *args, **kwargs):
        self.options_additional_values = kwargs.pop("options_additional_values")
        super().__init__(*args, **kwargs)

    def iter_choices(self):
        if self.allow_blank:
            yield ("__None", self.blank_text, {"selected": self.data is None})
        for pk, obj in self._get_object_list():
            options = {k: getattr(obj, k) for k in self.options_additional_values}
            options["selected"] = obj == self.data
            yield (pk, self.get_label(obj), options)


### ModelLoader


class UserAjaxModelLoader(QueryAjaxModelLoader):
    def format(self, user):
        if not user:
            return None

        def format_availability(availability):
            return ":".join(
                [str(getattr(availability, attr)) for attr in get_primary_key(PermissionAvailable)]
            )

        def filter_availability(availability):
            filters_count = sum(
                [
                    getattr(availability, field.name)
                    for field in PermissionAvailable.filters_fields.values()
                ]
            )
            return filters_count < 2

        availabilities = {p.availability for p in user.permissions if p.availability}
        excluded_availabilities = filter(filter_availability, availabilities)
        excluded_availabilities = map(format_availability, excluded_availabilities)
        return super().format(user) + (list(excluded_availabilities),)

    def get_query(self):
        return (
            super()
            .get_query()
            .options(joinedload(User.permissions).joinedload(Permission.availability))
        )


### ModelViews


class ObjectAdmin(CruvedProtectedMixin, ModelView):
    module_code = "ADMIN"
    object_code = "PERMISSIONS"

    can_create = False
    can_edit = False
    can_delete = False

    column_list = ("code_object", "description_object", "modules")
    column_labels = {
        "code_object": "Code",
        "description_object": "Description",
    }
    column_default_sort = "id_object"
    column_formatters = {
        "modules": modules_formatter,
    }


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
        "scope": "Appartenance des données",
        "sensitivity_filter": "Exclure les données sensibles",
    }
    column_select_related_list = ("availability",)
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
        ("role.nom_complet", False),
        ("module.module_code", False),
        ("object.code_object", False),
        ("id_action", False),
    ]
    form_columns = ("role", "availability", "scope", "sensitivity_filter")
    form_overrides = dict(availability=OptionQuerySelectField)
    form_args = dict(
        availability=dict(
            query_factory=lambda: PermissionAvailable.query.nice_order(),
            options_additional_values=["sensitivity_filter", "scope_filter"],
        )
    )
    create_template = "admin/hide_select2_options_create.html"
    edit_template = "admin/hide_select2_options_edit.html"
    form_ajax_refs = {
        "role": UserAjaxModelLoader(
            "role",
            db.session,
            User,
            fields=(
                "identifiant",
                "nom_role",
                "prenom_role",
            ),
            placeholder="Veuillez sélectionner un utilisateur ou un groupe",
            minimum_input_length=0,
        ),
    }

    def render(self, template, **kwargs):
        self.extra_js = [url_for("static", filename="js/hide_unnecessary_filters.js")]
        return super().render(template, **kwargs)

    def create_form(self):
        form = super().create_form()
        if request.method == "GET":
            # Set default values from request.args
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

    can_create = False
    can_delete = False
    can_export = False

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
    column_sortable_list = (
        ("module", "module.module_code"),
        ("object", "object.code_object"),
        ("action", "action.code_action"),
    )
    column_filters = (ModuleFilter(column=PermissionAvailable.id_module, name="Module"),)
    column_default_sort = [
        ("module.module_code", False),
        ("object.code_object", False),
        ("id_action", False),
    ]
    form_columns = ("scope_filter", "sensitivity_filter")


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
    column_searchable_list = ("identifiant", "nom_complet")
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
