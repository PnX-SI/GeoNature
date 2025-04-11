"""auto update cor_area_synthese

Revision ID: c0fdf2ee7f4f
Revises: f06cc80cc8ba
Create Date: 2021-09-14 17:18:11.606752

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "c0fdf2ee7f4f"
down_revision = "f06cc80cc8ba"
branch_labels = None
depends_on = None


def upgrade():
    # Add 'on delete cascade' on gn_synthese.cor_area_synthese.id_area FK
    op.drop_constraint(
        "fk_cor_area_synthese_id_area", table_name="cor_area_synthese", schema="gn_synthese"
    )
    op.create_foreign_key(
        "fk_cor_area_synthese_id_area",
        source_schema="gn_synthese",
        source_table="cor_area_synthese",
        local_cols=["id_area"],
        referent_schema="ref_geo",
        referent_table="l_areas",
        remote_cols=["id_area"],
        onupdate="CASCADE",
        ondelete="CASCADE",
    )

    # Populate gn_synthese.cor_area_synthese on new areas inserted in ref_geo.l_areas
    op.execute(
        """
    CREATE OR REPLACE FUNCTION gn_synthese.fct_trig_l_areas_insert_cor_area_synthese_on_each_statement()
     RETURNS trigger
     LANGUAGE plpgsql
    AS $function$
      DECLARE
      BEGIN
      -- Intersection de toutes les observations avec les nouvelles zones et écriture dans cor_area_synthese
          INSERT INTO gn_synthese.cor_area_synthese (id_area, id_synthese)
            SELECT
              new_areas.id_area AS id_area,
              s.id_synthese as id_synthese
            FROM NEW as new_areas
            join gn_synthese.synthese s
              ON public.ST_INTERSECTS(s.the_geom_local, new_areas.geom)
            WHERE new_areas.enable IS true
                AND (
                        ST_GeometryType(s.the_geom_local) = 'ST_Point'
                    OR
                    NOT public.ST_TOUCHES(s.the_geom_local, new_areas.geom)
                );
      RETURN NULL;
      END;
      $function$
    """
    )
    op.execute(
        """
    CREATE TRIGGER tri_insert_cor_area_synthese after
    INSERT ON ref_geo.l_areas
    REFERENCING NEW TABLE AS new
    FOR EACH STATEMENT
    EXECUTE PROCEDURE gn_synthese.fct_trig_l_areas_insert_cor_area_synthese_on_each_statement();
    """
    )


def downgrade():
    op.execute("DROP TRIGGER tri_insert_cor_area_synthese ON ref_geo.l_areas")
    op.execute(
        "DROP FUNCTION gn_synthese.fct_trig_l_areas_insert_cor_area_synthese_on_each_statement"
    )

    # Remove 'on delete cascade' on gn_synthese.cor_area_synthese.id_area FK
    op.drop_constraint(
        "fk_cor_area_synthese_id_area", table_name="cor_area_synthese", schema="gn_synthese"
    )
    op.create_foreign_key(
        "fk_cor_area_synthese_id_area",
        source_schema="gn_synthese",
        source_table="cor_area_synthese",
        local_cols=["id_area"],
        referent_schema="ref_geo",
        referent_table="l_areas",
        remote_cols=["id_area"],
        onupdate="CASCADE",
    )
