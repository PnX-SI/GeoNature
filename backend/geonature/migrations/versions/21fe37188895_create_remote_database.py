"""Create remote_database table

Revision ID: 21fe37188895
Revises: 21fe37188895
Create Date: 2026-07-15 11:10:00

"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "21fe37188895"
down_revision = "ae0b6362fb22"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "remote_database",
        sa.Column("id_remote_database", sa.Integer(), nullable=False),
        sa.Column("name", sa.Unicode(), nullable=False),
        sa.Column("id_contact", sa.Integer(), nullable=True),
        sa.Column("meta_create_date", sa.DateTime(), server_default=sa.func.now(), nullable=True),
        sa.Column("meta_update_date", sa.DateTime(), server_default=sa.func.now(), nullable=True),
        sa.ForeignKeyConstraint(
            ["id_contact"],
            ["utilisateurs.t_roles.id_role"],
        ),
        sa.PrimaryKeyConstraint("id_remote_database"),
        sa.UniqueConstraint("name", name="uk_remote_database_name"),
        schema="gn_meta",
    )
    op.create_index(
        op.f("ix_gn_meta_remote_database_name"),
        "remote_database",
        ["name"],
        unique=True,
        schema="gn_meta",
    )

    op.add_column(
        "t_datasets", sa.Column("id_remote_database", sa.Integer(), nullable=True), schema="gn_meta"
    )
    op.create_foreign_key(
        "fk_t_datasets_id_remote_database",
        "t_datasets",
        "remote_database",
        ["id_remote_database"],
        ["id_remote_database"],
        source_schema="gn_meta",
        referent_schema="gn_meta",
    )


def downgrade():
    op.drop_constraint(
        "fk_t_datasets_id_remote_database", "t_datasets", schema="gn_meta", type_="foreignkey"
    )
    op.drop_column("t_datasets", "id_remote_database", schema="gn_meta")

    op.drop_index(
        op.f("ix_gn_meta_remote_database_name"), table_name="remote_database", schema="gn_meta"
    )
    op.drop_table("remote_database", schema="gn_meta")
