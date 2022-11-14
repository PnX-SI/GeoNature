"""t_releves triggers optimization

Revision ID: 0ff94776a962
Revises: 61802a0f83b8
Create Date: 2022-11-14 15:39:49.550279

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "0ff94776a962"
down_revision = "61802a0f83b8"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        DROP TRIGGER IF EXISTS tri_update_synthese_t_releve_occtax ON pr_occtax.t_releves_occtax;
        CREATE TRIGGER tri_update_synthese_t_releve_occtax AFTER
        UPDATE
        OF
            id_dataset, observers_txt, id_digitiser, grp_method, id_nomenclature_grp_typ,
            date_min, hour_min, date_max, hour_max, altitude_min, altitude_max, depth_min,
            depth_max, place_name, precision, geom_local, geom_4326,
            id_nomenclature_geo_object_nature, comment, additional_fields
        ON pr_occtax.t_releves_occtax
        FOR EACH ROW EXECUTE FUNCTION pr_occtax.fct_tri_synthese_update_releve();

        DROP TRIGGER IF EXISTS tri_calculate_altitude ON pr_occtax.t_releves_occtax;
        CREATE TRIGGER tri_calculate_altitude BEFORE
        INSERT OR  UPDATE
        OF geom_4326
        ON pr_occtax.t_releves_occtax
        FOR EACH ROW EXECUTE FUNCTION ref_geo.fct_trg_calculate_alt_minmax('geom_4326');

        DROP TRIGGER IF EXISTS tri_calculate_geom_local ON pr_occtax.t_releves_occtax;
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
        DROP TRIGGER IF EXISTS tri_update_synthese_t_releve_occtax ON pr_occtax.t_releves_occtax;
        CREATE TRIGGER tri_update_synthese_t_releve_occtax AFTER
        UPDATE
        ON pr_occtax.t_releves_occtax
        FOR EACH ROW EXECUTE FUNCTION pr_occtax.fct_tri_synthese_update_releve();

        DROP TRIGGER IF EXISTS tri_calculate_altitude ON pr_occtax.t_releves_occtax;
        CREATE TRIGGER tri_calculate_altitude BEFORE
        INSERT OR UPDATE
        ON pr_occtax.t_releves_occtax
        FOR EACH ROW EXECUTE FUNCTION ref_geo.fct_trg_calculate_alt_minmax('geom_4326');

        DROP TRIGGER IF EXISTS tri_calculate_geom_local ON pr_occtax.t_releves_occtax;
        CREATE TRIGGER tri_calculate_geom_local BEFORE
        INSERT OR UPDATE
        ON pr_occtax.t_releves_occtax
        FOR EACH ROW EXECUTE FUNCTION ref_geo.fct_trg_calculate_geom_local('geom_4326', 'geom_local');
    """
    )
