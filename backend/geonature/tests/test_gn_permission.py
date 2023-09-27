import pytest
from flask import url_for


@pytest.mark.usefixtures("client_class")
class TestGnPermissionsRoutes:
    def test_logout(self):
        response = self.client.get(url_for("gn_permissions.logout"))

        assert response.status_code == 200
        assert response.data == b"Logout"
