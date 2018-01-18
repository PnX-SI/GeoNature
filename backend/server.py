'''
Démarrage de l'application
'''

import logging

from flask import Flask

from flask_cors import CORS

from geonature.utils.env import ROOT_DIR, DB, load_config

log = logging.getLogger(__name__)


def get_app(config, _app=None):

    # Make sure app is a singleton
    if _app is not None:
        return _app

    app = Flask(__name__)
    app.config.update(config)

    # Bind app to DB
    DB.init_app(app)

    with app.app_context():
        DB.create_all()

        from pypnusershub.routes import routes
        app.register_blueprint(routes, url_prefix='/auth')

        from pypnnomenclature.routes import routes
        app.register_blueprint(routes, url_prefix='/nomenclatures')

        from geonature.core.users.routes import routes
        app.register_blueprint(routes, url_prefix='/users')

        from geonature.modules.pr_contact.routes import routes
        app.register_blueprint(routes, url_prefix='/contact')

        from geonature.core.gn_meta.routes import routes
        app.register_blueprint(routes, url_prefix='/meta')

        from geonature.core.ref_geo.routes import routes
        app.register_blueprint(routes, url_prefix='/geo')

        from geonature.core.gn_exports.routes import routes
        app.register_blueprint(routes, url_prefix='/exports')

        from geonature.core.auth.routes import routes
        app.register_blueprint(routes, url_prefix='/auth_cas')

        # errors
        from geonature.core.errors import routes

        CORS(app, supports_credentials=True)

        _app = app
    return app

