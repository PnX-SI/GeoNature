"""
    Modèles du schéma gn_commons
"""
from sqlalchemy.dialects.postgresql import JSONB

from utils_flask_sqla.serializers import serializable


from geonature.utils.env import DB

from .base import cor_field_module, cor_field_object, cor_field_dataset
from geonature.core.gn_meta.models import TDatasets
from geonature.core.gn_permissions.models import TObjects


@serializable
class TAdditionalFields(DB.Model):
    __tablename__ = "t_additional_fields"
    __table_args__ = {"schema": "gn_commons"}
    id_field = DB.Column(DB.Integer, primary_key=True)
    field_name = DB.Column(DB.String, nullable=False)
    field_label = DB.Column(DB.String, nullable=False)
    required = DB.Column(DB.Boolean)
    description = DB.Column(DB.String)
    quantitative = DB.Column(DB.Boolean, default=False)
    unity = DB.Column(DB.String(50))
    field_values = DB.Column(JSONB)
    code_nomenclature_type = DB.Column(
        DB.String,
        DB.ForeignKey("ref_nomenclatures.bib_nomenclatures_types.mnemonique"),
    )
    additional_attributes = DB.Column(JSONB)
    id_widget = DB.Column(
        DB.Integer, DB.ForeignKey("gn_commons.bib_widgets.id_widget"), nullable=False
    )
    id_list = DB.Column(DB.Integer)
    exportable = DB.Column(DB.Boolean, default=True)
    field_order = DB.Column(DB.Integer)
    type_widget = DB.relationship("BibWidgets")
    bib_nomenclature_type = DB.relationship(
        "BibNomenclaturesTypes",
        primaryjoin="BibNomenclaturesTypes.mnemonique == TAdditionalFields.code_nomenclature_type",
    )
    additional_attributes = DB.Column(JSONB)
    multiselect = DB.Column(DB.Boolean)
    key_label = DB.Column(DB.String)
    key_value = DB.Column(DB.String)
    api = DB.Column(DB.String)
    default_value = DB.Column(DB.String)
    modules = DB.relationship(
        "TModules",
        secondary=cor_field_module,
    )
    objects = DB.relationship("TObjects", secondary=cor_field_object)
    datasets = DB.relationship("TDatasets", secondary=cor_field_dataset)

    def __str__(self):
        return f"{self.field_label} ({self.description})"
