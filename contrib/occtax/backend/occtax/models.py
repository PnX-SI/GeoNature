from typing import Any, Optional

from geoalchemy2 import Geometry
from sqlalchemy import FetchedValue, ForeignKey, not_
from sqlalchemy.sql import select, func, and_
from sqlalchemy.orm import relationship, backref, Mapped, mapped_column
from sqlalchemy.dialects.postgresql import UUID, JSONB
from flask import g

from pypnusershub.db.models import User
from pypn_habref_api.models import Habref
from apptax.taxonomie.models import Taxref
from utils_flask_sqla.serializers import serializable
from utils_flask_sqla_geo.serializers import geoserializable

from geonature.core.gn_commons.models import TMedias
from geonature.core.gn_meta.models import TDatasets
from geonature.core.gn_permissions.tools import get_scopes_by_action
from geonature.utils.env import DB, db


class corRoleRelevesOccurrence(DB.Model):
    __tablename__ = "cor_role_releves_occtax"
    __table_args__ = {"schema": "pr_occtax"}
    unique_id_cor_role_releve: Mapped[Any] = mapped_column(
        "unique_id_cor_role_releve",
        UUID(as_uuid=True),
        default=select(func.uuid_generate_v4()),
        primary_key=True,
    )
    id_releve_occtax: Mapped[Optional[int]] = mapped_column(
        "id_releve_occtax",
        DB.Integer,
        ForeignKey("pr_occtax.t_releves_occtax.id_releve_occtax"),
    )
    id_role: Mapped[Optional[int]] = mapped_column(
        "id_role",
        DB.Integer,
        ForeignKey("utilisateurs.t_roles.id_role"),
    )


@serializable
class CorCountingOccurrence(DB.Model):
    __tablename__ = "cor_counting_occtax"
    __table_args__ = {"schema": "pr_occtax"}
    id_counting_occtax: Mapped[int] = mapped_column(DB.Integer, primary_key=True)
    unique_id_sinp_occtax: Mapped[Any] = mapped_column(
        UUID(as_uuid=True), default=select(func.uuid_generate_v4())
    )
    id_occurrence_occtax: Mapped[int] = mapped_column(
        DB.Integer,
        ForeignKey("pr_occtax.t_occurrences_occtax.id_occurrence_occtax"),
    )
    id_nomenclature_life_stage: Mapped[int] = mapped_column(
        DB.Integer, server_default=FetchedValue()
    )
    id_nomenclature_sex: Mapped[int] = mapped_column(DB.Integer, server_default=FetchedValue())
    id_nomenclature_obj_count: Mapped[int] = mapped_column(
        DB.Integer, server_default=FetchedValue()
    )
    id_nomenclature_type_count: Mapped[Optional[int]] = mapped_column(
        DB.Integer, server_default=FetchedValue()
    )
    count_min: Mapped[Optional[int]]
    count_max: Mapped[Optional[int]]

    # additional fields dans occtax MET 14/10/2020
    additional_fields: Mapped[Optional[Any]] = mapped_column(JSONB)
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
        overlaps="medias",
    )


@serializable
class TOccurrencesOccurrence(DB.Model):
    __tablename__ = "t_occurrences_occtax"
    __table_args__ = {"schema": "pr_occtax"}
    id_occurrence_occtax: Mapped[int] = mapped_column(DB.Integer, primary_key=True)
    id_releve_occtax: Mapped[Optional[int]] = mapped_column(
        DB.Integer, ForeignKey("pr_occtax.t_releves_occtax.id_releve_occtax")
    )
    releve = relationship("TRelevesOccurrence", back_populates="t_occurrences_occtax")
    id_nomenclature_obs_technique: Mapped[Optional[int]] = mapped_column(
        DB.Integer, server_default=FetchedValue()
    )
    id_nomenclature_bio_condition: Mapped[Optional[int]] = mapped_column(
        DB.Integer, server_default=FetchedValue()
    )
    id_nomenclature_bio_status: Mapped[Optional[int]] = mapped_column(
        DB.Integer, server_default=FetchedValue()
    )
    id_nomenclature_naturalness: Mapped[Optional[int]] = mapped_column(
        DB.Integer, server_default=FetchedValue()
    )
    id_nomenclature_exist_proof: Mapped[Optional[int]] = mapped_column(
        DB.Integer, server_default=FetchedValue()
    )
    id_nomenclature_observation_status: Mapped[Optional[int]] = mapped_column(
        DB.Integer, server_default=FetchedValue()
    )
    id_nomenclature_blurring: Mapped[Optional[int]] = mapped_column(
        DB.Integer, server_default=FetchedValue()
    )
    id_nomenclature_source_status: Mapped[Optional[int]] = mapped_column(
        DB.Integer, server_default=FetchedValue()
    )
    determiner: Mapped[Optional[str]] = mapped_column(DB.Unicode)
    id_nomenclature_determination_method: Mapped[Optional[int]] = mapped_column(
        DB.Integer, server_default=FetchedValue()
    )
    id_nomenclature_behaviour: Mapped[Optional[int]] = mapped_column(
        DB.Integer, server_default=FetchedValue()
    )
    cd_nom: Mapped[Optional[int]] = mapped_column(DB.Integer, ForeignKey(Taxref.cd_nom))
    nom_cite: Mapped[Optional[str]] = mapped_column(DB.Unicode)
    meta_v_taxref: Mapped[Optional[str]] = mapped_column(
        DB.Unicode,
        default=select(func.gn_commons.get_default_parameter("taxref_version")),
    )
    sample_number_proof: Mapped[Optional[str]] = mapped_column(DB.Unicode)
    digital_proof: Mapped[Optional[str]] = mapped_column(DB.Unicode)
    non_digital_proof: Mapped[Optional[str]] = mapped_column(DB.Unicode)
    comment: Mapped[Optional[str]] = mapped_column(DB.Unicode)

    # additional fields dans occtax MET 28/09/2020
    additional_fields: Mapped[Optional[Any]] = mapped_column(JSONB)

    unique_id_occurence_occtax: Mapped[Optional[Any]] = mapped_column(
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
    id_releve_occtax: Mapped[int] = mapped_column(DB.Integer, primary_key=True)
    unique_id_sinp_grp: Mapped[Optional[Any]] = mapped_column(
        UUID(as_uuid=True), default=select(func.uuid_generate_v4())
    )
    id_dataset: Mapped[Optional[int]] = mapped_column(
        DB.Integer, ForeignKey("gn_meta.t_datasets.id_dataset")
    )
    id_digitiser: Mapped[Optional[int]] = mapped_column(
        DB.Integer, ForeignKey("utilisateurs.t_roles.id_role")
    )
    id_nomenclature_grp_typ: Mapped[Optional[int]] = mapped_column(
        DB.Integer, server_default=FetchedValue()
    )
    id_module: Mapped[int] = mapped_column(DB.Integer, ForeignKey("gn_commons.t_modules.id_module"))
    grp_method: Mapped[Optional[str]] = mapped_column(DB.Unicode)
    observers_txt: Mapped[Optional[str]] = mapped_column(DB.Unicode)
    date_min: Mapped[Optional[Any]] = mapped_column(DB.DateTime)
    date_max: Mapped[Optional[Any]] = mapped_column(DB.DateTime)
    hour_min: Mapped[Optional[Any]] = mapped_column(DB.DateTime)
    hour_max: Mapped[Optional[Any]] = mapped_column(DB.DateTime)
    altitude_min: Mapped[Optional[int]]
    altitude_max: Mapped[Optional[int]]
    depth_min: Mapped[Optional[int]]
    depth_max: Mapped[Optional[int]]
    id_nomenclature_tech_collect_campanule: Mapped[Optional[int]] = mapped_column(
        DB.Integer, server_default=FetchedValue()
    )
    id_nomenclature_geo_object_nature: Mapped[Optional[int]] = mapped_column(
        DB.Integer, server_default=FetchedValue()
    )
    meta_device_entry: Mapped[Optional[str]] = mapped_column(DB.Unicode)
    comment: Mapped[Optional[str]] = mapped_column(DB.Unicode)
    place_name: Mapped[Optional[str]] = mapped_column(DB.Unicode)
    geom_4326: Mapped[Optional[Any]] = mapped_column(Geometry("GEOMETRY", 4326))
    geom_local: Mapped[Optional[Any]] = mapped_column(Geometry("GEOMETRY"))
    cd_hab: Mapped[Optional[int]] = mapped_column(DB.Integer, ForeignKey(Habref.cd_hab))
    precision: Mapped[Optional[int]]

    habitat = relationship(Habref, lazy="select")
    additional_fields: Mapped[Optional[Any]] = mapped_column(JSONB)

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
        primaryjoin=(User.id_role == id_digitiser),
        foreign_keys=[id_digitiser],
    )

    dataset = relationship(
        TDatasets,
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
    mnemonique_type: Mapped[int] = mapped_column(DB.Integer, primary_key=True)
    id_organism: Mapped[int] = mapped_column(DB.Integer, primary_key=True)
    id_nomenclature: Mapped[int] = mapped_column(DB.Integer, primary_key=True)
