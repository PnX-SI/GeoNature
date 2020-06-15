from geonature.utils.env import MA
from marshmallow import pre_load, fields
from .models import (
	TDatasets,
)

class DatasetSchema(MA.SQLAlchemyAutoSchema):
	class Meta:
		model = TDatasets
		load_instance = True
		include_fk = True