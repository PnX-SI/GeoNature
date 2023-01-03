"""add_altitude_calculation_in_t_base_site

Revision ID: 74908bad752e
Revises: ca0fe5d21ea2
Create Date: 2022-05-19 15:07:04.613778

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "74908bad752e"
down_revision = "ca0fe5d21ea2"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        CREATE TRIGGER tri_insert_calculate_altitude BEFORE
        INSERT ON gn_monitoring.t_base_sites
        FOR EACH ROW EXECUTE FUNCTION ref_geo.fct_trg_calculate_alt_minmax('geom')
        """
    )

    op.execute(
        """
        CREATE TRIGGER tri_update_calculate_altitude 
        BEFORE UPDATE OF geom_local, geom ON gn_monitoring.t_base_sites
        FOR EACH ROW EXECUTE FUNCTION ref_geo.fct_trg_calculate_alt_minmax('geom')
        """
    )

    op.execute(
        """
        update gn_monitoring.t_base_sites s 
        set altitude_min =a.altitude_min, altitude_max = a.altitude_max
        from (select 
            id_base_site,
            alti.*
            from gn_monitoring.t_base_sites bs, lateral ref_geo.fct_get_altitude_intersection(bs.geom) alti
        )a
        where a.id_base_site = s.id_base_site
        """
    )


def downgrade():
    op.execute(
        """
        DROP TRIGGER tri_insert_calculate_altitude ON gn_monitoring.t_base_sites;
        DROP TRIGGER tri_update_calculate_altitude ON gn_monitoring.t_base_sites;
        """
    )
