import pytest
from flask import url_for

from pypnusershub.tests.utils import set_logged_user
from werkzeug.exceptions import NotFound, Unauthorized


@pytest.mark.usefixtures("client_class")
class TestGnPermissionsRoutes:
    def test_logout(self):
        response = self.client.get(url_for("gn_permissions.logout"))

        assert response.status_code == 200
        assert response.data == b"Logout"

    def test_list_permissions_availables(self, users):
        url = url_for("gn_permissions.list_permissions_availables")

        response = self.client.get(url)
        assert response.status_code == Unauthorized.code

        set_logged_user(self.client, users["user"])
        response = self.client.get(url)
        assert response.status_code == 200

    def test_get_permission_available(self, users):
        url = url_for(
            "gn_permissions.get_permission_available",
            module_code="METADATA",
            code_object="ALL",
            code_action="R",
        )

        response = self.client.get(url)
        assert response.status_code == Unauthorized.code

        set_logged_user(self.client, users["user"])
        response = self.client.get(url)
        assert response.status_code == 200

        response = self.client.get(
            url_for(
                "gn_permissions.get_permission_available",
                module_code="METADATA",
                code_object="ALL",
                code_action="UNEXISTING",
            )
        )
        assert response.status_code == NotFound.code
