from flask import Blueprint
from flask_restful import Resource, Api
from resources.taxonomie.cor_nom_liste import CorNomTaxonomie, CorNomTaxonomieAll

routes = Blueprint('taxonomie', __name__)

api = Api(routes)

api.add_resource(CorNomTaxonomieAll, '/cornoms')
api.add_resource(CorNomTaxonomie, '/cornoms/<string:name>')
