from flask_sqlalchemy import SQLAlchemy
from flask import json
from geoalchemy2 import Geometry

db = SQLAlchemy()

class T_ObsContact(db.Model):
    __tablename__       = 't_obs_contact'
    __table_args__      = {'schema':'contact'}
    id_obs_contact      = db.Column(db.BigInteger, primary_key=True)
    id_lot              = db.Column(db.Integer, db.ForeignKey("meta.t_lots.id_lot"), nullable=False)
    id_nomenclature_technique_obs   = db.Column(db.Integer, db.ForeignKey("meta.t_nomenclatures.id_nomenclature"), nullable=False)
    id_numerisateur     = db.Column(db.Integer, db.ForeignKey("utilisateurs.t_roles.id_role"), nullable=False)
    date_min            = db.Column(db.Date, nullable=False)
    date_max            = db.Column(db.Date, nullable=False)
    heure_obs           = db.Column(db.Integer)
    insee               = db.Column(db.Text(length='5'))
    altitude_min        = db.Column(db.Integer)
    altitude_max        = db.Column(db.Integer)
    saisie_initiale     = db.Column(db.Text(length='20'))
    supprime            = db.Column(db.BOOLEAN(create_constraint=False))
    date_insert         = db.Column(db.Date)
    date_update         = db.Column(db.Date)
    contexte_obs        = db.Column(db.Text)
    commentaire         = db.Column(db.Text)
    the_geom_local      = db.Column(Geometry)
    the_geom_3857       = db.Column(Geometry)
    
    def __init__(self, id_obs_contact):
        self.id_obs_contact = id_obs_contact
    
    def json(self):
        return {column.key: getattr(self, column.key) if not isinstance(column.type, db.Date) else json.dumps(getattr(self, column.key)) for column in self.__table__.columns }

    @classmethod
    def find_by_id(cls, id_obs_contact):
        return cls.query.filter_by(id_obs_contact=id_obs_contact).first()