from flask_restful import Resource

from models.contactfaune.cor_nom_liste import CorNomListeModel

class CorNom(Resource):

    def get(self, name):
        nom = CorNomListeModel.find_by_name(name)
        if nom:
            return nom.json()
        return {'message': 'id_nom not found'}, 404

class CorNomAll(Resource):
    def get(self):
        return {'cornoms':  [x.json() for x in CorNomListeModel.query.all()]}