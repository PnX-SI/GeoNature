"""TAdditionalFields : remove useless columns and values

Revision ID: 497f52d996dd
Revises: 4cf3fd5d06f5
Create Date: 2023-01-04 16:02:45.953579

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "497f52d996dd"
down_revision = "4cf3fd5d06f5"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        ALTER TABLE gn_commons.t_additional_fields
        DROP COLUMN key_label;
        ALTER TABLE gn_commons.t_additional_fields
        DROP COLUMN key_value;
        """
    )
    op.execute("DELETE FROM gn_commons.bib_widgets WHERE widget_name = 'bool_radio'")


def downgrade():
    op.execute(
        """
        ALTER TABLE gn_commons.t_additional_fields
        ADD COLUMN key_label varchar(255);
        ALTER TABLE gn_commons.t_additional_fields
        ADD COLUMN key_value varchar(255);
        """
    )
    op.execute("INSERT INTO gn_commons.bib_widgets(widget_name) VALUES ('bool_radio')")
