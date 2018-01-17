'''
Démarrage de l'application
'''

import toml


from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS

from config_schema import GnCoreSchemaConf, ConfigError

db = SQLAlchemy()

app_globals = {}


def get_app():
    if app_globals.get('app', False):
        return app_globals['app']
    app = Flask(__name__)

    # load and validate configuration
    conf_toml = toml.load(['../config/custom_config.toml'])
    data, configerrors = GnCoreSchemaConf().load(conf_toml)
    if configerrors:
        print('BAD CONFIG')
        print(configerrors)
        raise ConfigError(configerrors)

    app.config.update(data)
    db.init_app(app)
    with app.app_context():
        db.create_all()

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

        ## errors
        from geonature.core.errors import routes

        app_globals['app'] = app
    return app


app = get_app()
CORS(app, supports_credentials=True)


if __name__ == '__main__':
    from flask_script import Manager
    Manager(app).run()
