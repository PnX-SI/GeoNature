from flask import Flask, Blueprint
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()
app = Flask(__name__)

app.config.from_pyfile('config.py')

from resources.contact.routes import routes
app.register_blueprint(routes, url_prefix='/contact')

from resources.taxonomie.routes import routes
app.register_blueprint(routes, url_prefix='/taxonomie')

from pypnnomenclature.routes import routes
app.register_blueprint(routes, url_prefix='/nomenclatures')

if __name__ == '__main__':
    db.init_app(app)
    app.run(port=5050, debug=True)
