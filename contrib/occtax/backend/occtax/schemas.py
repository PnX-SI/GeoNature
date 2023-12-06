from datetime import datetime

from flask import current_app, g
from marshmallow import pre_load, post_load, pre_dump, post_dump, fields, ValidationError
from marshmallow_sqlalchemy.convert import ModelConverter as BaseModelConverter
from shapely.geometry import shape
from geoalchemy2.shape import to_shape, from_shape
from geoalchemy2.types import Geometry as GeometryType
from geojson import Feature, FeatureCollection

from utils_flask_sqla_geo.utilsgeometry import remove_third_dimension

from geonature.utils.env import MA
from .models import CorCountingOccurrence, TOccurrencesOccurrence, TRelevesOccurrence
from geonature.core.gn_meta.schemas import DatasetSchema
from geonature.core.gn_commons.schemas import MediaSchema
from geonature.core.taxonomie.schemas import TaxrefSchema
from geonature.utils.config import config
from pypnusershub.db.models import User
from pypn_habref_api.schemas import HabrefSchema


@post_dump
def remove_additional_none_val(self, data, **kwargs):
    if "additional_fields" in data and data["additional_fields"] is None:
        data["additional_fields"] = {}
    return data


class GeojsonSerializationField(fields.Field):
    def _serialize(self, value, attr, obj):
        if value is None:
            return value
        else:
            if type(value).__name__ == "WKBElement":
                feature = Feature(geometry=to_shape(value))
                return feature.geometry
            else:
                return None

    def _deserialize(self, value, attr, data, **kwargs):
        try:
            shape_ = shape(value)
            two_dimension_geom = remove_third_dimension(shape_)
            return from_shape(two_dimension_geom, srid=4326)
        except ValueError as error:
            raise ValidationError("Geometry error") from error


class ObserverSchema(MA.SQLAlchemyAutoSchema):
    class Meta:
        model = User
        load_instance = True
        exclude = (
            "_password",
            "_password_plus",
            "active",
            "date_insert",
            "date_update",
            "desc_role",
            "email",
            "groupe",
            "remarques",
            "identifiant",
        )

    nom_complet = fields.Str(dump_only=True)

    @pre_load
    def make_observer(self, data, **kwargs):
        if isinstance(data, int):
            return dict({"id_role": data})
        return data


class CountingSchema(MA.SQLAlchemyAutoSchema):
    class Meta:
        model = CorCountingOccurrence
        load_instance = True

    medias = MA.Nested(MediaSchema, many=True)
    pre_dump_fn = remove_additional_none_val

    @pre_load
    def make_counting(self, data, **kwargs):
        if data.get("id_counting_occtax") is None:
            data.pop("id_counting_occtax", None)
        return data


class OccurrenceSchema(MA.SQLAlchemyAutoSchema):
    class Meta:
        model = TOccurrencesOccurrence
        load_instance = True
        include_fk = True

    additional_fields = fields.Raw(allow_none=False, required=True)
    # additional_fields = fields.Raw(load_only=True)
    cor_counting_occtax = MA.Nested(CountingSchema, many=True)
    taxref = MA.Nested(TaxrefSchema, dump_only=True)
    pre_dump_fn = remove_additional_none_val


class ReleveSchema(MA.SQLAlchemyAutoSchema):
    class Meta:
        model = TRelevesOccurrence
        load_instance = True
        include_fk = True
        exclude = ("geom_local",)

    date_min = fields.Date(format="%Y-%m-%d")
    date_max = fields.Date(format="%Y-%m-%d")
    hour_min = fields.Time(format="%H:%M", allow_none=True)
    hour_max = fields.Time(format="%H:%M", allow_none=True)
    geom_4326 = GeojsonSerializationField()

    id_digitiser = MA.auto_field(dump_only=True)

    t_occurrences_occtax = MA.Nested(OccurrenceSchema, many=True)
    observers = MA.Nested(
        ObserverSchema,
        many=True,
        allow_none=config.get("OCCTAX", {}).get("observers_txt", True),
    )
    digitiser = MA.Nested(ObserverSchema, dump_only=True)
    dataset = MA.Nested(DatasetSchema, dump_only=True)
    habitat = MA.Nested(HabrefSchema, dump_only=True)

    @pre_load
    def make_releve(self, data, **kwargs):
        data["id_module"] = g.current_module.id_module
        if "observers" in data and data["observers"] is None:
            data["observers"] = []
        if data.get("id_releve_occtax") is None:
            data.pop("id_releve_occtax", None)
        data.pop("id_digitiser", None)  # id_digitiser is dump_only
        return data

    pre_dump_fn = remove_additional_none_val


class GeojsonReleveSchema(MA.Schema):
    # class Meta:
    # load_instance = True

    id = fields.Integer()
    properties = fields.Nested(ReleveSchema(exclude=("geom_4326",)))
    geometry = GeojsonSerializationField()

    @post_load
    def make_geojsonReleve(self, data, **kwargs):
        if data.get("geometry") is not None:
            data.get("properties").geom_4326 = data.get("geometry")
        return data

    @pre_dump
    def set_(self, data, **kwargs):
        if data.get("properties") is not None:
            data["id"] = data.get("properties").id_releve_occtax
        return data


class CruvedSchema(MA.Schema):
    C = fields.Boolean(dump_default=False, load_default=False)
    R = fields.Boolean(dump_default=False, load_default=False)
    U = fields.Boolean(dump_default=False, load_default=False)
    V = fields.Boolean(dump_default=False, load_default=False)
    E = fields.Boolean(dump_default=False, load_default=False)
    D = fields.Boolean(dump_default=False, load_default=False)


class ReleveCruvedSchema(MA.Schema):
    releve = fields.Nested(GeojsonReleveSchema, dump_only=True)
    cruved = fields.Nested(CruvedSchema, dump_only=True)
