from flask import current_app
from wtforms import validators

from flask_admin.contrib.sqla import ModelView
from geonature.core.gn_commons.models import TModules
from geonature.core.gn_permissions.models import TObjects
from geonature.utils.env import DB


class BibFieldAdmin(ModelView):
    form_columns = (
        "field_name",
        "field_label",
        "type_widget",
        "modules",
        "objects",
        "datasets",
        "required",
        "description",
        "quantitative",
        "unity",
        "field_values",
        "default_value",
        "field_order",
        "exportable",
        "bib_nomenclature_type",
        "id_list",
        "additional_attributes",
    )
    column_exclude_list = (
        "field_values",
        "additional_attributes",
        "key_label",
        "key_value",
        "multiselect",
        "api",
        "id_list",
        "unity",
    )

    column_display_all_relations = True
    form_args = {
        "field_name": {"label": "Nom du champ"},
        "bib_nomenclature_type": {"label": "Type de nomenclature"},
        "field_label": {"label": "Label du champ"},
        "required": {"label": "Obligatoire"},
        "quantitative": {"label": "Quantitatif"},
        "unity": {"label": "Unité"},
        "field_values": {"label": "Valeurs"},
        "default_value": {"label": "Valeur par défaut"},
        "field_order": {"label": "Ordre"},
        "additional_attributes": {"label": "Attribut additionnels"},
        "modules": {
            "query_factory": lambda: DB.session.query(TModules).filter(
                TModules.module_code.in_(
                    current_app.config["ADDITIONAL_FIELDS"]["IMPLEMENTED_MODULES"]
                )
            )
        },
        "objects": {
            "query_factory": lambda: DB.session.query(TObjects).filter(
                TObjects.code_object.in_(
                    current_app.config["ADDITIONAL_FIELDS"]["IMPLEMENTED_OBJECTS"]
                )
            )
        },
    }
    column_descriptions = {
        "bib_nomenclature_type": "Si Type widget = Nomenclature",
        "field_label": "Label du champ en interface",
        "field_name": "Nom du champ en base de donnée",
        "field_values": """Obligatoire si widget = select/multiselect/checkbox,radio (Format JSON : tableau de 'value/label'.Utilisez des doubles quotes pour les valeurs et les clés). 
            Exemple [{"label": "trois", "value": 3}, {"label": "quatre", "value": 4}]""",
        "default_value": "La valeur par défaut doit être une des valeurs du champs 'Valeurs' ci dessus",
        "id_list": "Identifiant en BDD de la liste (pour Type widget = taxonomy/observers)",
        "field_order": "Numéro d'ordonnancement du champs (si plusieurs champs pour le même module/objet/JDD)",
        "modules": "Module(s) auquel le champs est rattaché. *Obligatoire",
        "objects": "Objet(s) auquel le champs est rattaché. *Obligatoire",
        "datasets": "Jeu(x) de donnés auquel le champs est rattaché",
    }

    def on_model_change(self, form, model, is_created):
        """
        Check the validity of field_values JSON field for some field types
        """
        if form.data["type_widget"].widget_name in ("select", "multiselect", "checkbox", "radio"):
            if not type(form.data["field_values"]) is list:
                form.field_values.errors.append(
                    f"Value items must be a list for {form.data['type_widget'].widget_name} forms"
                )

            for item in form.data["field_values"]:
                if not type(item) is dict:
                    form.field_values.errors.append(
                        f"List items must be a dict for {form.data['type_widget'].widget_name} forms"
                    )
                if type(item) is dict and (
                    "label" not in item.keys() or "value" not in item.keys()
                ):
                    form.field_values.errors.append(
                        f"Value items must contain a value/label dict for {form.data['type_widget'].widget_name} forms"
                    )

        if len(form.field_values.errors) > 0:
            raise validators.ValidationError("The form has errors")

        return super().on_model_change(form, model, is_created)
