from flask import current_app, flash
from wtforms import validators, Form

from flask_admin.contrib.sqla import ModelView
from flask_admin.form import BaseForm
from geonature.core.gn_commons.models import TModules
from geonature.core.gn_permissions.models import TObjects
from geonature.core.gn_commons.schemas import TAdditionalFieldsSchema
from geonature.utils.env import DB


from marshmallow import ValidationError


class TAdditionalFieldsForm(BaseForm):
    def validate(self, *args, **kwargs):
        try:
            TAdditionalFieldsSchema().load(self.data)
        except ValidationError as e:
            flash("The form has errors", "error")
            self.field_values.errors = (
                f"Value input must contain a list of dict with value/label key for {self.data['type_widget']} widget ",
            )
            return False

        return super().validate(*args, **kwargs)


class BibFieldAdmin(ModelView):
    form_base_class = TAdditionalFieldsForm
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
