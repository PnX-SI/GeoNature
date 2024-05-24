import sqlalchemy as sa
from sqlalchemy.orm import aliased

from geonature.utils.env import db


def generate_id_station(imprt, entity):
    transient_table = imprt.destination.get_transient_table()
    db.session.execute(
        sa.update(transient_table)
        .where(transient_table.c.id_import == imprt.id_import)
        .where(transient_table.c[entity.validity_column].is_(True))
        .values({"id_station": sa.func.nextval("pr_occhab.t_stations_id_station_seq")})
    )


def set_id_station_from_line_no(imprt, station_entity, habitat_entity):
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
