"""fix typo in t_habitats.id_nomenclature_sensitivity

Revision ID: 36e28d7bbe9b
Revises: 53e6505aaaa9
Create Date: 2026-10-19 16:25:13

"""

from alembic import op

# revision identifiers, used by Alembic.
revision = "36e28d7bbe9b"
down_revision = "53e6505aaaa9"
branch_labels = None
depends_on = None


def rename(old, new):
    op.execute(f"""
        ALTER TABLE pr_occhab.t_habitats
            RENAME COLUMN id_nomenclature_{old} TO id_nomenclature_{new};
        ALTER TABLE pr_occhab.t_habitats
            RENAME CONSTRAINT fk_t_habitats_id_nomenclature_{old}
            TO fk_t_habitats_id_nomenclature_{new};
        """)


def upgrade():
    rename("sensitvity", "sensitivity")


def downgrade():
    rename("sensitivity", "sensitvity")
