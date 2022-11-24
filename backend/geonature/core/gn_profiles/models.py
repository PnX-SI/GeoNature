from flask import current_app
from geoalchemy2 import Geometry
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.ext.hybrid import hybrid_property
from sqlalchemy.sql.schema import ForeignKey
from sqlalchemy.orm import relationship, backref

from utils_flask_sqla.serializers import serializable
from utils_flask_sqla_geo.serializers import geoserializable

from geonature.utils.env import DB
from geonature.core.gn_synthese.models import Synthese


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
@geoserializable
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

    def get_geofeature(self, recursif=False, columns=()):
        return self.as_geofeature("valid_distribution", "cd_ref", recursif, columns=columns)


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
