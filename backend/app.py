from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_restful import Resource, Api
from resources.contactfaune.cor_nom_liste import CorNom, CorNomAll
from resources.contactfaune.t_releves_cfaune import RelevesCFaune, RelevesCFauneAll
from resources.contactfaune.t_occurences_cfaune import OccurencesCFaune, OccurencesCFauneAll



db = SQLAlchemy()
app = Flask(__name__)
api = Api(app)

app.config.from_pyfile('config.py')

api.add_resource(CorNomAll, '/cornoms')
api.add_resource(CorNom, '/cornoms/<string:name>')

api.add_resource(RelevesCFauneAll, '/releves_cfaunes')
api.add_resource(RelevesCFaune, '/releves_cfaunes/<string:id>')

api.add_resource(OccurencesCFauneAll, '/occurences_cfaunes')
api.add_resource(OccurencesCFaune, '/occurences_cfaunes/<string:id>')

if __name__ == '__main__':
    db.init_app(app)
    app.run(port=5000, debug=True)
