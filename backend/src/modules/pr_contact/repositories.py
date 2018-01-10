# coding: utf8
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import  or_

from ...core.gn_meta.models import CorDatasetsActor
from ...core.gn_meta import routes as gn_meta
from .models import corRoleRelevesContact
db = SQLAlchemy()



class ReleveRepository():
    """Repository: classe permettant l'acces au données d'un modèle"""
    def __init__(self, model) :
        self.model = model


    def get_one(self, id_releve, info_user):
        """Retourne un releve si autorisé, sinon -1
        """
        try:
            releve = db.session.query(self.model).get(id_releve)
        except:
            db.session.rollback()
            raise
        if releve:
           return releve.get_releve_if_allowed(info_user)

        return None
            

    def update(self, releve, info_user):
        """Met a jour le releve passé en parametre  
        retourne un releve si autorisé, sinon -1
        """
        releve = releve.get_releve_if_allowed(info_user)
        if releve != -1:
            try:
                db.session.merge(releve)
                db.session.commit()
            except:
                db.session.rollback()
                raise
        return releve


            
    def delete(self, id_releve, info_user):
        """Supprime un releve
        retourne un releve sinon -1"""
        try:
            releve = db.session.query(self.model).get(id_releve)
        except:
            db.session.rollback()
        if not releve:
            return None
        releve = releve.get_releve_if_allowed(info_user)
        if releve != -1:
            try:
                db.session.delete(releve)
                db.session.commit()
            except:
                db.session.rollback()
                raise
        return releve

    def filter_query_with_autorization(self, user):
        q = db.session.query(self.model)
        if user.tag_object_code == '2':
            allowed_datasets = gn_meta.get_allowed_datasets(user)
            q = q.join(
                    corRoleRelevesContact,
                    corRoleRelevesContact.c.id_releve_contact == self.model.id_releve_contact
                    ).filter(
                        or_(
                        self.model.id_dataset.in_(tuple(allowed_datasets)),
                        corRoleRelevesContact.c.id_role == user.id_role,
                        self.model.id_digitiser == user.id_role
                        )
                    )
        elif user.tag_object_code == '1':
            q = q.join(
                    corRoleRelevesContact,
                    corRoleRelevesContact.c.id_releve_contact == self.model.id_releve_contact
                    ).filter(
                        or_(
                        corRoleRelevesContact.c.id_role == user.id_role,
                        self.model.id_digitiser == user.id_role
                        )
                    )
        return q       

    def get_all(self, info_user):
        """Retourne toute les données du modèle, filtrées
             en fonction de la portée des droits autorisés"""
        q = self.filter_query_with_autorization(info_user)
        try:
            return q.all()
        except:
            db.session.rollback()
            raise

    def get_filtered_query(self, info_user):
        """Retourne un objet query déjà filtré en fonction de la portée des droits autorisés"""
        return self.filter_query_with_autorization(info_user)
    




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

