from typing import Optional, Any
from datetime import datetime

from flask import current_app
from geoalchemy2 import Geometry
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.ext.hybrid import hybrid_property
from sqlalchemy.sql.schema import ForeignKey
from sqlalchemy.orm import relationship, backref, deferred, Mapped, mapped_column
from geoalchemy2 import Geometry

from utils_flask_sqla.serializers import serializable
from utils_flask_sqla_geo.serializers import geoserializable
from pypnnomenclature.models import TNomenclatures

from geonature.utils.env import DB, db
from geonature.core.gn_synthese.models import Synthese

from apptax.taxonomie.models import Taxref


@serializable
class VmCorTaxonPhenology(DB.Model):
    __tablename__ = "vm_cor_taxon_phenology"
    __table_args__ = {"schema": "gn_profiles"}
    cd_ref: Mapped[int] = mapped_column(DB.Integer, primary_key=True)
    doy_min: Mapped[int] = mapped_column(DB.Integer, primary_key=True)
    doy_max: Mapped[int] = mapped_column(DB.Integer, primary_key=True)
    id_nomenclature_life_stage: Mapped[int] = mapped_column(
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        primary_key=True,
    )
    extreme_altitude_min: Mapped[Optional[int]]
    calculated_altitude_min: Mapped[Optional[int]]
    extreme_altitude_max: Mapped[Optional[int]]
    calculated_altitude_max: Mapped[Optional[int]]
    nomenclature_life_stage = DB.relationship("TNomenclatures")


@serializable
@geoserializable(geoCol="valid_distribution", idCol="cd_ref")
class VmValidProfiles(DB.Model):
    __tablename__ = "vm_valid_profiles"
    __table_args__ = {"schema": "gn_profiles"}
    cd_ref: Mapped[int] = mapped_column(DB.Integer, primary_key=True)
    valid_distribution: Mapped[Optional[Any]] = mapped_column(Geometry("GEOMETRY"))
    altitude_min: Mapped[Optional[int]]
    altitude_max: Mapped[Optional[int]]
    first_valid_data: Mapped[Optional[datetime]] = mapped_column(DB.DateTime)
    last_valid_data: Mapped[Optional[datetime]] = mapped_column(DB.DateTime)
    count_valid_data: Mapped[Optional[int]]
    active_life_stage: Mapped[Optional[bool]]


@serializable
class VConsistencyData(DB.Model):
    __tablename__ = "v_consistancy_data"
    __table_args__ = {"schema": "gn_profiles"}
    id_synthese: Mapped[int] = mapped_column(DB.Integer, ForeignKey(Synthese.id_synthese), primary_key=True)
    synthese = relationship(Synthese, backref=backref("profile", uselist=False))
    id_sinp: Mapped[Optional[Any]] = mapped_column(UUID(as_uuid=True))
    cd_ref: Mapped[Optional[int]]
    valid_name: Mapped[Optional[str]] = mapped_column(DB.Unicode)
    valid_distribution: Mapped[Optional[bool]]
    valid_phenology: Mapped[Optional[bool]]
    valid_altitude: Mapped[Optional[bool]]
    # score = DB.Column(DB.Integer)
    valid_status: Mapped[Optional[str]] = mapped_column(DB.Unicode)

    @hybrid_property
    def score(self):
        return int(
            int(self.valid_distribution is True)
            + int(self.valid_phenology is True)
            + int(self.valid_altitude is True)
        )

    @score.expression
    def score(cls):
        return (
            cls.valid_distribution.cast(sa.Integer)
            + cls.valid_phenology.cast(sa.Integer)
            + cls.valid_altitude.cast(sa.Integer)
        )


class VSyntheseForProfiles(db.Model):
    __tablename__ = "v_synthese_for_profiles"
    __table_args__ = {"schema": "gn_profiles"}

    id_synthese: Mapped[int] = mapped_column(db.Integer, ForeignKey(Synthese.id_synthese), primary_key=True)
    synthese = relationship(Synthese)
    cd_nom: Mapped[Optional[int]]
    nom_cite: Mapped[Optional[str]] = mapped_column(db.Unicode(length=1000))
    cd_ref: Mapped[Optional[int]]
    nom_valide: Mapped[Optional[str]] = mapped_column(db.Unicode(length=500))
    id_rang: Mapped[Optional[str]] = mapped_column(db.Unicode(length=10))
    date_min: Mapped[Optional[datetime]] = mapped_column(db.DateTime)
    date_max: Mapped[Optional[datetime]] = mapped_column(db.DateTime)
    the_geom_local: Mapped[Optional[Any]] = deferred(mapped_column(Geometry("GEOMETRY")))
    the_geom_4326: Mapped[Optional[Any]] = deferred(mapped_column(Geometry("GEOMETRY", 4326)))
    altitude_min: Mapped[Optional[int]]
    altitude_max: Mapped[Optional[int]]

    id_nomenclature_life_stage: Mapped[Optional[int]] = mapped_column(db.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_life_stage = db.relationship(
        TNomenclatures, foreign_keys=[id_nomenclature_life_stage]
    )
    id_nomenclature_valid_status: Mapped[Optional[int]] = mapped_column(db.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_valid_status = db.relationship(
        TNomenclatures, foreign_keys=[id_nomenclature_valid_status]
    )

    spatial_precision: Mapped[Optional[int]]
    temporal_precision_days: Mapped[Optional[int]]
    active_life_stage: Mapped[Optional[bool]]
    distance: Mapped[Optional[int]]


class TParameters(DB.Model):
    __tablename__ = "t_parameters"
    __table_args__ = {"schema": "gn_profiles"}
    id_parameter: Mapped[int] = mapped_column(DB.Integer, primary_key=True)
    name: Mapped[Optional[str]] = mapped_column(DB.String(100))
    desc: Mapped[Optional[str]] = mapped_column(DB.Text)
    value: Mapped[Optional[str]] = mapped_column(DB.Text)


class CorTaxonParameters(DB.Model):
    __tablename__ = "cor_taxons_parameters"
    __table_args__ = {"schema": "gn_profiles"}
    cd_nom: Mapped[int] = mapped_column(DB.Integer, ForeignKey(Taxref.cd_nom), primary_key=True)
    spatial_precision: Mapped[Optional[int]]
    temporal_precision_days: Mapped[Optional[int]]
    active_life_stage: Mapped[Optional[bool]]
