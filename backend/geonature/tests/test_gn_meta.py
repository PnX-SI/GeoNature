import pytest

from flask import url_for, current_app
from werkzeug.exceptions import Unauthorized, BadRequest

from pypnusershub.db.tools import user_to_token

from . import users, temporary_transaction
from .utils import set_logged_user_cookie


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestGNMeta:
    def test_get_acquisition_frameworks(self, users):
        response = self.client.get(url_for("gn_meta.get_acquisition_frameworks"))
        assert response.status_code == Unauthorized.code

        set_logged_user_cookie(self.client, users['admin_user'])

        response = self.client.get(url_for("gn_meta.get_acquisition_frameworks"))
        assert response.status_code == 200

    def test_get_datasets(self, users):
        response = self.client.get(url_for("gn_meta.get_datasets"))
        assert response.status_code == Unauthorized.code

        set_logged_user_cookie(self.client, users['admin_user'])

        response = self.client.get(url_for("gn_meta.get_datasets"))
        assert response.status_code == 200

    def test_create_dataset(self, users):
        response = self.client.post(url_for("gn_meta.create_dataset"))
        assert response.status_code == Unauthorized.code

        set_logged_user_cookie(self.client, users['admin_user'])

        response = self.client.post(url_for("gn_meta.create_dataset"))
        assert response.status_code == BadRequest.code
