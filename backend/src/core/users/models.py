
# coding: utf8
from __future__ import (unicode_literals, print_function,
                        absolute_import, division)

from flask_sqlalchemy import SQLAlchemy
from ...utils.utilssqlalchemy import serializableModel

db = SQLAlchemy()


class VUserslistForallMenu(serializableModel):
    __tablename__ = 'v_userslist_forall_menu'
    __table_args__ = {'schema': 'utilisateurs'}
    id_role = db.Column(db.Integer, primary_key=True)
    nom_role = db.Column(db.Unicode)
    prenom_role = db.Column(db.Unicode)
    nom_complet = db.Column(db.Unicode)
    id_menu = db.Column(db.Integer, primary_key=True)


class BibOrganismes(serializableModel):
    __tablename__ = 'bib_organismes'
    __table_args__ = {'schema': 'utilisateurs'}
    id_organisme = db.Column(db.Integer, primary_key=True)
    nom_organisme = db.Column(db.Unicode)
    cp_organisme = db.Column(db.Unicode)
    ville_organisme = db.Column(db.Unicode)
    tel_organisme = db.Column(db.Unicode)
    fax_organisme = db.Column(db.Unicode)
    email_organisme = db.Column(db.Unicode)


class TRoles (serializableModel):
    __tablename__ = 't_roles'
    __table_args__ = {'schema': 'utilisateurs'}
    id_role = db.Column(db.Integer, primary_key=True)
    identifiant = db.Column(db.Unicode)
    nom_role = db.Column(db.Unicode)
    prenom_role = db.Column(db.Unicode)
    id_organisme = db.Column(db.Integer)

class CorRole(serializableModel):
    __tablename__ = 'cor_roles'
    __table_args__ = {'schema': 'utilisateurs'}
    id_role_groupe = db.Column(db.Integer, primary_key=True)
    id_role_utilisateur = db.Column(db.Integer, primary_key=True)

