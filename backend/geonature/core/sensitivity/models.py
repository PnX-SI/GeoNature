from sqlalchemy import ForeignKey, event
from sqlalchemy.orm import backref, relationship
from sqlalchemy.ext.associationproxy import association_proxy

from geonature.utils.env import db

from ref_geo.models import LAreas
from apptax.taxonomie.models import Taxref
from pypnnomenclature.models import BibNomenclaturesTypes, TNomenclatures


cor_sensitivity_area = db.Table(
    "cor_sensitivity_area",
    db.Column(
        "id_sensitivity",
        db.Integer,
        ForeignKey("gn_sensitivity.t_sensitivity_rules.id_sensitivity"),
        primary_key=True,
    ),
    db.Column("id_area", db.Integer, ForeignKey(LAreas.id_area), primary_key=True),
    schema="gn_sensitivity",
)


class SensitivityRule(db.Model):
    __tablename__ = "t_sensitivity_rules"
    __table_args__ = {"schema": "gn_sensitivity"}

    id = db.Column("id_sensitivity", db.Integer, primary_key=True)
    cd_nom = db.Column(db.Integer, ForeignKey(Taxref.cd_nom), nullable=False)
    nom_cite = db.Column(db.String(length=100))
    id_nomenclature_sensitivity = db.Column(
        db.Integer, ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"), nullable=False
    )
    nomenclature_sensitivity = relationship(TNomenclatures)
    sensitivity_duration = db.Column(db.Integer, nullable=False)
    sensitivity_territory = db.Column(db.String(length=1000))
    id_territory = db.Column(db.String(length=50))
    date_min = db.Column(db.Date)
    date_max = db.Column(db.Date)
    source = db.Column(db.String(length=250))
    active = db.Column(db.Boolean, default=True)
    comments = db.Column(db.String(length=500))
    meta_create_date = db.Column(db.DateTime)
    meta_update_date = db.Column(db.DateTime)

    areas = relationship(LAreas, secondary=cor_sensitivity_area)
    criterias = association_proxy("sensitivity_criterias", "criteria")


class CorSensitivityCriteria(db.Model):
    __tablename__ = "cor_sensitivity_criteria"
    __table_args__ = {"schema": "gn_sensitivity"}

    id_sensitivity_rule = db.Column(
        "id_sensitivity", db.Integer, ForeignKey(SensitivityRule.id), primary_key=True
    )
    sensitivity_rule = relationship(
        SensitivityRule, backref=backref("sensitivity_criterias", cascade="all, delete-orphan")
    )

    id_criteria = db.Column(
        "id_criteria", db.Integer, ForeignKey(TNomenclatures.id_nomenclature), primary_key=True
    )
    criteria = relationship(TNomenclatures)

    id_nomenclature_type = db.Column(
        "id_type_nomenclature", db.Integer, ForeignKey(BibNomenclaturesTypes.id_type)
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
