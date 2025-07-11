from flask import url_for, has_app_context, request
from flask_admin.contrib.sqla import ModelView
from flask_admin.contrib.sqla.filters import FilterEqual
from ref_geo.models import BibAreasTypes, LAreas
from apptax.taxonomie.models import Taxref, VMTaxrefListForautocomplete
import sqlalchemy as sa
from flask_admin.contrib.sqla.tools import get_primary_key
from flask_admin.contrib.sqla.fields import QuerySelectField
from flask_admin.contrib.sqla.ajax import QueryAjaxModelLoader
from flask_admin.form.widgets import Select2Widget
from markupsafe import Markup
from sqlalchemy.orm import contains_eager, joinedload
from sqlalchemy import select
from markupsafe import Markup

from geonature.utils.env import db
from geonature.utils.config import config
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
            yield from [(u.id_role, u.nom_complet) for u in db.session.scalars(select(User)).all()]


class ModuleFilter(DynamicOptionsMixin, FilterEqual):
    def get_dynamic_options(self, view):
        if has_app_context():
            modules = db.session.scalars(select(TModules).order_by(TModules.module_code)).all()
            yield from [(module.id_module, module.module_code) for module in modules]


class ObjectFilter(DynamicOptionsMixin, FilterEqual):
    def get_dynamic_options(self, view):
        if has_app_context():
            objects = db.session.scalars(select(PermObject)).all()
            yield from [(object.id_object, object.code_object) for object in objects]


class ActionFilter(DynamicOptionsMixin, FilterEqual):
    def get_dynamic_options(self, view):
        if has_app_context():
            actions = db.session.scalars(select(PermAction)).all()
            yield from [(action.id_action, action.code_action) for action in actions]


class ScopeFilter(DynamicOptionsMixin, FilterEqual):
    def apply(self, query, value, alias=None):
        column = self.get_column(alias)
        if value:
            return query.where(column == value)
        else:
            return query.where(column.is_(None))

    def get_dynamic_options(self, view):
        if has_app_context():
            yield (None, "Sans restriction")
            scopes = db.session.scalars(select(PermScope)).all()
            yield from [(scope.value, scope.label) for scope in scopes]


### Formatters


def filters_formatter(v, c, m, p):
    return Markup(
        "<ul >"
        + "".join(["<li>{}</li>".format(f.__str__()) for f in m.as_dict()["filters"]])
        + "</ul>"
    )


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


def list_permissions_formatter(
    permissions, available_permission, managable, current_user, return_url
):
    """
    Render a list of permissions for module-object-action item as an HTML table.

    This function generates an HTML table that displays permissions associated to specific
     module, object, or action. Each permission is rendered with its status, expiration
    date, and associated filters. If the permissions are manageable, edit and delete options are
    included for each permission.

    Parameters
    ----------
    permissions : list[Permission]
        A list of permission objects to be rendered.
    available_permission : PermissionAvailable
        the permission template.
    managable : bool
        A boolean indicating whether the permissions are manageable. If True,
        edit and delete options will be included in the rendered HTML.
    model : User
        current user
    return_url : str
        The URL to return to after performing an action (e.g., editing or
        deleting a permission).

    Returns
    -------
    str
        An HTML string representing the permissions table.

    Notes
    -----
    The function uses Bootstrap classes for styling the table and its elements.
    If a permission has filters, they are displayed as a list within the table cell.
    If a permission is not active, it is marked with a 'table-secondary' class and a
    'text-danger' class for the expiration date.
    If a permission is active but has an expiration date, it is marked with a 'text-success'
    class for the expiration date.
    """

    html_output = ""
    if permissions:

        # List of permissions is shown in a HTML table TODO -> maybe use card of bootstrap -> https://getbootstrap.com/docs/4.6/components/card/
        html_output += '<table class="table table-sm" style="border-collapse: separate; border-spacing:0 8px;">'

        for perm in permissions:

            permission_filters = perm.filters
            html_output += "<tr>"

            if not permission_filters:
                html_output += '<td class="table-success">'
            elif not perm.is_active:
                html_output += '<td class="table-secondary">'
            else:
                html_output += '<td class="table-light">'

            html_output += """<div class="row"><div class="col">"""
            if not perm.is_active:
                html_output += f"""<p class="small text-danger" style="margin-bottom:0;">Expiré le {perm.expire_on}</p>"""
            elif perm.expire_on:
                html_output += f"""<p class="small text-success" style="margin-bottom:0;">Expire le {perm.expire_on}</p>"""
            # Display filters associated to the permission
            if permission_filters:
                filter_html = ""
                for flt_name in perm.availability.filters:
                    flt_field = Permission.filters_fields[flt_name]
                    flt = PermFilter(flt_name, getattr(perm, flt_field))
                    filter_html += f"""<li class="list-group-item" style="margin-bottom:0.2em;border-radius:5px">{flt}</li>"""
                html_output += f"""<ul class="list-group">{filter_html}</ul>"""
            else:
                html_output += """<i class="fa fa-check" aria-hidden="true"></i>"""

            html_output += """</div></div>"""
            if managable:
                html_output += """<div class="row"><div class="col text-right pt-1">"""
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
                html_output += f"""<form method="post" action="{delete_url}">"""
                if len(available_permission.filters) > 0:
                    html_output += (
                        f"""<a class="btn btn-primary btn-sm m-1" href="{edit_url}">"""
                        """<i class="fa fa-pencil" aria-hidden="true"></i>"""
                        """</a>"""
                    )
                html_output += (
                    """<button class="btn btn-danger btn-sm m-1" onclick="return faHelpers.safeConfirm('Supprimer cette permission ?');">"""
                    """<i class="fa fa-trash" aria-hidden="true"></i>"""
                    "</button>"
                    "</form>"
                )
                html_output += """</div></div>"""
            html_output += "</td></tr>"
        html_output += "</table>"

    # If cell contains user permission, include create permission button
    # Permission may be created if no permission was set or that multiple permission can be assign to this permission item (module, object, action)
    if managable and (not permissions or len(available_permission.filters) > 1):
        add_url = url_for(
            "permissions/permission.create_view",
            id_role=current_user.id_role,
            module_code=available_permission.module.module_code,
            code_object=available_permission.object.code_object,
            code_action=available_permission.action.code_action,
            url=return_url,
        )
        html_output += (
            f"""<a class="btn btn-success btn-sm float-right" href="{add_url}">"""
            """<i class="fa fa-plus" aria-hidden="true"></i>"""
            """</a>"""
        )
    html_output = f"<td> {html_output}</td>"
    return html_output


def permissions_formatter(view, context, model, name):
    available_permissions = db.session.scalars(PermissionAvailable.nice_order()).unique().all()
    html_output = "<table class='table'>"
    columns = ["Module", "Object", "Action", "Label"]

    if model.groupe:
        return_url = url_for("permissions/group.details_view", id=model.id_role)
        columns += ["Permissions"]
    else:
        return_url = url_for("permissions/user.details_view", id=model.id_role)
        columns += ["Permissions personnelles", "Permissions effectives"]

    html_output += "<thead><tr>" + "".join([f"<th>{col}</th>" for col in columns]) + "</tr></thead>"
    html_output += "<tbody>"

    for available_permission in available_permissions:
        permissions = [permission for permission in model.permissions]
        own_permissions = list(
            filter(
                lambda p: p.module == available_permission.module
                and p.object == available_permission.object
                and p.action == available_permission.action,
                permissions,
            )
        )
        permissions = [(own_permissions, True, "own")]
        if not model.groupe:
            effective_permissions = list(
                get_permissions(
                    id_role=model.id_role,
                    module_code=available_permission.module.module_code,
                    object_code=available_permission.object.code_object,
                    action_code=available_permission.action.code_action,
                )
            )
            permissions.append((effective_permissions, False, "effective"))
            html_output += (
                "<tr>"
                if own_permissions or effective_permissions
                else "<tr class='text-muted alert alert-danger'>"
            )
        else:
            html_output += (
                "<tr>" if own_permissions else "<tr class='text-muted alert alert-danger'>"
            )

        html_output += "".join(
            [
                f"<td>{col}</td>"
                for col in [
                    available_permission.module.module_code,
                    available_permission.object.code_object,
                    available_permission.action.code_action,
                    available_permission.label,
                ]
            ]
        )
        for perms, managable, name in permissions:
            html_output += list_permissions_formatter(
                perms, available_permission, managable, model, return_url
            )

        html_output += "</tr>"
    html_output += "</tbody>"
    html_output += "</table>"
    return Markup(html_output)


def permissions_count_formatter(view, context, model, name):
    url = url_for("permissions/permission.index_view", flt1_rle_equals=model.id_role)
    permissions_count = len([p for p in model.permissions if p.is_active])
    return Markup(f'<a href="{url}">{permissions_count}</a>')


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
        """
        Instead of returning a list of tuple (id, label), we return a list of tuple (id, label, excluded_availabilities).
        The third element of each tuple is the list of type of permissions the user already have, so it is useless
        to add this permission to the user, and they will be not available in the front select.
        Two remarks:
        - We only consider active permissions of the user
        - If the type of the permission allows two or more filters, we do not exclude it as it makes sens to add several
          permissions of the same type with differents set of filters.
        """
        if not user:
            return None

        def format_availability(availability):
            return ":".join(
                [str(getattr(availability, attr)) for attr in get_primary_key(PermissionAvailable)]
            )

        def filter_availability(availability):
            filters_count = sum(
                [
                    getattr(availability, field)
                    for field in PermissionAvailable.filters_fields.values()
                ]
            )
            return filters_count < 2

        availabilities = {
            p.availability for p in user.permissions if p.availability and p.is_active
        }
        excluded_availabilities = filter(filter_availability, availabilities)
        excluded_availabilities = map(format_availability, excluded_availabilities)
        return super().format(user) + (list(excluded_availabilities),)

    def get_query(self):
        return (
            super()
            .get_query()
            .options(joinedload(User.permissions).joinedload(Permission.availability))
            .order_by(User.groupe.desc(), User.nom_role)
        )


class AreaAjaxModelLoader(QueryAjaxModelLoader):
    def format(self, area):
        return (area.id_area, f"{area.area_name} ({area.area_type.type_name})")

    def get_one(self, pk):
        # prevent autoflush from occuring during populate_obj
        with self.session.no_autoflush:
            return self.session.get(self.model, pk)

    def get_query(self):
        return (
            super()
            .get_query()
            .join(LAreas.area_type)
            .where(
                BibAreasTypes.type_code.in_(config["PERMISSIONS"]["GEOGRAPHIC_FILTER_AREA_TYPES"])
            )
            .order_by(BibAreasTypes.id_type, LAreas.area_name)
        )


class TaxrefAjaxModelLoader(QueryAjaxModelLoader):
    def format(self, taxref):
        if not hasattr(taxref, "search_name"):
            label = db.session.scalar(
                sa.select(VMTaxrefListForautocomplete.search_name).filter_by(cd_nom=taxref.cd_nom)
            )
        else:
            label = taxref.search_name
        return (taxref.cd_nom, label.replace("<i>", "").replace("</i>", ""))

    def get_query(self):
        return db.session.query(
            Taxref.cd_nom,
            VMTaxrefListForautocomplete.search_name,
        ).join(
            VMTaxrefListForautocomplete,
            VMTaxrefListForautocomplete.cd_nom == Taxref.cd_nom,
        )

    def get_one(self, pk):
        with self.session.no_autoflush:
            return self.session.get(self.model, pk)


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


# self.allow_blank = (True,)
# self.blank_test = "lalala"
class PermissionAdmin(CruvedProtectedMixin, ModelView):
    module_code = "ADMIN"
    object_code = "PERMISSIONS"

    column_list = (
        "role",
        "module",
        "object",
        "action",
        "label",
        "filters",
        "expire_on",
    )
    column_labels = {
        "role": "Rôle",
        "filters": "Restriction(s)",
        "object": "Objet",
        "role.identifiant": "identifiant du rôle",
        "role.nom_complet": "nom du rôle",
        "availability": "Permission",
        "expire_on": "Date d’expiration",
        "scope": "Filtre sur l'appartenance des données",
        "sensitivity_filter": (
            "Flouter" if config["SYNTHESE"]["BLUR_SENSITIVE_OBSERVATIONS"] else "Exclure"
        )
        + " les données sensibles",
        "areas_filter": "Filtre géographique",
        "taxons_filter": "Filtre taxonomique",
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
        ("expire_on", "expire_on"),
    )
    column_default_sort = [
        ("role.nom_complet", False),
        ("module.module_code", False),
        ("object.code_object", False),
        ("id_action", False),
    ]
    form_columns = (
        "role",
        "availability",
        "scope",
        "sensitivity_filter",
        "areas_filter",
        "taxons_filter",
        "expire_on",
    )
    form_overrides = dict(
        availability=OptionQuerySelectField,
    )
    form_args = dict(
        availability=dict(
            query_factory=lambda: PermissionAvailable.nice_order(),
            options_additional_values=[
                "sensitivity_filter",
                "scope_filter",
                "areas_filter",
                "taxons_filter",
            ],
        ),
    )
    create_template = "admin/hide_select2_options_create.html"
    edit_template = "admin/hide_select2_options_edit.html"
    form_ajax_refs = {
        "role": UserAjaxModelLoader(
            name="role",
            session=db.session,
            model=User,
            fields=(
                "identifiant",
                "nom_role",
                "prenom_role",
            ),
            placeholder="Veuillez sélectionner un utilisateur ou un groupe",
            minimum_input_length=0,
        ),
        "areas_filter": AreaAjaxModelLoader(
            name="areas_filter",
            session=db.session,
            model=LAreas,
            fields=(LAreas.area_name, LAreas.area_code),
            page_size=25,
            placeholder="Sélectionnez une ou plusieurs zones géographiques",
            minimum_input_length=1,
        ),
        "taxons_filter": TaxrefAjaxModelLoader(
            name="taxons_filter",
            session=db.session,
            model=Taxref,
            fields=(
                Taxref.cd_nom,
                Taxref.nom_vern,
                Taxref.nom_valide,
                Taxref.nom_complet,
            ),
            page_size=25,
            placeholder="Sélectionnez un ou plusieurs taxons",
            minimum_input_length=1,
        ),
    }

    def get_query(self):
        return super().get_query().where(Permission.active_filter())

    def get_count_query(self):
        return super().get_count_query().where(Permission.active_filter())

    def render(self, template, **kwargs):
        self.extra_js = [url_for("static", filename="js/hide_unnecessary_filters.js")]
        return super().render(template, **kwargs)

    def create_form(self):
        form = super().create_form()
        if request.method == "GET":
            # Set default values from request.args
            if "id_role" in request.args:
                form.role.data = db.session.get(User, request.args.get("id_role", type=int))
            if {"module_code", "code_object", "code_action"}.issubset(request.args.keys()):
                form.availability.data = db.session.execute(
                    select(PermissionAvailable)
                    .join(PermissionAvailable.module)
                    .join(PermissionAvailable.object)
                    .join(PermissionAvailable.action)
                    .where(
                        TModules.module_code == request.args.get("module_code"),
                        PermObject.code_object == request.args.get("code_object"),
                        PermAction.code_action == request.args.get("code_action"),
                    )
                ).scalar_one_or_none()
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
        "areas_filter": "Filtre géographique",
        "taxons_filter": "Filtre taxonomique",
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
    form_columns = ("scope_filter", "sensitivity_filter", "areas_filter", "taxons_filter")


class RolePermAdmin(CruvedProtectedMixin, ModelView):
    module_code = "ADMIN"
    object_code = "PERMISSIONS"

    can_create = False
    can_edit = False
    can_delete = False
    can_export = False
    can_view_details = True

    details_template = "role_or_group_detail.html"
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

    def get_query(self):
        # TODO : change to sqla2.0 query when flask admin update to sqla2
        return db.session.query(User).where(User.filter_by_app())

    def get_count_query(self):
        # TODO : change to sqla2.0 query when flask admin update to sqla2
        return db.session.query(sa.func.count("*")).select_from(User).where(User.filter_by_app())


class GroupPermAdmin(RolePermAdmin):
    column_list = (
        "nom_role",
        "permissions_count",
    )
    column_details_list = ("nom_role", "permissions_count", "permissions")

    def get_query(self):
        return super().get_query().where(User.groupe.is_(sa.true()))

    def get_count_query(self):
        return super().get_count_query().where(User.groupe.is_(sa.true()))


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
        return super().get_query().where(User.groupe.is_(sa.false()))

    def get_count_query(self):
        return super().get_count_query().where(User.groupe.is_(sa.false()))


admin.add_view(
    GroupPermAdmin(
        User,
        db.session,
        name="Par groupes",
        category="Permissions",
        endpoint="permissions/group",
    )
)


admin.add_view(
    UserPermAdmin(
        User,
        db.session,
        name="Par utilisateurs",
        category="Permissions",
        endpoint="permissions/user",
    )
)

# Retirer pour plus de lisibilité de l'interface des permissions
# admin.add_view(
#     ObjectAdmin(
#         PermObject,
#         db.session,
#         name="Objets",
#         category="Permissions",
#         endpoint="permissions/object",
#     )
# )


admin.add_view(
    PermissionAdmin(
        Permission,
        db.session,
        name="Permissions",
        category="Permissions",
        endpoint="permissions/permission",
    )
)

# Retirer pour plus de lisibilité de l'interface des permissions
# admin.add_view(
#     PermissionAvailableAdmin(
#         PermissionAvailable,
#         db.session,
#         name="Permissions disponibles",
#         category="Permissions",
#         endpoint="permissions/availablepermission",
#     )
# )
