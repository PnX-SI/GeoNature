from flask import current_app
from geoalchemy2 import Geometry
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.ext.hybrid import hybrid_property
from sqlalchemy.sql.schema import ForeignKey

from utils_flask_sqla.serializers import serializable
from utils_flask_sqla_geo.serializers import geoserializable

from geonature.utils.env import DB
from geonature.utils.config import config



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
    valid_distribution = DB.Column(Geometry("GEOMETRY", config["LOCAL_SRID"]))
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
    id_synthese = DB.Column(DB.Integer, primary_key=True)
    id_sinp = DB.Column(UUID(as_uuid=True))
    cd_ref = DB.Column(DB.Integer)
    valid_name = DB.Column(DB.Unicode)
    valid_distribution = DB.Column(DB.Boolean)
    valid_phenology = DB.Column(DB.Boolean)
    valid_altitude = DB.Column(DB.Boolean)
    # score = DB.Column(DB.Integer)
    valid_status = DB.Column(DB.Unicode)

    def as_dict(self, data):
        score = (data["valid_distribution"] or 0) + (
                data["valid_altitude"] or 0
                ) + (data["valid_phenology"] or 0)
        data.update({"score":score})
        return data
