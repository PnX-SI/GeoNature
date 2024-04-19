"""add required conditions in import

Revision ID: 8b149244d586
Revises: fe3d0b49ee14
Create Date: 2024-03-20 11:17:57.360785

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "8b149244d586"
down_revision = "fe3d0b49ee14"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        table_name="bib_fields",
        schema="gn_imports",
        column=sa.Column("mandatory_conditions", sa.ARRAY(sa.Unicode)),
    )
    op.add_column(
        table_name="bib_fields",
        schema="gn_imports",
        column=sa.Column("optional_conditions", sa.ARRAY(sa.Unicode)),
    )

    op.execute(
        """
        CREATE OR REPLACE FUNCTION gn_imports.isInNameFields (
            fields TEXT[]
        )
        RETURNS BOOLEAN
        AS $$
        DECLARE
            name_field_other TEXT;
        BEGIN
            IF fields IS DISTINCT FROM NULL THEN
                FOREACH name_field_other IN ARRAY fields LOOP
                    IF NOT EXISTS (
                        SELECT * 
                        FROM gn_imports.bib_fields 
                        WHERE name_field = name_field_other
                        ) then
                        return FALSE;
                    END IF;
                END LOOP;
            END IF;
            return TRUE;
        END;
        $$ LANGUAGE plpgsql;
        """
    )

    op.execute(
        """
        alter table gn_imports.bib_fields
        ADD CONSTRAINT mandatory_conditions_field_exists CHECK (gn_imports.isInNameFields(mandatory_conditions));
        """
    )
    op.execute(
        """
        alter table gn_imports.bib_fields
        ADD CONSTRAINT optional_conditions_field_exists CHECK (gn_imports.isInNameFields(optional_conditions));
        """
    )


def downgrade():
    op.drop_constraint("mandatory_conditions_field_exists", "bib_fields", schema="gn_imports")
    op.drop_constraint("optional_conditions_field_exists", "bib_fields", schema="gn_imports")
    op.execute("DROP FUNCTION IF EXISTS gn_imports.isInNameFields")
    op.drop_column(table_name="bib_fields", schema="gn_imports", column_name="mandatory_conditions")
    op.drop_column(table_name="bib_fields", schema="gn_imports", column_name="optional_conditions")
