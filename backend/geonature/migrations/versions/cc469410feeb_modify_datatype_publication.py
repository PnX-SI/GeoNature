"""Rename sinp_datatype_publications to datatype_publications and add fields

Revision ID: cc469410feeb
Revises: ae0b6362fb22
Create Date: 2026-08-07 08:24:44.564373

"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "cc469410feeb"
down_revision = "1ca1e8ec50f4"
branch_labels = None
depends_on = None


NOMENCLATURE_TYPE_MNEMONIQUE = "PUBLICATION_TYPE"

NOMENCLATURE_VALUES = [
    ("PDF_PROTOCOL", "PDF de protocole"),
    ("PDF_TRAITEMENT", "PDF de traitement"),
    ("PDF_VALORISATION", "PDF de valorisation"),
    ("DATAPAPER", "Datapaper"),
]


def create_datatype_nomenclature():
    definition = "Type de publication renseignée"
    op.execute(
        sa.text("""
            INSERT INTO ref_nomenclatures.bib_nomenclatures_types
                (mnemonique, definition_default, label_default, label_fr, "source", statut)
            VALUES (:mnemonique, :definition_default, :label, :label, 'GEONATURE', 'Validé')
            """).bindparams(
            mnemonique=NOMENCLATURE_TYPE_MNEMONIQUE,
            definition_default=definition,
            label="Type de publication",
        )
    )

    insert_stmt = sa.text("""
        INSERT INTO ref_nomenclatures.t_nomenclatures (
            id_type,
            cd_nomenclature,
            mnemonique,
            label_default,
            label_fr,
            source,
            statut,
            hierarchy,
            active
        ) VALUES (
            ref_nomenclatures.get_id_nomenclature_type(:type_mnemonique),
            :cd_nomenclature,
            :mnemonique,
            :label,
            :label,
            'GEONATURE',
            'Validé',
            ref_nomenclatures.get_id_nomenclature_type(:type_mnemonique) || '.' || :cd_nomenclature,
            true
        )
        """)
    for index, (mnemonique, label) in enumerate(NOMENCLATURE_VALUES, start=1):
        op.execute(
            insert_stmt.bindparams(
                type_mnemonique=NOMENCLATURE_TYPE_MNEMONIQUE,
                cd_nomenclature=str(index),
                mnemonique=mnemonique,
                label=label,
            )
        )


def delete_datatype_nomenclature():
    op.execute(sa.text("""
            DELETE FROM ref_nomenclatures.t_nomenclatures
            WHERE id_type = ref_nomenclatures.get_id_nomenclature_type(:type_mnemonique)
            """).bindparams(type_mnemonique=NOMENCLATURE_TYPE_MNEMONIQUE))
    op.execute(
        sa.text(
            "DELETE FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = :mnemonique"
        ).bindparams(mnemonique=NOMENCLATURE_TYPE_MNEMONIQUE)
    )


def upgrade_datatype_publication_table():
    op.rename_table("sinp_datatype_publications", "datatype_publications", schema="gn_meta")
    op.execute(
        "ALTER SEQUENCE gn_meta.sinp_datatype_publications_id_publication_seq "
        "RENAME TO datatype_publications_id_publication_seq"
    )
    op.add_column(
        "datatype_publications",
        sa.Column("description_publication", sa.Text(), nullable=True),
        schema="gn_meta",
    )

    op.add_column(
        "datatype_publications",
        sa.Column("id_nomenclature_type_publication", sa.Integer(), nullable=True),
        schema="gn_meta",
    )
    op.create_foreign_key(
        "fk_datatype_publications_id_nomenclature_type_publication",
        source_table="datatype_publications",
        referent_table="t_nomenclatures",
        local_cols=["id_nomenclature_type_publication"],
        remote_cols=["id_nomenclature"],
        source_schema="gn_meta",
        referent_schema="ref_nomenclatures",
        onupdate="RESTRICT",
    )
    op.create_check_constraint(
        "check_datatype_publications_type_publication",
        table_name="datatype_publications",
        condition=(
            "ref_nomenclatures.check_nomenclature_type_by_mnemonique("
            f"id_nomenclature_type_publication, '{NOMENCLATURE_TYPE_MNEMONIQUE}')"
        ),
        schema="gn_meta",
        postgresql_not_valid=True,
    )
    # For migration purpose only we let the column be nullable (if publication already exists we must keep it)
    op.add_column(
        "datatype_publications",
        sa.Column("id_digitizer", sa.Integer(), nullable=True),
        schema="gn_meta",
    )
    op.create_foreign_key(
        "fk_datatype_publications_id_digitizer",
        source_table="datatype_publications",
        referent_table="t_roles",
        local_cols=["id_digitizer"],
        remote_cols=["id_role"],
        source_schema="gn_meta",
        referent_schema="utilisateurs",
        onupdate="RESTRICT",
    )
    op.create_unique_constraint(
        "uq_datatype_publications_reference",
        "datatype_publications",
        ["publication_reference"],
        schema="gn_meta",
    )


def downgrade_datatype_publication_table():
    op.drop_constraint(
        "uq_datatype_publications_reference",
        "datatype_publications",
        schema="gn_meta",
        type_="unique",
    )
    op.drop_constraint(
        "check_datatype_publications_type_publication",
        "datatype_publications",
        schema="gn_meta",
        type_="check",
    )
    op.drop_constraint(
        "fk_datatype_publications_id_digitizer",
        "datatype_publications",
        schema="gn_meta",
        type_="foreignkey",
    )
    op.drop_constraint(
        "fk_datatype_publications_id_nomenclature_type_publication",
        "datatype_publications",
        schema="gn_meta",
        type_="foreignkey",
    )
    op.drop_column("datatype_publications", "id_digitizer", schema="gn_meta")
    op.drop_column("datatype_publications", "id_nomenclature_type_publication", schema="gn_meta")
    op.drop_column("datatype_publications", "description_publication", schema="gn_meta")
    op.execute(
        "ALTER SEQUENCE gn_meta.datatype_publications_id_publication_seq "
        "RENAME TO sinp_datatype_publications_id_publication_seq"
    )
    op.rename_table("datatype_publications", "sinp_datatype_publications", schema="gn_meta")


def create_cor_dataset_publication():
    op.create_table(
        "cor_dataset_publication",
        sa.Column("id_dataset", sa.Integer(), nullable=False),
        sa.Column("id_publication", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(
            ("id_dataset",),
            ["gn_meta.t_datasets.id_dataset"],
            ondelete="CASCADE",
            onupdate="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ("id_publication",),
            ["gn_meta.datatype_publications.id_publication"],
            ondelete="RESTRICT",  # So we can't delete a publication if it's used by a dataset
            onupdate="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id_dataset", "id_publication"),
        schema="gn_meta",
    )
    op.create_index(
        op.f("ix_gn_meta_cor_dataset_publication_id_dataset"),
        "cor_dataset_publication",
        ["id_dataset"],
        schema="gn_meta",
    )
    op.create_index(
        op.f("ix_gn_meta_cor_dataset_publication_id_publication"),
        "cor_dataset_publication",
        ["id_publication"],
        schema="gn_meta",
    )


def delete_cor_dataset_publication():
    op.drop_table("cor_dataset_publication", schema="gn_meta")


def create_cor_acquisition_framework_publication():
    op.create_table(
        "cor_acquisition_framework_publication",
        sa.Column("id_acquisition_framework", sa.Integer(), nullable=False),
        sa.Column("id_publication", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(
            ("id_acquisition_framework",),
            ["gn_meta.t_acquisition_frameworks.id_acquisition_framework"],
            ondelete="CASCADE",
            onupdate="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ("id_publication",),
            ["gn_meta.datatype_publications.id_publication"],
            ondelete="RESTRICT",  # So we can't delete a publication if it's used by an af
            onupdate="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id_acquisition_framework", "id_publication"),
        schema="gn_meta",
    )
    op.create_index(
        op.f("ix_gn_meta_cor_acquisition_framework_publication_id_af"),
        "cor_acquisition_framework_publication",
        ["id_acquisition_framework"],
        schema="gn_meta",
    )
    op.create_index(
        op.f("ix_gn_meta_cor_acquisition_framework_publication_id_publication"),
        "cor_acquisition_framework_publication",
        ["id_publication"],
        schema="gn_meta",
    )


def delete_cor_acquisition_framework_publication():
    op.drop_table("cor_acquisition_framework_publication", schema="gn_meta", if_exists=True)


def upgrade():
    # Unused table cor_acquisition_framework_publication sometimes already exists
    delete_cor_acquisition_framework_publication()
    create_datatype_nomenclature()
    upgrade_datatype_publication_table()
    create_cor_dataset_publication()
    create_cor_acquisition_framework_publication()


def downgrade():
    delete_cor_dataset_publication()
    delete_cor_acquisition_framework_publication()
    downgrade_datatype_publication_table()
    delete_datatype_nomenclature()
