"""Adjust occhab to datasate management modification in import

Revision ID: 65f77e9d4c6f
Revises: e43f039b5ff1
Create Date: 2025-01-28 11:28:51.311696

"""

from alembic import op
import sqlalchemy as sa

from geonature.core.imports.models import BibFields, Destination
from sqlalchemy.dialects.postgresql import UUID

# revision identifiers, used by Alembic.
revision = "65f77e9d4c6f"
down_revision = "e43f039b5ff1"
branch_labels = None
depends_on = None


def upgrade():
    op.drop_column(
        schema="gn_imports", table_name="t_imports_occhab", column_name="unique_dataset_id"
    )

    op.execute(
        sa.update(BibFields)
        .where(
            BibFields.name_field == "unique_dataset_id",
            BibFields.id_destination == Destination.id_destination,
            Destination.code == "occhab",
        )
        .values(
            dict(
                display=True,
                mandatory=True,
                type_field="dataset",
                type_field_params=dict(bind_value="unique_dataset_id"),
                source_field="src_unique_dataset_id",
                dest_field=None,
            )
        )
    )

    op.execute(
        sa.update(BibFields)
        .where(
            BibFields.name_field == "id_dataset",
            BibFields.id_destination == Destination.id_destination,
            Destination.code == "occhab",
        )
        .values(
            dict(
                display=False,
                type_field="textarea",
                mandatory=False,
                dest_field="id_dataset",
                source_field=None,
            )
        )
    )


def downgrade():
    op.execute(
        sa.update(BibFields)
        .where(
            BibFields.name_field == "unique_dataset_id",
            BibFields.id_destination == Destination.id_destination,
            Destination.code == "occhab",
        )
        .values(
            dict(
                display=False,
                mandatory=False,
                optional_conditions=None,
                type_field="text",
                type_field_params=None,
                dest_field="unique_dataset_id",
            )
        )
    )

    op.execute(
        sa.update(BibFields)
        .where(
            BibFields.name_field == "id_dataset",
            BibFields.id_destination == Destination.id_destination,
            Destination.code == "occhab",
        )
        .values(dict(dest_field=None))
    )

    op.add_column(
        schema="gn_imports",
        table_name="t_imports_occhab",
        column=sa.Column("unique_dataset_id", UUID(as_uuid=True)),
    )
