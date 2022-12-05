from geoalchemy2 import Geometry
from sqlalchemy import FetchedValue, ForeignKey, not_
from sqlalchemy.sql import select, func, and_
from sqlalchemy.orm import relationship, backref
from sqlalchemy.dialects.postgresql import UUID, JSONB
from werkzeug.exceptions import Forbidden

from pypnnomenclature.models import TNomenclatures
from pypnusershub.db.models import User
from pypn_habref_api.models import Habref
from apptax.taxonomie.models import Taxref
from utils_flask_sqla.serializers import serializable
from utils_flask_sqla_geo.serializers import geoserializable

from geonature.core.gn_commons.models import TMedias
from geonature.core.gn_meta.models import TDatasets
from geonature.utils.env import DB


class ReleveModel(DB.Model):
    """
    Classe abstraite permettant d'ajout des méthodes
    de controle d'accès à la donnée en fonction
    des droits associés à un utilisateur
    """

    __abstract__ = True

    def user_is_observer_or_digitiser(self, user):
        observers = [d.id_role for d in self.observers]
        return user.id_role == self.id_digitiser or user.id_role in observers

    def user_is_in_dataset_actor(self, user):
        return self.id_dataset in (
            d.id_dataset for d in TDatasets.query.filter_by_scope(int(user.value_filter)).all()
        )

    def user_is_allowed_to(self, user, level):
        """
        Fonction permettant de dire si un utilisateur
        peu ou non agir sur une donnée
        """
        # Si l'utilisateur n'a pas de droit d'accès aux données
        if level == "0" or level not in ("1", "2", "3"):
            return False

        # Si l'utilisateur à le droit d'accéder à toutes les données
        if level == "3":
            return True

        # Si l'utilisateur est propriétaire de la données
        if self.user_is_observer_or_digitiser(user):
            return True

        # Si l'utilisateur appartient à un organisme
        # qui a un droit sur la données et
        # que son niveau d'accès est 2 ou 3
        if self.user_is_in_dataset_actor(user) and level in ("2", "3"):
            return True
        return False

    def get_releve_if_allowed(self, user):
        """
        Return the releve if the user is allowed
        params:
            user: object from TRole
        """
        if self.user_is_allowed_to(user, user.value_filter):
            return self

        raise Forbidden(
            ('User "{}" cannot "{}" this current releve').format(user.id_role, user.code_action),
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
            action: self.user_is_allowed_to(user, level) for action, level in user_cruved.items()
        }


class corRoleRelevesOccurrence(DB.Model):
    __tablename__ = "cor_role_releves_occtax"
    __table_args__ = {"schema": "pr_occtax"}
    unique_id_cor_role_releve = DB.Column(
        "unique_id_cor_role_releve",
        UUID(as_uuid=True),
        default=select([func.uuid_generate_v4()]),
        primary_key=True,
    )
    id_releve_occtax = DB.Column(
        "id_releve_occtax",
        DB.Integer,
        ForeignKey("pr_occtax.t_releves_occtax.id_releve_occtax"),
        primary_key=False,
    )
    id_role = DB.Column(
        "id_role",
        DB.Integer,
        ForeignKey("utilisateurs.t_roles.id_role"),
        primary_key=False,
    )


@serializable
class CorCountingOccurrence(DB.Model):
    __tablename__ = "cor_counting_occtax"
    __table_args__ = {"schema": "pr_occtax"}
    id_counting_occtax = DB.Column(DB.Integer, primary_key=True)
    unique_id_sinp_occtax = DB.Column(
        UUID(as_uuid=True), default=select([func.uuid_generate_v4()]), nullable=False
    )
    id_occurrence_occtax = DB.Column(
        DB.Integer,
        ForeignKey("pr_occtax.t_occurrences_occtax.id_occurrence_occtax"),
        nullable=False,
    )
    id_nomenclature_life_stage = DB.Column(
        DB.Integer, nullable=False, server_default=FetchedValue()
    )
    id_nomenclature_sex = DB.Column(DB.Integer, nullable=False, server_default=FetchedValue())
    id_nomenclature_obj_count = DB.Column(
        DB.Integer, nullable=False, server_default=FetchedValue()
    )
    id_nomenclature_type_count = DB.Column(DB.Integer, server_default=FetchedValue())
    count_min = DB.Column(DB.Integer)
    count_max = DB.Column(DB.Integer)

    # additional fields dans occtax MET 14/10/2020
    additional_fields = DB.Column(JSONB)

    readonly_fields = [
        "id_counting_occtax",
        "unique_id_sinp_occtax",
        "id_occurrence_occtax",
    ]

    medias = DB.relationship(
        TMedias,
        primaryjoin=TMedias.uuid_attached_row == unique_id_sinp_occtax,
        foreign_keys=[TMedias.uuid_attached_row],
        cascade="all",
        lazy="select",
    )


@serializable
class TOccurrencesOccurrence(DB.Model):
    __tablename__ = "t_occurrences_occtax"
    __table_args__ = {"schema": "pr_occtax"}
    id_occurrence_occtax = DB.Column(DB.Integer, primary_key=True)
    id_releve_occtax = DB.Column(
        DB.Integer, ForeignKey("pr_occtax.t_releves_occtax.id_releve_occtax")
    )
    id_nomenclature_obs_technique = DB.Column(DB.Integer, server_default=FetchedValue())
    id_nomenclature_bio_condition = DB.Column(DB.Integer, server_default=FetchedValue())
    id_nomenclature_bio_status = DB.Column(DB.Integer, server_default=FetchedValue())
    id_nomenclature_naturalness = DB.Column(DB.Integer, server_default=FetchedValue())
    id_nomenclature_exist_proof = DB.Column(DB.Integer, server_default=FetchedValue())
    id_nomenclature_observation_status = DB.Column(DB.Integer, server_default=FetchedValue())
    id_nomenclature_blurring = DB.Column(DB.Integer, server_default=FetchedValue())
    id_nomenclature_source_status = DB.Column(DB.Integer, server_default=FetchedValue())
    determiner = DB.Column(DB.Unicode)
    id_nomenclature_determination_method = DB.Column(DB.Integer, server_default=FetchedValue())
    id_nomenclature_behaviour = DB.Column(DB.Integer, server_default=FetchedValue())
    cd_nom = DB.Column(DB.Integer, ForeignKey(Taxref.cd_nom))
    nom_cite = DB.Column(DB.Unicode)
    meta_v_taxref = DB.Column(
        DB.Unicode,
        default=select([func.gn_commons.get_default_parameter("taxref_version")]),
    )
    sample_number_proof = DB.Column(DB.Unicode)
    digital_proof = DB.Column(DB.Unicode)
    non_digital_proof = DB.Column(DB.Unicode)
    comment = DB.Column(DB.Unicode)

    # additional fields dans occtax MET 28/09/2020
    additional_fields = DB.Column(JSONB)

    unique_id_occurence_occtax = DB.Column(
        UUID(as_uuid=True),
        default=select([func.uuid_generate_v4()]),
    )
    cor_counting_occtax = relationship(
        "CorCountingOccurrence",
        lazy="joined",
        cascade="all,delete-orphan",
        uselist=True,
        backref=DB.backref("occurence", lazy="joined"),
    )

    taxref = relationship(Taxref, lazy="joined")

    readonly_fields = ["id_occurrence_occtax", "id_releve_occtax", "taxref"]


@serializable
@geoserializable
class TRelevesOccurrence(ReleveModel):
    __tablename__ = "t_releves_occtax"
    __table_args__ = {"schema": "pr_occtax"}
    id_releve_occtax = DB.Column(DB.Integer, primary_key=True)
    unique_id_sinp_grp = DB.Column(UUID(as_uuid=True), default=select([func.uuid_generate_v4()]))
    id_dataset = DB.Column(DB.Integer, ForeignKey("gn_meta.t_datasets.id_dataset"))
    id_digitiser = DB.Column(DB.Integer, ForeignKey("utilisateurs.t_roles.id_role"))
    id_nomenclature_grp_typ = DB.Column(DB.Integer, server_default=FetchedValue())
    id_module = DB.Column(DB.Integer, ForeignKey("gn_commons.t_modules.id_module"), nullable=False)
    grp_method = DB.Column(DB.Unicode)
    observers_txt = DB.Column(DB.Unicode)
    date_min = DB.Column(DB.DateTime)
    date_max = DB.Column(DB.DateTime)
    hour_min = DB.Column(DB.DateTime)
    hour_max = DB.Column(DB.DateTime)
    altitude_min = DB.Column(DB.Integer)
    altitude_max = DB.Column(DB.Integer)
    depth_min = DB.Column(DB.Integer)
    depth_max = DB.Column(DB.Integer)
    id_nomenclature_tech_collect_campanule = DB.Column(DB.Integer, server_default=FetchedValue())
    id_nomenclature_geo_object_nature = DB.Column(DB.Integer, server_default=FetchedValue())
    meta_device_entry = DB.Column(DB.Unicode)
    comment = DB.Column(DB.Unicode)
    place_name = DB.Column(DB.Unicode)
    geom_4326 = DB.Column(Geometry("GEOMETRY", 4326))
    geom_local = DB.Column(Geometry("GEOMETRY"))
    cd_hab = DB.Column(DB.Integer, ForeignKey(Habref.cd_hab))
    precision = DB.Column(DB.Integer)

    habitat = relationship(Habref, lazy="select")
    additional_fields = DB.Column(JSONB)

    t_occurrences_occtax = relationship(
        "TOccurrencesOccurrence", lazy="joined", cascade="all, delete-orphan"
    )

    observers = DB.relationship(
        User,
        lazy="joined",
        secondary=corRoleRelevesOccurrence.__table__,
        primaryjoin=(corRoleRelevesOccurrence.id_releve_occtax == id_releve_occtax),
        secondaryjoin=(corRoleRelevesOccurrence.id_role == User.id_role),
        foreign_keys=[
            corRoleRelevesOccurrence.id_releve_occtax,
            corRoleRelevesOccurrence.id_role,
        ],
    )

    digitiser = relationship(
        User,
        lazy="joined",
        primaryjoin=(User.id_role == id_digitiser),
        foreign_keys=[id_digitiser],
    )

    dataset = relationship(
        TDatasets,
        lazy="joined",
        primaryjoin=(TDatasets.id_dataset == id_dataset),
        foreign_keys=[id_dataset],
    )

    readonly_fields = ["id_releve_occtax", "t_occurrences_occtax", "observers"]

    def get_geofeature(self, fields=[], depth=None):
        return self.as_geofeature("geom_4326", "id_releve_occtax", fields=fields, depth=depth)


@serializable
@geoserializable
class VReleveOccurrence(ReleveModel):
    __tablename__ = "v_releve_occtax"
    __table_args__ = {"schema": "pr_occtax"}
    id_releve_occtax = DB.Column(DB.Integer)
    id_dataset = DB.Column(DB.Integer)
    id_digitiser = DB.Column(DB.Integer)
    date_min = DB.Column(DB.DateTime)
    date_max = DB.Column(DB.DateTime)
    altitude_min = DB.Column(DB.Integer)
    altitude_max = DB.Column(DB.Integer)
    depth_min = DB.Column(DB.Integer)
    depth_max = DB.Column(DB.Integer)
    place_name = DB.Column(DB.Unicode)
    meta_device_entry = DB.Column(DB.Unicode)
    comment = DB.Column(DB.Unicode)
    geom_4326 = DB.Column(Geometry("GEOMETRY", 4326))
    id_occurrence_occtax = DB.Column(DB.Integer, primary_key=True)
    cd_nom = DB.Column(DB.Integer)
    nom_cite = DB.Column(DB.Unicode)
    lb_nom = DB.Column(DB.Unicode)
    nom_valide = DB.Column(DB.Unicode)
    nom_vern = DB.Column(DB.Unicode)
    leaflet_popup = DB.Column(DB.Unicode)
    observateurs = DB.Column(DB.Unicode)
    observers = DB.relationship(
        User,
        secondary=corRoleRelevesOccurrence.__table__,
        primaryjoin=(corRoleRelevesOccurrence.id_releve_occtax == id_releve_occtax),
        secondaryjoin=(corRoleRelevesOccurrence.id_role == User.id_role),
        foreign_keys=[
            corRoleRelevesOccurrence.id_releve_occtax,
            corRoleRelevesOccurrence.id_role,
        ],
    )

    def get_geofeature(self, recursif=True):
        return self.as_geofeature("geom_4326", "id_occurrence_occtax", recursif)


@serializable
class DefaultNomenclaturesValue(DB.Model):
    __tablename__ = "defaults_nomenclatures_value"
    __table_args__ = {"schema": "pr_occtax"}
    mnemonique_type = DB.Column(DB.Integer, primary_key=True)
    id_organism = DB.Column(DB.Integer, primary_key=True)
    id_nomenclature = DB.Column(DB.Integer, primary_key=True)
