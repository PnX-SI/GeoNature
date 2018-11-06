from geonature.utils.env import DB
from geonature.utils.utilssqlalchemy import serializable


@serializable
class VUserslistForallMenu(DB.Model):
    __tablename__ = 'v_userslist_forall_menu'
    __table_args__ = {'schema': 'utilisateurs'}
    id_role = DB.Column(DB.Integer, primary_key=True)
    nom_role = DB.Column(DB.Unicode)
    prenom_role = DB.Column(DB.Unicode)
    nom_complet = DB.Column(DB.Unicode)
    id_menu = DB.Column(DB.Integer, primary_key=True)


@serializable
class BibOrganismes(DB.Model):
    __tablename__ = 'bib_organismes'
    __table_args__ = {'schema': 'utilisateurs'}
    id_organisme = DB.Column(DB.Integer, primary_key=True)
    nom_organisme = DB.Column(DB.Unicode)
    cp_organisme = DB.Column(DB.Unicode)
    ville_organisme = DB.Column(DB.Unicode)
    tel_organisme = DB.Column(DB.Unicode)
    fax_organisme = DB.Column(DB.Unicode)
    email_organisme = DB.Column(DB.Unicode)


@serializable
class CorRole(DB.Model):
    __tablename__ = 'cor_roles'
    __table_args__ = {'schema': 'utilisateurs'}
    id_role_groupe = DB.Column(DB.Integer, primary_key=True)
    id_role_utilisateur = DB.Column(DB.Integer, primary_key=True)

    def __init__(self, id_group, id_role):
        self.id_role_groupe = id_group
        self.id_role_utilisateur = id_role


@serializable
class TApplications(DB.Model):
    __tablename__ = 't_applications'
    __table_args__ = {'schema': 'utilisateurs', 'extend_existing': True}
    id_application = DB.Column(DB.Integer, primary_key=True)
    nom_application = DB.Column(DB.Unicode)
    desc_application = DB.Column(DB.Unicode)
    id_parent = DB.Column(DB.Integer)


class UserRigth():
    def __init__(
        self,
        id_role=None,
        id_organisme=None,
        tag_action_code=None,
        tag_object_code=None,
        id_application=None,
        nom_role=None,
        prenom_role=None

    ):
        self.id_role = id_role
        self.id_organisme = id_organisme
        self.tag_action_code = tag_action_code
        self.tag_object_code = tag_object_code
        self.id_application = id_application
        self.nom_role = nom_role
        self.prenom_role = prenom_role
