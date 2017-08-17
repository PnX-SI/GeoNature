from flask_restful import Resource

from models.contact.t_occurrences_contact import T_OccurrencesContact

class T_OccurrencesContactByID(Resource):
    def get(self, id):
        id = T_OccurrencesContact.find_by_id(id)
        if id:
            return id.json()
        return {'message': 'id_occurrence_contact not found'}, 404

class T_OccurrencesContactAll(Resource):
    def get(self):
        return [x.json() for x in T_OccurrencesContact.query.all()]