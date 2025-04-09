from geonature.core.gn_permissions.tools import get_scopes_by_action
from geonature.core.imports.checks.errors import ImportCodeError
from geonature.core.imports.checks.sql.utils import report_erroneous_rows
from geonature.core.imports.models import Entity, TImports
from gn_module_occhab.models import Station
import sqlalchemy as sa
from sqlalchemy.orm import aliased

from geonature.utils.env import db


def check_existing_station_permissions(imprt: TImports) -> None:
    """
    Check that the user has update right on all stations associated with the newly imported habitats.

    Parameters
    ----------
    imprt : TImports
        Current import
    """

    transient_table = imprt.destination.get_transient_table()
    entity_habitat = Entity.query.filter_by(code="habitat").one()

    # Get User permissions on OCCHAB
    author = imprt.authors[0]
    cruved = get_scopes_by_action(id_role=author.id_role, module_code="OCCHAB")

    # Return error when a station in the transition table is not updatable
    report_erroneous_rows(
        imprt,
        entity=entity_habitat,
        error_type=ImportCodeError.DATASET_NOT_AUTHORIZED,
        error_column="",
        whereclause=sa.and_(
            transient_table.c.id_station == Station.id_station,
            sa.not_(Station.filter_by_scope(scope=cruved["U"], user=author)),
        ),
    )
