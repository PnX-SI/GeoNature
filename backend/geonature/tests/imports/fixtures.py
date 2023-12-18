import pytest
from flask import g

from geonature.core.gn_commons.models import TModules

from geonature.core.imports.models import Destination


@pytest.fixture(scope="session")
def default_destination(app):
    """
    This fixture set default destination when not specified in call to url_for.
    """

    @app.url_defaults
    def set_default_destination(endpoint, values):
        if (
            app.url_map.is_endpoint_expecting(endpoint, "destination")
            and "destination" not in values
        ):
            values["destination"] = g.default_destination.code


@pytest.fixture(scope="session")
def synthese_destination():
    return Destination.query.filter(
        Destination.module.has(TModules.module_code == "SYNTHESE")
    ).one()


@pytest.fixture(scope="class")
def default_synthese_destination(app, default_destination, synthese_destination):
    g.default_destination = synthese_destination
    yield
    del g.default_destination
