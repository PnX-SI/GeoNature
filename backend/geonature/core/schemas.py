from flask import g
from geonature.core.gn_commons.models.base import BibWidgets
from marshmallow import fields
from sqlalchemy import select
from sqlalchemy.orm import joinedload
from werkzeug.exceptions import BadRequest

from geonature.utils.env import db
from geonature.core.gn_commons.models import TAdditionalFields
from pypnnomenclature.models import TNomenclatures


def _add_label_nomenclature_data_dict(value, module_code, object_code):
    duplicate_key_dict = {}
    fields = (
        db.session.execute(
            select(TAdditionalFields)
            .options(joinedload(TAdditionalFields.type_widget))
            .where(TAdditionalFields.modules.any(module_code=module_code))
            .where(TAdditionalFields.objects.any(code_object=object_code))
        )
        .scalars()
        .all()
    )
    nomenclature_fields_name = [
        field.field_name for field in fields if field.type_widget.widget_name == "nomenclature"
    ]
    for key, val in (value or {}).items():
        duplicate_key_dict[key] = val
        if key in nomenclature_fields_name:
            if nomenclature := db.session.get(TNomenclatures, val):
                duplicate_key_dict[f"_label_{key}"] = nomenclature.label_default
    return duplicate_key_dict


class AdditionalDataWithNomenclatureField(fields.Dict):
    def __init__(self, object_code, module_code=None, keys=None, values=None, **kwargs):
        kwargs.setdefault("allow_none", True)
        super().__init__(keys, values, **kwargs)
        self.module_code = module_code
        self.object_code = object_code

    def _deserialize(self, value, attr, data, **kwargs):
        # module_code may only be known at request time (eg. g.current_module),
        # in which case it's set on the parent schema instance instead of here.
        module_code = self.module_code or (
            self.parent.module_code if hasattr(self.parent, "module_code") else None
        )
        if not module_code:
            module_code = g.current_module.module_code if hasattr(g, "current_module") else None
        if module_code is None:
            raise BadRequest("No module code provided in NomenclatureAdditionalDataField")
        return _add_label_nomenclature_data_dict(
            value, module_code=module_code, object_code=self.object_code
        )
