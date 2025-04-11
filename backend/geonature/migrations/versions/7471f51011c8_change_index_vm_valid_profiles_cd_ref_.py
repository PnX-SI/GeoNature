"""change index_vm_valid_profiles_cd_ref to unique index

Revision ID: 7471f51011c8
Revises: 1eb624249f2b
Create Date: 2021-11-08 10:59:23.047142

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "7471f51011c8"
down_revision = "1eb624249f2b"
branch_labels = None
depends_on = None


def upgrade():
    op.execute("DROP INDEX gn_profiles.index_vm_valid_profiles_cd_ref")
    op.execute(
        "CREATE UNIQUE INDEX index_vm_valid_profiles_cd_ref ON gn_profiles.vm_valid_profiles USING btree (cd_ref)"
    )


def downgrade():
    op.execute("DROP INDEX gn_profiles.index_vm_valid_profiles_cd_ref")
    op.execute(
        "CREATE INDEX index_vm_valid_profiles_cd_ref ON gn_profiles.vm_valid_profiles USING btree (cd_ref)"
    )
