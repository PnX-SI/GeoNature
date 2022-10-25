from flask_admin.contrib.sqla import ModelView

from geonature.utils.env import DB
from geonature.core.notifications.models import BibNotificationsCategories


class BibNotificationsTemplatesAdmin(ModelView):
    form_columns = (
        "notification_template_category",
        "notification_template_method",
        "notification_template_content",
    )
    column_exclude_list = ()
    column_display_all_relations = True
    form_args = {
        "notification_template_category": {"label": "Catégorie"},
        "notification_template_method": {"label": "Methode d'envoi"},
        "notification_template_content": {"label": "Contenu de la notification"},
    }
    column_descriptions = {
        "notification_template_category": "Catégorie",
        "notification_template_method": "Methode d'envoi",
        "notification_template_content": "Contenu du template de notification",
    }


class BibNotificationsCategoriesAdmin(ModelView):
    form_columns = (
        "code_notification_category",
        "label_notification_category",
        "description_notification_category",
    )
    column_exclude_list = ()
    column_display_all_relations = True
    form_args = {
        "code_notification_category": {"label": "Id de la catégorie de notification"},
        "label_notification_category": {"label": "Titre afficher dans la notification"},
        "description_notification_category": {"label": "Description de la règle de notification"},
    }
    column_descriptions = {
        "code_notification_category": "Code catégorie",
        "label_notification_category": "Label catégorie",
        "description_notification_category": "Description du code a utiliser ensuite dans la notification",
    }


class BibNotificationsMethodsAdmin(ModelView):
    form_columns = (
        "code_notification_method",
        "label_notification_method",
        "description_notification_method",
    )
    column_exclude_list = ()
    column_display_all_relations = True
    form_args = {
        "code_notification_method": {"label": "Id de la méthode de notification"},
        "label_notification_method": {"label": "Titre pour cette méthode"},
        "description_notification_method": {"label": "Description de la méthode"},
    }
    column_descriptions = {
        "code_notification_method": "Code méthode",
        "label_notification_method": "Label méthode",
        "description_notification_method": "Description de la méthode",
    }
