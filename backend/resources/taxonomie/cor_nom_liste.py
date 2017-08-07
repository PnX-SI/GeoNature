from flask_restful import Resource

from models.taxonomie.cor_nom_liste import CorNomListeTaxonomieModel

class CorNomTaxonomie(Resource):

    def get(self, name):
        nom = CorNomListeTaxonomieModel.find_by_name(name)
        if nom:
            return nom.json()
        return {'message': 'id_nom not found'}, 404

class CorNomTaxonomieAll(Resource):
    def get(self):
        return {'cornoms':  [x.json() for x in CorNomListeTaxonomieModel.query.all()]}