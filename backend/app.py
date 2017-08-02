from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_restful import Resource, Api
from resources.contactfaune.cor_nom_liste import CorNom


db = SQLAlchemy()
app = Flask(__name__)
api = Api(app)

app.config.from_pyfile('config.py')

class Student(Resource):
    def get(sef, name):
        return {'student': name}

api.add_resource(Student, '/student/<string:name>')
api.add_resource(CorNom, '/cornoms')
if __name__ == '__main__':
    db.init_app(app)
    app.run(port=5000, debug=True)
