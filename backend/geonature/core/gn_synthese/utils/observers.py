from geonature.core.gn_synthese.models import Synthese, CorObserverSynthese
from sqlalchemy import select, and_
from sqlalchemy.orm import Query


class ObserversUtils:

    @staticmethod
    def get_observers_subquery(id_role: int) -> Query:
        return (
            select(Synthese.id_synthese)
            .join(
                CorObserverSynthese,
                and_(
                    CorObserverSynthese.id_synthese == Synthese.id_synthese,
                    CorObserverSynthese.id_role == id_role,
                ),
            )
            .alias("observers")
        )
