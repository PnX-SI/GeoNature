# coding: utf8

from __future__ import (unicode_literals, print_function,
                        absolute_import, division)

'''
mappings applications et utilisateurs
'''

import hashlib
import bcrypt
from bcrypt import checkpw
from os import environ
from importlib import import_module

from flask_sqlalchemy import SQLAlchemy

from flask import current_app

from sqlalchemy.ext.hybrid import hybrid_property
from sqlalchemy.orm import relationship, backref
from sqlalchemy import Sequence, func, ForeignKey
from sqlalchemy.sql import select, func
from sqlalchemy.dialects.postgresql import UUID

from pypnusershub.db.tools import NoPasswordError, DifferentPasswordError
from pypnusershub.env import db
from utils_flask_sqla.serializers import serializable




def check_and_encrypt_password(password, password_confirmation, md5=False):
    if not password:
        raise NoPasswordError
    if password != password_confirmation:
        raise DifferentPasswordError
    pass_plus = bcrypt.hashpw(password.encode(
        'utf-8'), bcrypt.gensalt())
    pass_md5 = None
    if md5:
        pass_md5 = hashlib.md5(password.encode("utf-8")).hexdigest()
    return pass_plus.decode('utf-8'), pass_md5


def fn_check_password(self, pwd):
    if (current_app.config['PASS_METHOD'] == 'md5'):
        if not self._password:
            raise ValueError('User %s has no password' % (self.identifiant))
        return self._password == hashlib.md5(pwd.encode('utf8')).hexdigest()
    elif (current_app.config['PASS_METHOD'] == 'hash'):
        if not self._password_plus:
            raise ValueError('User %s has no password' % (self.identifiant))
        return checkpw(pwd.encode('utf8'), self._password_plus.encode('utf8'))
    else:
        raise ValueError('Undefine crypt method (PASS_METHOD)')


cor_roles = db.Table('cor_roles',
    db.Column('id_role_utilisateur', db.Integer, db.ForeignKey('utilisateurs.t_roles.id_role'), primary_key=True),
    db.Column('id_role_groupe', db.Integer, db.ForeignKey('utilisateurs.t_roles.id_role'), primary_key=True),
    schema='utilisateurs',
    extend_existing=True,
)

@serializable(exclude=["_password", "_password_plus"])
class User(db.Model):
    __tablename__ = 't_roles'
    __table_args__ = {'schema': 'utilisateurs'}

    TABLE_ID = Sequence(
        't_roles_id_role_seq',
        schema="utilisateurs",
    )
    groupe = db.Column(db.Boolean, default=False)
    id_role = db.Column(
        db.Integer,
        TABLE_ID,
        primary_key=True,
    )

    # TODO: make that unique ?
    identifiant = db.Column(db.Unicode)
    nom_role = db.Column(db.Unicode)
    prenom_role = db.Column(db.Unicode)
    desc_role = db.Column(db.Unicode)
    _password = db.Column('pass', db.Unicode)
    _password_plus = db.Column('pass_plus', db.Unicode)
    email = db.Column(db.Unicode)
    id_organisme = db.Column(db.Integer, ForeignKey("utilisateurs.bib_organismes.id_organisme"))
    remarques = db.Column(db.Unicode)
    date_insert = db.Column(db.DateTime)
    date_update = db.Column(db.DateTime)
    active = db.Column(db.Boolean)
    groups = db.relationship('User', lazy="joined",
                             secondary=cor_roles,
                             primaryjoin="User.id_role == utilisateurs.cor_roles.c.id_role_utilisateur",
                             secondaryjoin="User.id_role == utilisateurs.cor_roles.c.id_role_groupe",
                             backref=backref('members'))

    @hybrid_property
    def nom_complet(self):
        return '{0} {1}'.format(self.nom_role, self.prenom_role)

    @nom_complet.expression
    def nom_complet(cls):
        return db.func.concat(cls.nom_role, ' ', cls.prenom_role)

    # applications_droits = db.relationship('AppUser', lazy='joined')

    @property
    def password(self):
        if (current_app.config['PASS_METHOD'] == 'md5'):
            return self._password
        elif (current_app.config['PASS_METHOD'] == 'hash'):
            return self._password_plus
        else:
            raise Exception

    # TODO: change password digest algorithm for something stronger such
    # as bcrypt. This need to be done at usershub level first.
    @password.setter
    def password(self, pwd):
        pwd = pwd.encode('utf-8')
        if current_app.config['PASS_METHOD'] == 'md5':
            self._password = hashlib.md5(pwd).hexdigest()
        elif current_app.config['PASS_METHOD'] == 'hash':
            self._password_plus = bcrypt.hashpw(pwd, bcrypt.gensalt()).decode('utf-8')
        else:
            raise Exception('Unknown pass method')

    check_password = fn_check_password

    def to_json(self):
        out = {
            'id': self.id_role,
            'login': self.identifiant,
            'email': self.email,
            'applications': []
        }
        for app_data in self.applications_droits:
            app = {
                'id': app_data.application_id,
                'nom': app_data.application.nom_application,
                'niveau': app_data.id_droit_max
            }
            out['applications'].append(app)
        return out

    def __repr__(self):
        return "<User '{!r}' id='{}'>".format(self.identifiant, self.id_role)

    def __str__(self):
        return self.identifiant or ''

    def as_dict(self, data):
        if 'nom_role' in data:
            data["nom_role"] = data["nom_role"] or ""
        if 'prenom_role' in data:
            data["prenom_role"] = data["prenom_role"] or ""
        return data



@serializable
class Organisme(db.Model):
    __tablename__ = "bib_organismes"
    __table_args__ = {"schema": "utilisateurs"}

    id_organisme = db.Column(db.Integer, primary_key=True)
    uuid_organisme = db.Column(
        UUID(as_uuid=True), default=select([func.uuid_generate_v4()])
    )
    nom_organisme = db.Column(db.Unicode)
    adresse_organisme = db.Column(db.Unicode)
    cp_organisme = db.Column(db.Unicode)
    ville_organisme = db.Column(db.Unicode)
    tel_organisme = db.Column(db.Unicode)
    fax_organisme = db.Column(db.Unicode)
    email_organisme = db.Column(db.Unicode)
    url_organisme = db.Column(db.Unicode)
    url_logo = db.Column(db.Unicode)
    id_parent = db.Column(db.Integer, db.ForeignKey('utilisateurs.bib_organismes.id_organisme'))
    members = db.relationship(User, backref="organisme")


class Profils(db.Model):
    """
    Model de la classe t_profils
    """

    __tablename__ = 't_profils'
    __table_args__ = {'schema': 'utilisateurs', 'extend_existing': True}
    id_profil = db.Column(db.Integer, primary_key=True)
    code_profil = db.Column(db.Unicode)
    nom_profil = db.Column(db.Unicode)
    desc_profil = db.Column(db.Unicode)


class ProfilsForApp(db.Model):
    """
    Model de la classe t_profils
    """

    __tablename__ = 'cor_profil_for_app'
    __table_args__ = {'schema': 'utilisateurs', 'extend_existing': True}
    id_profil = db.Column(
        db.Integer,
        ForeignKey('utilisateurs.t_profils.id_profil'),
        primary_key=True
    )
    id_application = db.Column(db.Integer, primary_key=True)

    profil = relationship("Profils")

@serializable
class Application(db.Model):
    '''
    Représente une application ou un module
    '''
    __tablename__ = 't_applications'
    __table_args__ = {'schema': 'utilisateurs'}
    id_application = db.Column(db.Integer, primary_key=True)
    code_application = db.Column(db.Unicode)
    nom_application = db.Column(db.Unicode)
    desc_application = db.Column(db.Unicode)
    id_parent = db.Column(db.Integer)

    def __repr__(self):
        return "<Application {!r}>".format(self.nom_application)

    def __str__(self):
        return self.nom_application

    @staticmethod
    def get_application(nom_application):
        return (Application.query
                .filter(Application.nom_application == nom_application)
                .one())


class ApplicationRight(db.Model):
    '''
    Droit d'acces a une application
    '''
    __tablename__ = 'bib_droits'
    __table_args__ = {'schema': 'utilisateurs'}
    id_droit = db.Column(db.Integer, primary_key=True)
    nom_droit = db.Column(db.Unicode)
    desc_droit = db.Column(db.UnicodeText)

    def __repr__(self):
        return "<ApplicationRight {!r}>".format(self.desc_droit)

    def __str__(self):
        return self.nom_droit


class UserApplicationRight(db.Model):
    '''
    Droit d'acces d'un user particulier a une application particuliere
    '''
    __tablename__ = 'cor_role_app_profil'
    __table_args__ = {'schema': 'utilisateurs'}#, 'extend_existing': True}
    id_role = db.Column(db.Integer, ForeignKey('utilisateurs.t_roles.id_role'), primary_key=True)
    id_profil = db.Column(db.Integer, ForeignKey('utilisateurs.t_profils.id_profil'), primary_key=True)
    id_application = db.Column(db.Integer, ForeignKey('utilisateurs.t_applications.id_application'), primary_key=True)

    role = relationship("User")
    profil = relationship("Profils")
    application = relationship("Application")

    def __repr__(self):
        return "<UserApplicationRight role='{}' profil='{}' app='{}'>".format(
            self.id_role, self.id_profil, self.id_application
        )

@serializable(exclude=["password", "_password_plus"])
class AppUser(db.Model):
    '''
    Relations entre applications et utilisateurs
    '''
    __tablename__ = 'v_userslist_forall_applications'
    __table_args__ = {'schema': 'utilisateurs'}

    id_role = db.Column(
        db.Integer,
        db.ForeignKey('utilisateurs.t_roles.id_role'),
        primary_key=True
    )
    role = relationship("User", backref="app_users")
    nom_role = db.Column(db.Unicode)
    prenom_role = db.Column(db.Unicode)
    id_application = db.Column(
        db.Integer,
        db.ForeignKey('utilisateurs.t_applications.id_application'),
        primary_key=True
    )
    id_organisme = db.Column(db.Integer)
    application = relationship("Application", backref="app_users")
    identifiant = db.Column(db.Unicode)
    _password = db.Column('pass', db.Unicode)
    _password_plus = db.Column('pass_plus', db.Unicode)
    id_droit_max = db.Column(db.Integer, primary_key=True)
    # user = db.relationship('User', backref='relations', lazy='joined')
    # application = db.relationship('Application',
    #                               backref='relations', lazy='joined')

    @property
    def password(self):
        return self._password

    check_password = fn_check_password

    def __repr__(self):
        return "<AppUser role='{}' app='{}'>".format(
            self.id_role, self.id_application
        )


class AppRole(db.Model):
    '''
    Relations entre applications et role
    '''
    __tablename__ = 'v_roleslist_forall_applications'
    __table_args__ = {'schema': 'utilisateurs'}

    id_role = db.Column(
        db.Integer,
        db.ForeignKey('utilisateurs.t_roles.id_role'),
        primary_key=True
    )
    groupe = db.Column(db.Boolean)
    nom_role = db.Column(db.Unicode)
    prenom_role = db.Column(db.Unicode)
    id_application = db.Column(
        db.Integer,
        db.ForeignKey('utilisateurs.t_applications.id_application'),
        primary_key=True
    )
    id_organisme = db.Column(db.Integer)
    identifiant = db.Column(db.Unicode)

    def as_dict(self):
        cols = (c for c in self.__table__.columns)
        return {c.name: getattr(self, c.name) for c in cols}
