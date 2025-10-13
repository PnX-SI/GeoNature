"""add sample data for frontend tests

Revision ID: d17db834aca5
Revises: 1f223c509a80
Create Date: 2025-10-13 12:18:26.053230

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "d17db834aca5"
down_revision = None
branch_labels = ("cypress-samples-test",)
depends_on = (
    "1f223c509a80",  # geonature@1f223c509a80 - "add additional_fields support for acquisition frameworks"
    "2a0ab7644e1c",  # occtax-samples-test@2a0ab7644e1c - "occtax sample test"
)


def upgrade():
    # Create a new additional field for test
    #   named "test_champs_additionnel"
    op.execute(
        """
        INSERT INTO 
            gn_commons.t_additional_fields 
                (
                field_name,
                field_label,
                id_widget
                )
        VALUES
                (
                'test_champs_additionnel',
                'Test Champs Additionnel',
                    (
                        SELECT
                            id_widget
                        FROM
                            gn_commons.bib_widgets
                        WHERE
                            widget_name = 'text'
                    )
                )
    """
    )

    # Add the association between the new additional field and the module 'METADATA'
    op.execute(
        """
        INSERT INTO 
            gn_commons.cor_field_module
                (
                id_field,
                id_module
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
                            id_module
                        FROM
                            gn_commons.t_modules
                        WHERE
                            module_code = 'METADATA'
                    )
                )
        ;
    """
    )

    # Add the association between the new additional field and the object 'METADATA_CADRE_ACQUISITION'
    op.execute(
        """
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
                            code_object = 'METADATA_CADRE_ACQUISITION'
                    )
                )
        ;
    """
    )


def downgrade():
    # Remove the associations with
    #   the additional field "test_champs_additionnel"
    #   and objects
    op.execute(
        f"""
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
        ;
    """
    )

    # Remove the associations with
    #   the additional field "test_champs_additionnel"
    #   and modules
    op.execute(
        f"""
        DELETE FROM 
            gn_commons.cor_field_module
        WHERE
            id_field = (
                SELECT
                    id_field
                FROM
                    gn_commons.t_additional_fields
                WHERE
                    field_name = 'test_champs_additionnel'
            )
        ;
    """
    )

    # Remove the additional field "test_champs_additionnel"
    op.execute(
        f"""
        DELETE FROM 
            gn_commons.t_additional_fields
        WHERE
            id_field = (
                SELECT
                    id_field
                FROM
                    gn_commons.t_additional_fields
                WHERE
                    field_name = 'test_champs_additionnel'
            )
        ;
    """
    )
