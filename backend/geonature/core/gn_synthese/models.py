from collections import OrderedDict

from sqlalchemy import ForeignKey
from sqlalchemy.orm import relationship, column_property
from sqlalchemy.ext.hybrid import hybrid_property
from sqlalchemy.sql import select, func, exists
from sqlalchemy.dialects.postgresql import UUID, JSONB
from geoalchemy2 import Geometry
from geoalchemy2.shape import to_shape
from geojson import Feature

from werkzeug.exceptions import NotFound

from pypnnomenclature.models import TNomenclatures
from pypnusershub.db.models import User
from utils_flask_sqla.serializers import serializable, SERIALIZERS
from utils_flask_sqla_geo.serializers import geoserializable, shapeserializable
from pypn_habref_api.models import Habref

from geonature.core.gn_meta.models import TDatasets, TAcquisitionFramework
from geonature.core.ref_geo.models import LAreas
from geonature.core.ref_geo.models import LiMunicipalities
from geonature.core.gn_commons.models import THistoryActions, TValidations, TMedias, TModules
from geonature.utils.env import DB
from geonature.utils.config import config


@serializable
class TSources(DB.Model):
    __tablename__ = "t_sources"
    __table_args__ = {"schema": "gn_synthese"}
    id_source = DB.Column(DB.Integer, primary_key=True)
    name_source = DB.Column(DB.Unicode)
    desc_source = DB.Column(DB.Unicode)
    entity_source_pk_field = DB.Column(DB.Unicode)
    url_source = DB.Column(DB.Unicode)
    meta_create_date = DB.Column(DB.DateTime)
    meta_update_date = DB.Column(DB.DateTime)


cor_observer_synthese = DB.Table("cor_observer_synthese",
    DB.Column("id_synthese", DB.Integer, ForeignKey("gn_synthese.synthese.id_synthese"), primary_key=True),
    DB.Column("id_role", DB.Integer, ForeignKey(User.id_role), primary_key=True),
    schema='gn_synthese',
)


@serializable
class CorObserverSynthese(DB.Model):
    __tablename__ = "cor_observer_synthese"
    __table_args__ = {"schema": "gn_synthese", "extend_existing": True}
    id_synthese = DB.Column(
        DB.Integer, ForeignKey("gn_synthese.synthese.id_synthese"), primary_key=True
    )
    id_role = DB.Column(DB.Integer, ForeignKey(User.id_role), primary_key=True)


corAreaSynthese = DB.Table("cor_area_synthese",
    DB.Column("id_synthese", DB.Integer, ForeignKey("gn_synthese.synthese.id_synthese"), primary_key=True),
    DB.Column("id_area", DB.Integer, ForeignKey("ref_geo.l_areas.id_area"), primary_key=True),
    schema='gn_synthese',
)


@serializable
class VSyntheseDecodeNomenclatures(DB.Model):
    __tablename__ = "v_synthese_decode_nomenclatures"
    __table_args__ = {"schema": "gn_synthese"}
    id_synthese = DB.Column(DB.Integer, primary_key=True)
    nat_obj_geo = DB.Column(DB.Unicode)
    grp_typ = DB.Column(DB.Unicode)
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
    occ_behaviour = DB.Column(DB.Unicode)
    occ_stat_biogeo = DB.Column(DB.Unicode)


@serializable
@geoserializable
@shapeserializable
class Synthese(DB.Model):
    __tablename__ = "synthese"
    __table_args__ = {"schema": "gn_synthese"}
    id_synthese = DB.Column(DB.Integer, primary_key=True)
    unique_id_sinp = DB.Column(UUID(as_uuid=True))
    unique_id_sinp_grp = DB.Column(UUID(as_uuid=True))
    id_source = DB.Column(DB.Integer, ForeignKey(TSources.id_source))
    source = relationship(TSources)
    id_module = DB.Column(DB.Integer, ForeignKey(TModules.id_module))
    module = DB.relationship(TModules)
    entity_source_pk_value = DB.Column(DB.Integer)  # FIXME varchar in db!
    id_dataset = DB.Column(DB.Integer, ForeignKey(TDatasets.id_dataset))
    dataset = relationship(TDatasets)
    grp_method = DB.Column(DB.Unicode(length=255))

    id_nomenclature_geo_object_nature = DB.Column(DB.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_geo_object_nature = DB.relationship(TNomenclatures, foreign_keys=[id_nomenclature_geo_object_nature])

    id_nomenclature_grp_typ = DB.Column(DB.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_grp_typ = DB.relationship(TNomenclatures, foreign_keys=[id_nomenclature_grp_typ])

    id_nomenclature_obs_technique = DB.Column(DB.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_obs_technique = DB.relationship(TNomenclatures, foreign_keys=[id_nomenclature_obs_technique])

    id_nomenclature_bio_status = DB.Column(DB.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_bio_status = DB.relationship(TNomenclatures, foreign_keys=[id_nomenclature_bio_status])

    id_nomenclature_bio_condition = DB.Column(DB.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_bio_condition = DB.relationship(TNomenclatures, foreign_keys=[id_nomenclature_bio_condition])

    id_nomenclature_naturalness = DB.Column(DB.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_naturalness = DB.relationship(TNomenclatures, foreign_keys=[id_nomenclature_naturalness])

    id_nomenclature_exist_proof = DB.Column(DB.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_exist_proof = DB.relationship(TNomenclatures, foreign_keys=[id_nomenclature_exist_proof])

    id_nomenclature_valid_status = DB.Column(DB.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_valid_status = DB.relationship(TNomenclatures, foreign_keys=[id_nomenclature_valid_status])

    id_nomenclature_diffusion_level = DB.Column(DB.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_diffusion_level = DB.relationship(TNomenclatures, foreign_keys=[id_nomenclature_diffusion_level])

    id_nomenclature_life_stage = DB.Column(DB.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_life_stage = DB.relationship(TNomenclatures, foreign_keys=[id_nomenclature_life_stage])

    id_nomenclature_sex = DB.Column(DB.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_sex = DB.relationship(TNomenclatures, foreign_keys=[id_nomenclature_sex])

    id_nomenclature_obj_count = DB.Column(DB.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_obj_count = DB.relationship(TNomenclatures, foreign_keys=[id_nomenclature_obj_count])

    id_nomenclature_type_count = DB.Column(DB.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_type_count = DB.relationship(TNomenclatures, foreign_keys=[id_nomenclature_type_count])

    id_nomenclature_sensitivity = DB.Column(DB.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_sensitivity = DB.relationship(TNomenclatures, foreign_keys=[id_nomenclature_sensitivity])

    id_nomenclature_observation_status = DB.Column(DB.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_observation_status = DB.relationship(TNomenclatures, foreign_keys=[id_nomenclature_observation_status])

    id_nomenclature_blurring = DB.Column(DB.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_blurring = DB.relationship(TNomenclatures, foreign_keys=[id_nomenclature_blurring])

    id_nomenclature_source_status = DB.Column(DB.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_source_status = DB.relationship(TNomenclatures, foreign_keys=[id_nomenclature_source_status])

    id_nomenclature_info_geo_type = DB.Column(DB.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_info_geo_type = DB.relationship(TNomenclatures, foreign_keys=[id_nomenclature_info_geo_type])

    id_nomenclature_behaviour = DB.Column(DB.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_behaviour = DB.relationship(TNomenclatures, foreign_keys=[id_nomenclature_behaviour])

    id_nomenclature_biogeo_status = DB.Column(DB.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_biogeo_status = DB.relationship(TNomenclatures, foreign_keys=[id_nomenclature_biogeo_status])

    id_nomenclature_determination_method = DB.Column(DB.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_determination_method = DB.relationship(TNomenclatures, foreign_keys=[id_nomenclature_determination_method])

    reference_biblio = DB.Column(DB.Unicode(length=5000))
    count_min = DB.Column(DB.Integer)
    count_max = DB.Column(DB.Integer)
    cd_nom = DB.Column(DB.Integer)
    cd_hab = DB.Column(DB.Integer, ForeignKey(Habref.cd_hab))
    habitat = relationship(Habref)
    nom_cite = DB.Column(DB.Unicode(length=1000), nullable=False)
    meta_v_taxref = DB.Column(DB.Unicode(length=50))
    sample_number_proof = DB.Column(DB.UnicodeText)
    digital_proof = DB.Column(DB.UnicodeText)
    non_digital_proof = DB.Column(DB.UnicodeText)
    altitude_min = DB.Column(DB.Integer)
    altitude_max = DB.Column(DB.Integer)
    depth_min = DB.Column(DB.Integer)
    depth_max = DB.Column(DB.Integer)
    place_name = DB.Column(DB.Unicode(length=500))
    the_geom_4326 = DB.Column(Geometry("GEOMETRY", 4326))
    the_geom_point = DB.Column(Geometry("GEOMETRY", 4326))
    the_geom_local = DB.Column(Geometry("GEOMETRY", config["LOCAL_SRID"]))
    precision = DB.Column(DB.Integer)
    id_area_attachment = DB.Column(DB.Integer)
    date_min = DB.Column(DB.DateTime, nullable=False)
    date_max = DB.Column(DB.DateTime, nullable=False)
    validator = DB.Column(DB.Unicode(length=1000))
    validation_comment = DB.Column(DB.Unicode)
    observers = DB.Column(DB.Unicode(length=1000))
    determiner = DB.Column(DB.Unicode(length=1000))
    id_digitiser = DB.Column(DB.Integer)
    comment_context = DB.Column(DB.UnicodeText)
    comment_description = DB.Column(DB.UnicodeText)
    additional_data = DB.Column(JSONB)
    meta_validation_date = DB.Column(DB.DateTime)
    meta_create_date = DB.Column(DB.DateTime)
    meta_update_date = DB.Column(DB.DateTime)
    last_action = DB.Column(DB.Unicode)

    areas = relationship('LAreas', secondary=corAreaSynthese)
    validations = relationship(TValidations, backref='attached_row')
    medias = relationship(TMedias, backref='attached_row')

    cor_observers = DB.relationship(User, secondary=cor_observer_synthese)

    def get_geofeature(self, recursif=True, fields=None):
        return self.as_geofeature("the_geom_4326", "id_synthese", recursif, fields=fields)


@serializable
class CorAreaSynthese(DB.Model):
    __tablename__ = "cor_area_synthese"
    __table_args__ = {"schema": "gn_synthese", "extend_existing": True}
    id_synthese = DB.Column(DB.Integer, ForeignKey("gn_synthese.synthese.id_synthese"), primary_key=True)
    id_area = DB.Column(DB.Integer, ForeignKey("ref_geo.l_areas.id_area"), primary_key=True)


@serializable
class CorSensitivitySynthese(DB.Model):
    __tablename__ = "cor_sensitivity_synthese"
    __table_args__ = {"schema": "gn_sensitivity"}
    uuid_attached_row = DB.Column(UUID(as_uuid=True), primary_key=True)
    id_nomenclature_sensitivity = DB.Column(DB.Integer, primary_key=True)
    sensitivity_comment = DB.Column(DB.Text)
    meta_create_date = DB.Column(DB.DateTime)
    meta_update_date = DB.Column(DB.DateTime)


@serializable
class DefaultsNomenclaturesValue(DB.Model):
    __tablename__ = "defaults_nomenclatures_value"
    __table_args__ = {"schema": "gn_synthese"}
    mnemonique_type = DB.Column(DB.Integer, primary_key=True)
    id_organism = DB.Column(DB.Integer, primary_key=True)
    regne = DB.Column(DB.Unicode, primary_key=True)
    group2_inpn = DB.Column(DB.Unicode, primary_key=True)
    id_nomenclature = DB.Column(DB.Integer)


@serializable
@geoserializable
class VSyntheseForWebApp(DB.Model):
    __tablename__ = "v_synthese_for_web_app"
    __table_args__ = {"schema": "gn_synthese"}

    id_synthese = DB.Column(
        DB.Integer,
        ForeignKey("gn_synthese.v_synthese_decode_nomenclatures.id_synthese"),
        primary_key=True,
    )
    unique_id_sinp = DB.Column(UUID(as_uuid=True))
    unique_id_sinp_grp = DB.Column(UUID(as_uuid=True))
    id_source = DB.Column(DB.Integer)
    entity_source_pk_value = DB.Column(DB.Integer)
    id_dataset = DB.Column(DB.Integer)
    dataset_name = DB.Column(DB.Integer)
    id_acquisition_framework = DB.Column(DB.Integer)
    count_min = DB.Column(DB.Integer)
    count_max = DB.Column(DB.Integer)
    cd_nom = DB.Column(DB.Integer)
    cd_ref = DB.Column(DB.Unicode)
    nom_cite = DB.Column(DB.Unicode)
    nom_valide = DB.Column(DB.Unicode)
    nom_vern = DB.Column(DB.Unicode)
    lb_nom = DB.Column(DB.Unicode)
    meta_v_taxref = DB.Column(DB.Unicode)
    sample_number_proof = DB.Column(DB.Unicode)
    digital_proof = DB.Column(DB.Unicode)
    non_digital_proof = DB.Column(DB.Unicode)
    altitude_min = DB.Column(DB.Integer)
    altitude_max = DB.Column(DB.Integer)
    depth_min = DB.Column(DB.Integer)
    depth_max = DB.Column(DB.Integer)
    place_name = DB.Column(DB.Unicode)
    precision = DB.Column(DB.Integer)
    the_geom_4326 = DB.Column(Geometry("GEOMETRY", 4326))
    date_min = DB.Column(DB.DateTime)
    date_max = DB.Column(DB.DateTime)
    validator = DB.Column(DB.Unicode)
    validation_comment = DB.Column(DB.Unicode)
    observers = DB.Column(DB.Unicode)
    determiner = DB.Column(DB.Unicode)
    id_digitiser = DB.Column(DB.Integer)
    comment_context = DB.Column(DB.Unicode)
    comment_description = DB.Column(DB.Unicode)
    meta_validation_date = DB.Column(DB.DateTime)
    meta_create_date = DB.Column(DB.DateTime)
    meta_update_date = DB.Column(DB.DateTime)
    last_action = DB.Column(DB.Unicode)
    id_nomenclature_geo_object_nature = DB.Column(DB.Integer)
    id_nomenclature_info_geo_type = DB.Column(DB.Integer)
    id_nomenclature_grp_typ = DB.Column(DB.Integer)
    grp_method = DB.Column(DB.Unicode)
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
    id_nomenclature_determination_method = DB.Column(DB.Integer)
    id_nomenclature_behaviour = DB.Column(DB.Integer)
    reference_biblio = DB.Column(DB.Unicode)
    name_source = DB.Column(DB.Unicode)
    url_source = DB.Column(DB.Unicode)
    st_asgeojson = DB.Column(DB.Unicode)

    has_medias = column_property(
        exists([TMedias.id_media]).\
            where(TMedias.uuid_attached_row==unique_id_sinp)
    )

    def get_geofeature(self, recursif=False, fields=[]):
        return self.as_geofeature("the_geom_4326", "id_synthese", recursif, fields=fields)


# Non utilisé - laissé pour exemple d'une sérialisation ordonnée
def synthese_export_serialization(cls):
    """
    Décorateur qui definit une serialisation particuliere pour la vue v_synthese_for_export
    Il rajoute la fonction as_dict_ordered qui conserve l'ordre des attributs tel que definit dans le model
    (fonctions utilisees pour les exports) et qui redefinit le nom des colonnes tel qu'ils sont nommes en configuration
    """
    EXPORT_COLUMNS = config["SYNTHESE"]["EXPORT_COLUMNS"]
    # tab of cls attributes from EXPORT COLUMNS
    formated_default_columns = [key for key, value in EXPORT_COLUMNS.items()]

    # list of tuple (class attribute, serializer)
    cls_db_cols_and_serializer = []
    # list of attributes of the class which are in the synthese export cnfig
    # use for generate shapefiles
    cls.db_cols = []
    for key in formated_default_columns:
        # get the cls attribut:
        try:
            # get the class atribut from the syntese export config
            cls_attri = getattr(cls, key)
            # add in serialiser list
            if not cls_attri.type.__class__.__name__ == "Geometry":
                cls_db_cols_and_serializer.append(
                    (
                        cls_attri.key,
                        SERIALIZERS.get(cls_attri.type.__class__.__name__.lower(), lambda x: x),
                    )
                )
            # add in cls.db_cols
            cls.db_cols.append(cls_attri)
        # execpt if the attribute does not exist
        except AttributeError:
            pass

    def serialize_order_fn(self):
        order_dict = OrderedDict()
        for item, _serializer in cls_db_cols_and_serializer:
            order_dict.update({EXPORT_COLUMNS.get(item): _serializer(getattr(self, item))})
        return order_dict

    def serialize_geofn(self, geoCol, idCol):
        if not getattr(self, geoCol) is None:
            geometry = to_shape(getattr(self, geoCol))
        else:
            geometry = {"type": "Point", "coordinates": [0, 0]}

        feature = Feature(
            id=str(getattr(self, idCol)), geometry=geometry, properties=self.as_dict_ordered(),
        )
        return feature

    cls.as_dict_ordered = serialize_order_fn
    cls.as_geofeature_ordered = serialize_geofn

    return cls


@serializable
class VColorAreaTaxon(DB.Model):
    __tablename__ = "v_color_taxon_area"
    __table_args__ = {"schema": "gn_synthese"}
    cd_nom = DB.Column(DB.Integer(), ForeignKey("taxonomie.taxref.cd_nom"), primary_key=True)
    id_area = DB.Column(DB.Integer(), ForeignKey("ref_geo.l_area.id_area"), primary_key=True)
    nb_obs = DB.Column(DB.Integer())
    last_date = DB.Column(DB.DateTime())
    color = DB.Column(DB.Unicode())
