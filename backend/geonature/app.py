"""
Démarrage de l'application
"""

import logging, warnings, os, sys
from itertools import chain
from pkg_resources import iter_entry_points, load_entry_point
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
    static_folder = os.environ.get("GEONATURE_STATIC_FOLDER", "../static")
    app = Flask(__name__.split(".")[0], static_folder=static_folder)

    app.config.update(config)

    if "SCRIPT_NAME" not in os.environ:
        os.environ["SCRIPT_NAME"] = app.config["APPLICATION_ROOT"].rstrip("/")

    # Enable deprecation warnings in debug mode
    if app.debug and not sys.warnoptions:
        warnings.filterwarnings(action="default", category=DeprecationWarning)

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
            for module_code_entry in iter_entry_points("gn_module", "code"):
                module_code = module_code_entry.resolve()
                if module_code in config["DISABLED_MODULES"]:
                    continue
                try:
                    module_blueprint = load_entry_point(
                        module_code_entry.dist, "gn_module", "blueprint"
                    )
                except Exception as e:
                    logging.exception(e)
                    logging.warning(f"Unable to load module {module_code}, skipping…")
                    current_app.config["DISABLED_MODULES"].append(module_code)
                else:
                    module_blueprint.config = config[module_code]
                    app.register_blueprint(module_blueprint, url_prefix=f"/{module_code.lower()}")

    return app
