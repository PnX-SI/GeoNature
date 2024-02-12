"""t_releves triggers optimization

Revision ID: 0ff94776a962
Revises: 61802a0f83b8
Create Date: 2022-11-14 15:39:49.550279

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "0ff94776a962"
down_revision = "9668b861bdb6"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        DROP TRIGGER tri_calculate_altitude ON pr_occtax.t_releves_occtax;
        CREATE TRIGGER tri_calculate_altitude BEFORE
        INSERT OR UPDATE
        OF geom_4326
        ON pr_occtax.t_releves_occtax
        FOR EACH ROW EXECUTE FUNCTION ref_geo.fct_trg_calculate_alt_minmax('geom_4326');

        DROP TRIGGER tri_calculate_geom_local ON pr_occtax.t_releves_occtax;
        CREATE TRIGGER tri_calculate_geom_local BEFORE
        INSERT OR UPDATE
        OF geom_4326
        ON pr_occtax.t_releves_occtax
        FOR EACH ROW EXECUTE FUNCTION ref_geo.fct_trg_calculate_geom_local('geom_4326', 'geom_local');
        """
    )


def downgrade():
    op.execute(
        """
        DROP TRIGGER tri_calculate_altitude ON pr_occtax.t_releves_occtax;
        CREATE TRIGGER tri_calculate_altitude BEFORE
        INSERT OR UPDATE
        ON pr_occtax.t_releves_occtax
        FOR EACH ROW EXECUTE FUNCTION ref_geo.fct_trg_calculate_alt_minmax('geom_4326');

        DROP TRIGGER tri_calculate_geom_local ON pr_occtax.t_releves_occtax;
        CREATE TRIGGER tri_calculate_geom_local BEFORE
        INSERT OR UPDATE
        ON pr_occtax.t_releves_occtax
        FOR EACH ROW EXECUTE FUNCTION ref_geo.fct_trg_calculate_geom_local('geom_4326', 'geom_local');
        """
    )
