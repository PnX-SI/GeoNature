from flask import Blueprint
from flask_restful import Resource, Api
from resources.contactfaune.t_releves_cfaune import RelevesCFaune, RelevesCFauneAll
from resources.contactfaune.t_occurences_cfaune import OccurencesCFaune, OccurencesCFauneAll

adresses = Blueprint('contactfaune', __name__)

api = Api(adresses)

api.add_resource(RelevesCFauneAll, '/releves_cfaunes')
api.add_resource(RelevesCFaune, '/releves_cfaunes/<string:id>')

api.add_resource(OccurencesCFauneAll, '/occurences_cfaunes')
api.add_resource(OccurencesCFaune, '/occurences_cfaunes/<string:id>')
