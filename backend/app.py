from flask import Flask, Blueprint
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()
app = Flask(__name__)

app.config.from_pyfile('config.py')

from resources.contactfaune.routes import adresses
app.register_blueprint(adresses, url_prefix='/contactfaune')

from resources.taxonomie.routes import adresses
app.register_blueprint(adresses, url_prefix='/taxonomie')

if __name__ == '__main__':
    db.init_app(app)
    app.run(port=5000, debug=True)
