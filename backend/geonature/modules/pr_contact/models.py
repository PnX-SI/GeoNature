
from sqlalchemy import ForeignKey
from sqlalchemy.sql import select, func
from sqlalchemy.orm import relationship
# from sqlalchemy.orm.exc import NoResultFound
from sqlalchemy.dialects.postgresql import UUID

from geonature.utils.utilssqlalchemy import (
    serializableModel, serializableGeoModel
)

from pypnusershub.db.tools import InsufficientRightsError

from geonature.utils.env import DB
from geonature.core.users.models import TRoles
from geonature.core.gn_meta import routes as gn_meta

from geoalchemy2 import Geometry


class ReleveModel(DB.Model):
    __abstract__ = True

    def user_is_observer_or_digitiser(self, user):
        observers = [d.id_role for d in self.observers]
        return user.id_role == self.id_digitiser or user.id_role in observers

    def user_is_in_dataset_actor(self, user):
        return self.id_dataset in gn_meta.get_allowed_datasets(user)

    def get_releve_if_allowed(self, user):
        """Return the releve if the user is allowed
          -params:
          user: object from TRole
        """
        if user.tag_object_code == '2':
            if (
                self.user_is_observer_or_digitiser(user) or
                self.user_is_in_dataset_actor(user)
            ):
                return self
        elif user.tag_object_code == '1':
            if self.user_is_observer_or_digitiser(user):
                return self
        else:
            return self
        raise InsufficientRightsError(
            ('User "{}" cannot "{}" this current releve')
            .format(user.id_role, user.tag_action_code),
            403
        )

    def get_releve_cruved(self, user, user_cruved):
        """ return the user's cruved for a Releve instance.
        Use in the map-list interface to allow or not an action
        params:
            - user : a TRole object
            - user_cruved: object return by fnauth.get_cruved(user) """
        releve_auth = {}
        allowed_datasets = gn_meta.get_allowed_datasets(user)
        for obj in user_cruved:
            if obj['level'] == '2':
                releve_auth[obj['action']] = self.user_is_observer_or_digitiser(user) or  self.user_is_in_dataset_actor(user)
            elif obj['level'] == '1':
                releve_auth[obj['action']] = self.user_is_observer_or_digitiser(user)
            elif obj['level'] == '3':
                releve_auth[obj['action']] = True
            else:
                releve_auth[obj['action']] = False
        return releve_auth


corRoleRelevesContact = DB.Table(
    'cor_role_releves_contact',
    DB.MetaData(schema='pr_contact'),
    DB.Column(
        'id_releve_contact',
        DB.Integer,
        ForeignKey('pr_contact.t_releves_contact.id_releve_contact'),
        primary_key=True
    ),
    DB.Column(
        'id_role',
        DB.Integer,
        ForeignKey('utilisateurs.t_roles.id_role'),
        primary_key=True
    )
)


class TRelevesContact(serializableGeoModel, ReleveModel):
    __tablename__ = 't_releves_contact'
    __table_args__ = {'schema': 'pr_contact'}
    id_releve_contact = DB.Column(DB.Integer, primary_key=True)
    id_dataset = DB.Column(DB.Integer)
    id_digitiser = DB.Column(
        DB.Integer,
        ForeignKey('utilisateurs.t_roles.id_role')
    )
    id_nomenclature_grp_typ = DB.Column(DB.Integer)
    observers_txt = DB.Column(DB.Unicode)
    date_min = DB.Column(DB.DateTime)
    date_max = DB.Column(DB.DateTime)
    hour_min = DB.Column(DB.DateTime)
    hour_max = DB.Column(DB.DateTime)
    altitude_min = DB.Column(DB.Integer)
    altitude_max = DB.Column(DB.Integer)
    meta_device_entry = DB.Column(DB.Unicode)
    deleted = DB.Column(DB.Boolean, default=False)
    meta_create_date = DB.Column(DB.DateTime)
    meta_update_date = DB.Column(DB.DateTime)
    comment = DB.Column(DB.Unicode)
    geom_local = DB.Column(Geometry)
    geom_4326 = DB.Column(Geometry('GEOMETRY', 4326))

    t_occurrences_contact = relationship(
        "TOccurrencesContact",
        lazy='joined',
        cascade="all,delete-orphan"
    )

    observers = DB.relationship(
        'TRoles',
        secondary=corRoleRelevesContact,
        primaryjoin=(
            corRoleRelevesContact.c.id_releve_contact == id_releve_contact
        ),
        secondaryjoin=(corRoleRelevesContact.c.id_role == TRoles.id_role),
        foreign_keys=[
            corRoleRelevesContact.c.id_releve_contact,
            corRoleRelevesContact.c.id_role
        ]
    )

    digitiser = relationship("TRoles", foreign_keys=[id_digitiser])

    def get_geofeature(self, recursif=True):
        return self.as_geofeature('geom_4326', 'id_releve_contact', recursif)


class TOccurrencesContact(serializableModel):
    __tablename__ = 't_occurrences_contact'
    __table_args__ = {'schema': 'pr_contact'}
    id_occurrence_contact = DB.Column(DB.Integer, primary_key=True)
    id_releve_contact = DB.Column(
        DB.Integer,
        ForeignKey('pr_contact.t_releves_contact.id_releve_contact')
    )
    id_nomenclature_obs_meth = DB.Column(DB.Integer)
    id_nomenclature_bio_condition = DB.Column(DB.Integer)
    id_nomenclature_bio_status = DB.Column(DB.Integer)
    id_nomenclature_naturalness = DB.Column(DB.Integer)
    id_nomenclature_exist_proof = DB.Column(DB.Integer)
    id_nomenclature_valid_status = DB.Column(DB.Integer)
    id_nomenclature_diffusion_level = DB.Column(DB.Integer)
    id_nomenclature_observation_status = DB.Column(DB.Integer)
    id_nomenclature_blurring = DB.Column(DB.Integer)
    id_validator = DB.Column(DB.Integer)
    determiner = DB.Column(DB.Unicode)
    id_nomenclature_determination_method = DB.Column(DB.Integer)
    determination_method_as_text = DB.Column(DB.Unicode)
    cd_nom = DB.Column(DB.Integer)
    nom_cite = DB.Column(DB.Unicode)
    meta_v_taxref = DB.Column(
        DB.Unicode,
        default=select([func.get_default_parameter('taxref_version', 'NULL')])
    )
    sample_number_proof = DB.Column(DB.Unicode)
    digital_proof = DB.Column(DB.Unicode)
    non_digital_proof = DB.Column(DB.Unicode)
    deleted = DB.Column(DB.Boolean)
    meta_create_date = DB.Column(DB.DateTime)
    meta_update_date = DB.Column(DB.DateTime)
    comment = DB.Column(DB.Unicode)

    cor_counting_contact = relationship(
        "CorCountingContact",
        lazy='joined',
        cascade="all, delete-orphan"
    )


class CorCountingContact(serializableModel):
    __tablename__ = 'cor_counting_contact'
    __table_args__ = {'schema': 'pr_contact'}
    id_counting_contact = DB.Column(DB.Integer, primary_key=True)
    id_occurrence_contact = DB.Column(
        DB.Integer,
        ForeignKey('pr_contact.t_occurrences_contact.id_occurrence_contact')
    )
    id_nomenclature_life_stage = DB.Column(DB.Integer)
    id_nomenclature_sex = DB.Column(DB.Integer)
    id_nomenclature_obj_count = DB.Column(DB.Integer)
    id_nomenclature_type_count = DB.Column(DB.Integer)
    count_min = DB.Column(DB.Integer)
    count_max = DB.Column(DB.Integer)
    unique_id_sinp_occtax = DB.Column(
        UUID(as_uuid=True),
        default=select([func.uuid_generate_v4()])
    )


class VReleveContact(serializableGeoModel, ReleveModel):
    __tablename__ = 'v_releve_contact'
    __table_args__ = {'schema': 'pr_contact'}
    id_releve_contact = DB.Column(DB.Integer)
    id_dataset = DB.Column(DB.Integer)
    id_digitiser = DB.Column(DB.Integer)
    date_min = DB.Column(DB.DateTime)
    date_max = DB.Column(DB.DateTime)
    altitude_min = DB.Column(DB.Integer)
    altitude_max = DB.Column(DB.Integer)
    meta_device_entry = DB.Column(DB.Unicode)
    deleted = DB.Column(DB.Boolean, default=False)
    meta_create_date = DB.Column(DB.DateTime)
    meta_update_date = DB.Column(DB.DateTime)
    comment = DB.Column(DB.Unicode)
    geom_4326 = DB.Column(Geometry('GEOMETRY', 4326))
    id_occurrence_contact = DB.Column(DB.Integer, primary_key=True)
    cd_nom = DB.Column(DB.Integer)
    nom_cite = DB.Column(DB.Unicode)
    occ_deleted = DB.Column(DB.Boolean)
    occ_meta_create_date = DB.Column(DB.DateTime)
    occ_meta_update_date = DB.Column(DB.DateTime)
    lb_nom = DB.Column(DB.Unicode)
    nom_valide = DB.Column(DB.Unicode)
    nom_vern = DB.Column(DB.Unicode)
    leaflet_popup = DB.Column(DB.Unicode)
    observateurs = DB.Column(DB.Unicode)
    observers = DB.relationship(
        'TRoles',
        secondary=corRoleRelevesContact,
        primaryjoin=(
            corRoleRelevesContact.c.id_releve_contact == id_releve_contact
        ),
        secondaryjoin=(corRoleRelevesContact.c.id_role == TRoles.id_role),
        foreign_keys=[
            corRoleRelevesContact.c.id_releve_contact,
            corRoleRelevesContact.c.id_role
        ]
    )

    def get_geofeature(self, recursif=True):
        return self.as_geofeature(
            'geom_4326',
            'id_occurrence_contact',
            recursif
        )


class VReleveList(serializableGeoModel, ReleveModel):
    __tablename__ = 'v_releve_list'
    __table_args__ = {'schema': 'pr_contact'}
    id_releve_contact = DB.Column(DB.Integer, primary_key=True)
    id_dataset = DB.Column(DB.Integer)
    id_digitiser = DB.Column(DB.Integer)
    date_min = DB.Column(DB.DateTime)
    date_max = DB.Column(DB.DateTime)
    altitude_min = DB.Column(DB.Integer)
    altitude_max = DB.Column(DB.Integer)
    meta_device_entry = DB.Column(DB.Unicode)
    deleted = DB.Column(DB.Boolean, default=False)
    meta_create_date = DB.Column(DB.DateTime)
    meta_update_date = DB.Column(DB.DateTime)
    comment = DB.Column(DB.Unicode)
    geom_4326 = DB.Column(Geometry('GEOMETRY', 4326))
    taxons = DB.Column(DB.Unicode)
    leaflet_popup = DB.Column(DB.Unicode)
    observateurs = DB.Column(DB.Unicode)
    observers = DB.relationship(
        'TRoles',
        secondary=corRoleRelevesContact,
        primaryjoin=(
            corRoleRelevesContact.c.id_releve_contact == id_releve_contact
        ),
        secondaryjoin=(corRoleRelevesContact.c.id_role == TRoles.id_role),
        foreign_keys=[
            corRoleRelevesContact.c.id_releve_contact,
            corRoleRelevesContact.c.id_role
        ]
    )

    def get_geofeature(self, recursif=True):

        return self.as_geofeature('geom_4326', 'id_releve_contact', recursif)


class DefaultNomenclaturesValue(serializableModel):
    __tablename__ = 'defaults_nomenclatures_value'
    __table_args__ = {'schema': 'pr_contact'}
    id_type = DB.Column(DB.Integer, primary_key=True)
    id_organism = DB.Column(DB.Integer, primary_key=True)
    id_nomenclature = DB.Column(DB.Integer, primary_key=True)
