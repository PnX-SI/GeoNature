from datetime import datetime
from typing import Any, Optional

import sqlalchemy as sa
from flask import g
from geoalchemy2 import Geometry
from sqlalchemy import ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship, synonym, deferred, Mapped, mapped_column
from sqlalchemy.schema import FetchedValue, UniqueConstraint
from sqlalchemy.sql import func, select


from geonature.core.gn_meta.models import TDatasets as Dataset
from geonature.core.imports.models import TImports as Import
from geonature.utils.env import db
from pypnnomenclature.models import TNomenclatures as Nomenclature
from pypnnomenclature.utils import NomenclaturesMixin
from pypnusershub.db.models import User
from utils_flask_sqla.models import qfilter
from utils_flask_sqla.serializers import serializable
from werkzeug.datastructures import TypeConversionDict

from flask_login import current_user

cor_station_observer = db.Table(
    "cor_station_observer",
    db.Column("id_cor_station_observer", db.Integer, primary_key=True),
    db.Column("id_station", db.Integer, ForeignKey("pr_occhab.t_stations.id_station")),
    db.Column("id_role", db.Integer, ForeignKey(User.id_role)),
    UniqueConstraint("id_station", "id_role"),
    schema="pr_occhab",
)


class CorStationObserver(db.Model):
    __table__ = cor_station_observer


class Station(NomenclaturesMixin, db.Model):
    __tablename__ = "t_stations"
    __table_args__ = {"schema": "pr_occhab"}

    id_station: Mapped[int] = mapped_column(db.Integer, primary_key=True)
    id_station_source: Mapped[Optional[str]] = mapped_column(db.String)
    unique_id_sinp_station: Mapped[Optional[Any]] = mapped_column(
        UUID(as_uuid=True),
        server_default=select(func.uuid_generate_v4()),
    )
    id_dataset: Mapped[int] = mapped_column(db.Integer, ForeignKey(Dataset.id_dataset))
    dataset = relationship(Dataset)
    date_min: Mapped[Optional[datetime]] = mapped_column(db.DateTime, server_default=FetchedValue())
    date_max: Mapped[Optional[datetime]] = mapped_column(db.DateTime, server_default=FetchedValue())
    observers_txt: Mapped[Optional[str]] = mapped_column(db.Unicode(length=500))
    station_name: Mapped[Optional[str]] = mapped_column(db.Unicode(length=1000))
    # is_habitat_complex = db.Column(db.Boolean)
    id_nomenclature_type_mosaique_habitat: Mapped[Optional[int]] = mapped_column(
        db.Integer,
        ForeignKey(Nomenclature.id_nomenclature),
    )
    type_mosaique_habitat = db.relationship(
        Nomenclature,
        foreign_keys=[id_nomenclature_type_mosaique_habitat],
    )
    altitude_min: Mapped[Optional[int]]
    altitude_max: Mapped[Optional[int]]
    depth_min: Mapped[Optional[int]]
    depth_max: Mapped[Optional[int]]
    area: Mapped[Optional[int]] = mapped_column(db.BigInteger)
    comment: Mapped[Optional[str]] = mapped_column(db.Unicode)
    precision: Mapped[Optional[int]]
    id_digitiser: Mapped[Optional[int]]
    geom_local: Mapped[Optional[Any]] = deferred(mapped_column(Geometry("GEOMETRY")))
    geom_4326: Mapped[Optional[Any]] = mapped_column(Geometry("GEOMETRY", 4326))
    id_import: Mapped[Optional[int]] = mapped_column(db.Integer, ForeignKey(Import.id_import))

    habitats = relationship(
        "OccurenceHabitat",
        lazy="joined",
        cascade="all, delete-orphan",
        back_populates="station",
    )
    t_habitats = synonym(habitats)
    observers = db.relationship(
        User,
        secondary=cor_station_observer,
        lazy="joined",
    )

    id_nomenclature_exposure: Mapped[Optional[int]] = mapped_column(
        db.Integer,
        ForeignKey(Nomenclature.id_nomenclature),
    )
    nomenclature_exposure = db.relationship(
        Nomenclature,
        foreign_keys=[id_nomenclature_exposure],
    )
    id_nomenclature_area_surface_calculation: Mapped[Optional[int]] = mapped_column(
        db.Integer,
        ForeignKey(Nomenclature.id_nomenclature),
    )
    nomenclature_area_surface_calculation = db.relationship(
        Nomenclature,
        foreign_keys=[id_nomenclature_area_surface_calculation],
    )
    id_nomenclature_geographic_object: Mapped[Optional[int]] = mapped_column(
        db.Integer, ForeignKey(Nomenclature.id_nomenclature), server_default=FetchedValue()
    )
    nomenclature_geographic_object = db.relationship(
        Nomenclature,
        foreign_keys=[id_nomenclature_geographic_object],
    )
    id_nomenclature_type_sol: Mapped[Optional[int]] = mapped_column(
        db.Integer, ForeignKey(Nomenclature.id_nomenclature), server_default=FetchedValue()
    )
    nomenclature_type_sol = db.relationship(
        Nomenclature,
        foreign_keys=[id_nomenclature_type_sol],
    )
    # habref = db.relationship(Habref, lazy="joined")

    def has_instance_permission(self, scope):
        if scope == 0:
            return False
        elif scope in (1, 2):
            # L’utilisateur est observateur de la station
            # ou numérisateur de la station
            # ou à les droits sur le JDD auquel est rattaché la station.
            return (
                g.current_user in self.observers
                or (self.id_digitiser and self.id_digitiser == g.current_user.id_role)
                or self.dataset.has_instance_permission(scope)
            )
        elif scope == 3:
            return True

    @qfilter(query=True)
    def filter_by_params(cls, params, *, query):
        params = TypeConversionDict(**params)
        id_dataset = params.get("id_dataset", type=int)
        if id_dataset:
            query = query.where(Station.id_dataset == id_dataset)

        cd_hab = params.get("cd_hab", type=int)
        if cd_hab:
            query = query.where(Station.habitats.any(OccurenceHabitat.cd_hab == cd_hab))

        date_low = params.get("date_low", type=lambda x: datetime.strptime(x, "%Y-%m-%d"))
        if date_low:
            query = query.where(Station.date_min >= date_low)
        date_up = params.get("date_up", type=lambda x: datetime.strptime(x, "%Y-%m-%d"))
        if date_up:
            query = query.where(Station.date_max <= date_up)
        id_import = params.get("id_import", type=int)
        if id_import:
            query = query.where(
                sa.or_(
                    Station.id_import == id_import,
                    Station.habitats.any(OccurenceHabitat.id_import == id_import),
                )
            )
        return query

    @qfilter
    def filter_by_scope(cls, scope, user=None, **kwargs):
        """
        Filter Station instances by scope and user.

        Parameters
        ----------
        scope : int
            0, 1, 2 or 3
        user : User, optional
            user instance. If None, use current_user (default is None)

        Returns
        -------
        sqlalchemy.sql.expression.BooleanClauseList
            filter by scope and user
        """
        if user is None:
            user = current_user

        if scope == 0:
            return False
        elif scope in (1, 2):
            ds_query = Dataset.filter_by_scope(scope, user=user)
            ds_list = select(Dataset.id_dataset).select_entity_from(ds_query)

            return sa.or_(
                Station.observers.any(id_role=user.id_role),
                sa.and_(
                    Station.id_digitiser.is_not(None),
                    Station.id_digitiser == user.id_role,
                ),
                Station.id_dataset.in_([ds.id_dataset for ds in db.session.execute(ds_list).all()]),
            )
        return True


@serializable
class OccurenceHabitat(NomenclaturesMixin, db.Model):
    __tablename__ = "t_habitats"
    __table_args__ = {"schema": "pr_occhab"}

    id_habitat: Mapped[int] = mapped_column(db.Integer, primary_key=True)
    id_station: Mapped[int] = mapped_column(db.Integer, ForeignKey(Station.id_station))
    station = db.relationship(
        Station, lazy="joined", back_populates="habitats"
    )  # TODO: remove joined
    unique_id_sinp_hab: Mapped[Optional[Any]] = mapped_column(
        UUID(as_uuid=True),
        server_default=select(func.uuid_generate_v4()),
    )
    cd_hab: Mapped[int] = mapped_column(db.Integer, ForeignKey("ref_habitats.habref.cd_hab"))
    habref = db.relationship("Habref", lazy="joined")
    nom_cite: Mapped[str] = mapped_column(db.Unicode)
    determiner: Mapped[Optional[str]] = mapped_column(db.Unicode)
    recovery_percentage: Mapped[Optional[float]] = mapped_column(db.Float)
    technical_precision: Mapped[Optional[str]] = mapped_column(db.Unicode)
    id_import: Mapped[Optional[int]] = mapped_column(db.Integer, ForeignKey(Import.id_import))

    id_nomenclature_determination_type: Mapped[Optional[int]] = mapped_column(
        db.Integer, ForeignKey(Nomenclature.id_nomenclature)
    )
    nomenclature_determination_type = db.relationship(
        Nomenclature,
        foreign_keys=[id_nomenclature_determination_type],
    )
    id_nomenclature_collection_technique: Mapped[int] = mapped_column(
        db.Integer,
        ForeignKey(Nomenclature.id_nomenclature),
        server_default=FetchedValue(),
    )
    nomenclature_collection_technique = db.relationship(
        Nomenclature,
        foreign_keys=[id_nomenclature_collection_technique],
    )
    id_nomenclature_abundance: Mapped[Optional[int]] = mapped_column(
        db.Integer,
        ForeignKey(Nomenclature.id_nomenclature),
    )
    nomenclature_abundance = db.relationship(
        Nomenclature,
        foreign_keys=[id_nomenclature_abundance],
    )
    id_nomenclature_sensitivity: Mapped[Optional[int]] = mapped_column(
        "id_nomenclature_sensitvity",  # TODO fix db column typo
        db.Integer,
        ForeignKey(Nomenclature.id_nomenclature),
    )
    nomenclature_sensitivity = db.relationship(
        Nomenclature,
        foreign_keys=[id_nomenclature_sensitivity],
    )
    id_nomenclature_community_interest: Mapped[Optional[int]] = mapped_column(
        "id_nomenclature_community_interest",
        db.Integer,
        ForeignKey(Nomenclature.id_nomenclature),
    )
    nomenclature_community_interest = db.relationship(
        Nomenclature,
        foreign_keys=[id_nomenclature_community_interest],
    )


@serializable
class DefaultNomenclatureValue(db.Model):
    __tablename__ = "defaults_nomenclatures_value"
    __table_args__ = {"schema": "pr_occhab"}
    mnemonique_type: Mapped[int] = mapped_column(db.Integer, primary_key=True)
    id_organism: Mapped[int] = mapped_column(db.Integer, primary_key=True)
    id_nomenclature: Mapped[int] = mapped_column(db.Integer, primary_key=True)
