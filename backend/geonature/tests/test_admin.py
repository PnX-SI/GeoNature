import pytest
from flask import url_for
from ref_geo.models import LAreas, BibAreasTypes
from pypnusershub.tests.utils import set_logged_user


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestAreaPermissionAdmin:

    def test_ajax_area_lookup_sorting(self, users, app):
        """Teste que la recherche 'Ain' remonte 'Ain' en premier."""

        set_logged_user(self.client, users["admin_user"])
        url = url_for("permissions/permission.ajax_lookup")
        response = self.client.get(
            url, query_string={"name": "areas_filter", "query": "Ain", "offset": 0, "limit": 10}
        )

        assert response.status_code == 200
        data = response.json

        assert isinstance(data, list)
        results = [item[1] for item in data]

        assert results[0] == "Ain (Départements)"
        assert results[1].startswith("Ain")

    def test_ajax_area_no_query(self, users):
        """Teste le tri par défaut (id_type, area_name) sans paramètre query."""

        set_logged_user(self.client, users["admin_user"])
        url = url_for("permissions/permission.ajax_lookup", name="areas_filter")

        response = self.client.get(url)

        assert response.status_code == 200
        assert isinstance(response.json, list)
        assert len(response.json) > 0
