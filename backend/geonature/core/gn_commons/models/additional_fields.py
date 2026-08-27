"""
Modèles du schéma gn_commons
"""

from typing import Any, Optional

from sqlalchemy import Boolean, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import JSONB

from utils_flask_sqla.serializers import serializable


from geonature.utils.env import DB

from .base import cor_field_module, cor_field_object, cor_field_dataset
from geonature.core.gn_meta.models import TDatasets
from geonature.core.gn_permissions.models import PermObject


@serializable
class TAdditionalFields(DB.Model):
    __tablename__ = "t_additional_fields"
    __table_args__ = {"schema": "gn_commons"}
    id_field: Mapped[int] = mapped_column(Integer, primary_key=True)
    field_name: Mapped[str] = mapped_column(String)
    field_label: Mapped[str] = mapped_column(String)
    required: Mapped[bool] = mapped_column(Boolean)
    description: Mapped[Optional[str]] = mapped_column(String)
    quantitative: Mapped[Optional[bool]] = mapped_column(Boolean, default=False)
    unity: Mapped[Optional[str]] = mapped_column(String(50))
    field_values: Mapped[Optional[Any]] = mapped_column(JSONB)
    code_nomenclature_type: Mapped[Optional[str]] = mapped_column(
        String,
        ForeignKey("ref_nomenclatures.bib_nomenclatures_types.mnemonique"),
    )
    additional_attributes: Mapped[Optional[Any]] = mapped_column(JSONB)
    id_widget: Mapped[int] = mapped_column(Integer, ForeignKey("gn_commons.bib_widgets.id_widget"))
    id_list: Mapped[Optional[int]] = mapped_column(Integer)
    exportable: Mapped[Optional[bool]] = mapped_column(Boolean, default=True)
    field_order: Mapped[Optional[int]] = mapped_column(Integer)
    type_widget = DB.relationship("BibWidgets")
    bib_nomenclature_type = DB.relationship("BibNomenclaturesTypes")
    additional_attributes: Mapped[Optional[Any]] = mapped_column(JSONB)
    multiselect: Mapped[Optional[bool]] = mapped_column(Boolean)
    api: Mapped[Optional[str]] = mapped_column(String)
    default_value: Mapped[Optional[str]] = mapped_column(String)
    modules = DB.relationship(
        "TModules",
        secondary=cor_field_module,
    )
    objects = DB.relationship(PermObject, secondary=cor_field_object)
    datasets = DB.relationship(
        TDatasets, secondary=cor_field_dataset, back_populates="additional_fields"
    )

    def __str__(self):
        return self.field_label
