"""
Modèles du schema gn_permissions
"""


from sqlalchemy import ForeignKey
from sqlalchemy.sql import select
from sqlalchemy.dialects.postgresql import JSONB, UUID

from utils_flask_sqla.serializers import serializable
from pypnusershub.db.models import User

from geonature.core.gn_commons.models import TModules
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

    def __repr__(self):
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


@serializable
class TObjects(DB.Model):
    __tablename__ = "t_objects"
    __table_args__ = {"schema": "gn_permissions"}
    id_object = DB.Column(DB.Integer, primary_key=True)
    code_object = DB.Column(DB.Unicode)
    description_object = DB.Column(DB.Unicode)


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

    role = DB.relationship(
        User,
        primaryjoin=(User.id_role == id_role),
        foreign_keys=[id_role],
    )
    action = DB.relationship(
        TActions,
        primaryjoin=(TActions.id_action == id_action),
        foreign_keys=[id_action],
    )
    filter = DB.relationship(
        TFilters,
        primaryjoin=(TFilters.id_filter == id_filter),
        foreign_keys=[id_filter],
        uselist=True,
    )
    module = DB.relationship(
        TModules,
        primaryjoin=(TModules.id_module == id_module),
        foreign_keys=[id_module],
    )
    object = DB.relationship(
        TObjects,
        primaryjoin=(TObjects.id_object == id_object),
        foreign_keys=[id_object],
    )

    def is_permission_already_exist(
        self, id_role, id_action, id_module, id_filter_type, value_filter, id_object=1
    ):
        """ Retourne la première permission trouvée pour un utilisateur,
            une action, un module et un type de filtre.

            Parameters
            ----------
            id_role : int
                Identifiant de l'utilisateur (=role)
            id_action : int
                Identifiant de l'action.
            id_module : int
                Identifiant du module.
            id_filter_type : int
                Identifiant du type de filtre.
            id_object : int, optional
                Identifiant de l'objet.

            Returns
            -------
            CorRoleActionFilterModuleObject or None
                Un objet CorRoleActionFilterModuleObject s'il existe ou sinon None.
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
            .join(TFilters, TFilters.id_filter == CorRoleActionFilterModuleObject.id_filter)
            .filter(TFilters.id_filter_type == id_filter_type)
            .filter(TFilters.value_filter == value_filter)
            .first()
        )


@serializable
class CorObjectModule(DB.Model):
    __tablename__ = "cor_object_module"
    __table_args__ = {"schema": "gn_permissions"}
    id_cor_object_module = DB.Column(DB.Integer, primary_key=True)
    id_object = DB.Column(DB.Integer)
    id_module = DB.Column(DB.Integer)


@serializable
class CorRequestsPermissions(DB.Model):
    __tablename__ = "cor_requests_permissions"
    __table_args__ = {"schema": "gn_permissions"}
    id_request_permission = DB.Column(DB.Integer, primary_key=True)
    id_request = DB.Column(
        DB.Integer,
        ForeignKey("gn_permissions.t_requests.id_request"),
    )
    id_module = DB.Column(
        DB.Integer,
        ForeignKey("gn_commons.t_modules.id_module"),
    )
    id_action = DB.Column(
        DB.Integer,
        ForeignKey("gn_permissions.t_actions.id_action"),
    )
    id_object = DB.Column(
        DB.Integer,
        ForeignKey("gn_permissions.t_objects.id_object"),
    )
    id_filter_type = DB.Column(
        DB.Integer,
        ForeignKey("gn_permissions.bib_filters_type.id_filter_type"),
    )
    value_filter = DB.Column(DB.Unicode)

    cor_module = DB.relationship(
        TModules,
        primaryjoin=(TModules.id_module == id_module),
        foreign_keys=[id_module],
    )
    cor_action = DB.relationship(
        TActions,
        primaryjoin=(TActions.id_action == id_action),
        foreign_keys=[id_action],
    )
    cor_object = DB.relationship(
        TObjects,
        primaryjoin=(TObjects.id_object == id_object),
        foreign_keys=[id_object],
    )
    cor_filter = DB.relationship(
        BibFiltersType,
        primaryjoin=(BibFiltersType.id_filter_type == id_filter_type),
        foreign_keys=[id_filter_type],
    )


@serializable
class TRequests(DB.Model):
    __tablename__ = "t_requests"
    __table_args__ = {"schema": "gn_permissions"}
    id_request = DB.Column(DB.Integer, primary_key=True)
    id_role = DB.Column(DB.Integer, ForeignKey("utilisateurs.t_roles.id_role"))
    token = DB.Column(UUID(as_uuid=True), server_default="uuid_generate_v4()")
    end_date = DB.Column(DB.DateTime)
    accepted = DB.Column(DB.Boolean)
    accepted_date = DB.Column(DB.DateTime)
    additional_data = DB.Column(JSONB)
    meta_create_date = DB.Column(DB.DateTime, default="now()")
    meta_update_date = DB.Column(DB.DateTime, default="now()")

    cor_permissions = DB.relationship(
        CorRequestsPermissions,
        lazy="joined",
        primaryjoin=(CorRequestsPermissions.id_request == id_request),
        foreign_keys=[CorRequestsPermissions.id_request],
    )

    cor_role = DB.relationship(
        User,
        primaryjoin=(User.id_role == id_role),
        foreign_keys=[id_role],
    )
