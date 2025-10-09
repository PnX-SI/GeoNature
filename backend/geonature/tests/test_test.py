from .generator.user import *
from .fixtures import client
from flask import url_for


@pytest.mark.usefixtures("client")
@with_dynamic_users(
    [
        dict(
            user=dict(nom_role="Utilisateur", prenom_role="Test", identifiant="test_user"),
            organisme=dict(nom_organisme="test orga"),
            perm=[
                dict(
                    module_code="SYNTHESE",
                    action_code=ACTION.R,
                    object_code="ALL",
                    scope_value=3,
                    areas=lambda: [LAreas.query.filter_by(area_name="Gap").one()],
                )
            ],
        ),
        dict(
            user=dict(
                nom_role="Utilisateur2",
                prenom_role="Test2",
                identifiant="test_user2",
            ),
            perm=[
                # dict(module_code="SYNTHESE", action_code=ACTION.R, object_code="ALL", scope_value=3)
            ],
        ),
    ]
)
def test_user(client):
    # print("aa")
    response = client.get(url_for("auth.get_user_data"))
    # print("-", response.json["user"], "-")

print(test_user)
