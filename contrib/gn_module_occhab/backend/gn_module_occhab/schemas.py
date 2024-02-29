from marshmallow import fields, validates_schema, EXCLUDE
from marshmallow.decorators import post_dump
from marshmallow.exceptions import ValidationError
from marshmallow_sqlalchemy import auto_field
from marshmallow_sqlalchemy.fields import Nested

from geonature.utils.env import db, ma
from geonature.utils.schema import CruvedSchemaMixin
from geonature.core.gn_meta.schemas import DatasetSchema
from geonature.core.gn_permissions.tools import get_scopes_by_action

from pypnusershub.schemas import UserSchema
from pypnnomenclature.utils import NomenclaturesConverter
from pypn_habref_api.schemas import HabrefSchema
from utils_flask_sqla.schema import SmartRelationshipsMixin
from utils_flask_sqla_geo.schema import GeoAlchemyAutoSchema, GeoModelConverter

from gn_module_occhab.models import Station, OccurenceHabitat


class StationConverter(NomenclaturesConverter, GeoModelConverter):
    pass


class StationSchema(CruvedSchemaMixin, SmartRelationshipsMixin, GeoAlchemyAutoSchema):
    class Meta:
        model = Station
        include_fk = True
        load_instance = True
        sqla_session = db.session
        feature_id = "id_station"
        model_converter = StationConverter
        feature_geometry = "geom_4326"

    __module_code__ = "OCCHAB"

    id_station = auto_field(allow_none=True)
    unique_id_sinp_station = fields.String(required=True)

    date_min = fields.DateTime("%Y-%m-%d")
    date_max = fields.DateTime("%Y-%m-%d")

    habitats = Nested("OccurenceHabitatSchema", unknown=EXCLUDE, many=True)
    observers = Nested(UserSchema, unknown=EXCLUDE, many=True)
    dataset = Nested(DatasetSchema, dump_only=True)

    @validates_schema
    def validate_habitats(self, data, **kwargs):
        """
        Ensure this schema is not leveraged to retrieve habitats from other station
        """
        for hab in data.get("habitats", []):
            # Note: unless instance is given during schema instantiation or when load is called,
            # self.instance in created in @post_load, but @validates_schema execute before @post_load
            # so we need to use data.get("id_station")
            sta_id_station = self.instance.id_station if self.instance else data.get("id_station")
            # we could have hab.id_station None with station.id_station not None when creating new habitats
            if hab.id_station is not None and hab.id_station != sta_id_station:
                raise ValidationError(
                    "Habitat does not belong to this station.", field_name="habitats"
                )


class OccurenceHabitatSchema(SmartRelationshipsMixin, ma.SQLAlchemyAutoSchema):
    class Meta:
        model = OccurenceHabitat
        include_fk = True
        load_instance = True
        sqla_session = db.session
        model_converter = NomenclaturesConverter

    id_habitat = auto_field(allow_none=True)
    id_station = auto_field(allow_none=True)
    unique_id_sinp_hab = auto_field(required=True)

    station = Nested(StationSchema)
    habref = Nested(HabrefSchema, dump_only=True)
