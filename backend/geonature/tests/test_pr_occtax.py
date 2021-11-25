import pytest

from flask import url_for, current_app
from werkzeug.exceptions import Forbidden

from . import *
from .fixtures import *


occtax = pytest.importorskip("occtax")


@pytest.mark.usefixtures("client_class", "temporary_transaction", "users", "datasets")
class TestOcctax:
    def test_post_releve(self, releve_data):
        # post with cruved = C = 2
        login(self.client, "user", "user")
        response = self.client.post(
            url_for("pr_occtax.createReleve"),
            json=releve_data
        )
        assert response.status_code == 200

        # Post in a dataset where 'self user' has no right
        login(self.client, "self_user", "self_user")
        #with pytest.raises(Forbidden):
        response = self.client.post(
            url_for("pr_occtax.createReleve"),
            json=releve_data
        )
        assert response == 403

        #TODO : test update, test post occurrence

    def test_get_defaut_nomenclatures(self):
        response = self.client.get(url_for("pr_occtax.getDefaultNomenclatures"))
        assert response.status_code == 200
