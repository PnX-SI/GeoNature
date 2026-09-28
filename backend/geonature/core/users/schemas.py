"""
Minimal user / organism schemas used whenever a user or an organism is nested in
another GeoNature payload (observers, digitiser, dataset actors, validators, ...).

They expose an explicit whitelist of fields instead of relying on the defaults of
``pypnusershub.schemas.UserSchema`` / ``OrganismeSchema``, so that personal data
(email, identifiant, remarques, API keys, organism address/phone/email, ...) can't
leak through a nested relationship, whatever the UsersHub schemas expose by default.
"""

from marshmallow import fields, pre_load

from utils_flask_sqla.schema import SmartRelationshipsMixin
from pypnusershub.db.models import User, Organisme

from geonature.utils.env import MA, db

MINIMAL_USER_FIELDS = ("id_role", "nom_role", "prenom_role", "nom_complet", "id_organisme")
MINIMAL_ORGANISM_FIELDS = ("id_organisme", "uuid_organisme", "nom_organisme")


class MinimalOrganismeSchema(SmartRelationshipsMixin, MA.SQLAlchemyAutoSchema):
    class Meta:
        model = Organisme
        load_instance = True
        sqla_session = db.session
        fields = MINIMAL_ORGANISM_FIELDS


class MinimalUserSchema(SmartRelationshipsMixin, MA.SQLAlchemyAutoSchema):
    """
    Nested user: only ``MINIMAL_USER_FIELDS`` are serialized. The ``organisme``
    relationship (itself minimal) is only serialized when explicitly asked for
    (e.g. ``only=["cor_observers.organisme"]``), as with any SmartRelationshipsMixin
    relationship.
    """

    class Meta:
        model = User
        include_fk = True
        load_instance = True
        sqla_session = db.session
        fields = MINIMAL_USER_FIELDS + ("organisme",)

    nom_complet = fields.String(dump_only=True)
    organisme = fields.Nested(MinimalOrganismeSchema, dump_only=True)

    @pre_load
    def make_observer(self, data, **kwargs):
        # Allow loading a user from its id only (same as pypnusershub UserSchema)
        if isinstance(data, int):
            return dict({"id_role": data})
        return data
