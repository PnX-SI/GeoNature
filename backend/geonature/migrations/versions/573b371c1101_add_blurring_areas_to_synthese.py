"""add blurring areas to synthese

Revision ID: 573b371c1101
Revises: 707390c722fe
Create Date: 2025-06-04 17:43:00.452956

"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.types import ARRAY


# revision identifiers, used by Alembic.
revision = "573b371c1101"
down_revision = "707390c722fe"
branch_labels = None
depends_on = None


def upgrade():
    # Ensure cor_area_synthese in populated before evaluating sensitivity
    op.execute(
        """
        ALTER TRIGGER tri_insert_cor_area_synthese ON gn_synthese.synthese RENAME TO tri_insert_10_cor_area_synthese;
               """
    )
    op.execute(
        """
        ALTER TRIGGER tri_insert_calculate_sensitivity ON gn_synthese.synthese RENAME TO tri_insert_20_calculate_sensitivity;
               """
    )
    op.execute(
        """
        ALTER TRIGGER tri_update_cor_area_synthese ON gn_synthese.synthese RENAME TO tri_update_10_cor_area_synthese;
               """
    )
    op.execute(
        """
        ALTER TRIGGER tri_update_calculate_sensitivity ON gn_synthese.synthese RENAME TO tri_update_20_calculate_sensitivity;
               """
    )
    op.add_column(
        schema="gn_synthese",
        table_name="synthese",
        column=sa.Column("id_areas_blurring", ARRAY(sa.Integer)),
    )
    op.execute(
        """
        CREATE FUNCTION gn_sensitivity.get_id_areas_blurring(id_synthese int4, id_nomenclature_sensitivity int4)
            RETURNS integer[]
            LANGUAGE plpgsql
        AS $function$
            DECLARE
                id_areas_blurring integer[];
            BEGIN
                SELECT INTO id_areas_blurring array_agg(cas.id_area)
                FROM gn_synthese.cor_area_synthese cas
                JOIN ref_geo.l_areas a ON a.id_area = cas.id_area
                JOIN ref_geo.bib_areas_types t ON t.id_type = a.id_type
                JOIN gn_sensitivity.cor_sensitivity_area_type cst ON cst.id_area_type = t.id_type
                WHERE cst.id_nomenclature_sensitivity = get_id_areas_blurring.id_nomenclature_sensitivity;

                RETURN id_areas_blurring;
            END;
        $function$
        ;
        """
    )


def downgrade():
    op.execute("DROP FUNCTION gn_sensitivity.get_id_areas_blurring(int4,int4)")
    op.drop_column(schema="gn_synthese", table_name="synthese", column_name="id_areas_blurring")
    op.execute(
        """
        ALTER TRIGGER tri_insert_10_cor_area_synthese ON gn_synthese.synthese RENAME TO tri_insert_cor_area_synthese;
               """
    )
    op.execute(
        """
        ALTER TRIGGER tri_insert_20_calculate_sensitivity ON gn_synthese.synthese RENAME TO tri_insert_calculate_sensitivity;
               """
    )
    op.execute(
        """
        ALTER TRIGGER tri_update_10_cor_area_synthese ON gn_synthese.synthese RENAME TO tri_update_cor_area_synthese;
               """
    )
    op.execute(
        """
        ALTER TRIGGER tri_update_20_calculate_sensitivity ON gn_synthese.synthese RENAME TO tri_update_calculate_sensitivity;
               """
    )
