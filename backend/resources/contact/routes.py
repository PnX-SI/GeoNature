from flask import Blueprint
from flask_restful import Resource, Api
from resources.contact.t_obs_contact import T_ObsContactByID, T_ObsContactAll
from resources.contact.t_occurrences_contact import T_OccurrencesContactByID, T_OccurrencesContactAll

routes = Blueprint('contact', __name__)

api = Api(routes)

api.add_resource(T_ObsContactAll, '/t_obs_contact')
api.add_resource(T_ObsContactByID, '/t_obs_contact/<string:id>')

api.add_resource(T_OccurrencesContactAll, '/t_occurrences_contact')
api.add_resource(T_OccurrencesContactByID, '/t_occurrences_contact/<string:id>')
