"""fill English labels of the individual marking type nomenclatures

Revision ID: 99e29fa95ab5
Revises: 78c7e705efd3
Create Date: 2026-10-29 20:00:00

Only empty labels are filled. The downgrade sets back to NULL the labels still equal to
the ones set here, a label typed by hand with the same text included.
"""

from alembic import op

revision = "99e29fa95ab5"
down_revision = "78c7e705efd3"
branch_labels = None
depends_on = None

# label_fr and definition_fr hold the same sentence, see 4e6ce32305f0
NOMENCLATURES = """
        ('1', 'The monitored individual is identifiable by a mark, a pattern or a natural distinctive sign'),
        ('2', 'The individual is identifiable by one or more rings'),
        ('3', 'A physical marking was made on the monitored individual (shaving or fur clipping, notch...)'),
        ('4', 'The individual is identifiable by numbering or a coloured marking (marker pen, paint...)'),
        ('5', 'The individual carries a transmitter or a chip')
"""


def upgrade():
    for column in ("label_en", "definition_en"):
        op.execute(f"""
            UPDATE ref_nomenclatures.t_nomenclatures n SET {column} = v.label
            FROM (VALUES
{NOMENCLATURES}
            ) AS v (cd_nomenclature, label)
            WHERE n.id_type = ref_nomenclatures.get_id_nomenclature_type('TYP_MARQUAGE')
              AND n.cd_nomenclature = v.cd_nomenclature AND coalesce(n.{column}, '') = ''
            """)
    op.execute("""
        UPDATE ref_nomenclatures.bib_nomenclatures_types SET label_en = 'Individual marking type'
        WHERE mnemonique = 'TYP_MARQUAGE' AND coalesce(label_en, '') = ''
        """)


def downgrade():
    for column in ("label_en", "definition_en"):
        op.execute(f"""
            UPDATE ref_nomenclatures.t_nomenclatures n SET {column} = NULL
            FROM (VALUES
{NOMENCLATURES}
            ) AS v (cd_nomenclature, label)
            WHERE n.id_type = ref_nomenclatures.get_id_nomenclature_type('TYP_MARQUAGE')
              AND n.cd_nomenclature = v.cd_nomenclature AND n.{column} = v.label
            """)
    op.execute("""
        UPDATE ref_nomenclatures.bib_nomenclatures_types SET label_en = NULL
        WHERE mnemonique = 'TYP_MARQUAGE' AND label_en = 'Individual marking type'
        """)
