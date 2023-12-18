import pytest
from flask import g
from sqlalchemy import select

from geonature.core.gn_commons.models import TModules
from geonature.utils.env import db

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


@pytest.fixture(scope="session")
def list_all_module_dest_code():
    module_code_dest = db.session.scalars(
        select(TModules.module_code).join(Destination, Destination.id_module == TModules.id_module)
    ).all()
    return module_code_dest


@pytest.fixture(scope="session")
def all_modules_destination(list_all_module_dest_code):
    dict_modules_dest = {}

    for module_code in list_all_module_dest_code:
        query = select(Destination).filter(
            Destination.module.has(TModules.module_code == module_code)
        )

        result = db.session.execute(query).scalar_one()

        dict_modules_dest[module_code] = result

    return dict_modules_dest
