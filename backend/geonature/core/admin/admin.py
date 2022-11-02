from flask import g
from werkzeug.exceptions import Unauthorized
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

    def _can_action(self, action):
        scope = get_scopes_by_action(
            g.current_user.id_role, module_code=self.module_code, object_code=self.object_code
        )[action]
        return scope == 3

    @property
    def can_create(self):
        return self._can_action("C")

    @property
    def can_edit(self):
        return self._can_action("U")

    @property
    def can_delete(self):
        return self._can_action("D")

    @property
    def can_export(self):
        return self._can_action("E")


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
    template_mode="bootstrap4",
    name="Administration GeoNature",
    base_template="layout.html",
    index_view=MyHomeView(
        name="Accueil",
        menu_icon_type="fa",
        menu_icon_value="fa-home",
    ),
)


admin.add_link(
    MenuLink(
        name="Retourner à GeoNature",
        url=config["URL_APPLICATION"],
        icon_type="fa",
        icon_value="fa-sign-out",
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
