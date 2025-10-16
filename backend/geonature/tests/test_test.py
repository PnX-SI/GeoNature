from .generator.user import *
from .fixtures import client
from flask import url_for

import pytest
from ref_geo.models import LAreas


@pytest.fixture()
def user():
    return create_user(dict(nom_role="Utilisateur", prenom_role="Test", identifiant="test_user"))


@pytest.fixture()
def user2():
    return create_user(dict(nom_role="Utilisateur", prenom_role="Test2", identifiant="test_user2"))


@pytest.mark.parametrize("user", ["user1", "user2"], indirect=True)
@pytest.mark.parametrize(
    "permissions, perm_name",
    [
        (
            [
                dict(
                    module_code="SYNTHESE",
                    action_code=ACTION.R,
                    object_code="ALL",
                    scope_value=3,
                    areas=lambda: [LAreas.query.filter_by(area_name="Gap").one()],
                )
            ],
            "perm1",
        ),
        (
            [
                dict(
                    module_code="OCCTAX",
                    action_code=ACTION.C,
                    object_code="ALL",
                    scope_value=2,
                )
            ],
            "perm2",
        ),
    ],
)
@pytest.mark.usefixtures("client")
@dec_permissions(expected_result={"perm1": 1, "perm2": 1})
def test_test(user, client, permissions, perm_name):
    # Exemple de test : vérifier que l'utilisateur a les bonnes permissions
    assert len(user.permissions) > 0

    # Vérifier le résultat attendu si nécessaire
    if hasattr(user, "expected_result"):
        assert user.expected_result in [0, 1]
