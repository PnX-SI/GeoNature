from flask import url_for

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
    with db.session.begin_nested():
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
        dict_params["scope_value"] = scope_value
    perm = Permission(role=user, **dict_params, **kwargs)
    with db.session.begin_nested():
        db.session.add(perm)
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


@contextmanager
def set_logged_user_context(client, user):
    try:
        set_logged_user(client, user)
        yield
    finally:
        unset_logged_user(client)


def dec_permissions(expected_result=None):
    def decorator(test_func):
        @wraps(test_func)
        def wrapper(user, client, permissions, *args, **kwargs):
            # Appliquer les permissions au user
            for p in permissions:
                areas = p.get("areas", [])
                if callable(areas):
                    areas = areas()
                taxons = p.get("taxons", [])
                if callable(taxons):
                    taxons = taxons()

                create_permission(
                    user,
                    module_code=p["module_code"],
                    action_code=p["action_code"],
                    object_code=p["object_code"],
                    scope_value=p.get("scope_value", 1),
                    taxons=taxons,
                    areas=areas,
                )

            # Déterminer le résultat attendu
            if expected_result is not None:
                if isinstance(expected_result, dict):
                    # on prend le bon résultat selon la clé de paramétrage (ex: perm1)
                    key = kwargs.get("perm_name")
                    setattr(user, "expected_result", expected_result.get(key))
                else:
                    setattr(user, "expected_result", expected_result)

            # Contexte utilisateur connecté
            with set_logged_user_context(client, user):
                return test_func(user, client, permissions, *args, **kwargs)

        return wrapper

    return decorator
