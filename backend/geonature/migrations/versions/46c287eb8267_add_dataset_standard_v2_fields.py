"""Add dataset standard V2 fields

Revision ID: 46c287eb8267
Revises: 0444c425fa27
Create Date: 2026-08-19 11:24:42.500962

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '46c287eb8267'
down_revision = '0444c425fa27'
branch_labels = None
depends_on = None


classe_ebv_values = [
    ("1", "Données de répartition"),
    ("2", "Données d\'abondance"),
    ("3", "Données de morphologie"),
    ("4", "Données de physiologie"),
    ("5", "Données de phénologie"),
    ("6", "Données de mobilité spatiale"),
    ("7", "Données liées à la reproduction"),
    ("8", "Données liées à la génétique"),
]


def upgrade():
    # Create new nomenclature type "JDD_CLASSE_EBV"
    op.execute("""
        INSERT INTO ref_nomenclatures.bib_nomenclatures_types (
            mnemonique, label_default, label_fr,
            "source", statut
        )
        VALUES
        (
            'JDD_CLASSE_EBV', 'Classe EBV', 'Classe EBV',
            'GEONATURE', 'Non validé'
        );
        """)

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
    for cd_nomenclature, label in classe_ebv_values:
        label = label.replace("'", "''")
        list_nomenclature.append(f"""(
            (ref_nomenclatures.get_id_nomenclature_type('JDD_CLASSE_EBV')),
            '{cd_nomenclature}',
            '{label}',
            '{label}',
            '{label}',
            '{label}',
            '{label}',
            'GEONATURE', 'Non validé', 0,
            (ref_nomenclatures.get_id_nomenclature_type('JDD_CLASSE_EBV'))||'.00{cd_nomenclature}',
            true
            )
    """)
    op.execute(sql + ",".join(list_nomenclature))

    # Create the dataset <-> classe EBV correspondance table
    op.execute("""
        CREATE TABLE gn_meta.cor_dataset_classe_ebv (
            id_dataset integer NOT NULL,
            id_nomenclature_classe_ebv integer NOT NULL
        );
        """)
    op.execute("""
        ALTER TABLE ONLY gn_meta.cor_dataset_classe_ebv
        ADD CONSTRAINT pk_cor_dataset_classe_ebv
        PRIMARY KEY (id_dataset, id_nomenclature_classe_ebv);
        """)
    op.create_table_comment(
        "cor_dataset_classe_ebv",
        'A dataset can have 0 or N "classe(s) EBV".',
        schema="gn_meta",
    )
    op.create_foreign_key(
        "fk_cor_dataset_classe_ebv_id_dataset",
        source_schema="gn_meta",
        source_table="cor_dataset_classe_ebv",
        local_cols=["id_dataset"],
        referent_schema="gn_meta",
        referent_table="t_datasets",
        remote_cols=["id_dataset"],
        onupdate="CASCADE",
        ondelete="CASCADE",
    )
    op.create_foreign_key(
        "fk_cor_dataset_classe_ebv_id_nomenclature_classe_ebv",
        source_schema="gn_meta",
        source_table="cor_dataset_classe_ebv",
        local_cols=["id_nomenclature_classe_ebv"],
        referent_schema="ref_nomenclatures",
        referent_table="t_nomenclatures",
        remote_cols=["id_nomenclature"],
        onupdate="CASCADE",
        ondelete="NO ACTION",
    )
    op.execute("""
        ALTER TABLE gn_meta.cor_dataset_classe_ebv
            ADD CONSTRAINT check_cor_dataset_classe_ebv
            CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_classe_ebv, 'JDD_CLASSE_EBV')) NOT VALID;
        """)


def downgrade():
    op.drop_table("cor_dataset_classe_ebv", schema="gn_meta")

    list_cd_nomenclature = [
        "'" + cd_nomenclature + "'" for cd_nomenclature, label in classe_ebv_values
    ]
    op.execute(f"""
        DELETE FROM ref_nomenclatures.t_nomenclatures
        WHERE id_type = ref_nomenclatures.get_id_nomenclature_type('JDD_CLASSE_EBV')
        AND cd_nomenclature IN ({",".join(list_cd_nomenclature)})
        """)
    op.execute(
        "DELETE FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique='JDD_CLASSE_EBV'"
    )
