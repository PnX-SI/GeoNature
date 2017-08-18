from flask_sqlalchemy import SQLAlchemy
from flask import json

db = SQLAlchemy()

class CorRoleObsContact(db.Model):
    # __tablename__       = 'cor_role_obs_contact'
    # __table_args__      = {'schema':'contact'}
    # id_obs_contact      = db.Column(db.BigInteger, db.ForeignKey("contact.t_obs_contact.id_obs_contact"), primary_key=True)
    # id_role             = db.Column(db.Integer, db.ForeignKey("utilisateurs.t_roles.id_role"), primary_key=True)

    __tablename__       = 'cor_role_obs_contact'
    __table_args__      = {'schema':'contact'}
    id_obs_contact      = db.Column(db.BigInteger, primary_key=True)
    id_role             = db.Column(db.Integer, primary_key=True)

    def json(self):
        return {column.key: getattr(self, column.key) 
                for column in self.__table__.columns }
    
    @classmethod
    def find_by_id(cls, id):
        return cls.query.filter_by(id_obs_contact=id).all()

    @classmethod
    def find_by_role(cls, role):
        return cls.query.filter_by(id_role=role).all()

    @classmethod
    def find_by_id_role(cls, id, role):
        return cls.query.filter_by(id_obs_contact=id).filter_by(id_role=role).first()

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