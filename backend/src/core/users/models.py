
# coding: utf8
from __future__ import (unicode_literals, print_function,
                        absolute_import, division)

from flask_sqlalchemy import SQLAlchemy
from ...utils.utilssqlalchemy import serializableModel

db = SQLAlchemy()


class VUserslistForallMenu(serializableModel, db.Model):
    __tablename__ = 'v_userslist_forall_menu'
    __table_args__ = {'schema':'utilisateurs'}
    id_role = db.Column(db.Integer, primary_key=True)
    nom_role = db.Column(db.Unicode)
    prenom_role = db.Column(db.Unicode)
    nom_complet = db.Column(db.Unicode)
    id_menu = db.Column(db.Integer, primary_key=True)
