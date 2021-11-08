import pytest

from flask import url_for, current_app
from werkzeug.exceptions import Unauthorized, BadRequest

from pypnusershub.db.tools import user_to_token

from . import users, temporary_transaction


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestGNMeta:
    def test_get_acquisition_frameworks(self, users):
        response = self.client.get(url_for("gn_meta.get_acquisition_frameworks"))
        assert response.status_code == Unauthorized.code

        self.client.set_cookie('*', 'token', user_to_token(users['admin_user']))

        response = self.client.get(url_for("gn_meta.get_acquisition_frameworks"))
        assert response.status_code == 200

    def test_get_acquisition_frameworks_list(self, users):
        response = self.client.get(url_for("gn_meta.get_acquisition_frameworks_list"))
        assert response.status_code == Unauthorized.code

        self.client.set_cookie('*', 'token', user_to_token(users['admin_user']))

        response = self.client.get(url_for("gn_meta.get_acquisition_frameworks_list"))
        assert response.status_code == 200

        response = self.client.get(url_for("gn_meta.get_acquisition_frameworks_list") + '?excluded_fields=lol')
        assert response.status_code == BadRequest.code
