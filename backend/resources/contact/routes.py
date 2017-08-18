from flask import Blueprint
from flask_restful import Resource, Api
from resources.contact.t_obs_contact import T_ObsContactByID, T_ObsContactAll
from resources.contact.t_occurrences_contact import T_OccurrencesContactByID, T_OccurrencesContactAll
from resources.contact.cor_role_obs_contact import CorRoleObsContactByID, CorRoleObsContactAll, CorRoleObsContactByRole, CorRoleObsContactByIDAndRole

routes = Blueprint('contact', __name__)

api = Api(routes)

api.add_resource(T_ObsContactAll, '/t_obs_contact')
api.add_resource(T_ObsContactByID, '/t_obs_contact/<string:id>')

api.add_resource(T_OccurrencesContactAll, '/t_occurrences_contact')
api.add_resource(T_OccurrencesContactByID, '/t_occurrences_contact/<string:id>')

api.add_resource(CorRoleObsContactAll, '/cor_role_obs_contact')
api.add_resource(CorRoleObsContactByID, '/cor_role_obs_contact/by_id/<string:id>')
api.add_resource(CorRoleObsContactByRole, '/cor_role_obs_contact/by_role/<string:role>')
api.add_resource(CorRoleObsContactByIDAndRole, '/cor_role_obs_contact/by_id_role/<string:id>/<string:role>')

