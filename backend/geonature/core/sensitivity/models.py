from typing import Optional
from datetime import datetime, date

from sqlalchemy import Boolean, Column, Date, DateTime, ForeignKey, Integer, String, Table, event
from sqlalchemy.orm import backref, relationship, Mapped, mapped_column
from sqlalchemy.ext.associationproxy import association_proxy

from geonature.utils.env import db

from ref_geo.models import BibAreasTypes, LAreas
from apptax.taxonomie.models import Taxref
from pypnnomenclature.models import BibNomenclaturesTypes, TNomenclatures

cor_sensitivity_area = Table(
    "cor_sensitivity_area",
    db.metadata,
    Column(
        "id_sensitivity",
        Integer,
        ForeignKey("gn_sensitivity.t_sensitivity_rules.id_sensitivity"),
        primary_key=True,
    ),
    Column("id_area", Integer, ForeignKey(LAreas.id_area), primary_key=True),
    schema="gn_sensitivity",
)

cor_sensitivity_area_type = Table(
    "cor_sensitivity_area_type",
    db.metadata,
    Column(
        "id_nomenclature_sensitivity",
        Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        primary_key=True,
    ),
    Column("id_area_type", Integer, ForeignKey(BibAreasTypes.id_type), primary_key=True),
    schema="gn_sensitivity",
)


class SensitivityRule(db.Model):
    __tablename__ = "t_sensitivity_rules"
    __table_args__ = {"schema": "gn_sensitivity"}

    id: Mapped[int] = mapped_column("id_sensitivity", Integer, primary_key=True)
    cd_nom: Mapped[int] = mapped_column(Integer, ForeignKey(Taxref.cd_nom))
    nom_cite: Mapped[Optional[str]] = mapped_column(String(length=100))
    id_nomenclature_sensitivity: Mapped[int] = mapped_column(
        Integer, ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature")
    )
    nomenclature_sensitivity = relationship(TNomenclatures)
    sensitivity_duration: Mapped[int]
    sensitivity_territory: Mapped[Optional[str]] = mapped_column(String(length=1000))
    id_territory: Mapped[Optional[str]] = mapped_column(String(length=50))
    date_min: Mapped[Optional[date]] = mapped_column(Date)
    date_max: Mapped[Optional[date]] = mapped_column(Date)
    source: Mapped[Optional[str]] = mapped_column(String(length=250))
    active: Mapped[Optional[bool]] = mapped_column(Boolean, default=True)
    comments: Mapped[Optional[str]] = mapped_column(String(length=500))
    meta_create_date: Mapped[Optional[datetime]] = mapped_column(DateTime)
    meta_update_date: Mapped[Optional[datetime]] = mapped_column(DateTime)

    areas = relationship(LAreas, secondary=cor_sensitivity_area)
    criterias = association_proxy("sensitivity_criterias", "criteria")


class CorSensitivityCriteria(db.Model):
    __tablename__ = "cor_sensitivity_criteria"
    __table_args__ = {"schema": "gn_sensitivity"}

    id_sensitivity_rule: Mapped[int] = mapped_column(
        "id_sensitivity", Integer, ForeignKey(SensitivityRule.id), primary_key=True
    )
    sensitivity_rule = relationship(
        SensitivityRule, backref=backref("sensitivity_criterias", cascade="all, delete-orphan")
    )

    id_criteria: Mapped[int] = mapped_column(
        "id_criteria", Integer, ForeignKey(TNomenclatures.id_nomenclature), primary_key=True
    )
    criteria = relationship(TNomenclatures)

    id_nomenclature_type: Mapped[Optional[int]] = mapped_column(
        "id_type_nomenclature", Integer, ForeignKey(BibNomenclaturesTypes.id_type)
    )
    nomenclature_type = relationship(BibNomenclaturesTypes)

    def __init__(self, criteria=None, sensitivity_rule=None, nomenclature_type=None):
        self.criteria = criteria
        self.sensitivity_rule = sensitivity_rule
        self.nomenclature_type = nomenclature_type


@event.listens_for(CorSensitivityCriteria, "before_insert")
@event.listens_for(CorSensitivityCriteria, "before_update")
def before_insert_sensitivity_criteria(mapper, connection, target):
    target.id_nomenclature_type = target.criteria.nomenclature_type.id_type
