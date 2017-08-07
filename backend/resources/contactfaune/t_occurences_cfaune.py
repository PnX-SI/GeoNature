from flask_restful import Resource

from models.contactfaune.t_occurences_cfaune import OccurencesCFauneModel

class OccurencesCFaune(Resource):
    def get(self, id):
        id = OccurencesCFauneModel.find_by_id(id)
        if id:
            return id.json()
        return {'message': 'id_occurence_cfaune not found'}, 404

class OccurencesCFauneAll(Resource):
    def get(self):
        return [x.json() for x in OccurencesCFauneModel.query.all()]