from flask_sqlalchemy import SQLAlchemy
from flask import json

db = SQLAlchemy()

class CorStadeSexEffectif(db.Model):
    # __tablename__       = 'cor_stade_sexe_effectif'
    # __table_args__      = {'schema':'contact'}

    # id_occurrence_contact       = db.Column(db.BigInteger, db.ForeignKey("contact.t_occurrences_contact.id_occurrence_contact"), primary_key=True)
    # id_nomenclature_stade_vie   = db.Column(db.Integer, db.ForeignKey("nomenclatures.t_nomenclatures.id_nomenclature"), primary_key=True)
    # id_nomenclature_sexe        = db.Column(db.Integer, db.ForeignKey("nomenclatures.t_nomenclatures.id_nomenclature"), primary_key=True)
    # id_nomenclature_obj_denbr   = db.Column(db.Integer, db.ForeignKey("nomenclatures.t_nomenclatures.id_nomenclature"))
    # id_nomenclature_typ_denbr   = db.Column(db.Integer, db.ForeignKey("nomenclatures.t_nomenclatures.id_nomenclature"))
    # denombrement_min            = db.Column(db.Integer)
    # denombrement_max            = db.Column(db.Integer)

    __tablename__       = 'cor_stade_sexe_effectif'
    __table_args__      = {'schema':'contact'}

    id_occurrence_contact       = db.Column(db.BigInteger, db.ForeignKey("contact.t_occurrences_contact.id_occurrence_contact"), primary_key=True)
    id_nomenclature_stade_vie   = db.Column(db.Integer, db.ForeignKey("nomenclatures.t_nomenclatures.id_nomenclature"), primary_key=True)
    id_nomenclature_sexe        = db.Column(db.Integer, db.ForeignKey("nomenclatures.t_nomenclatures.id_nomenclature"), primary_key=True)
    id_nomenclature_obj_denbr   = db.Column(db.Integer, db.ForeignKey("nomenclatures.t_nomenclatures.id_nomenclature"))
    id_nomenclature_typ_denbr   = db.Column(db.Integer, db.ForeignKey("nomenclatures.t_nomenclatures.id_nomenclature"))
    denombrement_min            = db.Column(db.Integer)
    denombrement_max            = db.Column(db.Integer)

    def json(self):
        return {column.key: getattr(self, column.key) 
                for column in self.__table__.columns }
    
    @classmethod
    def find_by_id_occ(cls, id):
        return cls.query.filter_by(id_occurrence_contact=id).all()

    @classmethod
    def find_by_id_stade(cls, id):
        return cls.query.filter_by(id_nomenclature_stade_vie=id).all()

    @classmethod
    def find_by_id_sexe(cls, id):
        return cls.query.filter_by(id_nomenclature_sexe=id).all()

    @classmethod
    def find_by_occ_stade_sexe(cls, occ, stade, sexe):
        return cls.query.filter_by(id_occurrence_contact=occ).filter_by(id_nomenclature_stade_vie=stade).filter_by(id_nomenclature_sexe=sexe).first()

    def add_to_db(self):
        db.session.add(self)
        db.session.commit()

    def modif_db(self):
        db.session.merge(self)
        db.session.commit()

    def delete_from_db(self):
        db.session.delete(self)
        db.session.commit()
    
    def rollback(self):
        db.session.rollback()