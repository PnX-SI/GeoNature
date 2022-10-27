from flask_admin.contrib.sqla import ModelView

from geonature.utils.env import DB


class NotificationTemplateAdmin(ModelView):
    form_columns = (
        "code_category",
        "code_method",
        "content",
    )
    column_exclude_list = ()
    column_display_all_relations = True
    form_args = {
        "code_category": {"label": "Catégorie"},
        "code_method": {"label": "Methode d'envoi"},
        "content": {"label": "Contenu de la notification"},
    }
    column_descriptions = {
        "code_category": "Catégorie",
        "code_method": "Methode d'envoi",
        "content": "Contenu du template de notification",
    }


class NotificationCategoryAdmin(ModelView):
    form_columns = (
        "code",
        "label",
        "description",
    )
    column_exclude_list = ()
    column_display_all_relations = True
    form_args = {
        "code": {"label": "Id de la catégorie de notification"},
        "label": {"label": "Titre affiché dans la notification"},
        "description": {"label": "Description de la règle de notification"},
    }
    column_descriptions = {
        "code": "Code catégorie",
        "label": "Label catégorie",
        "description": "Description du code a utiliser ensuite dans la notification",
    }


class NotificationMethodAdmin(ModelView):
    form_columns = (
        "code",
        "label",
        "description",
    )
    column_exclude_list = ()
    column_display_all_relations = True
    form_args = {
        "code": {"label": "Id de la méthode de notification"},
        "label": {"label": "Titre pour cette méthode"},
        "description": {"label": "Description de la méthode"},
    }
    column_descriptions = {
        "code": "Code méthode",
        "label": "Label méthode",
        "description": "Description de la méthode",
    }
