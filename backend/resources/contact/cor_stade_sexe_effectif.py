from flask_restful import Resource
from flask import request

from models.contact.cor_stade_sexe_effectif import CorStadeSexEffectif

# class CorRoleObsContactByIDAndRole(Resource):
#     def get(self, id, role):
#         row = CorRoleObsContact.find_by_id_role(id, role)
#         if row:
#             return row.json()
#         return {'message': 'id : role not found'}, 404

#     def post(self, id, role):
#         if CorRoleObsContact.find_by_id_role(id, role):
#             return {'message': "this id: '{}' role: '{}' already exists.".format(id,role)}, 400
#         res = request.get_json(silent=True)
#         insert_data = CorRoleObsContact(**res)
#         try:
#             insert_data.add_to_db()
#         except Exception as e:
#             insert_data.rollback()
#             return {e}, 500
#         return insert_data.json(), 200

#     def delete(self, id, role):
#         row = CorRoleObsContact.find_by_id_role(id, role)
#         if not row:
#             return {'message': "this id: '{}' role: '{}'  does not exist in database.".format(id,role)}, 404
#         else:
#             try:
#                 row.delete_from_db()
#             except Exception as e:
#                 return {e}, 500
#         return {'message': "data id: '{}' role: '{}' deleted".format(id,role)}, 200