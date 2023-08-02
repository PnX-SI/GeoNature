import os

from flask import g
from werkzeug.exceptions import Unauthorized
from flask_admin import Admin, AdminIndexView, expose
from flask_admin.menu import MenuLink
from flask_admin.contrib.sqla import ModelView

from geonature.utils.env import db
from geonature.utils.config import config
from geonature.core.gn_commons.models import TAdditionalFields, TMobileApps, TModules
from geonature.core.gn_commons.admin import BibFieldAdmin, TMobileAppsAdmin, TModulesAdmin
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

from pypnnomenclature.models import (
    BibNomenclaturesTypes,
    TNomenclatures,
)
from pypnnomenclature.admin import (
    BibNomenclaturesTypesAdmin,
    TNomenclaturesAdmin,
)

from .utils import CruvedProtectedMixin


class MyHomeView(AdminIndexView):
    def is_accessible(self):
        if not g.current_user.is_authenticated:
            raise Unauthorized  # return False leads to Forbidden which is different
        return True


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
    BibFieldAdmin(
        TAdditionalFields,
        db.session,
        name="Champs additionnels",
        category="Autres",
    )
)

admin.add_view(
    TMobileAppsAdmin(
        TMobileApps,
        db.session,
        name="Applications mobiles",
        category="Autres",
    )
)

admin.add_view(
    TModulesAdmin(
        TModules,
        db.session,
        name="Modules",
        category="Autres",
    )
)


flask_admin = admin  # for retro-compatibility, usefull for export module for instance
