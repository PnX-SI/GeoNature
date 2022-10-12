from flask import current_app

from flask_admin.contrib.sqla import ModelView
from flask_admin.contrib.sqla.ajax import QueryAjaxModelLoader
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

