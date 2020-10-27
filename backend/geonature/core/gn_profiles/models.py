from geonature.utils.env import DB
from utils_flask_sqla.serializers import serializable

@serializable
class VmCorTaxonPhenology(DB.Model):
    __tablename__ = "vm_cor_taxon_phenology"
    __table_args__ = {"schema": "gn_profiles"}
    cd_ref = DB.Column(DB.Integer)
    period = DB.Column(DB.Integer)
    id_nomenclature_life_stage = DB.Column(DB.Integer)
    id_altitude_range = DB.Column(DB.Integer)
    count_valid_data = DB.Column(DB.Integer)
