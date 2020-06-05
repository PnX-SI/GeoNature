from geonature.utils.env import MA
from marshmallow import post_load
from .models import CorCountingOccurrence

class CountingValidatorSchema(MA.SQLAlchemySchema):
	class Meta:
		model = CorCountingOccurrence
		include_fk = True
		strict = True

	@post_load
	def make_counting(self, data, **kwargs):
		return CorCountingOccurrence(**data)

	id_nomenclature_life_stage = MA.auto_field()
	id_nomenclature_sex = MA.auto_field()
	id_nomenclature_obj_count = MA.auto_field()
	id_nomenclature_type_count = MA.auto_field()
	count_min = MA.auto_field()
	count_max = MA.auto_field()
