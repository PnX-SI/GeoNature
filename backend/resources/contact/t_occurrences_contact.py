from flask_restful import Resource
from flask import request

from models.contact.t_occurrences_contact import T_OccurrencesContact

class T_OccurrencesContactByID(Resource):
    def get(self, id):
        id = T_OccurrencesContact.find_by_id(id)
        if id:
            return id.json()
        return {'message': 'id not found'}, 404

    def post(self, id):
        if T_OccurrencesContact.find_by_id(id):
            return {'message': "this id: '{}' already exists.".format(id)}, 400
        res = request.get_json(silent=True)
        insert_data = T_OccurrencesContact(**res)
        try:
            insert_data.add_to_db()
        except Exception as e:
            insert_data.rollback()
            return {e}, 500
        return insert_data.json(), 200

    def delete(self, id):
        row = T_OccurrencesContact.find_by_id(id)
        if row:
            try:
                row.delete_from_db()
            except Exception as e:
                return {e}, 500
        return {'message': "data id: '{}' deleted".format(id)}, 200

    def put(self, id):
        if not T_OccurrencesContact.find_by_id(id):
            return {'message': "this id: '{}' does not exist in database.".format(id)}, 404
        res = request.get_json(silent=True)
        modif_data = T_OccurrencesContact(**res)
        try:
            modif_data.modif_db()
        except Exception as e:
            modif_data.rollback()
            return {e}, 500
        return modif_data.json(), 200


class T_OccurrencesContactAll(Resource):
    def get(self):
        return [x.json() for x in T_OccurrencesContact.query.all()]