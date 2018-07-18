from sqlalchemy import ForeignKey, or_
from sqlalchemy.orm import relationship
from sqlalchemy.sql import select, func
# from sqlalchemy.orm import relationship, exc
from sqlalchemy.dialects.postgresql import UUID
from geoalchemy2 import Geometry

from werkzeug.exceptions import NotFound

from pypnnomenclature.models import TNomenclatures

from geonature.utils.utilssqlalchemy import (
    serializable, geoserializable
)
from geonature.utils.env import DB
from geonature.core.ref_geo.models import LiMunicipalities


@serializable
class TSources(DB.Model):
    __tablename__ = 't_sources'
    __table_args__ = {'schema': 'gn_synthese'}
    id_source = DB.Column(DB.Integer, primary_key=True)
    name_source = DB.Column(DB.Unicode)
    desc_source = DB.Column(DB.Unicode)
    entity_source_pk_field = DB.Column(DB.Unicode)
    url_source = DB.Column(DB.Unicode)
    target = DB.Column(DB.Unicode)
    picto_source = DB.Column(DB.Unicode)
    groupe_source = DB.Column(DB.Unicode)
    active = DB.Column(DB.Boolean)
    meta_create_date = DB.Column(DB.DateTime)
    meta_update_date = DB.Column(DB.DateTime)


@serializable
class VSyntheseDecodeNomenclatures(DB.Model):
    __tablename__ = 'v_synthese_decode_nomenclatures'
    __table_args__ = {'schema': 'gn_synthese'}
    id_synthese = DB.Column(DB.Integer, primary_key=True) 
    nat_obj_geo = DB.Column(DB.Unicode)
    grp_typ = DB.Column(DB.Unicode)
    obs_meth = DB.Column(DB.Unicode)
    obs_technique = DB.Column(DB.Unicode)
    bio_status = DB.Column(DB.Unicode)
    bio_condition = DB.Column(DB.Unicode)
    naturalness = DB.Column(DB.Unicode)
    exist_proof = DB.Column(DB.Unicode)
    valid_status = DB.Column(DB.Unicode)
    diffusion_level = DB.Column(DB.Unicode)
    life_stage = DB.Column(DB.Unicode)
    sex = DB.Column(DB.Unicode)
    obj_count = DB.Column(DB.Unicode)
    type_count = DB.Column(DB.Unicode)
    sensitivity = DB.Column(DB.Unicode)
    observation_status = DB.Column(DB.Unicode)
    blurring = DB.Column(DB.Unicode)
    source_status = DB.Column(DB.Unicode)


@serializable
@geoserializable
class Synthese(DB.Model):
    __tablename__ = 'synthese'
    __table_args__ = {'schema': 'gn_synthese'}
    id_synthese = DB.Column(DB.Integer, ForeignKey('gn_synthese.v_synthese_decode_nomenclatures.id_synthese'), primary_key=True)
    unique_id_sinp = DB.Column(UUID(as_uuid=True))
    unique_id_sinp_grp = DB.Column(UUID(as_uuid=True))
    id_source = DB.Column(DB.Integer)
    entity_source_pk_value = DB.Column(DB.Integer)
    id_dataset = DB.Column(DB.Integer)
    id_nomenclature_geo_object_nature = DB.Column(DB.Integer)
    id_nomenclature_grp_typ = DB.Column(DB.Integer)
    id_nomenclature_obs_meth = DB.Column(DB.Integer)
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
    id_municipality = DB.Column(DB.Unicode, ForeignKey('ref_geo.li_municipalities.insee_com'))
    count_min = DB.Column(DB.Integer)
    count_max = DB.Column(DB.Integer)
    cd_nom = DB.Column(DB.Integer)
    nom_cite = DB.Column(DB.Unicode)
    meta_v_taxref = DB.Column(DB.Unicode)
    sample_number_proof = DB.Column(DB.Unicode)
    digital_proof = DB.Column(DB.Unicode)
    non_digital_proof = DB.Column(DB.Unicode)
    altitude_min = DB.Column(DB.Unicode)
    altitude_max = DB.Column(DB.Unicode)
    the_geom_4326 = DB.Column(Geometry('GEOMETRY', 4326))
    the_geom_point = DB.Column(Geometry('GEOMETRY', 4326))
    the_geom_local = DB.Column(Geometry('GEOMETRY', 2154))
    date_min = DB.Column(DB.DateTime)
    date_max = DB.Column(DB.DateTime)
    id_validator = DB.Column(DB.Integer)
    validation_comment = DB.Column(DB.Unicode)
    observers = DB.Column(DB.Unicode)
    determiner = DB.Column(DB.Unicode)
    determination_method = DB.Column(DB.Unicode)
    comments = DB.Column(DB.Unicode)
    meta_validation_date = DB.Column(DB.DateTime)
    meta_create_date = DB.Column(DB.DateTime)
    meta_update_date = DB.Column(DB.DateTime)
    last_action = DB.Column(DB.Unicode)

    decoded_nomenclatures = relationship(
        "VSyntheseDecodeNomenclatures",
        lazy='joined'
    )

    municipalities = relationship(
        "LiMunicipalities",
        lazy='joined'
    )

    def get_geofeature(self, recursif=True):
        return self.as_geofeature('the_geom_4326', 'id_synthese', recursif)


@serializable
class CorAreaSynthese(DB.Model):
    __tablename__ = 'cor_area_synthese'
    __table_args__ = {'schema': 'gn_synthese'}
    id_synthese = DB.Column(DB.Integer, primary_key=True)
    id_area = DB.Column(DB.Integer)
    id_nomenclature_typ_inf_geo = DB.Column(DB.Integer)


@serializable
class DefaultsNomenclaturesValue(DB.Model):
    __tablename__ = 'defaults_nomenclatures_value'
    __table_args__ = {'schema': 'gn_synthese'}
    id_type = DB.Column(DB.Integer, primary_key=True)
    id_organism = DB.Column(DB.Integer, primary_key=True)
    regne = DB.Column(DB.Unicode, primary_key=True)
    group2_inpn = DB.Column(DB.Unicode, primary_key=True)
    id_nomenclature = DB.Column(DB.Integer)


@serializable
@geoserializable
class VSyntheseForWebApp(DB.Model):
    __tablename__ = 'v_synthese_for_web_app'
    __table_args__ = {'schema': 'gn_synthese'}
    id_synthese = DB.Column(DB.Integer, primary_key=True) 
    id_source = DB.Column(DB.Integer) 
    name_source = DB.Column(DB.Unicode)
    entity_source_pk_field = DB.Column(DB.Unicode)
    entity_source_pk_value = DB.Column(DB.Integer)
    dataset_name = DB.Column(DB.Unicode)
    nat_obj_geo = DB.Column(DB.Unicode)
    grp_typ = DB.Column(DB.Unicode)
    obs_meth = DB.Column(DB.Unicode)
    obs_technique = DB.Column(DB.Unicode)
    bio_status = DB.Column(DB.Unicode)
    bio_condition = DB.Column(DB.Unicode)
    naturalness = DB.Column(DB.Unicode)
    exist_proof = DB.Column(DB.Unicode)
    valid_status = DB.Column(DB.Unicode)
    diffusion_level = DB.Column(DB.Unicode)
    life_stage = DB.Column(DB.Unicode)
    sex = DB.Column(DB.Unicode)
    obj_count = DB.Column(DB.Unicode)
    type_count = DB.Column(DB.Unicode)
    sensitivity = DB.Column(DB.Unicode)
    observation_status = DB.Column(DB.Unicode)
    blurring = DB.Column(DB.Unicode)
    source_status = DB.Column(DB.Unicode)
    insee_com = DB.Column(DB.Unicode)
    nom_com = DB.Column(DB.Unicode)
    count_min = DB.Column(DB.Integer)
    count_max = DB.Column(DB.Integer)
    cd_nom = DB.Column(DB.Integer)
    nom_complet = DB.Column(DB.Unicode)
    nom_vern = DB.Column(DB.Unicode)
    nom_cite = DB.Column(DB.Unicode)
    meta_v_taxref = DB.Column(DB.Unicode)
    sample_number_proof = DB.Column(DB.Unicode)
    digital_proof = DB.Column(DB.Unicode)
    non_digital_proof = DB.Column(DB.Unicode)
    altitude_min = DB.Column(DB.Integer)
    altitude_max = DB.Column(DB.Integer)
    the_geom_point = DB.Column(Geometry('GEOMETRY', 4326))
    the_geom_4326 = DB.Column(Geometry('GEOMETRY', 4326))
    date_min = DB.Column(DB.DateTime)
    date_max = DB.Column(DB.DateTime)
    validateur = DB.Column(DB.Unicode)
    validation_comment = DB.Column(DB.Unicode)
    validation_date = DB.Column(DB.DateTime)
    observers = DB.Column(DB.Unicode)
    determiner = DB.Column(DB.Unicode)
    determination_method = DB.Column(DB.Unicode)
    comments = DB.Column(DB.Unicode)
