from flask import current_app

from flask_admin.contrib.sqla import ModelView
from geonature.core.gn_commons.models import TAddtitionalFields, TModules
from geonature.core.gn_permissions.models import TObjects
from geonature.utils.env import DB

class BibFieldAdmin(ModelView):
    form_columns = (
        "type_widget", "field_name", "field_label", "required", "description",
        "quantitative", "unity", "field_values", "field_order", "exportable",
         "bib_nomenclature_type", "id_list", "modules", "objects", "datasets",
         "additional_attributes"
    )

    column_display_all_relations = True
    # form_columns = ('truc', BibFields.field_name)
    # column_labels = dict(name='Name', last_name='Last Name')
    form_args = {
        "field_name": {"label":"Nom du champ"},
        "bib_nomenclature_type": {"label":"Type de nomenclature"},
        "field_label": {"label":"Label du champ"},
        "required": {"label":"Obligatoire"},
        "quantitative": {"label":"Quantitatif"},
        "unity": {"label":"Unité"},
        "field_values": {"label":"Valeurs"},
        "field_order": {"label":"Ordre"},
        "additional_attributes": {"label":"Attribut additionnels"},
        "modules": {
            "query_factory": lambda: DB.session.query(
                TModules).filter(TModules.module_code.in_(
                    current_app.config["ADDITIONAL_FIELDS"]["IMPLEMENTED_MODULES"]
                ))
        },
        "objects": {
            "query_factory": lambda: DB.session.query(
                TObjects).filter(TObjects.code_object.in_(
                    current_app.config["ADDITIONAL_FIELDS"]["IMPLEMENTED_OBJECTS"]
                ))
        }
    }
    column_descriptions = {
        "bib_nomenclature_type":'Si Type widget = Nomenclature',
        "field_label":'Label du champ en interface',
        "field_name":'Nom du champ en base de donnée',
        "field_values":'Obligatoire si widget = select/radio/bool_radio (tableau de valeurs ou tableau clé/valeur. Utilisez des doubles quotes pour les valeurs et les clés)',
        "id_list":'Identifiant en BDD de la liste (pour Type widget = taxonomy/observers)',

    }


