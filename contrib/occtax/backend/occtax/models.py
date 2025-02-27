from geoalchemy2 import Geometry
from sqlalchemy import FetchedValue, ForeignKey, not_
from sqlalchemy.sql import select, func, and_
from sqlalchemy.orm import relationship, backref
from sqlalchemy.dialects.postgresql import UUID, JSONB
from werkzeug.exceptions import Forbidden
from flask import g

from pypnnomenclature.models import TNomenclatures
from pypnusershub.db.models import User
from pypn_habref_api.models import Habref
from apptax.taxonomie.models import Taxref, TMetaTaxref
from utils_flask_sqla.serializers import serializable
from utils_flask_sqla_geo.serializers import geoserializable

from geonature.core.gn_commons.models import TMedias
from geonature.core.gn_meta.models import TDatasets
from geonature.core.gn_permissions.tools import get_scopes_by_action
from geonature.utils.env import DB, db


class corRoleRelevesOccurrence(DB.Model):
    __tablename__ = "cor_role_releves_occtax"
    __table_args__ = {"schema": "pr_occtax"}
    unique_id_cor_role_releve = DB.Column(
        "unique_id_cor_role_releve",
        UUID(as_uuid=True),
        default=select(func.uuid_generate_v4()),
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
        UUID(as_uuid=True), default=select(func.uuid_generate_v4()), nullable=False
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
    id_nomenclature_obj_count = DB.Column(DB.Integer, nullable=False, server_default=FetchedValue())
    id_nomenclature_type_count = DB.Column(DB.Integer, server_default=FetchedValue())
    count_min = DB.Column(DB.Integer)
    count_max = DB.Column(DB.Integer)

    # additional fields dans occtax MET 14/10/2020
    additional_fields = DB.Column(JSONB)
    occurrence = db.relationship("TOccurrencesOccurrence", back_populates="cor_counting_occtax")
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
    releve = relationship("TRelevesOccurrence", back_populates="t_occurrences_occtax")
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
    sample_number_proof = DB.Column(DB.Unicode)
    digital_proof = DB.Column(DB.Unicode)
    non_digital_proof = DB.Column(DB.Unicode)
    comment = DB.Column(DB.Unicode)

    # additional fields dans occtax MET 28/09/2020
    additional_fields = DB.Column(JSONB)

    unique_id_occurence_occtax = DB.Column(
        UUID(as_uuid=True),
        default=select(func.uuid_generate_v4()),
    )
    cor_counting_occtax = relationship(
        CorCountingOccurrence,
        lazy="joined",
        cascade="all,delete-orphan",
        uselist=True,
        back_populates="occurrence",
    )

    taxref = relationship(Taxref, lazy="joined")

    readonly_fields = ["id_occurrence_occtax", "id_releve_occtax", "taxref"]


@serializable
@geoserializable
class TRelevesOccurrence(DB.Model):
    __tablename__ = "t_releves_occtax"
    __table_args__ = {"schema": "pr_occtax"}
    id_releve_occtax = DB.Column(DB.Integer, primary_key=True)
    unique_id_sinp_grp = DB.Column(UUID(as_uuid=True), default=select(func.uuid_generate_v4()))
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
        "TOccurrencesOccurrence",
        lazy="joined",
        cascade="all, delete-orphan",
        back_populates="releve",
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

    def has_instance_permission(self, scope):
        """
        Fonction permettant de dire si un utilisateur
        peu ou non agir sur une donnée
        """
        # Si l'utilisateur à le droit d'accéder à toutes les données
        if scope == 3:
            return True
        elif scope in (1, 2):
            return (
                g.current_user.id_role == self.id_digitiser
                or g.current_user in self.observers
                or (
                    self.dataset and self.dataset.has_instance_permission(scope)
                )  # dataset is loaded
                or (
                    not self.dataset
                    and db.session.get(TDatasets, self.id_dataset).has_instance_permission(scope)
                )  # dataset is not loaded
            )
        else:
            return False

    def get_releve_cruved(self, **kwargs):
        """
        Return the user's cruved for a Releve instance.
        Use in the map-list interface to allow or not an action
        params:
            - user : a TRole object
            - kwargs:  extra args for get_scopes_by_action
        """
        return {
            action: self.has_instance_permission(scope)
            for action, scope in get_scopes_by_action(**kwargs).items()
        }


@serializable
class DefaultNomenclaturesValue(DB.Model):
    __tablename__ = "defaults_nomenclatures_value"
    __table_args__ = {"schema": "pr_occtax"}
    mnemonique_type = DB.Column(DB.Integer, primary_key=True)
    id_organism = DB.Column(DB.Integer, primary_key=True)
    id_nomenclature = DB.Column(DB.Integer, primary_key=True)
