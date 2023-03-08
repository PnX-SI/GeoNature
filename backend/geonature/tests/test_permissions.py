from collections import ChainMap
from itertools import product

import pytest

from geonature.core.gn_commons.models import TModules
from geonature.core.gn_permissions.models import (
    TObjects,
    TFilters,
    TActions,
    BibFiltersType,
    CorRoleActionFilterModuleObject as Permission,
)
from geonature.core.gn_permissions.tools import get_scopes_by_action
from geonature.utils.env import db

from pypnusershub.db.models import User


@pytest.fixture
def actions():
    return {action.code_action: action for action in TActions.query.all()}


@pytest.fixture
def scopes():
    scope_type = BibFiltersType.query.filter_by(code_filter_type="SCOPE").one()
    return {f.value_filter: f for f in TFilters.query.filter_by(filter_type=scope_type).all()}


def create_module(label):
    return TModules(
        module_code=label.upper(),
        module_label=label,
        module_path=label,
        active_frontend=False,
        active_backend=False,
    )


@pytest.fixture
def module_gn():
    return TModules.query.filter_by(module_code="GEONATURE").one()


@pytest.fixture
def object_all():
    return TObjects.query.filter_by(code_object="ALL").one()


@pytest.fixture
def object_a():
    obj = TObjects(code_object="object_a")
    return obj


@pytest.fixture
def object_b():
    obj = TObjects(code_object="object_b")
    return obj


@pytest.fixture
def module_a():
    with db.session.begin_nested():
        module = create_module("module_a")
        db.session.add(module)
    return module


@pytest.fixture
def module_b():
    with db.session.begin_nested():
        module = create_module("module_b")
        db.session.add(module)
    return module


@pytest.fixture
def groups():
    groups = {
        "g1": User(groupe=True),
        "g2": User(groupe=True),
    }
    with db.session.begin_nested():
        for group in groups.values():
            db.session.add(group)
    return groups


@pytest.fixture
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


@pytest.fixture
def permissions(roles, groups, actions, scopes):
    roles = ChainMap(roles, groups)

    def _permissions(role, cruved, **kwargs):
        role = roles[role]
        with db.session.begin_nested():
            for a, s in zip("CRUVED", cruved):
                if s == "-":
                    continue
                db.session.add(
                    Permission(role=role, action=actions[a], filter=scopes[s], **kwargs)
                )

    return _permissions


@pytest.fixture
def assert_cruved(roles):
    def _assert_cruved(role, cruved, module=None, object=None):
        role = roles[role]
        module_code = module.module_code if module else None
        object_code = object.code_object if object else None
        assert get_scopes_by_action(
            id_role=role.id_role, module_code=module_code, object_code=object_code
        ) == cruved_dict(cruved)

    return _assert_cruved


@pytest.mark.usefixtures("temporary_transaction")
class TestPermissions:
    def test_no_right(self, assert_cruved, module_gn, module_a, object_a):
        assert_cruved("r1", "000000")
        assert_cruved("g1_r1", "000000", module_a)
        assert_cruved("r1", "000000", module_gn, object_a)
        assert_cruved("r1", "000000", module_a, object_a)

    def test_module_perm(self, permissions, assert_cruved, module_gn, module_a):
        permissions("r1", "0123--", module=module_a)

        assert_cruved("r1", "000000")
        assert_cruved("r1", "012300", module_a)
        assert_cruved("r2", "000000", module_a)

    def test_group_inheritance(self, permissions, assert_cruved, module_gn, module_a):
        permissions("g1", "0123--", module=module_a)

        assert_cruved("r1", "000000")
        assert_cruved("r1", "000000", module_a)
        assert_cruved("g1_r1", "000000")
        assert_cruved("g1_r1", "012300", module_a)
        assert_cruved("g2_r1", "000000")
        assert_cruved("g2_r1", "000000", module_a)

    def test_user_and_group_perm(self, permissions, assert_cruved, module_a):
        permissions("g1", "0123--", module=module_a)
        permissions("g1_r1", "1023--", module=module_a)

        assert_cruved("g1_r1", "112300", module=module_a)  # max of user and group permission

    def test_module_inheritance(self, permissions, assert_cruved, module_gn, module_a, module_b):
        permissions("r1", "121---", module=module_gn)
        permissions("r1", "012123", module=module_b)

        assert_cruved("r1", "121000")
        assert_cruved("r1", "121000", module_a)  # A inherite GN permissions
        assert_cruved("r1", "012123", module_b)  # perms on B have precedence
        assert_cruved("r2", "000000")
        assert_cruved("r2", "000000", module_a)
        assert_cruved("r2", "000000", module_b)

    def test_multi_groups_one_perm(self, permissions, assert_cruved, module_a):
        permissions("g1", "0123--", module=module_a)

        assert_cruved("g1_r1", "012300", module_a)
        assert_cruved("g12_r1", "012300", module_a)
        assert_cruved("g2_r1", "000000", module_a)

    def test_multi_groups_multi_perms(self, permissions, assert_cruved, module_a):
        permissions("g1", "12131-", module=module_a)
        permissions("g2", "0121-3", module=module_a)

        assert_cruved("g1_r1", "121310", module_a)
        assert_cruved("g2_r1", "012103", module_a)
        assert_cruved("g12_r1", "122313", module_a)  # max of both groups permissions

    def test_group_module_inheritance(
        self, permissions, assert_cruved, module_gn, module_a, module_b
    ):
        permissions("g1", "121---", module=module_gn)
        permissions("g1", "012123", module=module_b)

        assert_cruved("g1_r1", "121000")
        assert_cruved("g1_r1", "121000", module_a)  # A inherite GN permissions
        assert_cruved("g1_r1", "012123", module_b)  # perms on B have precedence

    def test_group_and_user_module_inheritance(
        self, permissions, assert_cruved, module_gn, module_a
    ):
        permissions("g1", "1023--", module=module_gn)
        permissions("g1_r1", "0123--", module=module_a)

        assert_cruved("g1_r1", "102300")
        assert_cruved("g1_r2", "102300")
        assert_cruved("g1_r1", "012300", module_a)  # module A have precedence on GN
        assert_cruved("g1_r2", "102300", module_a)  # module A inherite GN perms

    def test_user_and_group_module_inheritance(
        self, permissions, assert_cruved, module_gn, module_a
    ):
        permissions("g1_r1", "0123--", module=module_gn)
        permissions("g1", "1023--", module=module_a)

        assert_cruved("g1_r1", "012300")
        assert_cruved("g1_r2", "000000")  # no perm on GN
        assert_cruved("g1_r1", "102300", module_a)  # module A have precedence on GN
        assert_cruved("g1_r2", "102300", module_a)  # module A perm through group

    def test_multi_group_module_inheritance(
        self, permissions, assert_cruved, module_gn, module_a, module_b
    ):
        permissions("g1", "121-1-", module=module_gn)
        permissions("g2", "2101-3", module=module_gn)
        permissions("g1", "0121-2", module=module_b)

        assert_cruved("g12_r1", "221113")  # max of both permissions
        assert_cruved("g12_r1", "221113", module_a)  # A inherite max of GN permissions
        assert_cruved("g12_r1", "012112", module_b)  # perms on B have precedence

        assert_cruved("g1_r1", "121010")
        assert_cruved("g2_r1", "210103")
        assert_cruved("g1_r1", "121010", module_a)  # A inherite GN permissions
        assert_cruved("g1_r1", "012112", module_b)  # perms on B have precedence
        assert_cruved("g2_r1", "210103", module_a)  # A inherite GN permissions
        assert_cruved("g2_r1", "210103", module_b)  # B inherite GN permissions

    def test_object_perm(self, permissions, assert_cruved, module_a, module_b, object_a, object_b):
        permissions("r1", "1----2", module=module_a)
        permissions("r1", "-1---1", module=module_a, object=object_a)
        permissions("r1", "--1---", module=module_b, object=object_a)
        permissions("r1", "---1--", module=module_a, object=object_b)

        assert_cruved("r1", "000000")
        assert_cruved("r1", "100002", module_a)
        assert_cruved("r1", "110001", module_a, object_a)
        assert_cruved("r1", "001000", module_b, object_a)
        assert_cruved("r1", "100102", module_a, object_b)

    def test_object_inheritance(
        self,
        permissions,
        assert_cruved,
        module_gn,
        module_a,
        module_b,
        object_all,
        object_a,
        object_b,
    ):
        permissions("r1", "1-----", module=module_gn, object=object_all)
        permissions("r1", "-1----", module=module_gn, object=object_a)
        permissions("r1", "--1---", module=module_a, object=object_all)
        permissions("r1", "---1--", module=module_a, object=object_a)

        assert_cruved("r1", "111100", module_a, object_a)

    def test_object_priority(
        self,
        permissions,
        assert_cruved,
        module_gn,
        module_a,
        module_b,
        object_all,
        object_a,
        object_b,
    ):
        permissions("r1", "222---", module=module_gn, object=object_all)
        permissions("r1", "1--22-", module=module_gn, object=object_a)
        permissions("r1", "-1-1-2", module=module_a, object=object_all)
        permissions("r1", "--1-11", module=module_a, object=object_a)

        assert_cruved("r1", "222000", module_gn, object_all)
        assert_cruved("r1", "122220", module_gn, object_a)
        assert_cruved("r1", "212102", module_a, object_all)
        assert_cruved("r1", "111111", module_a, object_a)
