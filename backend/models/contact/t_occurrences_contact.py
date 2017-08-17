from flask_sqlalchemy import SQLAlchemy
from flask import json


db = SQLAlchemy()

class T_OccurrencesContact(db.Model):
    __tablename__               = 't_occurrences_contact'
    __table_args__              = {'schema':'contact'}
    id_occurrence_contact       = db.Column(db.BigInteger, primary_key=True)
    id_obs_contact              = db.Column(db.BigInteger, db.ForeignKey("contact.t_obs_contact.id_obs_contact"), nullable=False)
    id_nomenclature_meth_obs    = db.Column(db.Integer, db.ForeignKey("meta.t_nomenclatures.id_nomenclature"), nullable=False)
    id_nomenclature_eta_bio     = db.Column(db.Integer, db.ForeignKey("meta.t_nomenclatures.id_nomenclature"), nullable=False)
    id_nomenclature_statut_bio  = db.Column(db.Integer, db.ForeignKey("meta.t_nomenclatures.id_nomenclature"))
    id_nomenclature_naturalite  = db.Column(db.Integer, db.ForeignKey("meta.t_nomenclatures.id_nomenclature"))
    id_nomenclature_preuve_exist = db.Column(db.Integer, db.ForeignKey("meta.t_nomenclatures.id_nomenclature"))
    id_nomenclature_statut_obs  = db.Column(db.Integer, db.ForeignKey("meta.t_nomenclatures.id_nomenclature"))
    id_nomenclature_statut_valid = db.Column(db.Integer, db.ForeignKey("meta.t_nomenclatures.id_nomenclature"))
    id_nomenclature_niv_precis  = db.Column(db.Integer, db.ForeignKey("meta.t_nomenclatures.id_nomenclature"))
    id_valideur                 = db.Column(db.Integer, db.ForeignKey("utilisateurs.t_roles.id_role"), nullable=False)
    determinateur               = db.Column(db.Text)
    methode_determination       = db.Column(db.Text)
    cd_nom                      = db.Column(db.Integer, db.ForeignKey("taxonomie.taxref.cd_nom"), nullable=False)
    nom_cite                    = db.Column(db.Text)
    v_taxref                    = db.Column(db.Integer)
    num_prelevement_contact     = db.Column(db.Text)
    preuve_numerique            = db.Column(db.Text)
    preuve_non_numerique        = db.Column(db.Text)
    supprime                    = db.Column(db.BOOLEAN(create_constraint=False))
    date_insert                 = db.Column(db.Date)
    date_update                 = db.Column(db.Date)
    commentaire                 = db.Column(db.Text)

    def __init__(self, id_occurrence_contact):
        self.id_occurrence_contact = id_occurrence_contact
    
    def json(self):
        return {column.key: getattr(self, column.key) if not isinstance(column.type, db.Date) else json.dumps(getattr(self, column.key)) for column in self.__table__.columns }

    @classmethod
    def find_by_id(cls, id_occurrence_contact):
        return cls.query.filter_by(id_occurrence_contact=id_occurrence_contact).first()