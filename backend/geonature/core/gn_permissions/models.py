"""
Models of gn_permissions schema
"""

from sqlalchemy import ForeignKey
from sqlalchemy.sql import select

from utils_flask_sqla.serializers import serializable
from pypnusershub.db.models import User

from geonature.utils.env import DB


@serializable
class VUsersPermissions(DB.Model):
    __tablename__ = "v_roles_permissions"
    __table_args__ = {"schema": "gn_permissions"}
    id_role = DB.Column(DB.Integer, primary_key=True)
    nom_role = DB.Column(DB.Unicode)
    prenom_role = DB.Column(DB.Unicode)
    id_organisme = DB.Column(DB.Integer)
    id_module = DB.Column(DB.Integer, primary_key=True)
    module_code = DB.Column(DB.Unicode)
    code_object = DB.Column(DB.Unicode)
    id_action = DB.Column(DB.Integer, primary_key=True)
    description_action = DB.Column(DB.Unicode)
    id_filter = DB.Column(DB.Integer, primary_key=True)
    label_filter = DB.Column(DB.Integer, primary_key=True)
    code_action = DB.Column(DB.Unicode)
    description_action = DB.Column(DB.Unicode)
    value_filter = DB.Column(DB.Unicode)
    code_filter_type = DB.Column(DB.Unicode)
    id_filter_type = DB.Column(DB.Integer)
    id_permission = DB.Column(DB.Integer)

    def __str__(self):
        return """VUsersPermissions
            role='{}' action='{}' filter='{}' module='{}' filter_type='{}' object='{} >""".format(
            self.id_role,
            self.code_action,
            self.value_filter,
            self.module_code,
            self.code_filter_type,
            self.code_object,
        )


@serializable
class BibFiltersType(DB.Model):
    __tablename__ = "bib_filters_type"
    __table_args__ = {"schema": "gn_permissions"}
    id_filter_type = DB.Column(DB.Integer, primary_key=True)
    code_filter_type = DB.Column(DB.Unicode)
    label_filter_type = DB.Column(DB.Unicode)
    description_filter_type = DB.Column(DB.Unicode)


@serializable
class TFilters(DB.Model):
    __tablename__ = "t_filters"
    __table_args__ = {"schema": "gn_permissions"}
    id_filter = DB.Column(DB.Integer, primary_key=True)
    value_filter = DB.Column(DB.Unicode)
    label_filter = DB.Column(DB.Unicode)
    description_filter = DB.Column(DB.Unicode)
    id_filter_type = DB.Column(DB.Integer)


@serializable
class TActions(DB.Model):
    __tablename__ = "t_actions"
    __table_args__ = {"schema": "gn_permissions"}
    id_action = DB.Column(DB.Integer, primary_key=True)
    code_action = DB.Column(DB.Unicode)
    description_action = DB.Column(DB.Unicode)


cor_object_module = DB.Table(
    "cor_object_module",
    DB.Column(
        "id_cor_object_module", DB.Integer, primary_key=True,
    ),
    
    DB.Column(
        "id_object", DB.Integer,
          ForeignKey("gn_permissions.t_objects.id_object"),
    ),
    DB.Column(
        "id_module", DB.Integer,
        ForeignKey("gn_commons.t_modules.id_module"),
    ),
    schema="gn_permissions",
)

@serializable
class TObjects(DB.Model):
    __tablename__ = "t_objects"
    __table_args__ = {"schema": "gn_permissions"}
    id_object = DB.Column(DB.Integer, primary_key=True)
    code_object = DB.Column(DB.Unicode)
    description_object = DB.Column(DB.Unicode)

    def __str__(self):
        return f"{self.code_object} ({self.description_object})"

@serializable
class CorRoleActionFilterModuleObject(DB.Model):
    __tablename__ = "cor_role_action_filter_module_object"
    __table_args__ = {"schema": "gn_permissions"}
    id_permission = DB.Column(DB.Integer, primary_key=True)
    id_role = DB.Column(DB.Integer, ForeignKey("utilisateurs.t_roles.id_role"))
    id_action = DB.Column(DB.Integer, ForeignKey("gn_permissions.t_actions.id_action"))
    id_filter = DB.Column(DB.Integer, ForeignKey("gn_permissions.t_filters.id_filter"))
    id_module = DB.Column(DB.Integer, ForeignKey("gn_commons.t_modules.id_module"))
    id_object = DB.Column(
        DB.Integer,
        ForeignKey("gn_permissions.t_objects.id_object"),
        default=select([TObjects.id_object]).where(TObjects.code_object == "ALL"),
    )

    role = DB.relationship(User, primaryjoin=(User.id_role == id_role), foreign_keys=[id_role])

    action = DB.relationship(
        TActions, primaryjoin=(TActions.id_action == id_action), foreign_keys=[id_action],
    )

    filter = DB.relationship(
        TFilters,
        primaryjoin=(TFilters.id_filter == id_filter), foreign_keys=[id_filter],
    )

    module = DB.relationship("TModules")
    object = DB.relationship("TObjects")

    def is_permission_already_exist(
        self, id_role, id_action, id_module, id_filter_type, id_object=1
    ):
        """ 
            Tell if a permission exist for a user, an action, a module and a filter_type
            Return:
                A CorRoleActionFilterModuleObject if exist or None
        """
        privilege = {
            "id_role": id_role,
            "id_action": id_action,
            "id_module": id_module,
            "id_object": id_object,
        }
        return (
            DB.session.query(CorRoleActionFilterModuleObject)
            .filter_by(**privilege)
            .join(TFilters, TFilters == CorRoleActionFilterModuleObject.id_filter)
            .join(BibFiltersType, BibFiltersType.id_filter_type == TFilters.id_filter)
            .filter(BibFiltersType.id_filter_type == id_filter_type)
            .first()
        )
