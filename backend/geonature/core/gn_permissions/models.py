'''
Models of gn_permissions schema
'''


from sqlalchemy import ForeignKey

from geonature.utils.utilssqlalchemy import serializable
from geonature.utils.env import DB

from pypnusershub.db.models import User
from geonature.core.gn_commons.models import TModules

@serializable
class VUsersPermissions(DB.Model):
    __tablename__ = 'v_roles_permissions'
    __table_args__ = {'schema': 'gn_permissions'}
    id_role = DB.Column(DB.Integer, primary_key=True)
    nom_role = DB.Column(DB.Unicode)
    prenom_role = DB.Column(DB.Unicode)
    id_organisme = DB.Column(DB.Integer)
    id_module = DB.Column(DB.Integer, primary_key=True)
    module_code = DB.Column(DB.Unicode)
    id_action = DB.Column(DB.Integer, primary_key=True)
    id_filter = DB.Column(DB.Integer, primary_key=True)
    code_action = DB.Column(DB.Unicode)
    value_filter = DB.Column(DB.Unicode)
    code_filter_type = DB.Column(DB.Unicode)
    id_filter_type = DB.Column(DB.Integer)

    def __repr__(self):
        return """VUsersPermissions
            role='{}' action='{}' filter='{}' module='{}' filter_type='{}'>""".format(
            self.id_role, self.code_action,
            self.value_filter, self.module_code, self.code_filter_type
        )

@serializable
class BibFiltersType(DB.Model):
    __tablename__ = 'bib_filters_type'
    __table_args__ = {'schema': 'gn_permissions'}
    id_filter_type = DB.Column(DB.Integer, primary_key=True)
    code_filter_type = DB.Column(DB.Unicode)
    description_filter_type = DB.Column(DB.Unicode)

@serializable
class TFilters(DB.Model):
    __tablename__ = 't_filters'
    __table_args__ = {'schema': 'gn_permissions'}
    id_filter = DB.Column(DB.Integer, primary_key=True)
    value_filter = DB.Column(DB.Unicode)
    label_filter = DB.Column(DB.Unicode)
    description_filter = DB.Column(DB.Unicode)
    id_filter_type = DB.Column(DB.Integer)

@serializable
class TActions(DB.Model):
    __tablename__ = 't_actions'
    __table_args__ = {'schema': 'gn_permissions'}
    id_action = DB.Column(DB.Integer, primary_key=True)
    code_action = DB.Column(DB.Unicode)
    description_action = DB.Column(DB.Unicode)


@serializable
class TObjects(DB.Model):
    __tablename__ = 't_objects'
    __table_args__ = {'schema': 'gn_permissions'}
    id_object = DB.Column(DB.Integer, primary_key=True)
    code_object = DB.Column(DB.Unicode)
    description_object = DB.Column(DB.Unicode)

@serializable
class CorRoleActionFilterModuleObject(DB.Model):
    __tablename__ = 'cor_role_action_filter_module_object'
    __table_args__ = {'schema': 'gn_permissions'}
    id_role = DB.Column(
        DB.Integer,
        ForeignKey('utilisateurs.t_roles.id_role'),
        primary_key=True
    )    
    id_action = DB.Column(
        DB.Integer,
        ForeignKey('gn_permissions.t_actions.id_action'),
        primary_key=True
    )
    id_filter = DB.Column(
        DB.Integer,
        ForeignKey('gn_permissions.t_filters.id_filter'),
    )
    id_module = DB.Column(
        DB.Integer, 
        ForeignKey('gn_commons.t_modules.id_module'),
        primary_key=True
    )
    id_object = DB.Column(
        DB.Integer, 
        ForeignKey('gn_permissions.t_objects.id_object'),
        primary_key=True
    )

    role = DB.relationship(
        User,
        primaryjoin=(User.id_role == id_role),
        foreign_keys=[id_role]       
    )

    action = DB.relationship(
        TActions,
        primaryjoin=(TActions.id_action == id_action),
        foreign_keys=[id_action]       
    )

    filter = DB.relationship(
        TFilters,
        primaryjoin=(TFilters.id_filter == id_filter),
        foreign_keys=[id_filter]       
    )

    module = DB.relationship(
        TModules,
        primaryjoin=(TModules.id_module == id_module),
        foreign_keys=[id_module]       
    )

    object = DB.relationship(
        TObjects,
        primaryjoin=(TObjects.id_object == id_object),
        foreign_keys=[id_object]       
    )

 

@serializable
class CorObjectModule(DB.Model):
    __tablename__ = 'cor_object_module'
    __table_args__ = {'schema': 'gn_permissions'}
    id_cor_object_module = DB.Column(DB.Integer, primary_key=True)  
    id_object = DB.Column(DB.Integer)
    id_module = DB.Column(DB.Integer)
    
    
