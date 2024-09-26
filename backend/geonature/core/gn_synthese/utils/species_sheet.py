import typing
from geonature.utils.env import db
from ref_geo.models import LAreas, BibAreasTypes

from geonature.core.gn_synthese.models import Synthese
from sqlalchemy import select
from apptax.taxonomie.models import Taxref
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery


class SpeciesSheetUtils:

    @staticmethod
    def get_cd_nom_list_from_cd_ref(cd_ref: int) -> typing.List[int]:
        return db.session.scalars(select(Taxref.cd_nom).where(Taxref.cd_ref == cd_ref))

    @staticmethod
    def get_synthese_query_with_scope(current_user, scope: int, query) -> any:
        synthese_query_obj = SyntheseQuery(Synthese, query, {})
        synthese_query_obj.filter_query_with_cruved(current_user, scope)
        return synthese_query_obj.query

    @staticmethod
    def is_valid_area_type(area_type: str) -> bool:
        # Ensure area_type is valid
        valid_area_types = (
            db.session.query(BibAreasTypes.type_code)
            .distinct()
            .filter(BibAreasTypes.type_code == area_type)
            .scalar()
        )

        return valid_area_types

    @staticmethod
    def get_area_subquery(area_type: str) -> any:

        # Subquery to fetch areas based on area_type
        return (
            select([LAreas.id_area])
            .where(LAreas.id_type == BibAreasTypes.id_type)
            .where(BibAreasTypes.type_code == area_type)
            .alias("areas")
        )
