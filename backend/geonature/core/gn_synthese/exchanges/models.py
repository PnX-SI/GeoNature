from geonature.utils.env import DB
from utils_flask_sqla_geo.serializers import geoserializable
from utils_flask_sqla.serializers import serializable
from sqlalchemy.dialects.postgresql import UUID, JSONB
from geoalchemy2 import Geometry
from flask import current_app

# Redefinition car si on prend le modele depuis ../models.py, il y a un bug (modeles trop tricotés????)
# Relation ships ?? 
@geoserializable
class Synthese(DB.Model):
    __tablename__ = "synthese"
    __table_args__ = {"schema": "gn_synthese", "extend_existing": True}
    id_synthese = DB.Column(DB.Integer, primary_key=True, autoincrement=True)
    unique_id_sinp = DB.Column(UUID(as_uuid=True))
    unique_id_sinp_grp = DB.Column(UUID(as_uuid=True))
    id_source = DB.Column(DB.Integer)
    entity_source_pk_value = DB.Column(DB.Integer)
    id_dataset = DB.Column(DB.Integer)
    id_nomenclature_grp_typ = DB.Column(DB.Integer)
    grp_method = DB.Column(DB.Unicode)
    id_nomenclature_geo_object_nature = DB.Column(DB.Integer)
    id_nomenclature_info_geo_type = DB.Column(DB.Integer)
    id_nomenclature_obs_technique = DB.Column(DB.Integer)
    id_nomenclature_bio_status = DB.Column(DB.Integer)
    id_nomenclature_bio_condition = DB.Column(DB.Integer)
    id_nomenclature_naturalness = DB.Column(DB.Integer)
    id_nomenclature_exist_proof = DB.Column(DB.Integer)
    id_nomenclature_valid_status = DB.Column(DB.Integer)
    id_nomenclature_diffusion_level = DB.Column(DB.Integer)
    id_nomenclature_life_stage = DB.Column(DB.Integer)
    id_nomenclature_sex = DB.Column(DB.Integer)
    id_nomenclature_obj_count = DB.Column(DB.Integer)
    id_nomenclature_type_count = DB.Column(DB.Integer)
    id_nomenclature_sensitivity = DB.Column(DB.Integer)
    id_nomenclature_observation_status = DB.Column(DB.Integer)
    id_nomenclature_blurring = DB.Column(DB.Integer)
    id_nomenclature_source_status = DB.Column(DB.Integer)
    id_nomenclature_behaviour = DB.Column(DB.Integer)
    count_min = DB.Column(DB.Integer)
    count_max = DB.Column(DB.Integer)
    cd_nom = DB.Column(DB.Integer)
    nom_cite = DB.Column(DB.Unicode)
    meta_v_taxref = DB.Column(DB.Unicode)
    sample_number_proof = DB.Column(DB.Unicode)
    digital_proof = DB.Column(DB.Unicode)
    non_digital_proof = DB.Column(DB.Unicode)
    altitude_min = DB.Column(DB.Integer)
    altitude_max = DB.Column(DB.Integer)
    depth_min = DB.Column(DB.Integer)
    depth_max = DB.Column(DB.Integer)
    precision = DB.Column(DB.Integer)
    the_geom_4326 = DB.Column(Geometry("GEOMETRY", 4326))
    the_geom_point = DB.Column(Geometry("GEOMETRY", 4326))
    the_geom_local = DB.Column(Geometry("GEOMETRY", current_app.config["LOCAL_SRID"]))
    place_name = DB.Column(DB.Unicode)
    date_min = DB.Column(DB.DateTime)
    date_max = DB.Column(DB.DateTime)
    validator = DB.Column(DB.Unicode)
    validation_comment = DB.Column(DB.Unicode)
    observers = DB.Column(DB.Unicode)
    determiner = DB.Column(DB.Unicode)
    id_digitiser = DB.Column(DB.Integer)
    id_nomenclature_determination_method = DB.Column(DB.Integer)
    comment_context = DB.Column(DB.Unicode)
    comment_description = DB.Column(DB.Unicode)
    additional_data = DB.Column(JSONB)
    meta_validation_date = DB.Column(DB.DateTime)
    meta_create_date = DB.Column(DB.DateTime)
    meta_update_date = DB.Column(DB.DateTime)
    last_action = DB.Column(DB.Unicode)
    

@serializable
class TSources(DB.Model):
    '''
        Sources pour la synthese
    '''

    __tablename__ = "t_sources"
    __table_args__ = {"schema": "gn_synthese", "extend_existing": True}
    id_source = DB.Column(DB.Integer, primary_key=True)
    name_source = DB.Column(DB.Unicode)
    desc_source = DB.Column(DB.Unicode),
    entity_source_pk_field = DB.Column(DB.Unicode)
    url_source = DB.Column(DB.Unicode)
    meta_create_date = DB.Column(DB.DateTime)
    meta_update_date = DB.Column(DB.DateTime)
