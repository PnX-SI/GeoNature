from sqlalchemy import ForeignKey

from geonature.utils.env import db

from pypnnomenclature.models import TNomenclatures


class SensitivityRule(db.Model):
    __tablename__ = "t_sensitivity_rules"
    __table_args__ = {"schema": "gn_sensitivity"}

    id = db.Column('id_sensitivity', db.Integer, primary_key=True)
    cd_nom = db.Column(db.Integer, ForeignKey('taxonomie.taxref.cd_nom'), nullable=False)
    nom_cite = db.Column(db.String(length=100))
    id_nomenclature_sensitivity = db.Column(db.Integer,
        ForeignKey('ref_nomenclatures.t_nomenclatures.id_nomenclature'), nullable=False)
    nomenclature_sensitivity = db.relationship(TNomenclatures)
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
