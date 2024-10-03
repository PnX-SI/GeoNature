from collections import ChainMap
from datetime import datetime, timedelta
from itertools import product
from copy import deepcopy

from marshmallow.exceptions import ValidationError
import pytest
from flask import g
import sqlalchemy as sa

from geonature.core.gn_commons.models import TModules
from geonature.core.gn_permissions.models import (
    PermObject,
    PermAction,
    PermFilterType,
    Permission,
    PermissionAvailable,
)
from geonature.core.gn_permissions.tools import (
    get_permissions,
    get_scopes_by_action,
    has_any_permissions_by_action,
)
from geonature.core.gn_permissions.schemas import PermissionSchema
from geonature.utils.env import db

from pypnusershub.db.models import User
from apptax.taxonomie.models import Taxref

from ref_geo.models import BibAreasTypes, LAreas
from sqlalchemy import select, null


@pytest.fixture(scope="class")
def actions():
    return {action.code_action: action for action in db.session.scalars(select(PermAction)).all()}


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
    return db.session.execute(select(TModules).filter_by(module_code="GEONATURE")).scalar_one()


@pytest.fixture(scope="class")
def object_all():
    return db.session.execute(select(PermObject).filter_by(code_object="ALL")).scalar_one()


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


def b_cruved(code: str) -> dict:
    return {action: bool(int(b)) for action, b in zip("CRUVED", code)}


@pytest.fixture()
def permissions(roles, groups, actions, module_gn):
    roles = ChainMap(roles, groups)

    def _permissions(role, cruved, *, module=module_gn, **kwargs):
        role = roles[role]
        scope_type = db.session.execute(
            select(PermFilterType).filter_by(code_filter_type="SCOPE")
        ).scalar_one()
        perms = {}
        with db.session.begin_nested():
            for a, s in zip("CRUVED", cruved):
                if s == "-":
                    continue
                elif s == "3":
                    s = None
                else:
                    s = int(s)
                perms[a] = Permission(
                    role=role, action=actions[a], module=module, scope_value=s, **kwargs
                )
                db.session.add(perms[a])
        return perms

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


@pytest.fixture()
def assert_permissions(roles):
    def _assert_permissions(role, action_code, expected_perms, module=None, object=None):
        role = roles[role]
        module_code = module.module_code if module else None
        object_code = object.code_object if object else None
        perms = get_permissions(
            id_role=role.id_role,
            action_code=action_code,
            module_code=module_code,
            object_code=object_code,
        )
        perms = set(
            (
                p.scope_value,
                p.sensitivity_filter,
                frozenset(p.areas_filter),
                frozenset(p.taxons_filter),
            )
            for p in perms
        )
        expected_perms = set(
            (
                (
                    p.get("SCOPE", None),
                    p.get("SENSITIVITY", False),
                    frozenset(p.get("AREAS", [])),
                    frozenset(p.get("TAXONS", [])),
                )
                for p in expected_perms
            )
        )
        assert perms == expected_perms

    return _assert_permissions


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

    def test_has_any_perms(
        self, permissions, permissions_available, assert_cruved, module_a, roles
    ):
        # scope cruved must be 3 even if other permissions that scope are declared
        permissions_available(module_a, "CRUVED", scope=True, sensitivity=True)
        permissions("r1", "333---", module=module_a, sensitivity_filter=False)

        assert has_any_permissions_by_action(
            id_role=roles["r1"].id_role, module_code=module_a.module_code
        ) == b_cruved("111000")

        permissions("r2", "333333", module=module_a, sensitivity_filter=True)
        assert has_any_permissions_by_action(
            id_role=roles["r2"].id_role, module_code=module_a.module_code
        ) == b_cruved("111111")

    def test_expired_perm(self, permissions, assert_cruved):
        """
        Expired permissions should not been taken into account.
        Permissons with expire_on=NULL should be considered active.
        """
        permissions("r1", "1-----")
        permissions("r1", "-1----", expire_on=None)
        permissions("r1", "--1---", expire_on=datetime.now() - timedelta(days=1))
        permissions("r1", "---1--", expire_on=datetime.now() + timedelta(days=1))

        assert_cruved("r1", "110100")

    def test_validation_perm(self, permissions, assert_cruved):
        """
        Permission not yet validated or refused should be ignored.
        """
        permissions("r1", "1-----")  # validation status default to True
        permissions("r1", "-1----", validated=null())  # validation pending
        permissions("r1", "--1---", validated=False)  # permission refused
        permissions("r1", "---1--", validated=True)  # permission granted

        assert_cruved("r1", "100100")


@pytest.mark.usefixtures("temporary_transaction", "g_permissions")
class TestPermissionsFilters:
    def test_sensitivity_filter(self, roles, permissions, assert_permissions):
        permissions("r1", "1-----")
        permissions("r1", "-1----", sensitivity_filter=False)
        permissions("r1", "--1---", sensitivity_filter=True)

        assert_permissions("r1", "C", [{"SCOPE": 1, "SENSITIVITY": False}])
        assert_permissions("r1", "R", [{"SCOPE": 1, "SENSITIVITY": False}])
        assert_permissions("r1", "U", [{"SCOPE": 1, "SENSITIVITY": True}])

    def test_sensitivity_filter_overlap(self, permissions, assert_permissions):
        permissions("g1", "1-----", sensitivity_filter=True)
        permissions("g2", "1-----", sensitivity_filter=False)
        permissions("g1", "-1----", sensitivity_filter=True)
        permissions("g2", "-2----", sensitivity_filter=False)
        permissions("g1", "--2---", sensitivity_filter=True)
        permissions("g2", "--1---", sensitivity_filter=False)

        # g2 permisson is superior
        assert_permissions("g12_r1", "C", [{"SCOPE": 1, "SENSITIVITY": False}])

        # g2 permisson is superior
        assert_permissions("g12_r1", "R", [{"SCOPE": 2, "SENSITIVITY": False}])

        # g1 and g2 permissions can not be simplified
        assert_permissions(
            "g12_r1", "U", [{"SCOPE": 2, "SENSITIVITY": True}, {"SCOPE": 1, "SENSITIVITY": False}]
        )

    def test_geographic_filter(self, roles, permissions, assert_permissions):
        grenoble = db.session.execute(
            sa.select(LAreas).where(
                LAreas.area_type.has(BibAreasTypes.type_code == "COM"),
                LAreas.area_name == "Grenoble",
            )
        ).scalar_one()

        permissions("r1", "1-----")
        permissions("r1", "-1----", areas_filter=[])
        permissions("r1", "--1---", areas_filter=[grenoble])

        assert_permissions("r1", "C", [{"SCOPE": 1, "AREAS": []}])
        assert_permissions("r1", "R", [{"SCOPE": 1, "AREAS": []}])
        assert_permissions("r1", "U", [{"SCOPE": 1, "AREAS": [grenoble]}])

    def test_geographic_filter_overlap(self, roles, permissions, assert_permissions):
        grenoble = db.session.execute(
            sa.select(LAreas).where(
                LAreas.area_type.has(BibAreasTypes.type_code == "COM"),
                LAreas.area_name == "Grenoble",
            )
        ).scalar_one()
        gap = db.session.execute(
            sa.select(LAreas).where(
                LAreas.area_type.has(BibAreasTypes.type_code == "COM"),
                LAreas.area_name == "Gap",
            )
        ).scalar_one()

        assert Permission(areas_filter=[gap]) <= Permission(areas_filter=[gap])
        assert not Permission(areas_filter=[gap]) <= Permission(areas_filter=[grenoble])
        assert not Permission(areas_filter=[grenoble]) <= Permission(areas_filter=[gap])

        permissions("g1", "1-----", areas_filter=[grenoble])
        permissions("g2", "1-----", areas_filter=[])
        permissions("g1", "-1----", areas_filter=[grenoble])
        permissions("g2", "-2----", areas_filter=[])
        permissions("g1", "--2---", areas_filter=[grenoble])
        permissions("g2", "--1---", areas_filter=[])
        permissions("g1", "---1--", areas_filter=[grenoble])
        permissions("g2", "---2--", areas_filter=[grenoble])
        permissions("g1", "----1-", areas_filter=[grenoble, gap])
        permissions("g2", "----2-", areas_filter=[grenoble])
        permissions("g1", "-----1", areas_filter=[grenoble])
        permissions("g2", "-----2", areas_filter=[grenoble, gap])

        assert_permissions("g12_r1", "C", [{"SCOPE": 1, "AREAS": []}])
        assert_permissions("g12_r1", "R", [{"SCOPE": 2, "AREAS": []}])
        assert_permissions(
            "g12_r1", "U", [{"SCOPE": 1, "AREAS": []}, {"SCOPE": 2, "AREAS": [grenoble]}]
        )
        assert_permissions("g12_r1", "V", [{"SCOPE": 2, "AREAS": [grenoble]}])
        assert_permissions(
            "g12_r1",
            "E",
            [{"SCOPE": 1, "AREAS": [grenoble, gap]}, {"SCOPE": 2, "AREAS": [grenoble]}],
        )
        assert_permissions("g12_r1", "D", [{"SCOPE": 2, "AREAS": [grenoble, gap]}])

    def test_taxonomic_filter(self, roles, permissions, assert_permissions):
        animalia = db.session.execute(sa.select(Taxref).where(Taxref.cd_nom == 183716)).scalar_one()

        permissions("r1", "1-----")
        permissions("r1", "-1----", taxons_filter=[])
        permissions("r1", "--1---", taxons_filter=[animalia])

        assert_permissions("r1", "C", [{"SCOPE": 1, "TAXONS": []}])
        assert_permissions("r1", "R", [{"SCOPE": 1, "TAXONS": []}])
        assert_permissions("r1", "U", [{"SCOPE": 1, "TAXONS": [animalia]}])

    def test_taxonomic_filter_overlap(self, roles, permissions, assert_permissions):
        animalia = db.session.execute(sa.select(Taxref).where(Taxref.cd_nom == 183716)).scalar_one()
        capra_ibex = db.session.execute(
            sa.select(Taxref).where(Taxref.cd_nom == 61098)
        ).scalar_one()
        cinnamon = db.session.execute(sa.select(Taxref).where(Taxref.cd_nom == 706584)).scalar_one()

        assert Permission(taxons_filter=[animalia]) <= Permission(taxons_filter=[animalia])
        assert Permission(taxons_filter=[capra_ibex]) <= Permission(taxons_filter=[animalia])
        assert not Permission(taxons_filter=[animalia]) <= Permission(taxons_filter=[capra_ibex])
        assert not Permission(taxons_filter=[cinnamon]) <= Permission(taxons_filter=[animalia])
        assert not Permission(taxons_filter=[cinnamon]) <= Permission(taxons_filter=[capra_ibex])
        assert not Permission(taxons_filter=[cinnamon, capra_ibex]) <= Permission(
            taxons_filter=[animalia]
        )

        permissions("g1", "1-----", taxons_filter=[capra_ibex])
        permissions("g2", "1-----", taxons_filter=[])
        permissions("g1", "-1----", taxons_filter=[capra_ibex])
        permissions("g2", "-2----", taxons_filter=[])
        permissions("g1", "--2---", taxons_filter=[capra_ibex])
        permissions("g2", "--1---", taxons_filter=[])
        permissions("g1", "---1--", taxons_filter=[capra_ibex])
        permissions("g2", "---2--", taxons_filter=[capra_ibex])
        permissions("g1", "----1-", taxons_filter=[capra_ibex])
        permissions("g2", "----2-", taxons_filter=[animalia])
        permissions("g1", "-----1", taxons_filter=[capra_ibex, cinnamon])
        permissions("g2", "-----2", taxons_filter=[animalia])

        assert_permissions("g12_r1", "C", [{"SCOPE": 1, "TAXONS": []}])
        assert_permissions("g12_r1", "R", [{"SCOPE": 2, "TAXONS": []}])
        assert_permissions(
            "g12_r1", "U", [{"SCOPE": 1, "TAXONS": []}, {"SCOPE": 2, "TAXONS": [capra_ibex]}]
        )
        assert_permissions("g12_r1", "V", [{"SCOPE": 2, "TAXONS": [capra_ibex]}])
        assert_permissions("g12_r1", "E", [{"SCOPE": 2, "TAXONS": [animalia]}])
        assert_permissions(
            "g12_r1",
            "D",
            [{"SCOPE": 1, "TAXONS": [capra_ibex, cinnamon]}, {"SCOPE": 2, "TAXONS": [animalia]}],
        )


@pytest.mark.usefixtures("temporary_transaction")
class TestPermissionSchema:
    def test_permission_schema(self, roles, actions, module_a):
        gap = db.session.execute(
            sa.select(LAreas).where(
                LAreas.area_type.has(BibAreasTypes.type_code == "COM"),
                LAreas.area_name == "Gap",
            )
        ).scalar_one()
        capra_ibex = db.session.execute(
            sa.select(Taxref).where(Taxref.cd_nom == 61098)
        ).scalar_one()
        data = {
            "id_role": roles["r1"].id_role,
            "id_action": actions["R"].id_action,
            "id_module": module_a.id_module,
            "scope_value": 3,
            "areas_filter": [{"id_area": gap.id_area}],
            "taxons_filter": [{"cd_nom": capra_ibex.cd_nom}],
        }
        schema = PermissionSchema(only=["areas_filter", "taxons_filter"])
        schema.load(data)
        unexisting_area_data = deepcopy(data)
        unexisting_area_id = (
            db.session.execute(sa.select(sa.func.max(LAreas.id_area)).select_from(LAreas)).scalar()
            + 1
        )
        unexisting_area_data["areas_filter"] = [{"id_area": unexisting_area_id}]
        with pytest.raises(ValidationError, match="Area does not exist"):
            schema.load(unexisting_area_data)
        unexisting_taxon_data = deepcopy(data)
        unexisting_taxon_id = (
            db.session.execute(sa.select(sa.func.max(Taxref.cd_nom)).select_from(Taxref)).scalar()
            + 1
        )
        unexisting_taxon_data["taxons_filter"] = [{"cd_nom": unexisting_taxon_id}]
        with pytest.raises(ValidationError, match="Taxon does not exist"):
            schema.load(unexisting_taxon_data)
