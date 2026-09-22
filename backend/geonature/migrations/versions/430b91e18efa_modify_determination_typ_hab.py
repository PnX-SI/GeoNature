"""modify DETERMINATION_TYP_HAB

Revision ID: 430b91e18efa
Revises: 78c7e705efd3
Create Date: 2026-09-21 08:01:14.258132

"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "430b91e18efa"
down_revision = "78c7e705efd3"
branch_labels = None
depends_on = None


def upgrade():
    op.execute("""
        DO $$
        DECLARE
            v_id_nomenclature_inconnu integer;
        BEGIN
            SELECT id_nomenclature INTO v_id_nomenclature_inconnu
            FROM ref_nomenclatures.t_nomenclatures
            WHERE id_type = ref_nomenclatures.get_id_nomenclature_type('DETERMINATION_TYP_HAB')
              AND cd_nomenclature = '0';

            IF v_id_nomenclature_inconnu IS NOT NULL THEN
                IF to_regclass('pr_occhab.t_habitats') IS NOT NULL THEN
                    UPDATE pr_occhab.t_habitats
                    SET id_nomenclature_determination_type = NULL
                    WHERE id_nomenclature_determination_type = v_id_nomenclature_inconnu;
                END IF;

                DELETE FROM ref_nomenclatures.t_nomenclatures
                WHERE id_nomenclature = v_id_nomenclature_inconnu;
            END IF;
        END $$;
        """)


def downgrade():
    op.execute("""
        INSERT INTO ref_nomenclatures.t_nomenclatures (
            id_type, cd_nomenclature, mnemonique, label_fr, definition_fr,
            source, statut, id_broader, hierarchy, active
        ) VALUES (
            ref_nomenclatures.get_id_nomenclature_type('DETERMINATION_TYP_HAB'),
            '0', '0', 'Inconnu', 'Inconnu : le type de détermination n''est pas connu',
            'SINP', 'Validé', 0, '118.001', true
        )
        """)
