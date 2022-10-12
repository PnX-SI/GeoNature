"""
Démarrage de l'application
"""

import logging, os
from itertools import chain
from pkg_resources import iter_entry_points
from urllib.parse import urlsplit
from importlib import import_module

from flask import Flask, g, request, current_app
from flask.json.provider import DefaultJSONProvider
from flask_mail import Message
from flask_cors import CORS
from flask_sqlalchemy import before_models_committed
from werkzeug.middleware.proxy_fix import ProxyFix
from psycopg2.errors import UndefinedTable
from sqlalchemy.exc import OperationalError, ProgrammingError
from sqlalchemy.orm.exc import NoResultFound
from sqlalchemy.engine import RowProxy

from geonature.utils.config import config
from geonature.utils.env import MAIL, DB, db, MA, migrate, BACKEND_DIR
from geonature.utils.logs import config_loggers
from geonature.utils.module import import_backend_enabled_modules
from geonature.core.admin.admin import admin
from geonature.middlewares import RequestID

from pypnusershub.db.tools import (
    user_from_token,
    UnreadableAccessRightsError,
    AccessRightsExpiredError,
)
from pypnusershub.db.models import Application


@migrate.configure
def configure_alembic(alembic_config):
    """
    This function add to the 'version_locations' parameter of the alembic config the
    'migrations' entry point value of the 'gn_module' group for all modules having such entry point.
    Thus, alembic will find migrations of all installed geonature modules.
    """
    version_locations = alembic_config.get_main_option("version_locations", default="").split()
    if "VERSION_LOCATIONS" in config["ALEMBIC"]:
        version_locations.extend(config["ALEMBIC"]["VERSION_LOCATIONS"].split())
    for entry_point in chain(
        iter_entry_points("alembic", "migrations"), iter_entry_points("gn_module", "migrations")
    ):
        # TODO: define enabled module in configuration (skip disabled module, raise error on missing module)
        _, migrations = str(entry_point).split("=", 1)
        version_locations += [migrations.strip()]
    alembic_config.set_main_option("version_locations", " ".join(version_locations))
    return alembic_config


if config.get("SENTRY_DSN"):
    import sentry_sdk
    from sentry_sdk.integrations.flask import FlaskIntegration
    from sentry_sdk.integrations.celery import CeleryIntegration

    sentry_sdk.init(
        config["SENTRY_DSN"],
        integrations=[FlaskIntegration(), CeleryIntegration()],
        traces_sample_rate=1.0,
    )


class MyJSONProvider(DefaultJSONProvider):
    @staticmethod
    def default(o):
        if isinstance(o, RowProxy):
            return dict(o)
        return DefaultJSONProvider.default(o)


def create_app(with_external_mods=True):
    app = Flask(__name__.split(".")[0], static_folder="../static")

    app.config.update(config)
    api_uri = urlsplit(app.config["API_ENDPOINT"])
    app.config["APPLICATION_ROOT"] = api_uri.path
    app.config["PREFERRED_URL_SCHEME"] = api_uri.scheme
    if "SCRIPT_NAME" not in os.environ:
        os.environ["SCRIPT_NAME"] = app.config["APPLICATION_ROOT"].rstrip("/")
    app.config["TEMPLATES_AUTO_RELOAD"] = True
    # disable cache for downloaded files (PDF file stat for ex)
    app.config["SEND_FILE_MAX_AGE_DEFAULT"] = 0
    if "GEONATURE_SETTINGS" in os.environ:
        app.config.from_object(os.environ["GEONATURE_SETTINGS"])

    if len(app.config["SECRET_KEY"]) < 20:
        raise Exception(
            "The SECRET_KEY config option must have a length "
            "greater or equals to 20 characters."
        )

    # set from headers HTTP_HOST, SERVER_NAME, and SERVER_PORT
    app.wsgi_app = ProxyFix(app.wsgi_app, x_host=1)
    app.wsgi_app = RequestID(app.wsgi_app)

    app.json = MyJSONProvider(app)

    # set logging config
    config_loggers(app.config)

    db.init_app(app)
    migrate.init_app(app, DB, directory=BACKEND_DIR / "geonature" / "migrations")
    MA.init_app(app)
    CORS(app, supports_credentials=True)

    if "CELERY" in app.config:
        from geonature.utils.celery import celery_app

        celery_app.conf.update(app.config["CELERY"])

    # Emails configuration
    if app.config["MAIL_CONFIG"]:
        conf = app.config.copy()
        conf.update(app.config["MAIL_CONFIG"])
        app.config = conf
        MAIL.init_app(app)

    # Notifications configuration enable/disabled
    if "NOTIFICATION" in app.config:
        notification = true

    # Pass parameters to the usershub authenfication sub-module, DONT CHANGE THIS
    app.config["DB"] = DB
    # Pass parameters to the submodules
    app.config["MA"] = MA

    # For deleting files on "delete" media
    @before_models_committed.connect_via(app)
    def on_before_models_committed(sender, changes):
        for obj, change in changes:
            if change == "delete" and hasattr(obj, "__before_commit_delete__"):
                obj.__before_commit_delete__()

    # setting g.current_user on each request
    @app.before_request
    def load_current_user():
        try:
            g.current_user = user_from_token(request.cookies["token"]).role
        except (KeyError, UnreadableAccessRightsError, AccessRightsExpiredError):
            g.current_user = None

    if config.get("SENTRY_DSN"):
        from sentry_sdk import set_tag, set_user

        @app.before_request
        def set_sentry_context():
            set_tag("request.id", request.environ["FLASK_REQUEST_ID"])
            if g.current_user:
                set_user(
                    {
                        "id": g.current_user.id_role,
                        "username": g.current_user.identifiant,
                        "email": g.current_user.email,
                    }
                )

    admin.init_app(app)

    # Pass the ID_APP to the submodule to avoid token conflict between app on the same server
    with app.app_context():
        try:
            gn_app = Application.query.filter_by(code_application=config["CODE_APPLICATION"]).one()
        except (
            OperationalError,  # database does not exist
            ProgrammingError,  # database empty
            NoResultFound,  # database has schema but not required data
        ):
            logging.warning(
                "Warning: unable to find GeoNature application, database not yet initialized?"
            )
        else:
            app.config["ID_APP"] = app.config["ID_APPLICATION_GEONATURE"] = gn_app.id_application

    for blueprint_path, url_prefix in [
        ("pypnusershub.routes:routes", "/auth"),
        ("pypn_habref_api.routes:routes", "/habref"),
        ("pypnusershub.routes_register:bp", "/pypn/register"),
        ("pypnnomenclature.routes:routes", "/nomenclatures"),
        ("geonature.core.gn_commons.routes:routes", "/gn_commons"),
        ("geonature.core.gn_permissions.routes:routes", "/permissions"),
        ("geonature.core.gn_permissions.backoffice.views:routes", "/permissions_backoffice"),
        ("geonature.core.routes:routes", "/"),
        ("geonature.core.users.routes:routes", "/users"),
        ("geonature.core.gn_synthese.routes:routes", "/synthese"),
        ("geonature.core.gn_meta.routes:routes", "/meta"),
        ("geonature.core.ref_geo.routes:routes", "/geo"),
        ("geonature.core.auth.routes:routes", "/gn_auth"),
        ("geonature.core.gn_monitoring.routes:routes", "/gn_monitoring"),
        ("geonature.core.gn_profiles.routes:routes", "/gn_profiles"),
        ("geonature.core.sensitivity.routes:routes", None),
    ]:
        module_name, blueprint_name = blueprint_path.split(":")
        blueprint = getattr(import_module(module_name), blueprint_name)
        app.register_blueprint(blueprint, url_prefix=url_prefix)

    with app.app_context():
        # register errors handlers
        import geonature.core.errors

        # Loading third-party modules
        if with_external_mods:
            try:
                for (
                    module_object,
                    module_config,
                    module_blueprint,
                ) in import_backend_enabled_modules():
                    app.config[module_config["MODULE_CODE"]] = module_config
                    app.register_blueprint(
                        module_blueprint, url_prefix=module_config["MODULE_URL"]
                    )
            except (OperationalError, ProgrammingError) as sqla_error:
                if not isinstance(sqla_error, ProgrammingError) or isinstance(
                    sqla_error.orig, UndefinedTable
                ):
                    logging.warning(
                        "Warning: database not yet initialized, skipping loading of external modules"
                    )
                else:
                    raise

    return app
