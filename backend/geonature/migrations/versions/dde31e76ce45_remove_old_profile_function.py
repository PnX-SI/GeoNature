"""remove old profile function

Revision ID: dde31e76ce45
Revises: 6f7d5549d49e
Create Date: 2022-01-06 10:23:55.290043

"""

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision = "dde31e76ce45"
down_revision = "6f7d5549d49e"
branch_labels = None
depends_on = None


def upgrade():
    op.execute("DROP MATERIALIZED VIEW gn_synthese.vm_min_max_for_taxons")
    op.execute("DROP FUNCTION gn_synthese.fct_calculate_min_max_for_taxon(int4)")


def downgrade():
    op.execute(
        """
        CREATE MATERIALIZED VIEW gn_synthese.vm_min_max_for_taxons AS
            WITH
            s as (
            SELECT synt.cd_nom, t.cd_ref, the_geom_local, date_min, date_max, altitude_min, altitude_max
            FROM gn_synthese.synthese synt
            LEFT JOIN taxonomie.taxref t ON t.cd_nom = synt.cd_nom
            WHERE id_nomenclature_valid_status IN('1','2')
            )
            ,loc AS (
            SELECT cd_ref,
                count(*) AS nbobs,
                public.ST_Transform(
                    public.ST_SetSRID(
                        public.box2d(public.ST_extent(s.the_geom_local))::geometry,
                        public.Find_SRID('gn_synthese', 'synthese', 'the_geom_local')
                    ),
                    4326
                ) AS bbox4326
            FROM  s
            GROUP BY cd_ref
            )
            ,dat AS (
            SELECT cd_ref,
                min(TO_CHAR(date_min, 'DDD')::int) AS daymin,
                max(TO_CHAR(date_max, 'DDD')::int) AS daymax
            FROM s
            GROUP BY cd_ref
            )
            ,alt AS (
            SELECT cd_ref,
                min(altitude_min) AS altitudemin,
                max(altitude_max) AS altitudemax
            FROM s
            GROUP BY cd_ref
            )
            SELECT loc.cd_ref, nbobs,  daymin, daymax, altitudemin, altitudemax, bbox4326
            FROM loc
            LEFT JOIN alt ON alt.cd_ref = loc.cd_ref
            LEFT JOIN dat ON dat.cd_ref = loc.cd_ref
            ORDER BY loc.cd_ref;
    """
    )

    op.execute(
        """
        CREATE FUNCTION gn_synthese.fct_calculate_min_max_for_taxon(mycdnom integer)
            RETURNS TABLE(cd_ref integer, nbobs bigint, daymin integer, daymax integer, altitudemin integer, altitudemax integer, bbox4326 geometry)
            LANGUAGE plpgsql
            AS $function$
            BEGIN
                --USAGE (getting all fields): SELECT * FROM gn_synthese.fct_calculate_min_max_for_taxon(351);
                --USAGE (getting one or more field) : SELECT cd_ref, bbox4326 FROM gn_synthese.fct_calculate_min_max_for_taxon(351)
                --See field names and types in TABLE declaration above
                --RETURN one row for the supplied cd_ref or cd_nom
                --This function can be use in a FROM clause, like a table or a view
                RETURN QUERY SELECT * FROM gn_synthese.vm_min_max_for_taxons WHERE cd_ref = taxonomie.find_cdref(mycdnom);
            END;
            $function$
            ;
        """
    )
