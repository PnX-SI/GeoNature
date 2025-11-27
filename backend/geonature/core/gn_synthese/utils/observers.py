from sqlalchemy import select

from geonature.core.gn_synthese.models import VSyntheseForWebApp
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery


class ObserversUtils:
    @staticmethod
    def get_observers_subquery(name: str):
        """Return a subquery yielding synthese ids filtered by observer name."""
        filters = {"observers": name}
        observer_query = select(VSyntheseForWebApp.id_synthese).distinct()
        synthese_query = SyntheseQuery(
            VSyntheseForWebApp,
            observer_query,
            filters,
        )
        synthese_query.filter_other_filters(user=None)
        return synthese_query.build_query().subquery("observer_filter")
