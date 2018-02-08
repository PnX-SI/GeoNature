'''
Démarrage de l'application
'''

import logging

from flask import Flask

from flask_cors import CORS

from geonature.utils.env import  DB, list_gn_modules


def get_app(config, _app=None):
    # Make sure app is a singleton
    if _app is not None:
        return _app

    app = Flask(__name__)
    app.config.update(config)

    # Bind app to DB
    DB.init_app(app)

    with app.app_context():
        from geonature.utils.logs import mail_handler
        loggers = [
            app.logger,
            logging.getLogger(),
            logging.getLogger('sqlalchemy'),
            logging.getLogger('werkzeug')
        ]
        for logger in loggers:
            if app.config['MAILERROR']['MAIL_ON_ERROR']:
                logger.addHandler(mail_handler)
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

        # Chargement des modules tiers
        for conf, manifest, module in list_gn_modules():
            app.register_blueprint(
                module.backend.blueprint.blueprint,
                url_prefix=conf['api_url']
            )

        _app = app
    return app
