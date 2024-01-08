"""
    Modèles du schéma gn_commons
"""
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import mapped_column, Mapped
from typing import Optional

from utils_flask_sqla.serializers import serializable


from geonature.utils.env import DB

from .base import cor_field_module, cor_field_object, cor_field_dataset
from geonature.core.gn_meta.models import TDatasets
from geonature.core.gn_permissions.models import PermObject


@serializable
class TAdditionalFields(DB.Model):
    __tablename__ = "t_additional_fields"
    __table_args__ = {"schema": "gn_commons"}
    id_field = DB.Column(DB.Integer, primary_key=True)
    field_name: Mapped[str]
    field_label: Mapped[str]
    required: Mapped[Optional[bool]]
    description: Mapped[Optional[str]]
    quantitative: Mapped[Optional[bool]] = mapped_column(default=False)
    unity: Mapped[str] = mapped_column(DB.String(30))
    field_values: Mapped[Optional[dict]] = mapped_column(JSONB)
    code_nomenclature_type: Mapped[Optional[str]] = mapped_column(DB.ForeignKey("ref_nomenclatures.bib_nomenclatures_types.mnemonique"),
    )
    additional_attributes: Mapped[Optional[dict]] = mapped_column(JSONB)
    id_widget: Mapped[int] = mapped_column(DB.ForeignKey("gn_commons.bib_widgets.id_widget"))
    id_list: Mapped[Optional[int]]
    exportable: Mapped[Optional[bool]] = mapped_column(default=True)
    field_order: Mapped[Optional[int]]
    type_widget: Mapped[Optional[int]] = DB.relationship("BibWidgets")
    bib_nomenclature_type: Mapped[Optional["BibNomenclaturesTypes"]] = DB.relationship()
    additional_attributes: Mapped[Optional[dict]] = DB.Column(JSONB)
    multiselect: Mapped[Optional[bool]]
    api: Mapped[Optional[str]]
    default_value: Mapped[Optional[str]]
    modules: Mapped[Optional["TModules"]] = DB.relationship(secondary=cor_field_module)
    objects: Mapped[Optional[PermObject]] = DB.relationship(secondary=cor_field_object)
    datasets: Mapped[Optional[TDatasets]] = DB.relationship(secondary=cor_field_dataset, back_populates="additional_fields")

    def __str__(self):
        return f"{self.field_label} ({self.description})"
