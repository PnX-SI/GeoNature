"""bib_field.type_field conforms to dynamic_form.type_widget

Revision ID: a94bea44ab56
Revises: e43b01a18850
Create Date: 2024-12-11 15:44:52.912515

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "a94bea44ab56"
down_revision = "e43b01a18850"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        ALTER TABLE gn_imports.bib_fields ADD type_field_params jsonb NULL;
    """
    )
    op.execute(
        """
        UPDATE gn_imports.bib_fields
        SET type_field = 
            case
                -- mnemonique is handled front side
                WHEN mnemonique IS NOT NULL AND mnemonique != '' THEN NULL

                -- multi is handled front side
                WHEN multi = true THEN null
                
                WHEN type_field IN ('integer', 'real') THEN 'number'
                
                WHEN type_field IN ('geometry', 'jsonb', 'json', 'wkt') THEN 'textarea'

                WHEN type_field LIKE 'timestamp%' THEN 'date'
                
                WHEN type_field ~ '^character varying\((\d+)\)$' 
                    AND COALESCE(substring(type_field FROM '\d+')::int, 0) > 68 THEN 'textarea'

                -- Default: garder la valeur actuelle.
                ELSE NULL
            END;
    """
    )


def downgrade():
    op.execute(
        """
        ALTER TABLE gn_imports.bib_fields DROP COLUMN type_field_params;

    """
    )
