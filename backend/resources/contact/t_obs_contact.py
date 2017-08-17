from flask_restful import Resource
from flask import request

from models.contact.t_obs_contact import T_ObsContact

class T_ObsContactByID(Resource):
    def get(self, id):
        id = T_ObsContact.find_by_id(id)
        if id:
            return id.json()
        return {'message': 'id not found'}, 404

    def post(self, id):
        if T_ObsContact.find_by_id(id):
            return {'message': "this id: '{}' already exists.".format(id)}, 400
        res = request.get_json(silent=True)

        # item = T_ObsContact(id, data['price'], data['store_id'])

        # try:
        #     item.save_to_db()
        # except:
        #     return {"message": "An error occurred inserting the item."}, 500

        # return item.json(), 201
        return "toto"

    def delete(self, id):
        item = T_ObsContact.find_by_id(id)
        if item:
            item.delete_from_db()

        return {'message': 'Item deleted'}

    def put(self, id):
        data = Item.parser.parse_args()

        item = T_ObsContact.find_by_id(id)

        if item:
            item.price = data['price']
        else:
            item = T_ObsContact(id, data['price'])

        item.save_to_db()

        return item.json()

class T_ObsContactAll(Resource):
    def get(self):
        return [x.json() for x in T_ObsContact.query.all()]