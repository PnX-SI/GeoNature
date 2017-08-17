from flask_restful import Resource

from models.contact.t_obs_contact import T_ObsContact

class T_ObsContactByID(Resource):
    def get(self, id):
        id = T_ObsContact.find_by_id(id)
        if id:
            return id.json()
        return {'message': 'id not found'}, 404

class T_ObsContactAll(Resource):
    def get(self):
        return [x.json() for x in T_ObsContact.query.all()]