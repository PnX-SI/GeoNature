"""[monitoring] add nomenclature marking type for individuals

Revision ID: 4e6ce32305f0
Revises: bc28b69025b3
Create Date: 2025-01-27 10:27:40.099564

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "4e6ce32305f0"
down_revision = "bc28b69025b3"
branch_labels = None
depends_on = None

nomenclature_type_marquage = [
    (
        "1",
        "Pattern / signe distinctif naturel",
        "L''individu suivi est identifiable par une marque, un pattern ou un signe distinctif naturel",
    ),
    (
        "2",
        "Baguage",
        "L''individu est identifiable par une ou des bagues",
    ),
    (
        "3",
        "Marque physique : encoche, tonsure...",
        "Un marquage physique a été réalisé sur l''individu suivi (rasage ou tonsure, encoche ...)",
    ),
    (
        "4",
        "Numérotation / Coloration",
        "L''individu est identifiable par une numérotation ou un marquage coloré (feutre, peinture...)",
    ),
    (
        "5",
        "Puce ou émetteur",
        "L''individu est porteur d''un émetteur ou d''une puce",
    ),
]


def upgrade():
    sql = """INSERT INTO ref_nomenclatures.t_nomenclatures (
        id_type, 
        cd_nomenclature, 
        mnemonique, 
        label_default, 
        definition_default, 
        label_fr, 
        definition_fr, 
        source, 
        statut, 
        id_broader, 
        hierarchy,
        active
    ) VALUES """
    list_nomenclature = []
    for cd_nomenclature, mnemonique, label_default in nomenclature_type_marquage:
        list_nomenclature.append(
            f"""(
            (ref_nomenclatures.get_id_nomenclature_type('TYP_MARQUAGE')),
            '{cd_nomenclature}', 
            '{mnemonique}', 
            '{label_default}',
            '{label_default}',
            '{label_default}',
            '{label_default}',
            'GEONATURE', 'Non validé', 0, 
            (ref_nomenclatures.get_id_nomenclature_type('TYP_MARQUAGE'))||'.00{cd_nomenclature}', 
            true
            )
    """
        )

    op.execute(sql + ",".join(list_nomenclature))


def downgrade():
    list_cd_nomenclature = [
        "'" + cd_nomenclature + "'"
        for cd_nomenclature, mnemonique, label_default in nomenclature_type_marquage
    ]
    sql = f"""
        DELETE FROM ref_nomenclatures.t_nomenclatures 
               WHERE id_type = ref_nomenclatures.get_id_nomenclature_type('TYP_MARQUAGE') 
               AND cd_nomenclature IN ({','.join(list_cd_nomenclature)})
        """
    op.execute(sql)
