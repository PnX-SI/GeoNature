from collections import OrderedDict
from packaging import version

import sqlalchemy as sa
import datetime
from sqlalchemy import ForeignKey, Unicode, and_
from sqlalchemy.orm import (
    relationship,
    column_property,
    foreign,
    joinedload,
    contains_eager,
    deferred,
)
from sqlalchemy.sql import select, func, exists
from sqlalchemy.dialects.postgresql import UUID, JSONB
from geoalchemy2 import Geometry
from geoalchemy2.shape import to_shape

from geojson import Feature
from flask import g
import flask_sqlalchemy

if version.parse(flask_sqlalchemy.__version__) >= version.parse("3"):
    from flask_sqlalchemy.query import Query
else:
    from flask_sqlalchemy import BaseQuery as Query

from werkzeug.exceptions import NotFound
from werkzeug.datastructures import MultiDict

from pypnnomenclature.models import TNomenclatures
from pypnusershub.db.models import User
from utils_flask_sqla.serializers import serializable, SERIALIZERS
from utils_flask_sqla_geo.serializers import geoserializable, shapeserializable
from utils_flask_sqla_geo.mixins import GeoFeatureCollectionMixin
from pypn_habref_api.models import Habref
from apptax.taxonomie.models import Taxref
from ref_geo.models import LAreas

from geonature.core.gn_meta.models import TDatasets, TAcquisitionFramework
from geonature.core.gn_commons.models import (
    THistoryActions,
    TValidations,
    last_validation,
    TMedias,
    TModules,
)
from geonature.utils.env import DB, db


@serializable(exclude=["module_url"])
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
    id_module = DB.Column(DB.Integer, ForeignKey(TModules.id_module))
    module = DB.relationship(TModules, backref="sources")

    @property
    def module_url(self):
        if self.module is not None and hasattr(self.module, "generate_module_url_for_source"):
            return self.module.generate_module_url_for_source(self)
        else:
            return None


cor_observer_synthese = DB.Table(
    "cor_observer_synthese",
    DB.Column(
        "id_synthese", DB.Integer, ForeignKey("gn_synthese.synthese.id_synthese"), primary_key=True
    ),
    DB.Column("id_role", DB.Integer, ForeignKey(User.id_role), primary_key=True),
    schema="gn_synthese",
)


@serializable
class CorObserverSynthese(DB.Model):
    __tablename__ = "cor_observer_synthese"
    __table_args__ = {"schema": "gn_synthese", "extend_existing": True}
    id_synthese = DB.Column(
        DB.Integer, ForeignKey("gn_synthese.synthese.id_synthese"), primary_key=True
    )
    id_role = DB.Column(DB.Integer, ForeignKey(User.id_role), primary_key=True)


corAreaSynthese = DB.Table(
    "cor_area_synthese",
    DB.Column(
        "id_synthese", DB.Integer, ForeignKey("gn_synthese.synthese.id_synthese"), primary_key=True
    ),
    DB.Column("id_area", DB.Integer, ForeignKey(LAreas.id_area), primary_key=True),
    schema="gn_synthese",
)


class SyntheseQuery(GeoFeatureCollectionMixin, Query):
    def join_nomenclatures(self):
        return self.options(*[joinedload(n) for n in Synthese.nomenclature_fields])

    def lateraljoin_last_validation(self):
        subquery = (
            TValidations.query.filter(TValidations.uuid_attached_row == Synthese.unique_id_sinp)
            .limit(1)
            .subquery()
            .lateral("last_validation")
        )
        return self.outerjoin(subquery, sa.true()).options(
            contains_eager(Synthese.last_validation, alias=subquery)
        )

    def filter_by_scope(self, scope, user=None):
        if user is None:
            user = g.current_user
        if scope == 0:
            self = self.filter(sa.false())
        elif scope in (1, 2):
            ors = []
            datasets = (
                TDatasets.query.filter_by_readable(user).with_entities(TDatasets.id_dataset).all()
            )
            self = self.filter(
                or_(
                    Synthese.id_digitizer == user.id_role,
                    Synthese.cor_observers.any(id_role=user.id_role),
                    Synthese.id_dataset.in_([ds.id_dataset for ds in datasets]),
                )
            )
        return self


    def filter_by_params(self, params: MultiDict = None):
        model = Synthese
        and_list = []
        for key, value in params.items():
            column = getattr(model, key)
            if isinstance(column.type, Unicode):
                and_list.append(column.ilike(f"%{value}%"))
            else:
                and_list.append(column == value)
        and_query = and_(*and_list)
        return self.filter(and_query)

    def sort(self, label: str, direction: str):
        model = Synthese
        order_by = getattr(model, label)
        if direction == "desc":
            order_by = order_by.desc()

        return self.order_by(order_by)

@serializable
class CorAreaSynthese(DB.Model):
    __tablename__ = "cor_area_synthese"
    __table_args__ = {"schema": "gn_synthese", "extend_existing": True}
    id_synthese = DB.Column(
        DB.Integer, ForeignKey("gn_synthese.synthese.id_synthese"), primary_key=True
    )
    id_area = DB.Column(DB.Integer, ForeignKey("ref_geo.l_areas.id_area"), primary_key=True)


@serializable
@geoserializable(geoCol="the_geom_4326", idCol="id_synthese")
@shapeserializable
class Synthese(DB.Model):
    __tablename__ = "synthese"
    __table_args__ = {"schema": "gn_synthese"}
    query_class = SyntheseQuery
    nomenclature_fields = [
        "nomenclature_geo_object_nature",
        "nomenclature_grp_typ",
        "nomenclature_obs_technique",
        "nomenclature_bio_status",
        "nomenclature_bio_condition",
        "nomenclature_naturalness",
        "nomenclature_exist_proof",
        "nomenclature_valid_status",
        "nomenclature_diffusion_level",
        "nomenclature_life_stage",
        "nomenclature_sex",
        "nomenclature_obj_count",
        "nomenclature_type_count",
        "nomenclature_sensitivity",
        "nomenclature_observation_status",
        "nomenclature_blurring",
        "nomenclature_source_status",
        "nomenclature_info_geo_type",
        "nomenclature_behaviour",
        "nomenclature_biogeo_status",
        "nomenclature_determination_method",
    ]

    id_synthese = DB.Column(DB.Integer, primary_key=True)
    unique_id_sinp = DB.Column(UUID(as_uuid=True))
    unique_id_sinp_grp = DB.Column(UUID(as_uuid=True))
    id_source = DB.Column(DB.Integer, ForeignKey(TSources.id_source), nullable=False)
    source = relationship(TSources)
    id_module = DB.Column(DB.Integer, ForeignKey(TModules.id_module))
    module = DB.relationship(TModules)
    entity_source_pk_value = DB.Column(DB.Unicode)
    id_dataset = DB.Column(DB.Integer, ForeignKey(TDatasets.id_dataset))
    dataset = DB.relationship(TDatasets, backref=DB.backref("synthese_records", lazy="dynamic"))
    grp_method = DB.Column(DB.Unicode(length=255))

    id_nomenclature_geo_object_nature = db.Column(
        db.Integer, ForeignKey(TNomenclatures.id_nomenclature)
    )
    nomenclature_geo_object_nature = db.relationship(
        TNomenclatures, foreign_keys=[id_nomenclature_geo_object_nature]
    )
    id_nomenclature_grp_typ = db.Column(db.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_grp_typ = db.relationship(TNomenclatures, foreign_keys=[id_nomenclature_grp_typ])
    id_nomenclature_obs_technique = db.Column(
        db.Integer, ForeignKey(TNomenclatures.id_nomenclature)
    )
    nomenclature_obs_technique = db.relationship(
        TNomenclatures, foreign_keys=[id_nomenclature_obs_technique]
    )
    id_nomenclature_bio_status = db.Column(db.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_bio_status = db.relationship(
        TNomenclatures, foreign_keys=[id_nomenclature_bio_status]
    )
    id_nomenclature_bio_condition = db.Column(
        db.Integer, ForeignKey(TNomenclatures.id_nomenclature)
    )
    nomenclature_bio_condition = db.relationship(
        TNomenclatures, foreign_keys=[id_nomenclature_bio_condition]
    )
    id_nomenclature_naturalness = db.Column(db.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_naturalness = db.relationship(
        TNomenclatures, foreign_keys=[id_nomenclature_naturalness]
    )
    id_nomenclature_valid_status = db.Column(
        db.Integer, ForeignKey(TNomenclatures.id_nomenclature)
    )
    nomenclature_valid_status = db.relationship(
        TNomenclatures, foreign_keys=[id_nomenclature_valid_status]
    )
    id_nomenclature_exist_proof = db.Column(db.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_exist_proof = db.relationship(
        TNomenclatures, foreign_keys=[id_nomenclature_exist_proof]
    )
    id_nomenclature_diffusion_level = db.Column(
        db.Integer, ForeignKey(TNomenclatures.id_nomenclature)
    )
    nomenclature_diffusion_level = db.relationship(
        TNomenclatures, foreign_keys=[id_nomenclature_diffusion_level]
    )
    id_nomenclature_life_stage = db.Column(db.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_life_stage = db.relationship(
        TNomenclatures, foreign_keys=[id_nomenclature_life_stage]
    )
    id_nomenclature_sex = db.Column(db.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_sex = db.relationship(TNomenclatures, foreign_keys=[id_nomenclature_sex])
    id_nomenclature_obj_count = db.Column(db.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_obj_count = db.relationship(
        TNomenclatures, foreign_keys=[id_nomenclature_obj_count]
    )
    id_nomenclature_type_count = db.Column(db.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_type_count = db.relationship(
        TNomenclatures, foreign_keys=[id_nomenclature_type_count]
    )
    id_nomenclature_sensitivity = db.Column(db.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_sensitivity = db.relationship(
        TNomenclatures, foreign_keys=[id_nomenclature_sensitivity]
    )
    id_nomenclature_observation_status = db.Column(
        db.Integer, ForeignKey(TNomenclatures.id_nomenclature)
    )
    nomenclature_observation_status = db.relationship(
        TNomenclatures, foreign_keys=[id_nomenclature_observation_status]
    )
    id_nomenclature_blurring = db.Column(db.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_blurring = db.relationship(
        TNomenclatures, foreign_keys=[id_nomenclature_blurring]
    )
    id_nomenclature_source_status = db.Column(
        db.Integer, ForeignKey(TNomenclatures.id_nomenclature)
    )
    nomenclature_source_status = db.relationship(
        TNomenclatures, foreign_keys=[id_nomenclature_source_status]
    )
    id_nomenclature_info_geo_type = db.Column(
        db.Integer, ForeignKey(TNomenclatures.id_nomenclature)
    )
    nomenclature_info_geo_type = db.relationship(
        TNomenclatures, foreign_keys=[id_nomenclature_info_geo_type]
    )
    id_nomenclature_behaviour = db.Column(db.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    nomenclature_behaviour = db.relationship(
        TNomenclatures, foreign_keys=[id_nomenclature_behaviour]
    )
    id_nomenclature_biogeo_status = db.Column(
        db.Integer, ForeignKey(TNomenclatures.id_nomenclature)
    )
    nomenclature_biogeo_status = db.relationship(
        TNomenclatures, foreign_keys=[id_nomenclature_biogeo_status]
    )
    id_nomenclature_determination_method = db.Column(
        db.Integer, ForeignKey(TNomenclatures.id_nomenclature)
    )
    nomenclature_determination_method = db.relationship(
        TNomenclatures, foreign_keys=[id_nomenclature_determination_method]
    )

    reference_biblio = DB.Column(DB.Unicode(length=5000))
    count_min = DB.Column(DB.Integer)
    count_max = DB.Column(DB.Integer)
    cd_nom = DB.Column(DB.Integer, ForeignKey(Taxref.cd_nom))
    taxref = relationship(Taxref)
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
    the_geom_4326_geojson = column_property(func.ST_AsGeoJSON(the_geom_4326), deferred=True)
    the_geom_point = deferred(DB.Column(Geometry("GEOMETRY", 4326)))
    the_geom_local = deferred(DB.Column(Geometry("GEOMETRY")))
    precision = DB.Column(DB.Integer)
    id_area_attachment = DB.Column(DB.Integer, ForeignKey(LAreas.id_area))
    date_min = DB.Column(DB.DateTime, nullable=False)
    date_max = DB.Column(DB.DateTime, nullable=False)
    validator = DB.Column(DB.Unicode(length=1000))
    validation_comment = DB.Column(DB.Unicode)
    observers = DB.Column(DB.Unicode(length=1000))
    determiner = DB.Column(DB.Unicode(length=1000))
    id_digitiser = DB.Column(DB.Integer, ForeignKey(User.id_role))
    digitiser = db.relationship(User, foreign_keys=[id_digitiser])
    comment_context = DB.Column(DB.UnicodeText)
    comment_description = DB.Column(DB.UnicodeText)
    additional_data = DB.Column(JSONB)
    meta_validation_date = DB.Column(DB.DateTime)
    meta_create_date = DB.Column(DB.DateTime)
    meta_update_date = DB.Column(DB.DateTime)
    last_action = DB.Column(DB.Unicode)

    areas = relationship(LAreas, secondary=corAreaSynthese, backref="synthese_obs")
    area_attachment = relationship(LAreas, foreign_keys=[id_area_attachment])
    validations = relationship(TValidations, backref="attached_row")
    last_validation = relationship(last_validation, uselist=False, viewonly=True)
    medias = relationship(
        TMedias, primaryjoin=(TMedias.uuid_attached_row == foreign(unique_id_sinp)), uselist=True
    )

    cor_observers = DB.relationship(User, secondary=cor_observer_synthese)

    def has_instance_permission(self, scope):
        if scope == 0:
            return False
        elif scope in (1, 2):
            if g.current_user == self.digitiser:
                return True
            if g.current_user in self.cor_observers:
                return True
            return self.dataset.has_instance_permission(scope)
        elif scope == 3:
            return True


@serializable
class DefaultsNomenclaturesValue(DB.Model):
    __tablename__ = "defaults_nomenclatures_value"
    __table_args__ = {"schema": "gn_synthese"}
    mnemonique_type = DB.Column(DB.Integer, primary_key=True)
    id_organism = DB.Column(DB.Integer, primary_key=True)
    regne = DB.Column(DB.Unicode, primary_key=True)
    group2_inpn = DB.Column(DB.Unicode, primary_key=True)
    id_nomenclature = DB.Column(DB.Integer)


# Type library to list every report types
@serializable
class BibReportsTypes(DB.Model):
    __tablename__ = "bib_reports_types"
    __table_args__ = {"schema": "gn_synthese"}
    id_type = DB.Column(DB.Integer(), primary_key=True)
    type = DB.Column(DB.Text())


# Relation report model with User and BibReportsTypes to get every infos about a report
@serializable
class TReport(DB.Model):
    __tablename__ = "t_reports"
    __table_args__ = {"schema": "gn_synthese"}
    id_report = DB.Column(DB.Integer(), primary_key=True)
    id_synthese = DB.Column(DB.Integer(), ForeignKey("gn_synthese.synthese.id_synthese"))
    id_role = DB.Column(DB.Integer(), ForeignKey(User.id_role))
    id_type = DB.Column(DB.Integer(), ForeignKey(BibReportsTypes.id_type))
    content = DB.Column(DB.Text())
    creation_date = DB.Column(DB.DateTime(), default=datetime.datetime.utcnow)
    deleted = DB.Column(DB.Boolean(), default=False)

    synthese = relationship(Synthese, backref=db.backref("reports", order_by=creation_date))
    report_type = relationship(BibReportsTypes)
    user = DB.relationship(User)


@serializable
@geoserializable(geoCol="the_geom_4326", idCol="id_synthese")
class VSyntheseForWebApp(DB.Model):
    __tablename__ = "v_synthese_for_web_app"
    __table_args__ = {"schema": "gn_synthese"}

    id_synthese = DB.Column(
        DB.Integer,
        ForeignKey("gn_synthese.synthese.id_synthese"),
        primary_key=True,
    )
    unique_id_sinp = DB.Column(UUID(as_uuid=True))
    unique_id_sinp_grp = DB.Column(UUID(as_uuid=True))
    id_source = DB.Column(DB.Integer, nullable=False)
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

    medias = relationship(
        TMedias, primaryjoin=(TMedias.uuid_attached_row == foreign(unique_id_sinp)), uselist=True
    )

    reports = relationship(
        TReport, primaryjoin=(TReport.id_synthese == foreign(id_synthese)), uselist=True
    )


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
            id=str(getattr(self, idCol)),
            geometry=geometry,
            properties=self.as_dict_ordered(),
        )
        return feature

    cls.as_dict_ordered = serialize_order_fn
    cls.as_geofeature_ordered = serialize_geofn

    return cls


@serializable
class VColorAreaTaxon(DB.Model):
    __tablename__ = "v_color_taxon_area"
    __table_args__ = {"schema": "gn_synthese"}
    cd_nom = DB.Column(DB.Integer(), ForeignKey(Taxref.cd_nom), primary_key=True)
    id_area = DB.Column(DB.Integer(), ForeignKey(LAreas.id_area), primary_key=True)
    nb_obs = DB.Column(DB.Integer())
    last_date = DB.Column(DB.DateTime())
    color = DB.Column(DB.Unicode())


@serializable
class SyntheseLogEntry(DB.Model):
    """Log synthese table, populated with Delete Triggers on gn_synthes.synthese
    Parameters
    ----------
    DB:
        Flask SQLAlchemy controller
    """

    __tablename__ = "t_log_synthese"
    __table_args__ = {"schema": "gn_synthese"}
    query_class = SyntheseQuery
    id_synthese = DB.Column(DB.Integer(), primary_key=True)
    last_action = DB.Column(DB.Unicode)
    meta_last_action_date = DB.Column(DB.DateTime)


# defined here to avoid circular dependencies
source_subquery = (
    select([TSources.id_source, Synthese.id_dataset])
    .where(TSources.id_source == Synthese.id_source)
    .distinct()
    .alias()
)
TDatasets.sources = db.relationship(
    TSources,
    primaryjoin=TDatasets.id_dataset == source_subquery.c.id_dataset,
    secondaryjoin=source_subquery.c.id_source == TSources.id_source,
    secondary=source_subquery,
    viewonly=True,
)
