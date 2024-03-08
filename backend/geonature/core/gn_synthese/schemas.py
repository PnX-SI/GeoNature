from geonature.utils.env import db, ma
from geonature.utils.config import config

from geonature.core.gn_commons.schemas import ModuleSchema, MediaSchema, TValidationSchema
from geonature.core.gn_synthese.models import (
    BibReportsTypes,
    TReport,
    TSources,
    Synthese,
    VSyntheseForWebApp,
)
from geonature.core.gn_synthese.synthese_config import MANDATORY_COLUMNS

from pypn_habref_api.schemas import HabrefSchema
from pypnusershub.schemas import UserSchema
from pypnnomenclature.utils import NomenclaturesConverter
from ref_geo.schemas import AreaSchema
from utils_flask_sqla.schema import SmartRelationshipsMixin
from utils_flask_sqla_geo.schema import GeoAlchemyAutoSchema, GeoModelConverter, GeometryField


class ReportTypeSchema(ma.SQLAlchemyAutoSchema):
    class Meta:
        model = BibReportsTypes


class ReportSchema(SmartRelationshipsMixin, ma.SQLAlchemyAutoSchema):
    class Meta:
        model = TReport

    report_type = ma.Nested(ReportTypeSchema, dump_only=True)
    user = ma.Nested(UserSchema, dump_only=True)


class SourceSchema(ma.SQLAlchemyAutoSchema):
    class Meta:
        model = TSources
        load_instance = True

    module_url = ma.String(dump_only=True)


class SyntheseConverter(NomenclaturesConverter, GeoModelConverter):
    pass


class SyntheseSchema(SmartRelationshipsMixin, GeoAlchemyAutoSchema):
    class Meta:
        model = Synthese
        exclude = ("the_geom_4326_geojson",)
        include_fk = True
        load_instance = True
        sqla_session = db.session
        feature_id = "id_synthese"
        feature_geometry = "the_geom_4326"
        model_converter = SyntheseConverter

    the_geom_4326 = ma.auto_field(metadata={"exclude": True})
    the_geom_authorized = GeometryField(metadata={"exclude": True}, dump_only=True)
    source = ma.Nested(SourceSchema, dump_only=True)
    module = ma.Nested(ModuleSchema, dump_only=True)
    dataset = ma.Nested("DatasetSchema", dump_only=True)
    habitat = ma.Nested(HabrefSchema, dump_only=True)
    digitiser = ma.Nested(UserSchema, dump_only=True)
    cor_observers = ma.Nested(UserSchema, many=True, dump_only=True)
    medias = ma.Nested(MediaSchema, many=True, dump_only=True)
    areas = ma.Nested(AreaSchema, many=True, dump_only=True)
    area_attachment = ma.Nested(AreaSchema, dump_only=True)
    validations = ma.Nested(TValidationSchema, many=True, dump_only=True)
    last_validation = ma.Nested(TValidationSchema, dump_only=True)
    reports = ma.Nested(ReportSchema, many=True)
    # Missing nested schemas: taxref
