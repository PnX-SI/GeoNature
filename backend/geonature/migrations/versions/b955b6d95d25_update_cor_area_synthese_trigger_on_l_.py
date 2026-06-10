"""Update cor_area_synthese trigger on l_areas

Revision ID: b955b6d95d25
Revises: cad98c048b5e
Create Date: 2025-12-02 14:36:03.650273

"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "b955b6d95d25"
down_revision = "cad98c048b5e"
branch_labels = None
depends_on = None


def upgrade():
    op.execute("""
                CREATE OR REPLACE FUNCTION gn_synthese.fct_trig_l_areas_update_cor_area_synthese_on_each_statement() RETURNS TRIGGER
                    LANGUAGE plpgsql
                AS
                $update_cor_area_synthese$
                DECLARE
                    count_delete  INT;
                    count_inserts INT;
                BEGIN
                    RAISE NOTICE 'Update areas %', (SELECT STRING_AGG(concat(area_name, ' (', area_code,')'), ', ') FROM new);

                    WITH deleted AS (DELETE FROM gn_synthese.cor_area_synthese WHERE id_area IN (SELECT id_area FROM new) RETURNING *)
                    SELECT COUNT(*)
                    INTO count_delete
                    FROM deleted;
                    RAISE NOTICE '% row deleted from cor_area_synthese', count_delete;
                    WITH inserts AS (INSERT INTO gn_synthese.cor_area_synthese (id_area, id_synthese)
                        SELECT new_areas.id_area AS id_area
                            , s.id_synthese     AS id_synthese
                        FROM new AS new_areas
                                JOIN gn_synthese.synthese s
                                    ON public.st_intersects(s.the_geom_local, new_areas.geom)
                        WHERE new_areas.enable IS TRUE
                        AND (
                            public.st_geometrytype(s.the_geom_local) = 'ST_Point'
                                OR
                            NOT public.st_touches(s.the_geom_local, new_areas.geom)
                            )
                        RETURNING *)
                    SELECT COUNT(*)
                    INTO count_inserts
                    FROM inserts;
                    RAISE NOTICE '% row inserted into cor_area_synthese', count_inserts;
                    RETURN NULL;
                    -- result is ignored since this is an AFTER trigger
                    -- Intersection de toutes les observations avec les nouvelles zones et écriture dans cor_area_synthese
                END;
                $update_cor_area_synthese$;

                CREATE TRIGGER tri_update_cor_area_synthese
                    AFTER UPDATE
                    ON ref_geo.l_areas
                    REFERENCING new TABLE new
                EXECUTE PROCEDURE gn_synthese.fct_trig_l_areas_update_cor_area_synthese_on_each_statement();
        """)


def downgrade():
    op.execute("""
        DROP TRIGGER tri_update_cor_area_synthese ON ref_geo.l_areas;   
        DROP FUNCTION gn_synthese.fct_trig_l_areas_update_cor_area_synthese_on_each_statement();
        """)
