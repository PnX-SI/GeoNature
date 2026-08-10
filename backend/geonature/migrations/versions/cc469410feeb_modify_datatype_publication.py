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


def upgrade_datatype_publication_table():
    op.rename_table("sinp_datatype_publications", "datatype_publications", schema="gn_meta")
    op.execute(
        "ALTER SEQUENCE gn_meta.sinp_datatype_publications_id_publication_seq RENAME TO datatype_publications_id_publication_seq"
    )
    op.add_column(
        "datatype_publications",
        sa.Column("description_publication", sa.Text(), nullable=True),
        schema="gn_meta",
    )
    op.add_column(
        "datatype_publications",
        sa.Column("type_publication", sa.Text(), nullable=True),
        schema="gn_meta",
    )


def downgrade_datatype_publication_table():
    op.drop_column("datatype_publications", "type_publication", schema="gn_meta")
    op.drop_column("datatype_publications", "description_publication", schema="gn_meta")
    op.execute(
        "ALTER SEQUENCE gn_meta.datatype_publications_id_publication_seq RENAME TO sinp_datatype_publications_id_publication_seq"
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
            ondelete="CASCADE",
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
            ondelete="CASCADE",
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
    op.drop_table("cor_acquisition_framework_publication", schema="gn_meta")


def upgrade():
    upgrade_datatype_publication_table()
    create_cor_dataset_publication()
    create_cor_acquisition_framework_publication()


def downgrade():
    delete_cor_dataset_publication()
    delete_cor_acquisition_framework_publication()
    downgrade_datatype_publication_table()
