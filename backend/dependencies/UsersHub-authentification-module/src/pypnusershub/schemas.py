from marshmallow import pre_load, fields

from pypnusershub.env import MA 
from pypnusershub.db.models import User, Organisme

class UserSchema(MA.SQLAlchemyAutoSchema):
    class Meta:
        model = User
        load_instance = True
        exclude = (
            "_password",
            "_password_plus",
            "active",
            "date_insert",
            "date_update",
            "desc_role",
            "email",
            "groupe",
            "remarques",
            "identifiant",
        )

    nom_complet = fields.Function(
        lambda obj: (obj.nom_role if obj.nom_role else "")
        + (" " + obj.prenom_role if obj.prenom_role else "")
    )

    @pre_load
    def make_observer(self, data, **kwargs):
        if isinstance(data, int):
            return dict({"id_role": data})
        return data

class OrganismeSchema(MA.SQLAlchemyAutoSchema):
    class Meta:
        model = Organisme
        load_instance = True