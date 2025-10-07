"""[import.monitorings] Adjust gn.imports bib_fields id_dataset and unique_id_dataset values for synthese destination

Revision ID: 51ee1572f71f
Revises: df277299fdda
Create Date: 2025-01-24 16:38:46.007151

"""

from alembic import op
import sqlalchemy as sa

from geonature.core.imports.models import BibFields, Destination
from sqlalchemy.dialects.postgresql import UUID

# revision identifiers, used by Alembic.
revision = "51ee1572f71f"
down_revision = "df277299fdda"
branch_labels = None
depends_on = None


def upgrade():
    op.drop_column(
        schema="gn_imports", table_name="t_imports_synthese", column_name="unique_dataset_id"
    )

    op.execute(
        sa.update(BibFields)
        .where(
            BibFields.name_field == "unique_dataset_id",
            BibFields.id_destination == Destination.id_destination,
            Destination.code == "synthese",
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
            Destination.code == "synthese",
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

    op.execute(
        """
        DO $$
        BEGIN
            -- Vérifier si la colonne existe dans la table
            IF EXISTS (SELECT 1
                    FROM information_schema.columns
                    WHERE
                    table_name = 't_imports'
                    AND column_name = 'id_dataset') THEN
                -- Supprimer la colonne si elle existe
                ALTER TABLE gn_imports.t_imports DROP COLUMN id_dataset;
            END IF;
        END $$;
        """
    )


def downgrade():
    op.execute(
        sa.update(BibFields)
        .where(
            BibFields.name_field == "unique_dataset_id",
            BibFields.id_destination == Destination.id_destination,
            Destination.code == "synthese",
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
            Destination.code == "synthese",
        )
        .values(dict(dest_field=None))
    )

    op.add_column(
        schema="gn_imports",
        table_name="t_imports",
        column=sa.Column("id_dataset", sa.INTEGER),
    )

    op.add_column(
        schema="gn_imports",
        table_name="t_imports_synthese",
        column=sa.Column("unique_dataset_id", UUID(as_uuid=True)),
    )
