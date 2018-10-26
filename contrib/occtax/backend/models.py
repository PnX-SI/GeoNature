
from flask import current_app
from sqlalchemy import ForeignKey
from sqlalchemy.sql import select, func
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
from geoalchemy2 import Geometry

from geonature.utils.utilssqlalchemy import (
    serializable, geoserializable
)
from geonature.utils.env import DB
from geonature.utils.errors import InsufficientRightsError
from geonature.core.users.models import TRoles
from geonature.core.gn_meta.models import TDatasets


class ReleveModel(DB.Model):
    """
        Classe abstraite permettant d'ajout des méthodes
        de controle d'accès à la donnée en fonction
        des droits associés à un utilisateur
    """

    __abstract__ = True

    def user_is_observer_or_digitiser(self, user):
        observers = [d.id_role for d in self.observers]
        print(user)
        print(observers)
        return user.id_role == self.id_digitiser or user.id_role in observers

    def user_is_in_dataset_actor(self, user):
        return self.id_dataset in TDatasets.get_user_datasets(user)

    def user_is_allowed_to(self, user, level):
        """
            Fonction permettant de dire si un utilisateur
            peu ou non agir sur une donnée
        """
        # Si l'utilisateur n'a pas de droit d'accès aux données
        if level == '0' or level not in ('1', '2', '3'):
            return False

        # Si l'utilisateur à le droit d'accéder à toutes les données
        if level == '3':
            return True

        # Si l'utilisateur est propriétaire de la données
        if self.user_is_observer_or_digitiser(user):
            return True

        # Si l'utilisateur appartient à un organisme
        # qui a un droit sur la données et
        # que son niveau d'accès est 2 ou 3
        if (
            self.user_is_in_dataset_actor(user) and
            level in ('2', '3')
        ):
            print('actor and 2 or 3')
            return True
        return False

    def get_releve_if_allowed(self, user):
        """
            Return the releve if the user is allowed
            params:
                user: object from TRole
        """
        if self.user_is_allowed_to(user, user.tag_object_code):
            return self

        raise InsufficientRightsError(
            ('User "{}" cannot "{}" this current releve')
            .format(user.id_role, user.tag_action_code),
            403
        )

    def get_releve_cruved(self, user, user_cruved):
        """
        Return the user's cruved for a Releve instance.
        Use in the map-list interface to allow or not an action
        params:
            - user : a TRole object
            - user_cruved: object return by cruved_for_user_in_app(user)
        """
        return {
            action: self.user_is_allowed_to(user, level)
            for action, level in user_cruved.items()
        }


corRoleRelevesOccurrence = DB.Table(
    'cor_role_releves_occtax',
    DB.MetaData(schema='pr_occtax'),
    DB.Column(
        'unique_id_cor_role_releve',
        UUID(as_uuid=True),
        default=select([func.uuid_generate_v4()]),
        primary_key=True
    ),
    DB.Column(
        'id_releve_occtax',
        DB.Integer,
        ForeignKey('pr_occtax.t_releves_occtax.id_releve_occtax'),
        primary_key=False
    ),
    DB.Column(
        'id_role',
        DB.Integer,
        ForeignKey('utilisateurs.t_roles.id_role'),
        primary_key=False
    )
)


@serializable
class CorCountingOccurrence(DB.Model):
    __tablename__ = 'cor_counting_occtax'
    __table_args__ = {'schema': 'pr_occtax'}
    id_counting_occtax = DB.Column(DB.Integer, primary_key=True)
    id_occurrence_occtax = DB.Column(
        DB.Integer,
        ForeignKey('pr_occtax.t_occurrences_occtax.id_occurrence_occtax')
    )
    id_nomenclature_life_stage = DB.Column(DB.Integer)
    id_nomenclature_sex = DB.Column(DB.Integer)
    id_nomenclature_obj_count = DB.Column(DB.Integer)
    id_nomenclature_type_count = DB.Column(DB.Integer)
    count_min = DB.Column(DB.Integer)
    count_max = DB.Column(DB.Integer)


@serializable
class TOccurrencesOccurrence(DB.Model):
    __tablename__ = 't_occurrences_occtax'
    __table_args__ = {'schema': 'pr_occtax'}
    id_occurrence_occtax = DB.Column(DB.Integer, primary_key=True)
    id_releve_occtax = DB.Column(
        DB.Integer,
        ForeignKey('pr_occtax.t_releves_occtax.id_releve_occtax')
    )
    id_nomenclature_obs_meth = DB.Column(DB.Integer)
    id_nomenclature_bio_condition = DB.Column(DB.Integer)
    id_nomenclature_bio_status = DB.Column(DB.Integer)
    id_nomenclature_naturalness = DB.Column(DB.Integer)
    id_nomenclature_exist_proof = DB.Column(DB.Integer)
    id_nomenclature_diffusion_level = DB.Column(DB.Integer)
    id_nomenclature_observation_status = DB.Column(DB.Integer)
    id_nomenclature_blurring = DB.Column(DB.Integer)
    id_nomenclature_source_status = DB.Column(DB.Integer)
    determiner = DB.Column(DB.Unicode)
    id_nomenclature_determination_method = DB.Column(DB.Integer)
    cd_nom = DB.Column(DB.Integer)
    nom_cite = DB.Column(DB.Unicode)
    meta_v_taxref = DB.Column(
        DB.Unicode,
        default=select([func.gn_commons.get_default_parameter('taxref_version')])
    )
    sample_number_proof = DB.Column(DB.Unicode)
    digital_proof = DB.Column(DB.Unicode)
    non_digital_proof = DB.Column(DB.Unicode)
    comment = DB.Column(DB.Unicode)

    cor_counting_occtax = relationship(
        "CorCountingOccurrence",
        lazy='joined',
        cascade="all, delete-orphan"
    )


@serializable
@geoserializable
class TRelevesOccurrence(ReleveModel):
    __tablename__ = 't_releves_occtax'
    __table_args__ = {'schema': 'pr_occtax'}
    id_releve_occtax = DB.Column(DB.Integer, primary_key=True)
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
    id_nomenclature_obs_technique = DB.Column(DB.Integer)
    meta_device_entry = DB.Column(DB.Unicode)
    comment = DB.Column(DB.Unicode)
    geom_4326 = DB.Column(Geometry('GEOMETRY', 4326))
    geom_local = DB.Column(
        Geometry('GEOMETRY', current_app.config['LOCAL_SRID'])
    )

    t_occurrences_occtax = relationship(
        "TOccurrencesOccurrence",
        lazy='joined',
        cascade="all,delete-orphan"
    )

    observers = DB.relationship(
        'TRoles',
        secondary=corRoleRelevesOccurrence,
        primaryjoin=(
            corRoleRelevesOccurrence.c.id_releve_occtax == id_releve_occtax
        ),
        secondaryjoin=(corRoleRelevesOccurrence.c.id_role == TRoles.id_role),
        foreign_keys=[
            corRoleRelevesOccurrence.c.id_releve_occtax,
            corRoleRelevesOccurrence.c.id_role
        ]
    )

    digitiser = relationship("TRoles", foreign_keys=[id_digitiser])

    def get_geofeature(self, recursif=True):
        return self.as_geofeature('geom_4326', 'id_releve_occtax', recursif)


@serializable
@geoserializable
class VReleveOccurrence(ReleveModel):
    __tablename__ = 'v_releve_occtax'
    __table_args__ = {'schema': 'pr_occtax'}
    id_releve_occtax = DB.Column(DB.Integer)
    id_dataset = DB.Column(DB.Integer)
    id_digitiser = DB.Column(DB.Integer)
    date_min = DB.Column(DB.DateTime)
    date_max = DB.Column(DB.DateTime)
    altitude_min = DB.Column(DB.Integer)
    altitude_max = DB.Column(DB.Integer)
    meta_device_entry = DB.Column(DB.Unicode)
    comment = DB.Column(DB.Unicode)
    geom_4326 = DB.Column(Geometry('GEOMETRY', 4326))
    id_occurrence_occtax = DB.Column(DB.Integer, primary_key=True)
    cd_nom = DB.Column(DB.Integer)
    nom_cite = DB.Column(DB.Unicode)
    lb_nom = DB.Column(DB.Unicode)
    nom_valide = DB.Column(DB.Unicode)
    nom_vern = DB.Column(DB.Unicode)
    leaflet_popup = DB.Column(DB.Unicode)
    observateurs = DB.Column(DB.Unicode)
    observers = DB.relationship(
        'TRoles',
        secondary=corRoleRelevesOccurrence,
        primaryjoin=(
            corRoleRelevesOccurrence.c.id_releve_occtax == id_releve_occtax
        ),
        secondaryjoin=(corRoleRelevesOccurrence.c.id_role == TRoles.id_role),
        foreign_keys=[
            corRoleRelevesOccurrence.c.id_releve_occtax,
            corRoleRelevesOccurrence.c.id_role
        ]
    )

    def get_geofeature(self, recursif=True):
        return self.as_geofeature(
            'geom_4326',
            'id_occurrence_occtax',
            recursif
        )


@serializable
@geoserializable
class VReleveList(ReleveModel):
    __tablename__ = 'v_releve_list'
    __table_args__ = {'schema': 'pr_occtax'}
    id_releve_occtax = DB.Column(DB.Integer, primary_key=True)
    id_dataset = DB.Column(DB.Integer)
    id_digitiser = DB.Column(DB.Integer)
    date_min = DB.Column(DB.DateTime)
    date_max = DB.Column(DB.DateTime)
    altitude_min = DB.Column(DB.Integer)
    altitude_max = DB.Column(DB.Integer)
    meta_device_entry = DB.Column(DB.Unicode)
    comment = DB.Column(DB.Unicode)
    geom_4326 = DB.Column(Geometry('GEOMETRY', 4326))
    taxons = DB.Column(DB.Unicode)
    leaflet_popup = DB.Column(DB.Unicode)
    observateurs = DB.Column(DB.Unicode)
    dataset_name = DB.Column(DB.Unicode)
    observers = DB.relationship(
        'TRoles',
        secondary=corRoleRelevesOccurrence,
        primaryjoin=(
            corRoleRelevesOccurrence.c.id_releve_occtax == id_releve_occtax
        ),
        secondaryjoin=(corRoleRelevesOccurrence.c.id_role == TRoles.id_role),
        foreign_keys=[
            corRoleRelevesOccurrence.c.id_releve_occtax,
            corRoleRelevesOccurrence.c.id_role
        ]
    )

    def get_geofeature(self, recursif=True):

        return self.as_geofeature('geom_4326', 'id_releve_occtax', recursif)


@serializable
class DefaultNomenclaturesValue(DB.Model):
    __tablename__ = 'defaults_nomenclatures_value'
    __table_args__ = {'schema': 'pr_occtax'}
    mnemonique_type = DB.Column(DB.Integer, primary_key=True)
    id_organism = DB.Column(DB.Integer, primary_key=True)
    id_nomenclature = DB.Column(DB.Integer, primary_key=True)
