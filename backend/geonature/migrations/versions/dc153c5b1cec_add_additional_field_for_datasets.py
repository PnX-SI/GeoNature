"""add additional field for datasets

Revision ID: dc153c5b1cec
Revises: d17db834aca5
Create Date: 2026-07-06 12:26:11.536057

"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "dc153c5b1cec"
down_revision = "d17db834aca5"
branch_labels = None
depends_on = "1ebab31227b8"  # geonature@1ebab31227b8 - "add additional fields support for datasets"


def upgrade():
    # Add the association between the additional field "test_champs_additionnel" and the object 'METADATA_JEU_DE_DONNEES'
    op.execute("""
        INSERT INTO 
            gn_commons.cor_field_object
                (
                id_field,
                id_object
                )
        VALUES
                (
                    (
                        SELECT
                            id_field
                        FROM
                            gn_commons.t_additional_fields
                        WHERE
                            field_name = 'test_champs_additionnel'
                    ),
                    (
                        SELECT
                            id_object
                        FROM
                            gn_permissions.t_objects
                        WHERE
                            code_object = 'METADATA_JEU_DE_DONNEES'
                    )
                )
        ;
    """)


def downgrade():
    # Remove the associations with
    #   the additional field "test_champs_additionnel"
    #   and object "METADATA_JEU_DE_DONNEES"
    op.execute(f"""
        DELETE FROM 
            gn_commons.cor_field_object
        WHERE
            id_field = (
                SELECT
                    id_field
                FROM
                    gn_commons.t_additional_fields
                WHERE
                    field_name = 'test_champs_additionnel'
            )
            AND
            id_object = (
                SELECT
                    id_object
                FROM
                    gn_permissions.t_objects
                WHERE
                    code_object = 'METADATA_JEU_DE_DONNEES'
            )
        ;
    """)
