# coding: utf8
from flask import g, Response
from .models import corRoleRelevesContact
from ...core.gn_meta.models import CorDatasetsActor
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import  or_
import json

db = SQLAlchemy()



class ReleveRepository():
    """Repository: classe permettant l'acces au données d'un modèle"""
    def __init__(self, model) :
        self.model = model
        
    def get_one(self, id, info_user):
        """Retourne un releve si autorisé, sinon -1
        """
        id_role, data_scope = info_user
        try:
            releve = db.session.query(self.model).get(id)
        except:
            db.session.rollback()
            raise
        if not releve:
           return None
        if data_scope == 1:
            observers = [d.id_role for d in releve.observers]
            if not (id_role in observers or id_role == releve.id_digitiser):
                return -1
        if data_scope == 2:
            if not releve.id_dataset in self.get_allowed_datasets():
                return -1
        return releve


    def update(self, releve, info_user):
        """Met a jour le releve passé en parametre  
        retourne un releve si autorisé, sinon -1
        """
        id_role, data_scope = info_user
        if data_scope == 1:
            observers = [d.id_role for d in releve.observers]
            if not (id_role in observers or id_role == releve.id_digitiser):
                return -1
        if data_scope == 2:
            if not(releve.id_dataset in self.get_allowed_datasets()):
                return -1
        try:
            db.session.merge(releve)
            db.session.commit()
            return releve
        except:
            db.session.rollback()
            raise

            
    def delete(self, id_releve, info_user):
        """Supprime un releve
        retourne un releve sinon -1"""
        id_role, data_scope = info_user
        try:
            releve = db.session.query(self.model).get(id_releve)
        except:
            db.session.rollback()
        if not releve:
            return None
        if data_scope == '1':
            observers = [d.id_role for d in releve.observers]
            if not(id_role in observers or id_role == releve.id_digitiser):
                return -1
        if data_scope == '2':
            if not releve.id_dataset in self.get_allowed_datasets():
                return -1
        try:
            db.session.delete(releve)
            db.session.commit()
            return releve
        except:
            db.session.rollback()
            raise

    def get_all(self, info_user):
        """Retourne toute les données du modèle, filtrées
             en fonction de la portée des droits autorisés"""
        id_role, data_scope = info_user
        q = db.session.query(self.model)

        if data_scope == '1':
            q = q.join(corRoleRelevesContact, corRoleRelevesContact.c.id_releve_contact == self.model.id_releve_contact
            ).filter(or_(corRoleRelevesContact.c.id_role == id_role, self.model.id_digitiser == id_role))

        if data_scope == '2':
            allowed_datasets = self.get_allowed_datasets()
            q = q.filter(self.model.id_dataset.in_(tuple(allowed_datasets)))
        
        try:
            return q.all()
        except:
            db.session.rollback()
            raise

    def get_filtered_query(self, info_user):
        """Retourne un objet query déjà filtré en fonction de la portée des droits autorisés"""
        id_role, data_scope = info_user
        q = db.session.query(self.model)
        if data_scope == '1':
            q = q.join(corRoleRelevesContact, corRoleRelevesContact.c.id_releve_contact == self.model.id_releve_contact
            ).filter(or_(corRoleRelevesContact.c.id_role == id_role, self.model.id_digitiser == id_role))
        if data_scope == '2':
            allowed_datasets = self.get_allowed_datasets()
            q = q.filter(self.model.id_dataset.in_(tuple(allowed_datasets)))
        return q
    
    def get_allowed_datasets(releve):
        """ Fonction utils pour renvoyer tout les datasets d'un organisme"""
        q = db.session.query(
                        CorDatasetsActor,
                        CorDatasetsActor.id_dataset
                        ).filter(
                            CorDatasetsActor.id_actor == g.user.id_organisme
                        )
        try:
            return [d.id_dataset for d in q.all()]
        except:
            db.session.rollback()
            raise

# # a tester     
#     def get_all_observers_releve(cor_user_table, fk_name, q):
#         """retourne une query filtrée à partir des observateurs de la table de corespondance des observateurs
#         --- params:
#         cor_user_table: le modèle de la table de corespondance des observateurs
#         fk_name: string: nom de la foreign key entre la table releve et la table de corespondance
#         q : un objet query
#          """
#         q = q.join(
#              cor_user_table,
#             getattr(corRoleRelevesContact, fk_name)== getattr(self.model, fk_name)
#              ).filter(or_(cor_user_table.c.id_role == g.user.id_role, self.model.id_digitiser == g.user.id_role))
#         return q