from flask_restful import Resource, reqparse

from models.contactfaune.cor_nom_liste import CorNomListeModel

class CorNom(Resource):
    def get(seft):
        return {'cornoms': list(map(lambda x: x.json(), CorNomListeModel.query.all()))}
