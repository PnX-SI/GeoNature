from geonature.utils.env import ma

from geonature.core.gn_synthese.models import TSources


class SourceSchema(ma.SQLAlchemyAutoSchema):
    class Meta:
        model = TSources
        load_instance = True

    module_url = ma.String(dump_only=True)
