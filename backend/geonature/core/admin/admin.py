from flask import g
from werkzeug.exceptions import Unauthorized
from flask_admin import Admin, AdminIndexView, expose
from flask_admin.menu import MenuLink
from flask_admin.contrib.sqla import ModelView

from geonature.utils.env import db
from geonature.utils.config import config
from geonature.core.gn_commons.models import TAdditionalFields, TMobileApps
from geonature.core.gn_commons.admin import BibFieldAdmin, TMobileAppsAdmin
from geonature.core.notifications.admin import (
    NotificationTemplateAdmin,
    NotificationCategoryAdmin,
    NotificationMethodAdmin,
)
from geonature.core.notifications.models import (
    NotificationTemplate,
    NotificationCategory,
    NotificationMethod,
)
from geonature.core.gn_permissions.tools import get_scopes_by_action

from pypnnomenclature.models import (
    BibNomenclaturesTypes,
    TNomenclatures,
)
from pypnnomenclature.admin import (
    BibNomenclaturesTypesAdmin,
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
            g.current_user.id_role,
            module_code=self.module_code,
            object_code=getattr(self, "object_code", "ALL"),
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


class ProtectedBibNomenclaturesTypesAdmin(
    CruvedProtectedMixin,
    BibNomenclaturesTypesAdmin,
):
    module_code = "ADMIN"
    object_code = "NOMENCLATURES"


class ProtectedTNomenclaturesAdmin(
    CruvedProtectedMixin,
    TNomenclaturesAdmin,
):
    module_code = "ADMIN"
    object_code = "NOMENCLATURES"


class ProtectedBibFieldAdmin(
    CruvedProtectedMixin,
    BibFieldAdmin,
):
    module_code = "ADMIN"
    object_code = "ADDITIONAL_FIELDS"


class ProtectedNotificationTemplateAdmin(
    CruvedProtectedMixin,
    NotificationTemplate,
):
    module_code = "ADMIN"
    object_code = "NOTIFICATIONS"


class ProtectedNotificationCategoryAdmin(
    CruvedProtectedMixin,
    NotificationCategory,
):
    module_code = "ADMIN"
    object_code = "NOTIFICATIONS"


class ProtectedNotificationMethodAdmin(
    CruvedProtectedMixin,
    NotificationMethod,
):
    module_code = "ADMIN"
    object_code = "NOTIFICATIONS"


class ProtectedTMobileAppsAdmin(
    CruvedProtectedMixin,
    TMobileAppsAdmin,
):
    module_code = "ADMIN"
    object_code = "ALL"


## déclaration de la page d'admin
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

## ajout des liens
admin.add_link(
    MenuLink(
        name="Retourner à GeoNature",
        url=config["URL_APPLICATION"],
        icon_type="fa",
        icon_value="fa-sign-out",
    )
)

## ajout des elements

admin.add_view(
    ProtectedBibNomenclaturesTypesAdmin(
        BibNomenclaturesTypes,
        db.session,
        name="Type de nomenclatures",
        category="Nomenclatures",
    )
)

admin.add_view(
    ProtectedTNomenclaturesAdmin(
        TNomenclatures,
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

# Ajout de la vue pour la gestion des templates de notifications
# accès protegé par CruvedProtectedMixin
admin.add_view(
    NotificationTemplateAdmin(
        NotificationTemplate,
        db.session,
        name="Templates des notifications",
        category="Notifications",
    )
)

admin.add_view(
    NotificationCategoryAdmin(
        NotificationCategory,
        db.session,
        name="Catégories des notifications",
        category="Notifications",
    )
)

admin.add_view(
    NotificationMethodAdmin(
        NotificationMethod,
        db.session,
        name="Méthodes de notification",
        category="Notifications",
    )
)

admin.add_view(
    ProtectedTMobileAppsAdmin(
        TMobileApps,
        db.session,
        name="Applications mobiles",
        category="Applications mobiles",
    )
)

flask_admin = admin  # for retro-compatibility, usefull for export module for instance
