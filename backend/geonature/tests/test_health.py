import pytest

from geonature.utils.config import config
from .fixtures import *


@pytest.mark.usefixtures("client_class")
class TestHealth:
    def test_healthz_endpoint(self):
        # do not use url_for to be sur the endpoint is always behind API_ENDPOINT / healthz
        url = f"{config['API_ENDPOINT']}/healthz"
        response = self.client.get(url)
        assert response.status_code == 200
