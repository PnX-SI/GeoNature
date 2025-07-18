import logging

from itertools import groupby, permutations

import sqlalchemy as sa
from sqlalchemy.orm import joinedload, selectinload
from sqlalchemy.dialects.postgresql import array_agg, aggregate_order_by
from flask import has_request_context, g

from geonature.core.gn_commons.models import TModules
from geonature.core.gn_permissions.models import (
    PermAction,
    PermObject,
    PermScope,
    Permission,
    cor_permission_area,
    cor_permission_taxref,
)
from geonature.utils.env import db

from pypnusershub.db.models import User
from apptax.taxonomie.models import Taxref

log = logging.getLogger()


def _get_user_permissions(id_role):
    # This subquery create a list of areas which is used to identify duplicated permissions.
    areas_filter_query = (
        sa.select(
            cor_permission_area.c.id_permission,
            array_agg(
                aggregate_order_by(cor_permission_area.c.id_area, cor_permission_area.c.id_area),
            ).label("areas_filter"),
        )
        .group_by(cor_permission_area.c.id_permission)
        .subquery()
    )
    taxons_filter_query = (
        sa.select(
            cor_permission_taxref.c.id_permission,
            array_agg(
                aggregate_order_by(cor_permission_taxref.c.cd_nom, cor_permission_taxref.c.cd_nom),
            ).label("taxons_filter"),
        )
        .group_by(cor_permission_taxref.c.id_permission)
        .subquery()
    )
    query = (
        sa.select(Permission)
        .options(
            joinedload(Permission.module),
            joinedload(Permission.object),
            joinedload(Permission.action),
            selectinload(Permission.areas_filter),
            selectinload(Permission.taxons_filter).joinedload(Taxref.tree),
        )
        .outerjoin(areas_filter_query)
        .outerjoin(taxons_filter_query)
        .where(
            Permission.active_filter(),
            sa.or_(
                # direct permissions
                Permission.id_role == id_role,
                # permissions through group
                # FIXME : provoke a cartesian product warning (but )
                Permission.role.has(User.members.any(User.id_role == id_role)),
            ),
        )
        .order_by(Permission.id_module, Permission.id_object, Permission.id_action)
        # Remove duplicate permissions (typically overlapping user-level and group-level permissions)
        .distinct(
            Permission.id_module,
            Permission.id_object,
            Permission.id_action,
            *[
                getattr(Permission, v)
                for v in Permission.filters_fields.values()
                if v in Permission.__mapper__.columns
            ],
            areas_filter_query.c.areas_filter,
            taxons_filter_query.c.taxons_filter,
        )
    )
    return db.session.scalars(query).all()


def get_user_permissions(id_role=None):
    if id_role is None:
        id_role = g.current_user.id_role
    if has_request_context():
        if id_role not in g._permissions_by_user:
            g._permissions_by_user[id_role] = _get_user_permissions(id_role)
        return g._permissions_by_user[id_role]
    else:
        return _get_user_permissions(id_role)


def _get_permissions(id_role, module_code, object_code, action_code):
    permissions = {
        p
        for p in get_user_permissions(id_role)
        if p.module.module_code == module_code
        and p.object.code_object == object_code
        and p.action.code_action == action_code
    }

    # Remove all permissions supersed by another permission
    # /!\ if p1 == p2, both will be removed!
    # Ensure to eliminate all duplicates when querying permissions
    for p1, p2 in permutations(permissions, 2):
        if p1 in permissions and p1 <= p2:
            permissions.remove(p1)

    return permissions


def get_permissions(action_code, id_role=None, module_code=None, object_code=None):
    """
    This function returns a set of all the permissions that match (action_code, id_role, module_code, object_code).
    If module_code is None, it is set as the code of the current module or as "GEONATURE" if no current module found.
    If object_code is None, it is set as the code of the current object or as "ALL" if no current object found.

    :returns : the list of permissions that match, and an empty list if no match
    """
    if module_code is None:
        if hasattr(g, "current_module"):
            module_code = g.current_module.module_code
        else:
            module_code = "GEONATURE"

    if object_code is None:
        if hasattr(g, "current_object"):
            object_code = g.current_object.code_object
        else:
            object_code = "ALL"

    ident = (id_role, module_code, object_code, action_code)
    if has_request_context():
        if ident not in g._permissions:
            g._permissions[ident] = _get_permissions(*ident)
        return g._permissions[ident]
    else:
        return _get_permissions(*ident)


def get_scope(action_code, id_role=None, module_code=None, object_code=None, bypass_warning=False):
    """
    This function gets the final scope permission.

    It takes the maximum for all the permissions that match (action_code, id_role, module_code, object_code) and with
    of a "SCOPE" filter type.

    :returns : (int) The scope computed for specified arguments
    """
    permissions = get_permissions(action_code, id_role, module_code, object_code)
    max_scope = 0
    for permission in permissions:
        if permission.has_other_filters_than("SCOPE") and not bypass_warning:
            log.warning(
                f"""WARNING : You are trying to get scope permission for a module ({module_code}) which implements other permissions type. Please use get_permission instead
            """
            )
        if permission.scope_value is None:
            max_scope = 3
        else:
            max_scope = max(max_scope, permission.scope_value)
    return max_scope


def get_scopes_by_action(id_role=None, module_code=None, object_code=None):
    """
    This function gets the scopes permissions for each one of the 6 actions in "CRUVED",
    that match (id_role, module_code, object_code)

    :returns : (dict) A dict of the scope for each one of the 6 actions (the char in "CRUVED")
    """
    return {
        action_code: get_scope(action_code, id_role, module_code, object_code)
        for action_code in "CRUVED"
    }


def has_any_permissions(action_code, id_role=None, module_code=None, object_code=None) -> bool:
    """
    This function return the scope for an action, a module and an object as a Boolean
    Use for frontend
    """
    permissions = get_permissions(action_code, id_role, module_code, object_code)
    return len(permissions) > 0


def has_any_permissions_by_action(id_role=None, module_code=None, object_code=None):
    """
    This function gets the scopes permissions for each one of the 6 actions in "CRUVED",
    that match (id_role, module_code, object_code)

    :returns : (dict) A dict of the boolean for each one of the 6 actions (the char in "CRUVED")
    """
    return {
        action_code: has_any_permissions(action_code, id_role, module_code, object_code)
        for action_code in "CRUVED"
    }
