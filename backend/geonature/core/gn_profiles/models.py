from flask import current_app
from geoalchemy2 import Geometry
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.ext.hybrid import hybrid_property
from sqlalchemy.sql.schema import ForeignKey
from sqlalchemy.orm import relationship, backref, deferred
from geoalchemy2 import Geometry

from utils_flask_sqla.serializers import serializable
from utils_flask_sqla_geo.serializers import geoserializable
from pypnnomenclature.models import TNomenclatures

from geonature.utils.env import DB, db
from geonature.core.gn_synthese.models import Synthese
from geonature.core.taxonomie.models import Taxref


@serializable
class VmCorTaxonPhenology(DB.Model):
    __tablename__ = "vm_cor_taxon_phenology"
    __table_args__ = {"schema": "gn_profiles"}
    cd_ref = DB.Column(DB.Integer, primary_key=True)
    doy_min = DB.Column(DB.Integer, primary_key=True)
    doy_max = DB.Column(DB.Integer, primary_key=True)
    id_nomenclature_life_stage = DB.Column(
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        primary_key=True,
    )
    extreme_altitude_min = DB.Column(DB.Integer)
    calculated_altitude_min = DB.Column(DB.Integer)
    extreme_altitude_max = DB.Column(DB.Integer)
    calculated_altitude_max = DB.Column(DB.Integer)
    nomenclature_life_stage = DB.relationship("TNomenclatures")


@serializable
@geoserializable(geoCol="valid_distribution", idCol="cd_ref")
class VmValidProfiles(DB.Model):
    __tablename__ = "vm_valid_profiles"
    __table_args__ = {"schema": "gn_profiles"}
    cd_ref = DB.Column(DB.Integer, primary_key=True)
    valid_distribution = DB.Column(Geometry("GEOMETRY"))
    altitude_min = DB.Column(DB.Integer)
    altitude_max = DB.Column(DB.Integer)
    first_valid_data = DB.Column(DB.DateTime)
    last_valid_data = DB.Column(DB.DateTime)
    count_valid_data = DB.Column(DB.Integer)
    active_life_stage = DB.Column(DB.Boolean)


@serializable
class VConsistancyData(DB.Model):
    __tablename__ = "v_consistancy_data"
    __table_args__ = {"schema": "gn_profiles"}
    id_synthese = DB.Column(DB.Integer, ForeignKey(Synthese.id_synthese), primary_key=True)
    synthese = relationship(Synthese, backref=backref("profile", uselist=False))
    id_sinp = DB.Column(UUID(as_uuid=True))
    cd_ref = DB.Column(DB.Integer)
    valid_name = DB.Column(DB.Unicode)
    valid_distribution = DB.Column(DB.Boolean)
    valid_phenology = DB.Column(DB.Boolean)
    valid_altitude = DB.Column(DB.Boolean)
    # score = DB.Column(DB.Integer)
    valid_status = DB.Column(DB.Unicode)

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

    id_synthese = db.Column(db.Integer, ForeignKey(Synthese.id_synthese), primary_key=True)
    synthese = relationship(Synthese)
    cd_nom = db.Column(db.Integer)
    nom_cite = db.Column(db.Unicode(length=1000))
    cd_ref = db.Column(db.Integer)
    nom_valide = db.Column(db.Unicode(length=500))
    id_rang = db.Column(db.Unicode(length=10))
    date_min = db.Column(db.DateTime)
    date_max = db.Column(db.DateTime)
    the_geom_local = deferred(db.Column(Geometry("GEOMETRY")))
    the_geom_4326 = deferred(db.Column(Geometry("GEOMETRY", 4326)))
    altitude_min = db.Column(db.Integer)
    altitude_max = db.Column(db.Integer)

    id_nomenclature_life_stage = db.Column(db.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_life_stage = db.relationship(
        TNomenclatures, foreign_keys=[id_nomenclature_life_stage]
    )
    id_nomenclature_valid_status = db.Column(
        db.Integer, ForeignKey(TNomenclatures.id_nomenclature)
    )
    nomenclature_valid_status = db.relationship(
        TNomenclatures, foreign_keys=[id_nomenclature_valid_status]
    )

    spatial_precision = db.Column(db.Integer)
    temporal_precision_days = db.Column(db.Integer)
    active_life_stage = db.Column(db.Boolean)
    distance = db.Column(db.Integer)


class TParameters(DB.Model):
    __tablename__ = "t_parameters"
    __table_args__ = {"schema": "gn_profiles"}
    id_parameter = DB.Column(DB.Integer, primary_key=True)
    name = DB.Column(DB.String(100))
    desc = DB.Column(DB.Text)
    value = DB.Column(DB.Text)


class CorTaxonParameters(DB.Model):
    __tablename__ = "cor_taxons_parameters"
    __table_args__ = {"schema": "gn_profiles"}
    cd_nom = DB.Column(DB.Integer, ForeignKey(Taxref.cd_nom), primary_key=True)
    spatial_precision = DB.Column(DB.Integer)
    temporal_precision_days = DB.Column(DB.Integer)
    active_life_stage = DB.Column(DB.Boolean)
