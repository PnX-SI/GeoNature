import logging

import sqlalchemy as sa
from sqlalchemy.orm import exc


from pypnusershub.db.models import User
from geonature.core.gn_commons.models import TModules
from geonature.core.gn_permissions.models import (
    VUsersPermissions,
    BibFiltersType,
    BibFiltersValues,
    CorModuleActionObjectFilter,
    CorRoleActionFilterModuleObject,
    TActions,
    TObjects,
)
from geonature.utils.env import DB

log = logging.getLogger(__name__)


class PermissionRepository:
    def delete_permission_by_gathering(self, gathering):
        result = (
            DB.session
            .query(CorRoleActionFilterModuleObject)
            .filter(CorRoleActionFilterModuleObject.gathering == gathering)
            .delete()
        )
        return result

    def get_permission_available(self, module_code, action_code, object_code, filter_type_code):
        try:
            query = (
                DB.session.query(
                    CorModuleActionObjectFilter.label,
                    CorModuleActionObjectFilter.code,
                )
                .join(
                    TModules, 
                    TModules.id_module == CorModuleActionObjectFilter.id_module
                )
                .join(
                    TActions, 
                    TActions.id_action == CorModuleActionObjectFilter.id_action
                )
                .join(
                    TObjects, 
                    TObjects.id_object == CorModuleActionObjectFilter.id_object
                )
                .join(
                    BibFiltersType, 
                    BibFiltersType.id_filter_type == CorModuleActionObjectFilter.id_filter_type
                )
                .filter(TModules.module_code == module_code)
                .filter(TActions.code_action == action_code)
                .filter(TObjects.code_object == object_code)
                .filter(BibFiltersType.code_filter_type == filter_type_code)
            )
            result = query.one()
            data = {"label": result.label, "code": result.code}
        except exc.NoResultFound:
            log.warn(
                "Permission available not found for: "
                f"module={module_code}, "+
                f"action={action_code}, "+
                f"object={object_code}, "+
                f"filter_type={filter_type_code}. "
            )
            return False
        return data

    def get_all_personal_permissions(self, id_role, gatherings=None, limit_by_filter_code=None):
        query = (
            DB.session.query(
                CorRoleActionFilterModuleObject.id_role,
                CorModuleActionObjectFilter.label,
                CorModuleActionObjectFilter.code,
                TModules.module_code,
                TActions.code_action,
                TObjects.code_object,
                sa.cast(CorRoleActionFilterModuleObject.end_date, sa.Date),
                CorRoleActionFilterModuleObject.gathering,
                BibFiltersType.code_filter_type,
                CorRoleActionFilterModuleObject.value_filter
            )
            .select_from(CorRoleActionFilterModuleObject)
            .join(User, User.id_role == CorRoleActionFilterModuleObject.id_role)
            .join(CorModuleActionObjectFilter, sa.and_(
                CorModuleActionObjectFilter.id_module == CorRoleActionFilterModuleObject.id_module,
                CorModuleActionObjectFilter.id_action == CorRoleActionFilterModuleObject.id_action,
                CorModuleActionObjectFilter.id_object == CorRoleActionFilterModuleObject.id_object,
                CorModuleActionObjectFilter.id_filter_type == CorRoleActionFilterModuleObject.id_filter_type,
            ))
            .join(
                TActions, 
                TActions.id_action == CorModuleActionObjectFilter.id_action
            )
            .join(
                TObjects, 
                TObjects.id_object == CorModuleActionObjectFilter.id_object
            )
            .join(TModules, TModules.id_module == CorRoleActionFilterModuleObject.id_module)
            .join(BibFiltersType, BibFiltersType.id_filter_type == CorRoleActionFilterModuleObject.id_filter_type)
        )
        query = query.filter(User.id_role == id_role)
        if gatherings:
            query = query.filter(CorRoleActionFilterModuleObject.gathering.in_(gatherings))
        if limit_by_filter_code:
            query = query.filter(BibFiltersType.code_filter_type == limit_by_filter_code)
        return query.all()