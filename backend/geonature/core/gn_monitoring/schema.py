from marshmallow import fields

from geonature.core.gn_commons.schemas import ModuleSchema
from geonature.utils.env import MA
from geonature.core.gn_monitoring.models import TIndividuals, TMarkingEvent
from pypnnomenclature.schemas import NomenclatureSchema
from pypnusershub.schemas import UserSchema


class TMarkingEventSchema(MA.SQLAlchemyAutoSchema):
    class Meta:
        model = TMarkingEvent
        include_fk = True
        load_instance = True

    operator = MA.Nested(UserSchema, dump_only=True)

class TIndividualsSchema(MA.SQLAlchemyAutoSchema):
    class Meta:
        model = TIndividuals
        include_fk = True
        load_instance = True

    nomenclature_sex = MA.Nested(NomenclatureSchema, dump_only=True)
    digitiser = MA.Nested(UserSchema, dump_only=True)
    modules = fields.List(MA.Nested(ModuleSchema, dump_only=True))
    markings = fields.List(MA.Nested(TMarkingEventSchema, dump_only=True))
