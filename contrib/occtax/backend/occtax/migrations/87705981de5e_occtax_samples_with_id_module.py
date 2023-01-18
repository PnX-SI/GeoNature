"""insert occtax sample data

Revision ID: 87705981de5e
Revises: cce08a64eb4f
Create Date: 2023-01-18 10:29:41.071499

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "87705981de5e"
down_revision = "cce08a64eb4f"
branch_labels = None
depends_on = ("023b0be41829",)  # add id_module in t_releves_occtax


def upgrade():
    """
    Test if samples data have already been inserted in previous revision.
    """
    if (
        not op.get_bind()
        .execute(
            """
                SELECT EXISTS(
                    SELECT 1
                    FROM gn_meta.t_acquisition_frameworks af
                    WHERE af.unique_acquisition_framework_id = '57b7d0f2-4183-4b7b-8f08-6e105d476dc5'
                )
                """
        )
        .scalar()
    ):
        operations = importlib.resources.read_text("occtax.migrations.data", "sample_data.sql")
        op.execute(operations)


def downgrade():
    pass
