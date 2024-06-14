from geonature.core.imports.models import Entity, TImports
import sqlalchemy as sa
from sqlalchemy.orm import aliased

from geonature.utils.env import db


def generate_id_station(imprt: TImports, station_entity: Entity) -> None:
    """
    Generate the id_station for each new valid station

    Parameters
    ----------
    imprt : TImports
        _description_
    entity : Entity
        station entity
    """
    # Generate for each uuid an id_station
    transient_table = imprt.destination.get_transient_table()
    uuid_station_valid_cte = (
        sa.select(sa.distinct(transient_table.c.unique_id_sinp_station), transient_table.c.line_no)
        .where(transient_table.c.id_import == imprt.id_import)
        .where(transient_table.c[station_entity.validity_column].is_(True))
        .cte("uuid_station_valid_cte")
    )

    db.session.execute(
        sa.update(transient_table)
        .where(transient_table.c.line_no == uuid_station_valid_cte.c.line_no)
        .values({"id_station": sa.func.nextval("pr_occhab.t_stations_id_station_seq")})
    )

    # in the previous query, we only updated the id_station for the first occurance of each uuid
    # the following query will set the id_station for all occurrence of each uuid
    id_station_to_uuid_cte = (
        sa.select(transient_table.c.id_station, transient_table.c.unique_id_sinp_station)
        .where(transient_table.c.id_station.is_not(None))
        .where(transient_table.c.id_import == imprt.id_import)
        .where(transient_table.c[station_entity.validity_column].is_(True))
        .cte("cte")
    )
    db.session.execute(
        sa.update(transient_table)
        .where(transient_table.c.id_import == imprt.id_import)
        .where(transient_table.c[station_entity.validity_column].is_(True))
        .where(
            transient_table.c.unique_id_sinp_station
            == id_station_to_uuid_cte.c.unique_id_sinp_station
        )
        .values({"id_station": id_station_to_uuid_cte.c.id_station})
    )


def set_id_station_from_line_no(imprt: TImports, habitat_entity: Entity) -> None:
    """
    Set the id_station of each habitat in the transient table using the line_no of the corresponding station.

    Parameters
    ----------
    imprt : TImports
        The import object containing the destination.
    station_entity : Entity
        The entity representing the station.
    habitat_entity : Entity
        The entity representing the habitat.
    """
    transient_habitat = imprt.destination.get_transient_table()
    transient_station = aliased(transient_habitat)
    db.session.execute(
        sa.update(transient_habitat)
        .where(transient_habitat.c.id_import == imprt.id_import)
        .where(transient_habitat.c[habitat_entity.validity_column].is_(True))
        .where(transient_station.c.id_import == imprt.id_import)
        .where(transient_station.c.line_no == transient_habitat.c.station_line_no)
        .values({"id_station": transient_station.c.id_station})
    )
