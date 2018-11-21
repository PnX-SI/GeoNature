from geonature.utils.utilssqlalchemy import serializable
from geonature.utils.env import DB


@serializable
class VUsersPermissions(DB.Model):
    __tablename__ = 'v_users_permissions'
    __table_args__ = {'schema': 'gn_permissions'}
    id_role = DB.Column(DB.Integer, primary_key=True)
    nom_role = DB.Column(DB.Unicode)
    prenom_role = DB.Column(DB.Unicode)
    id_organisme = DB.Column(DB.Integer)
    id_module = DB.Column(DB.Integer, primary_key=True)
    module_code = DB.Column(DB.Unicode)
    id_action = DB.Column(DB.Integer, primary_key=True)
    id_filter = DB.Column(DB.Integer, primary_key=True)
    code_action = DB.Column(DB.Unicode)
    code_filter = DB.Column(DB.Unicode)
    code_filter_type = DB.Column(DB.Unicode)
    id_filter_type = DB.Column(DB.Integer)

    def __repr__(self):
        return """VUsersPermissions
            role='{}' action='{}' filter='{}' module='{}' filter_type='{}'>""".format(
            self.id_role, self.code_action,
            self.code_action, self.module_code, self.code_filter_type
        )
