"""Insert French regions 1970-2016 in ref_geo

Revision ID: 05a0ae652c13
Create Date: 2021-11-23 12:06:37.699867

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import func
from shutil import copyfileobj

from ref_geo.migrations.utils import (
    schema,
    delete_area_with_type,
)
from utils_flask_sqla.migrations.utils import logger, open_remote_file


# revision identifiers, used by Alembic.
revision = "05a0ae652c13"
down_revision = None
branch_labels = ("ref_geo_fr_regions_1970",)
depends_on = ("3fdaa1805575",)  # ref_geo_fr_departments


def upgrade():
    conn = op.get_bind()

    metadata = sa.MetaData(bind=conn)
    area_type = sa.Table("bib_areas_types", metadata, schema="ref_geo", autoload_with=conn)
    conn.execute(
        area_type.insert().values(
            type_name="Ancienne régions",
            type_code="REG_1970",
            type_desc="Type anciennes régions",
            ref_name="Fusion départements IGN admin_express",
        )
    )
    area = sa.Table("l_areas", metadata, schema="ref_geo", autoload_with=conn)
    insert = area.insert(
        {
            "id_type": func.ref_geo.get_id_area_type("REG_1970"),
            "area_name": sa.bindparam("name"),
            "area_code": sa.bindparam("code"),
            "geom": sa.select(
                [
                    func.ST_Multi(
                        func.ST_Union(
                            func.ST_Transform(
                                area.c.geom, func.Find_SRID(schema, "l_areas", "geom")
                            )
                        )
                    )
                ]
            ).where(
                sa.and_(
                    area.c.id_type == func.ref_geo.get_id_area_type("DEP"),
                    area.c.area_code.in_(sa.bindparam("deps", expanding=True)),
                )
            ),
            "enable": False,
        }
    )
    # Note: 'expanding' parameters can't be used with executemany()
    # Note: are excluded regions not modified in 2016
    for params in [
        {"name": "Alsace", "code": 42, "deps": ["67", "68"]},
        {"name": "Aquitaine", "code": 72, "deps": ["24", "33", "40", "47", "64"]},
        {"name": "Auvergne", "code": 83, "deps": ["03", "15", "43", "63"]},
        {"name": "Bourgogne", "code": 26, "deps": ["21", "58", "71", "89"]},
        {"name": "Centre", "code": 24, "deps": ["18", "28", "36", "37", "41", "45"]},
        {"name": "Champagne-Ardenne", "code": 21, "deps": ["08", "10", "51", "52"]},
        {"name": "Franche-Comté", "code": 43, "deps": ["25", "39", "70", "90"]},
        {"name": "Languedoc-Roussillon", "code": 91, "deps": ["11", "30", "34", "48", "66"]},
        {"name": "Limousin", "code": 74, "deps": ["19", "23", "87"]},
        {"name": "Lorraine", "code": 41, "deps": ["54", "55", "57", "88"]},
        {
            "name": "Midi-Pyrénées",
            "code": 73,
            "deps": ["9", "12", "31", "32", "46", "65", "81", "82"],
        },
        {"name": "Nord-Pas-de-Calais", "code": 31, "deps": ["59", "62"]},
        {"name": "Basse-Normandie", "code": 25, "deps": ["14", "50", "61"]},
        {"name": "Haute-Normandie", "code": 23, "deps": ["27", "76"]},
        {"name": "Picardie", "code": 22, "deps": ["02", "60", "80"]},
        {"name": "Poitou-Charentes", "code": 54, "deps": ["16", "17", "79", "86"]},
        {
            "name": "Rhône-Alpes",
            "code": 82,
            "deps": ["01", "07", "26", "38", "42", "69", "73", "74"],
        },
    ]:
        conn.execute(insert, params)


def downgrade():
    delete_area_with_type("REG_1970")
    conn = op.get_bind()
    metadata = sa.MetaData(bind=conn)
    area_type = sa.Table("bib_areas_types", metadata, schema="ref_geo", autoload_with=conn)
    conn.execute(area_type.delete().where(area_type.c.type_code == "REG_1970"))
