"""Add dataset standard V2 fields

Revision ID: 46c287eb8267
Revises: 0444c425fa27
Create Date: 2026-08-19 11:24:42.500962

"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "46c287eb8267"
down_revision = "7808ac8b10b6"
branch_labels = None
depends_on = None


data_type_values = [
    ("1", "données source"),
    ("2", "données d'observation"),
    ("3", "données intermédiaires"),
    ("4", "indicateurs"),
]

classe_ebv_values = [
    ("1", "Données de répartition"),
    ("2", "Données d'abondance"),
    ("3", "Données de morphologie"),
    ("4", "Données de physiologie"),
    ("5", "Données de phénologie"),
    ("6", "Données de mobilité spatiale"),
    ("7", "Données liées à la reproduction"),
    ("8", "Données liées à la génétique"),
]


def insert_type_donnees():
    # Create new nomenclature type "TYPE_DONNEES"
    op.execute("""
        INSERT INTO ref_nomenclatures.bib_nomenclatures_types (
            mnemonique, label_default, label_fr,
            "source", statut
        )
        VALUES
        (
            'TYPE_DONNEES', 'Type de données', 'Type de données',
            'GEONATURE', 'Validé'
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
    for cd_nomenclature, label in data_type_values:
        label = label.replace("'", "''")
        list_nomenclature.append(f"""(
            (ref_nomenclatures.get_id_nomenclature_type('TYPE_DONNEES')),
            '{cd_nomenclature}',
            '{label}',
            '{label}',
            '{label}',
            '{label}',
            '{label}',
            'GEONATURE', 'Validé', 0,
            (ref_nomenclatures.get_id_nomenclature_type('TYPE_DONNEES'))||'.000{cd_nomenclature}',
            true
            )
    """)
    op.execute(sql + ",".join(list_nomenclature))


def insert_ebv_class():
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


def add_cor_dataset_ebv():
    # Create the dataset <-> classe EBV correspondance table
    op.execute("""
               CREATE TABLE gn_meta.cor_dataset_classe_ebv
               (
                   id_dataset                 integer NOT NULL,
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
                       CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_classe_ebv,
                                                                                      'JDD_CLASSE_EBV')) NOT VALID;
               """)


def add_data_type_2_column():
    # Add the id_nomenclature_data_type_2 column to t_datasets
    op.add_column(
        "t_datasets",
        sa.Column(
            "id_nomenclature_data_type_2",
            sa.Integer(),
            sa.ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
            nullable=True,
            server_default=sa.text(
                "ref_nomenclatures.get_default_nomenclature_value('TYPE_DONNEES')"
            ),
        ),
        schema="gn_meta",
    )

    # Add constraint to check nomenclature type
    op.execute("""
        ALTER TABLE gn_meta.t_datasets
        ADD CONSTRAINT check_data_type_2_nomenclature
        CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_data_type_2, 'TYPE_DONNEES')) NOT VALID
        """)


def set_default_data_type_2():
    # Set the default value for TYPE_DONNEES to "2" (données d'observation) in defaults_nomenclatures_value
    op.execute("""
        INSERT INTO ref_nomenclatures.defaults_nomenclatures_value
        (mnemonique_type, id_organism, id_nomenclature)
        SELECT 
            'TYPE_DONNEES',
            (SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'ALL'),
            nom.id_nomenclature
        FROM ref_nomenclatures.t_nomenclatures nom
        JOIN ref_nomenclatures.bib_nomenclatures_types t 
            ON nom.id_type = t.id_type
        WHERE t.mnemonique = 'TYPE_DONNEES'
        AND nom.cd_nomenclature = '2'
        ON CONFLICT (mnemonique_type, id_organism) DO UPDATE
        SET id_nomenclature = EXCLUDED.id_nomenclature
        """)


def upgrade():
    insert_ebv_class()
    add_cor_dataset_ebv()
    insert_type_donnees()
    add_data_type_2_column()
    set_default_data_type_2()


def downgrade_type_donnees():
    op.execute("""
        DELETE FROM ref_nomenclatures.defaults_nomenclatures_value
        WHERE mnemonique_type = 'TYPE_DONNEES' AND id_organism = (SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'ALL')
        """)
    # Remove the constraint
    op.execute("""
        ALTER TABLE gn_meta.t_datasets
        DROP CONSTRAINT IF EXISTS check_data_type_2_nomenclature
        """)

    # Drop the column
    op.drop_column("t_datasets", "id_nomenclature_data_type_2", schema="gn_meta")

    # Delete nomenclatures
    list_cd_nomenclature = [
        "'" + cd_nomenclature + "'" for cd_nomenclature, label in data_type_values
    ]
    op.execute(f"""
        DELETE FROM ref_nomenclatures.t_nomenclatures
        WHERE id_type = ref_nomenclatures.get_id_nomenclature_type('TYPE_DONNEES')
        AND cd_nomenclature IN ({",".join(list_cd_nomenclature)})
        """)
    op.execute(
        "DELETE FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique='TYPE_DONNEES'"
    )


def downgrade_ebv_class():
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


def downgrade():
    downgrade_type_donnees()
    downgrade_ebv_class()
