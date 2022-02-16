from flask import g
from werkzeug.exceptions import Unauthorized, Forbidden
from flask_admin import Admin, AdminIndexView, expose
from flask_admin.menu import MenuLink
from flask_admin.contrib.sqla import ModelView

from geonature.utils.env import db
from geonature.utils.config import config
from geonature.core.gn_commons.models import TAdditionalFields
from geonature.core.gn_commons.admin import BibFieldAdmin
from geonature.core.gn_permissions.tools import get_scopes_by_action


from pypnnomenclature.admin import (
    BibNomenclaturesTypesAdminConfig,
    BibNomenclaturesTypesAdmin,
    TNomenclaturesAdminConfig,
    TNomenclaturesAdmin,
)


class MyHomeView(AdminIndexView):
    def is_accessible(self):
        if g.current_user is None:
            raise Unauthorized  # return False leads to Forbidden which is different
        return True


class CruvedProtectedMixin:
    def is_accessible(self):
        if g.current_user is None:
            raise Unauthorized  # return False leads to Forbidden which is different
        return True

    def get_query(self):
        q = self.model.query
        if hasattr(q, "filter_by_scope"):
            q = q.filter_by_scope(self._get_action_scope("R"))
        return q

    def get_one(self, id):
        model = super().get_one(id)
        if hasattr(model, "has_instance_permission"):
            if not model.has_instance_permission(self._get_action_scope("R")):
                raise Forbidden
        return model

    def on_model_change(self, form, model, is_created):
        if is_created:
            return
        if hasattr(model, "has_instance_permission"):
            if not model.has_instance_permission(self._get_action_scope("U")):
                raise Forbidden

    def on_model_delete(self, model):
        if hasattr(model, "has_instance_permission"):
            if not model.has_instance_permission(self._get_action_scope("D")):
                raise Forbidden

    def _get_action_scope(self, action):
        return get_scopes_by_action(
            module_code=self.module_code, object_code=self.object_code
        )[action]

    @property
    def can_create(self):
        return self._get_action_scope("C") > 0

    @property
    def can_view_details(self):
        return self._get_action_scope("R") > 0

    @property
    def can_edit(self):
        return self._get_action_scope("U") > 0

    @property
    def can_delete(self):
        return self._get_action_scope("D") > 0

    @property
    def can_export(self):
        return self._get_action_scope("E") > 0


class ProtectedBibNomenclaturesTypesAdminConfig(
    CruvedProtectedMixin,
    BibNomenclaturesTypesAdminConfig,
):
    module_code = "ADMIN"
    object_code = "NOMENCLATURES"


class ProtectedTNomenclaturesAdminConfig(
    CruvedProtectedMixin,
    TNomenclaturesAdminConfig,
):
    module_code = "ADMIN"
    object_code = "NOMENCLATURES"


class ProtectedBibNomenclaturesTypesAdminConfig(
    CruvedProtectedMixin,
    BibNomenclaturesTypesAdminConfig,
):
    module_code = "ADMIN"
    object_code = "NOMENCLATURES"


class ProtectedBibFieldAdmin(
    CruvedProtectedMixin,
    BibFieldAdmin,
):
    module_code = "ADMIN"
    object_code = "ADDITIONAL_FIELDS"


admin = Admin(
    template_mode="bootstrap3",
    name="Administration GeoNature",
    index_view=MyHomeView(
        name="Accueil",
        menu_icon_type="glyph",
        menu_icon_value="glyphicon-home",
    ),
)


admin.add_link(
    MenuLink(
        name='Retourner à GeoNature',
        url=config['URL_APPLICATION'],
        icon_type="glyph",
        icon_value="glyphicon-log-out",
    )
)


admin.add_view(
    ProtectedBibNomenclaturesTypesAdminConfig(
        BibNomenclaturesTypesAdmin,
        db.session,
        name="Type de nomenclatures",
        category="Nomenclatures",
    )
)

admin.add_view(
    ProtectedTNomenclaturesAdminConfig(
        TNomenclaturesAdmin,
        db.session,
        name="Items de nomenclatures",
        category="Nomenclatures",
    )
)

admin.add_view(
    ProtectedBibFieldAdmin(
        TAdditionalFields,
        db.session,
        name="Bibliothèque de champs additionnels",
        category="Champs additionnels",
    )
)

flask_admin = admin  # for retro-compatibility, usefull for export module for instance
