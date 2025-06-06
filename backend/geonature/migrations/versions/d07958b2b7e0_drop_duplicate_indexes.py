"""Drop duplicate indexes.

Revision ID: d07958b2b7e0
Revises: 707390c722fe
Create Date: 2025-06-06 10:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'd07958b2b7e0'
down_revision = '707390c722fe'
branch_labels = None
depends_on = None


def upgrade():
    """Drops some unique indexes
    redundants with unique constraints on the same columns.
    """

    # redundant with unique_acquisition_frameworks_uuid
    op.drop_index(
        "i_unique_t_acquisition_framework_unique_id",
        schema="gn_meta",
        table_name="t_acquisition_frameworks",
        if_exists=True
    )

    # redundant with unique_dataset_uuid
    op.drop_index(
        "i_unique_t_datasets_unique_id",
        schema="gn_meta",
        table_name="t_datasets",
        if_exists=True
    )

    # redundant with unique_name_source
    op.drop_index(
        "i_unique_t_sources_name_source",
        schema="gn_synthese",
        table_name="t_sources",
        if_exists=True
    )


def downgrade():
    """Creates back the redundant indexes.
    """

    op.create_index(
        "i_unique_t_acquisition_framework_unique_id",
        schema="gn_meta",
        table_name="t_acquisition_frameworks",
        columns=["unique_acquisition_framework_id"],
        unique=True
    )

    op.create_index(
        "i_unique_t_datasets_unique_id",
        schema="gn_meta",
        table_name="t_datasets",
        columns=["unique_dataset_id"],
        unique=True
    )

    op.create_index(
        "i_unique_t_sources_name_source",
        schema="gn_synthese",
        table_name="t_sources",
        columns=["name_source"],
        unique=True
    )