from collections import ChainMap
from itertools import product

import pytest

from flask import g

from geonature.core.gn_commons.models import TModules
from geonature.core.gn_permissions.models import (
    PermObject,
    PermAction,
    PermFilterType,
    Permission,
    PermissionAvailable,
)
from geonature.core.gn_permissions.tools import get_scopes_by_action
from geonature.utils.env import db

from pypnusershub.db.models import User


@pytest.fixture(scope="class")
def actions():
    return {action.code_action: action for action in PermAction.query.all()}


def create_module(label):
    return TModules(
        module_code=label.upper(),
        module_label=label,
        module_path=label,
        active_frontend=False,
        active_backend=False,
    )


@pytest.fixture(scope="class")
def module_gn():
    return TModules.query.filter_by(module_code="GEONATURE").one()


@pytest.fixture(scope="class")
def object_all():
    return PermObject.query.filter_by(code_object="ALL").one()


@pytest.fixture(scope="class")
def object_a():
    obj = PermObject(code_object="object_a")
    return obj


@pytest.fixture(scope="class")
def object_b():
    obj = PermObject(code_object="object_b")
    return obj


@pytest.fixture(scope="class")
def module_a():
    with db.session.begin_nested():
        module = create_module("module_a")
        db.session.add(module)
    return module


@pytest.fixture(scope="class")
def module_b():
    with db.session.begin_nested():
        module = create_module("module_b")
        db.session.add(module)
    return module


@pytest.fixture()
def groups():
    groups = {
        "g1": User(groupe=True),
        "g2": User(groupe=True),
    }
    with db.session.begin_nested():
        for group in groups.values():
            db.session.add(group)
    return groups


@pytest.fixture()
def roles(groups):
    roles = {
        "r1": User(),
        "r2": User(),
        "g1_r1": User(groups=[groups["g1"]]),
        "g1_r2": User(groups=[groups["g1"]]),
        "g2_r1": User(groups=[groups["g2"]]),
        "g2_r2": User(groups=[groups["g2"]]),
        "g12_r1": User(groups=[groups["g1"], groups["g2"]]),
        "g12_r2": User(groups=[groups["g1"], groups["g2"]]),
    }
    with db.session.begin_nested():
        for role in roles.values():
            db.session.add(role)
    return roles


def cruved_dict(scopes):
    scopes = str(scopes)
    return {
        "C": int(scopes[0]),
        "R": int(scopes[1]),
        "U": int(scopes[2]),
        "V": int(scopes[3]),
        "E": int(scopes[4]),
        "D": int(scopes[5]),
    }


@pytest.fixture()
def permissions(roles, groups, actions, module_gn):
    roles = ChainMap(roles, groups)

    def _permissions(role, cruved, *, module=module_gn, **kwargs):
        role = roles[role]
        scope_type = PermFilterType.query.filter_by(code_filter_type="SCOPE").one()
        with db.session.begin_nested():
            for a, s in zip("CRUVED", cruved):
                if s == "-":
                    continue
                elif s == "3":
                    s = None
                else:
                    s = int(s)
                db.session.add(
                    Permission(
                        role=role, action=actions[a], module=module, scope_value=s, **kwargs
                    )
                )

    return _permissions


@pytest.fixture()
def permissions_available(object_all, actions):
    def _permissions_available(
        module, str_actions, object=object_all, scope=False, sensitivity=False
    ):
        with db.session.begin_nested():
            for action in str_actions:
                if action == "-":
                    continue
            else:
                print(actions)

                db.session.add(
                    PermissionAvailable(
                        id_module=module.id_module,
                        id_object=object.id_object,
                        id_action=actions[action].id_action,
                        scope_filter=scope,
                        sensitivity_filter=sensitivity,
                    )
                )

    return _permissions_available


@pytest.fixture()
def assert_cruved(roles):
    def _assert_cruved(role, cruved, module=None, object=None):
        role = roles[role]
        module_code = module.module_code if module else None
        object_code = object.code_object if object else None
        assert get_scopes_by_action(
            id_role=role.id_role, module_code=module_code, object_code=object_code
        ) == cruved_dict(cruved)

    return _assert_cruved


@pytest.fixture(scope="class")
def g_permissions():
    """
    Fixture to initialize flask g variable
    Mandatory if we want to run this test file standalone
    """
    g._permissions_by_user = {}
    g._permissions = {}


@pytest.mark.usefixtures("temporary_transaction", "g_permissions")
class TestPermissions:
    def test_no_right(self, assert_cruved, module_gn, module_a, object_a, g_permissions):
        assert_cruved("r1", "000000")
        assert_cruved("g1_r1", "000000", module_a)
        assert_cruved("r1", "000000", module_gn, object_a)
        assert_cruved("r1", "000000", module_a, object_a)

    def test_module_perm(self, permissions, assert_cruved, module_gn, module_a, module_b):
        permissions("r1", "1----2", module=module_gn)
        permissions("r1", "-1---1", module=module_a)
        permissions("r1", "--1---", module=module_b)

        assert_cruved("r1", "100002")
        assert_cruved("r1", "010001", module_a)
        assert_cruved("r1", "001000", module_b)
        assert_cruved("r2", "000000", module_a)

    def test_no_module_no_object_specified(
        self, permissions, assert_cruved, module_gn, object_all, module_a, object_a
    ):
        permissions("r1", "11----", module=module_gn, object=object_all)
        permissions("r1", "--11--", module=module_gn, object=object_a)
        permissions("r1", "----11", module=module_a, object=object_all)

        assert_cruved("r1", "110000", module=module_gn)
        assert_cruved("r1", "110000", object=object_all)
        assert_cruved("r1", "110000")

        assert_cruved("r1", "001100", object=object_a)

        assert_cruved("r1", "000011", module=module_a)

    def test_group_inheritance(self, permissions, assert_cruved, module_gn, module_a):
        permissions("g1", "-123--", module=module_a)

        assert_cruved("r1", "000000")
        assert_cruved("r1", "000000", module_a)
        assert_cruved("g1_r1", "000000")
        assert_cruved("g1_r1", "012300", module_a)
        assert_cruved("g2_r1", "000000")
        assert_cruved("g2_r1", "000000", module_a)

    def test_user_and_group_perm(self, permissions, assert_cruved, module_a):
        permissions("g1", "-123--", module=module_a)
        permissions("g1_r1", "1-23--", module=module_a)

        assert_cruved("g1_r1", "112300", module=module_a)  # max of user and group permission

    def test_multi_groups_one_perm(self, permissions, assert_cruved, module_a):
        permissions("g1", "-123--", module=module_a)

        assert_cruved("g1_r1", "012300", module_a)
        assert_cruved("g12_r1", "012300", module_a)
        assert_cruved("g2_r1", "000000", module_a)

    def test_multi_groups_multi_perms(self, permissions, assert_cruved, module_a):
        permissions("g1", "12131-", module=module_a)
        permissions("g2", "-121-3", module=module_a)

        assert_cruved("g1_r1", "121310", module_a)
        assert_cruved("g2_r1", "012103", module_a)
        assert_cruved("g12_r1", "122313", module_a)  # max of both groups permissions

    def test_object_perm(self, permissions, assert_cruved, module_a, module_b, object_a, object_b):
        permissions("r1", "1----2", module=module_a)
        permissions("r1", "-1---1", module=module_a, object=object_a)
        permissions("r1", "--1---", module=module_b, object=object_a)
        permissions("r1", "---1--", module=module_a, object=object_b)

        assert_cruved("r1", "000000")
        assert_cruved("r1", "100002", module_a)
        assert_cruved("r1", "010001", module_a, object_a)
        assert_cruved("r1", "001000", module_b, object_a)
        assert_cruved("r1", "000100", module_a, object_b)

    def test_multiple_scope_with_permissions_available(
        self, permissions, permissions_available, assert_cruved, module_a
    ):
        # scope cruved must be 3 even if other permissions that scope are declared
        permissions_available(module_a, "CRUVED", scope=True, sensitivity=True)
        permissions("r1", "333333", module=module_a, sensitivity_filter=True)
        assert_cruved("r1", "333333", module_a)
