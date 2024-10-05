"""permissions: add extended filters

Revision ID: 707390c722fe
Revises: 4e6ce32305f0
Create Date: 2024-09-30 17:13:44.650757

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "707390c722fe"
down_revision = "4e6ce32305f0"
branch_labels = None
depends_on = None


def upgrade():
    with op.batch_alter_table(schema="gn_permissions", table_name="t_permissions") as batch_op:
        batch_op.add_column(
            column=sa.Column("created_on", sa.DateTime),
        )
        batch_op.add_column(
            column=sa.Column("expire_on", sa.DateTime),
        )
        batch_op.add_column(
            column=sa.Column("validated", sa.Boolean, server_default=sa.true()),
        )
    # We set server_default after column creation to initialialize existing rows with NULL value
    op.alter_column(
        schema="gn_permissions",
        table_name="t_permissions",
        column_name="created_on",
        server_default=sa.func.now(),
    )
    op.create_table(
        "cor_permission_area",
        sa.Column(
            "id_permission",
            sa.Integer,
            sa.ForeignKey("gn_permissions.t_permissions.id_permission"),
            primary_key=True,
        ),
        sa.Column(
            "id_area", sa.Integer, sa.ForeignKey("ref_geo.l_areas.id_area"), primary_key=True
        ),
        schema="gn_permissions",
    )
    op.create_table(
        "cor_permission_taxref",
        sa.Column(
            "id_permission",
            sa.Integer,
            sa.ForeignKey("gn_permissions.t_permissions.id_permission"),
            primary_key=True,
        ),
        sa.Column("cd_nom", sa.Integer, sa.ForeignKey("taxonomie.taxref.cd_nom"), primary_key=True),
        schema="gn_permissions",
    )
    with op.batch_alter_table(
        schema="gn_permissions", table_name="t_permissions_available"
    ) as batch_op:
        batch_op.add_column(
            column=sa.Column("areas_filter", sa.Boolean, nullable=False, server_default=sa.false())
        )
        batch_op.add_column(
            column=sa.Column("taxons_filter", sa.Boolean, nullable=False, server_default=sa.false())
        )
    op.execute(
        """
        UPDATE
            gn_permissions.t_permissions_available pa
        SET
            areas_filter = True
        FROM
            gn_commons.t_modules m,
            gn_permissions.t_objects o,
            gn_permissions.bib_actions a
        WHERE
            pa.id_module = m.id_module
            AND
            pa.id_object = o.id_object
            AND
            pa.id_action = a.id_action
            AND
            m.module_code = 'SYNTHESE' AND o.code_object = 'ALL' and a.code_action IN ('R','E')
        """
    )


def downgrade():
    with op.batch_alter_table(
        schema="gn_permissions", table_name="t_permissions_available"
    ) as batch_op:
        batch_op.drop_column(column_name="taxons_filter")
        batch_op.drop_column(column_name="areas_filter")
    op.drop_table(schema="gn_permissions", table_name="cor_permission_taxref")
    op.drop_table(schema="gn_permissions", table_name="cor_permission_area")
    with op.batch_alter_table(schema="gn_permissions", table_name="t_permissions") as batch_op:
        batch_op.drop_column(column_name="validated")
        batch_op.drop_column(column_name="created_on")
        batch_op.drop_column(column_name="expire_on")
