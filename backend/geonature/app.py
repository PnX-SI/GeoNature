"""
Démarrage de l'application
"""

import logging, warnings, os, sys
from itertools import chain
from importlib import import_module
from packaging import version

if sys.version_info < (3, 10):
    from importlib_metadata import entry_points
else:
    from importlib.metadata import entry_points
from flask import Flask, g, request, current_app, send_from_directory
from flask.json.provider import DefaultJSONProvider
from flask_mail import Message
from flask_babel import Babel
from flask_cors import CORS
from flask_login import current_user
from flask_sqlalchemy.track_modifications import before_models_committed
from werkzeug.middleware.proxy_fix import ProxyFix
from werkzeug.middleware.shared_data import SharedDataMiddleware
from werkzeug.middleware.dispatcher import DispatcherMiddleware
from werkzeug.wrappers import Response
import sqlalchemy as sa

if version.parse(sa.__version__) >= version.parse("1.4"):
    from sqlalchemy.engine import Row
else:  # retro-compatibility SQLAlchemy 1.3
    from sqlalchemy.engine import RowProxy as Row

from geonature.utils.config import config

from geonature.utils.env import MAIL, DB, db, MA, migrate, BACKEND_DIR
from geonature.utils.logs import config_loggers
from geonature.utils.module import iter_modules_dist
from geonature.core.admin.admin import admin
from geonature.middlewares import SchemeFix, RequestID


from pypnusershub.db.models import Application
from pypnusershub.auth import auth_manager
from pypnusershub.login_manager import login_manager


@migrate.configure
def configure_alembic(alembic_config):
    """
    This function add to the 'version_locations' parameter of the alembic config the
    'migrations' entry point value of the 'gn_module' group for all modules having such entry point.
    Thus, alembic will find migrations of all installed geonature modules.
    """
    version_locations = set(alembic_config.get_main_option("version_locations", default="").split())
    if "VERSION_LOCATIONS" in config["ALEMBIC"]:
        version_locations |= set(config["ALEMBIC"]["VERSION_LOCATIONS"].split())
    for entry_point in chain(
        entry_points(group="alembic", name="migrations"),
        entry_points(group="gn_module", name="migrations"),
    ):
        version_locations.add(entry_point.value)
    alembic_config.set_main_option("version_locations", " ".join(version_locations))
    return alembic_config


if config.get("SENTRY_DSN"):
    import sentry_sdk
    from sentry_sdk.integrations.flask import FlaskIntegration
    from sentry_sdk.integrations.redis import RedisIntegration
    from sentry_sdk.integrations.celery import CeleryIntegration

    sentry_sdk.init(
        config["SENTRY_DSN"],
        integrations=[FlaskIntegration(), RedisIntegration(), CeleryIntegration()],
        traces_sample_rate=1.0,
    )


class MyJSONProvider(DefaultJSONProvider):
    @staticmethod
    def default(o):
        if isinstance(o, Row):
            return o._asdict()
        return DefaultJSONProvider.default(o)


def get_locale():
    # if a user is logged in, use the locale from the user settings
    user = getattr(g, "user", None)
    if user is not None:
        return user.locale
    # otherwise try to guess the language from the user accept
    # header the browser transmits.  We support de/fr/en in this
    # example.  The best match wins.
    return request.accept_languages.best_match(["de", "fr", "en"])


def create_app(with_external_mods=True):
    app = Flask(
        __name__.split(".")[0],
        root_path=config["ROOT_PATH"],
        static_folder=config["STATIC_FOLDER"],
        static_url_path=config["STATIC_URL"],
        template_folder="geonature/templates",
    )
    app.config.update(config)

    # Enable deprecation warnings in debug mode
    if app.debug and not sys.warnoptions:
        warnings.filterwarnings(action="default", category=DeprecationWarning)

    # set from headers HTTP_HOST, SERVER_NAME, and SERVER_PORT
    app.wsgi_app = SchemeFix(app.wsgi_app, scheme=config.get("PREFERRED_URL_SCHEME"))
    app.wsgi_app = ProxyFix(app.wsgi_app, x_host=1)
    app.wsgi_app = RequestID(app.wsgi_app)
    if config.get("CUSTOM_STATIC_FOLDER"):
        app.wsgi_app = SharedDataMiddleware(
            app.wsgi_app,
            {
                app.static_url_path: config["CUSTOM_STATIC_FOLDER"],
            },
        )
    if app.config["APPLICATION_ROOT"] != "/":
        app.wsgi_app = DispatcherMiddleware(
            Response("Not Found", status=404),
            {app.config["APPLICATION_ROOT"].rstrip("/"): app.wsgi_app},
        )

    app.json = MyJSONProvider(app)

    # set logging config
    config_loggers(app.config)

    db.init_app(app)
    migrate.init_app(app, DB, directory=BACKEND_DIR / "geonature" / "migrations")
    MA.init_app(app)
    CORS(app, supports_credentials=True)
    auth_manager.init_app(app, providers_declaration=config["AUTHENTICATION"]["PROVIDERS"])
    auth_manager.home_page = config["URL_APPLICATION"]

    if "CELERY" in app.config:
        from geonature.utils.celery import celery_app

        celery_app.init_app(app)

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

    @app.before_request
    def load_current_user():
        g._permissions_by_user = {}
        g._permissions = {}

    if config.get("SENTRY_DSN"):
        from sentry_sdk import set_tag, set_user

        @app.before_request
        def set_sentry_context():
            from flask_login import current_user

            if "FLASK_REQUEST_ID" in request.environ:
                set_tag("request.id", request.environ["FLASK_REQUEST_ID"])
            if current_user.is_authenticated:
                set_user(
                    {
                        "id": current_user.id_role,
                        "username": current_user.identifiant,
                        "email": current_user.email,
                    }
                )

    admin.init_app(app)

    # babel
    babel = Babel(app, locale_selector=get_locale)

    # Enable serving of media files
    app.add_url_rule(
        f"{config['MEDIA_URL']}/<path:filename>",
        view_func=lambda filename: send_from_directory(config["MEDIA_FOLDER"], filename),
        endpoint="media",
    )
    app.add_url_rule(
        f"{config['MEDIA_URL']}/taxhub/<path:filename>",
        view_func=lambda filename: send_from_directory(
            config["MEDIA_FOLDER"] + "/taxhub", filename
        ),
        endpoint="media_taxhub",
    )

    for blueprint_path, url_prefix in [
        ("pypn_habref_api.routes:routes", "/habref"),
        ("pypnusershub.routes_register:bp", "/pypn/register"),
        ("pypnnomenclature.routes:routes", "/nomenclatures"),
        ("ref_geo.routes:routes", "/geo"),
        ("geonature.core.gn_commons.routes:routes", "/gn_commons"),
        ("geonature.core.gn_permissions.routes:routes", "/permissions"),
        ("geonature.core.users.routes:routes", "/users"),
        ("geonature.core.gn_synthese.routes:routes", "/synthese"),
        ("geonature.core.gn_meta.routes:routes", "/meta"),
        ("geonature.core.gn_monitoring.routes:routes", "/gn_monitoring"),
        ("geonature.core.gn_profiles.routes:routes", "/gn_profiles"),
        ("geonature.core.sensitivity.routes:routes", None),
        ("geonature.core.notifications.routes:routes", "/notifications"),
        ("geonature.core.imports.blueprint:blueprint", "/import"),
    ]:
        module_name, blueprint_name = blueprint_path.split(":")
        blueprint = getattr(import_module(module_name), blueprint_name)
        app.register_blueprint(blueprint, url_prefix=url_prefix)

    with app.app_context():
        # taxhub api
        from apptax import taxhub_api_routes

        base_api_prefix = app.config["TAXHUB"].get("API_PREFIX")

        for blueprint_path, url_prefix in taxhub_api_routes:
            module_name, blueprint_name = blueprint_path.split(":")
            blueprint = getattr(import_module(module_name), blueprint_name)
            app.register_blueprint(blueprint, url_prefix="/taxhub" + base_api_prefix + url_prefix)

        # taxhub admin
        from apptax.admin.admin import adresses

        app.register_blueprint(adresses, url_prefix="/taxhub")

        # register taxhub admin view which need app context
        from geonature.core.taxonomie.admin import load_admin_views

        load_admin_views(app, admin)

        # register errors handlers
        import geonature.core.errors

        # Loading third-party modules
        if with_external_mods:
            for module_dist in iter_modules_dist():
                module_code = module_dist.entry_points["code"].load()
                if module_code in config["DISABLED_MODULES"]:
                    continue
                try:
                    module_blueprint = module_dist.entry_points["blueprint"].load()
                except Exception as e:
                    logging.exception(e)
                    logging.warning(f"Unable to load module {module_code}, skipping…")
                    current_app.config["DISABLED_MODULES"].append(module_code)
                else:
                    module_blueprint.config = config[module_code]
                    app.register_blueprint(module_blueprint, url_prefix=f"/{module_code.lower()}")

    return app
