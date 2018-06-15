'''
Démarrage de l'application
'''

import logging

from flask import Flask

from flask_cors import CORS

from geonature.utils.env import DB, list_and_import_gn_modules


def get_app(config, _app=None, with_external_mods=True):
    # Make sure app is a singleton
    if _app is not None:
        return _app

    app = Flask(__name__)
    app.config.update(config)

    # Bind app to DB
    DB.init_app(app)

    with app.app_context():
        from geonature.utils.logs import mail_handler
        if app.config['MAILERROR']['MAIL_ON_ERROR']:
            logging.getLogger().addHandler(mail_handler)
        DB.create_all()

        from pypnusershub.routes import routes
        app.register_blueprint(routes, url_prefix='/auth')

        from pypnnomenclature.routes import routes
        app.register_blueprint(routes, url_prefix='/nomenclatures')

        from geonature.core.routes import routes
        app.register_blueprint(routes, url_prefix='')

        from geonature.core.users.routes import routes
        app.register_blueprint(routes, url_prefix='/users')

        from geonature.core.gn_synthese.routes import routes
        app.register_blueprint(routes, url_prefix='/synthese')

        from geonature.core.gn_meta.routes import routes
        app.register_blueprint(routes, url_prefix='/meta')

        from geonature.core.ref_geo.routes import routes
        app.register_blueprint(routes, url_prefix='/geo')

        from geonature.core.gn_exports.routes import routes
        app.register_blueprint(routes, url_prefix='/exports')

        from geonature.core.auth.routes import routes
        app.register_blueprint(routes, url_prefix='/auth_cas')

        from geonature.core.gn_monitoring.routes import routes
        app.register_blueprint(routes, url_prefix='/gn_monitoring')

        from geonature.core.gn_commons.routes import routes
        app.register_blueprint(routes, url_prefix='/gn_commons')

        # errors
        from geonature.core.errors import routes

        CORS(app, supports_credentials=True)
        # Chargement des mosdules tiers
        if with_external_mods:
            for conf, manifest, module in list_and_import_gn_modules(app):
                app.register_blueprint(
                    module.backend.blueprint.blueprint,
                    url_prefix=conf['api_url']
                )
                #chargement de la configuration du module dans le blueprint.config
                module.backend.blueprint.blueprint.config = conf
                app.config[manifest['module_name']] = conf

        _app = app
    return app
