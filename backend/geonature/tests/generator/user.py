from contextlib import contextmanager
from enum import Enum
from functools import wraps
from typing import Optional
from pypnusershub.tests.utils import set_logged_user, unset_logged_user
import pytest
from ref_geo.models import LAreas
from apptax.taxonomie.models import Taxref
from geonature.core.gn_commons.models.base import TModules
from geonature.core.gn_permissions.models import PermAction, PermObject, PermScope, Permission
from pypnusershub.db.models import Organisme, User
from inspect import isfunction
from geonature.utils.env import db
import sqlalchemy as sa


# from ..fixtures import client


class ACTION:
    R = "R"
    C = "C"
    U = "U"
    D = "D"
    V = "V"
    E = "E"


class MODULE:
    SYNTHESE = "SYNTHESE"
    OCCHAB = "OCCHAB"
    OCCTAX = "OCCTAX"
    VALIDATION = "VALIDATION"
    METADATA = "METADATA"


def create_user(user_spec: dict, organisme: Optional[Organisme] = None) -> User:
    user = User(**user_spec)
    if organisme:
        if isfunction(organisme):
            organisme = organisme()
        user.id_organisme = organisme.id_organisme
    db.session.add(user)
    return user


def create_permission(
    user: User,
    module_code: str,
    action_code: str,
    object_code: str,
    scope_value: int,
    taxons: Taxref = [],
    areas: LAreas = [],
    **kwargs,
) -> User:
    module = TModules.query.filter_by(module_code=module_code).one()
    action = PermAction.query.filter_by(code_action=action_code).one()
    object_ = PermObject.query.filter_by(code_object=object_code).one()
    dict_params = dict(
        action=action, module=module, object=object_, taxons_filter=taxons, areas_filter=areas
    )
    if scope_value and 0 < scope_value < 3:
        dict_params["scope_value"] = PermScope.query.filter_by(value=scope_value).one()
    perm = Permission(role=user, **dict_params, **kwargs)

    return perm


def create_organisme(orga_dict):
    is_in_db = db.session.scalar(
        sa.exists(Organisme)
        .where(*[getattr(Organisme, key) == value for key, value in orga_dict.items()])
        .select()
    )
    if is_in_db:
        return Organisme.query.filter_by(orga_dict).one()
    org = Organisme(**orga_dict)
    with db.session.begin_nested():
        db.session.add(org)
    return org


def with_dynamic_users(user_specs):
    """Décorateur compatible avec les fixtures pytest"""

    def decorator(test_func):
        @wraps(test_func)
        def wrapper(client, *args, **kwargs):
            created_users = []
            with db.session.begin_nested():
                for spec in user_specs:
                    org= None
                    if orga_dict := spec.get("organisme"):
                        org = create_organisme(orga_dict)
 
                    user = create_user(user_spec=spec["user"],organisme=org)

                    created_users.append(user)

                    for perm_spec in spec.get("perm", []): 
                        if "areas" in perm_spec:
                            perm_spec["areas"] = perm_spec["areas"]()
                        if "taxons" in perm_spec:
                            perm_spec["taxons"] = perm_spec["taxons"]()
                        perm = create_permission(user, **perm_spec)
                        db.session.add(perm)

            for user in created_users:
                test_name = f"user_{user.id_role}"
                
                marked_test = pytest.mark.user(test_name)(test_func)
                print(f"🧪 Exécution du test pour {test_name}")
                with set_logged_user_context(client, user):
                    result = marked_test(client, *args, **kwargs)  # Passe client et user
            return result

        return wrapper

    return decorator


@contextmanager
def set_logged_user_context(client, user):
    try:
        set_logged_user(client, user)
        yield
    finally:
        unset_logged_user(client)

