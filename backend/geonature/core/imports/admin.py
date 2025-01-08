import json
from itertools import groupby
from pprint import pformat

from markupsafe import Markup
from flask_admin.contrib.sqla import ModelView
from flask_admin.form import BaseForm
from wtforms.validators import StopValidation
from jsonschema.exceptions import ValidationError as JSONValidationError
from wtforms.fields import StringField

from geonature.utils.env import db
from geonature.core.admin.admin import admin as geonature_admin, CruvedProtectedMixin

from pypnnomenclature.models import TNomenclatures

from geonature.core.imports.models import Destination, FieldMapping, ContentMapping

from flask_admin.contrib.sqla.form import AdminModelConverter
from flask_admin.model.form import converts


class MappingView(CruvedProtectedMixin, ModelView):
    module_code = "IMPORT"
    object_code = "MAPPING"

    can_view_details = True
    column_list = ("label", "active", "public", "destination")
    column_searchable_list = ("label",)
    column_filters = (
        "active",
        "public",
    )
    form_columns = ("label", "active", "public", "owners", "values", "destination")
    column_details_list = ("label", "active", "public", "owners", "values", "destination")
    column_labels = {
        "active": "Actif",
        "owners": "Propriétaires",
        "values": "Correspondances",
        "destination": "Destinations",
    }
    column_formatters = {"destination": lambda v, c, m, p: m.destination.label}
    column_export_list = (
        "label",
        "values",
    )


def FieldMappingValuesValidator(form, field):
    destination = db.session.execute(
        db.select(Destination).where(Destination.id_destination == form.destination.raw_data[0])
    ).scalar_one_or_none()
    try:
        FieldMapping.validate_values(field.data, destination)
    except ValueError as e:
        raise StopValidation(*e.args)


def ContentMappingValuesValidator(form, field):
    destination = db.session.execute(
        db.select(Destination).where(Destination.id_destination == form.destination.raw_data[0])
    ).scalar_one_or_none()
    try:
        ContentMapping.validate_values(field.data, destination)
    except ValueError as e:
        raise StopValidation(*e.args)


class FieldMappingView(MappingView):
    form_args = {
        "values": {
            "validators": [FieldMappingValuesValidator],
        },
    }
    colmun_labels = {
        "values": "Association",
    }
    column_formatters_detail = {
        "values": lambda v, c, m, p: Markup("<pre>%s</pre>" % pformat(m.values)),
    }


class ContentMappingView(MappingView):
    form_args = {
        "values": {
            "validators": [ContentMappingValuesValidator],
        },
    }
    colmun_labels = {
        "values": "Association",
    }
    column_formatters_detail = {
        "values": lambda v, c, m, p: Markup("<pre>%s</pre>" % pformat(m.values)),
    }


geonature_admin.add_view(
    FieldMappingView(FieldMapping, db.session, name="Champs", category="Modèles d’import")
)
geonature_admin.add_view(
    ContentMappingView(
        ContentMapping, db.session, name="Nomenclatures", category="Modèles d’import"
    )
)
