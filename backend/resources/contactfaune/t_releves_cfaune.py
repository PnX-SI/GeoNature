from flask_restful import Resource

from models.contactfaune.t_releves_cfaune import RelevesCFauneModel

class RelevesCFaune(Resource):

    def get(self, id):
        id = RelevesCFauneModel.find_by_id(id)
        if id:
            return id.json()
        return {'message': 'id not found'}, 404

class RelevesCFauneAll(Resource):
    def get(self):
        return [x.json() for x in RelevesCFauneModel.query.all()]