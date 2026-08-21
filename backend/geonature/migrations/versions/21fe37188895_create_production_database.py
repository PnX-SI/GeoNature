"""Create production_database table

Revision ID: 21fe37188895
Revises: 570a8b7a030c
Create Date: 2026-07-15 11:10:00

"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "21fe37188895"
down_revision = "570a8b7a030c"
branch_labels = None
depends_on = None

from flask import current_app

app_name = current_app.config["appName"]


def upgrade():
    op.create_table(
        "production_database",
        sa.Column("id_production_database", sa.Integer(), nullable=False, primary_key=True),
        sa.Column("uuid_production_database", sa.UUID, nullable=True, unique=True),
        sa.Column("name", sa.Unicode(), nullable=False),
        sa.Column("id_contact", sa.Integer(), nullable=True),
        sa.Column("meta_create_date", sa.DateTime(), server_default=sa.func.now(), nullable=True),
        sa.Column("meta_update_date", sa.DateTime(), server_default=sa.func.now(), nullable=True),
        sa.Column("is_default", sa.Boolean, server_default=sa.false(), nullable=False),
        sa.ForeignKeyConstraint(
            ["id_contact"],
            ["utilisateurs.t_roles.id_role"],
        ),
        schema="gn_meta",
    )
    op.create_index(
        op.f("idx_gn_meta_production_database_name"),
        "production_database",
        ["name"],
        unique=True,
        schema="gn_meta",
    )
    op.create_index(
        "idx_gn_meta_production_database_unique_is_default",
        "production_database",
        ["is_default"],
        unique=True,
        schema="gn_meta",
        postgresql_where=sa.text("is_default"),
    )

    op.execute("""
    CREATE OR REPLACE FUNCTION gn_meta.get_default_production_database()
    RETURNS integer AS $$
        SELECT id_production_database
        FROM gn_meta.production_database
        WHERE is_default IS TRUE
        LIMIT 1;
    $$ LANGUAGE sql STABLE;
    """)

    op.add_column(
        "t_datasets",
        sa.Column(
            "id_production_database",
            sa.Integer(),
            server_default=sa.text("gn_meta.get_default_production_database()"),
            nullable=True,
        ),
        schema="gn_meta",
    )
    op.create_foreign_key(
        "fk_t_datasets_id_production_database",
        "t_datasets",
        "production_database",
        ["id_production_database"],
        ["id_production_database"],
        source_schema="gn_meta",
        referent_schema="gn_meta",
    )

    op.execute(f"""
    INSERT INTO gn_meta.production_database(uuid_production_database,name,is_default) VALUES (uuid_generate_v4(), '{app_name}',FALSE);
    """)


def downgrade():
    op.drop_constraint(
        "fk_t_datasets_id_production_database", "t_datasets", schema="gn_meta", type_="foreignkey"
    )
    op.drop_column("t_datasets", "id_production_database", schema="gn_meta")

    op.execute("DROP FUNCTION IF EXISTS gn_meta.get_default_production_database();")

    op.drop_table("production_database", schema="gn_meta")
