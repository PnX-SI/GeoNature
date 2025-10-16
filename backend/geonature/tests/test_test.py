from .fixtures import client
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
        dict_params["scope_value"] = PermScope.query.filter_by(value=scope_value).one()
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


def dec_permissions(perm, expected_result=None):
    def decorator(test_func):
        @wraps(test_func)
        def wrapper(user, client, *args, **kwargs):
            for p in perm:
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

            if expected_result is not None:
                setattr(user, "expected_result", expected_result)

            with set_logged_user_context(client, user):
                return test_func(user, client, *args, **kwargs)

        return wrapper
    return decorator


@pytest.fixture()
def user():
    return create_user(dict(nom_role="Utilisateur", prenom_role="Test", identifiant="test_user"))

@pytest.fixture()
def user2():
    return create_user(dict(nom_role="Utilisateur", prenom_role="Test2", identifiant="test_user2"))



@pytest.mark.parametrize("user", [user,user2],indirect=True)
@pytest.mark.usefixtures("client")
@dec_permissions(
    perm=[
        dict(
            module_code="SYNTHESE",
            action_code=ACTION.R,
            object_code="ALL",
            scope_value=3,
            areas=lambda: [LAreas.query.filter_by(area_name="Gap").one()],
        )
    ],
    expected_result=1  # Résultat attendu pour ce test spécifique
)
def test_test(user,client):
    # Exemple de test : vérifier que l'utilisateur a les bonnes permissions
    assert len(user.permissions) > 0
    # Vérifier le résultat attendu si nécessaire
    if hasattr(user, 'expected_result'):
        assert user.expected_result == 1  # Ajuste selon la logique de ton test

# @pytest.mark.parametrize("user", [user,user2],indirect=True)
# @pytest.mark.parametrize("permissions",{"perm1":[
#         dict(
#             module_code="SYNTHESE",
#             action_code=ACTION.R,
#             object_code="ALL",
#             scope_value=3,
#             areas=lambda: [LAreas.query.filter_by(area_name="Gap").one()],
#         )
#     ]})
# @pytest.mark.usefixtures("client")
# @dec_permissions(expected_result={"perm1":1})
# def test_test(user,client):
#     # Exemple de test : vérifier que l'utilisateur a les bonnes permissions
#     assert len(user.permissions) > 0
#     # Vérifier le résultat attendu si nécessaire
#     if hasattr(user, 'expected_result'):
#         assert user.expected_result == 1  # Ajuste selon la logique de ton test



# @pytest.mark.usefixtures("client")
# @with_dynamic_users(
#     [
#         dict(
#             user=dict(nom_role="Utilisateur", prenom_role="Test", identifiant="test_user"),
#             organisme=dict(nom_organisme="test orga"),
#             perm=[
#                 dict(
#                     module_code="SYNTHESE",
#                     action_code=ACTION.R,
#                     object_code="ALL",
#                     scope_value=3,
#                     areas=lambda: [LAreas.query.filter_by(area_name="Gap").one()],
#                 )
#             ],
#         ),
#         dict(
#             user=dict(
#                 nom_role="Utilisateur2",
#                 prenom_role="Test2",
#                 identifiant="test_user2",
#             ),
#             perm=[
#                 # dict(module_code="SYNTHESE", action_code=ACTION.R, object_code="ALL", scope_value=3)
#             ],
#         ),
#     ]
# )
# def test_user(client):
#     # print("aa")
#     response = client.get(url_for("auth.get_user_data"))
#     # print("-", response.json["user"], "-")

# print(test_user)
