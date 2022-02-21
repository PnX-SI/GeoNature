from marshmallow import pre_load, fields

from geonature.utils.env import MA

from apptax.taxonomie.models import Taxref


class TaxrefSchema(MA.SQLAlchemyAutoSchema):
    class Meta:
        model = Taxref
        load_instance = True
        include_fk = True
