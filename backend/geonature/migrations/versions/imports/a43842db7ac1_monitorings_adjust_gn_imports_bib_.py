"""[monitorings] Adjust gn.imports bib_fields id_dataset and unique_id_dataset values

Revision ID: a43842db7ac1
Revises: 2b0b3bd0248c
Create Date: 2024-12-17 11:18:07.806852

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "a43842db7ac1"
down_revision = "2b0b3bd0248c"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        UPDATE gn_imports.bib_fields
        SET display = TRUE,
            mandatory = TRUE,
            type_field = 'dataset',
            type_field_params = '{"bind_value": "unique_dataset_id"}',
            source_field = 'src_unique_dataset_id',
            dest_field = NULL
        WHERE name_field = 'unique_dataset_id'
        """
    )
    op.execute(
        """
        UPDATE gn_imports.bib_fields
        SET dest_field = 'id_dataset',
            source_field = NULL
        WHERE name_field = 'id_dataset'
        """
    )


def downgrade():
    op.execute(
        """
        UPDATE gn_imports.bib_fields
        SET display = FALSE,
            mandatory = FALSE,
            optional_conditions = NULL,
            type_field = 'text',
            type_field_params = NULL,
            dest_field = 'unique_dataset_id'
        WHERE name_field = 'unique_dataset_id'
        """
    )
    op.execute(
        """
        UPDATE gn_imports.bib_fields
        SET dest_field = NULL
        WHERE name_field = 'id_dataset'
        """
    )