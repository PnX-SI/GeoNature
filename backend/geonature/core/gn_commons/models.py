'''
    Modèles du schéma gn_commons
'''

from sqlalchemy import ForeignKey

from geonature.utils.utilssqlalchemy import serializable
from geonature.utils.env import DB

@serializable
class TModules(DB.Model):
    __tablename__ = 't_modules'
    __table_args__ = {'schema': 'gn_commons'}
    id_module = DB.Column(
        DB.Integer,
        primary_key=True
    )
    module_name = DB.Column(DB.Unicode)
    module_picto = DB.Column(DB.Unicode)
    module_desc = DB.Column(DB.Unicode)
    module_group = DB.Column(DB.Unicode)
    module_url = DB.Column(DB.Unicode)
    module_comment = DB.Column(DB.Unicode)
    active = DB.Column(DB.Boolean)
