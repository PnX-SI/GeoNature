from flask_admin.contrib.sqla import ModelView

from geonature.utils.env import DB
from geonature.core.admin.utils import CruvedProtectedMixin
from geonature.core.notifications.models import NotificationCategory


class NotificationTemplateAdmin(CruvedProtectedMixin, ModelView):
    module_code = "ADMIN"
    object_code = "NOTIFICATIONS"

    column_list = ("code_category", "code_method", "content")
    column_labels = {
        "code_category": "Catégorie",
        "code_method": "Méthode d'envoi",
        "content": "Contenu du template de notification",
    }
    form_columns = ("category", "method", "content")
    form_args = {
        "category": {"label": "Catégorie", "get_label": "display"},
        "method": {"label": "Methode d'envoi", "get_label": "display"},
        "content": {"label": "Contenu de la notification"},
    }


class NotificationCategoryAdmin(CruvedProtectedMixin, ModelView):
    module_code = "ADMIN"
    object_code = "NOTIFICATIONS"

    column_list = ("code", "label", "description")
    form_columns = ("code", "label", "description")
    form_args = {
        "code": {"description": "Identifiant de la catégorie de notification"},
        "label": {"description": "Titre affiché dans la notification"},
    }


class NotificationMethodAdmin(CruvedProtectedMixin, ModelView):
    module_code = "ADMIN"
    object_code = "NOTIFICATIONS"

    column_list = ("code", "label", "description")
    form_columns = ("code", "label", "description")
    form_args = {
        "code": {"description": "Identifiant de la méthode de notification"},
    }
