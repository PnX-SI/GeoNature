"""add sample data for frontend tests

Revision ID: d17db834aca5
Revises: 1f223c509a80
Create Date: 2025-10-13 12:18:26.053230

"""

from alembic import op
import sqlalchemy as sa

from geonature.utils.module import get_dist_from_code, PackageNotFoundError
from utils_flask_sqla.migrations.utils import logger


def is_module_installed(module_code):
    try:
        get_dist_from_code(module_code)
        return True
    except PackageNotFoundError:
        return False


# revision identifiers, used by Alembic.
revision = "d17db834aca5"
down_revision = None
branch_labels = ("cypress-samples-test",)

_depends_on = [
    "1f223c509a80",  # geonature@1f223c509a80 - "add additional_fields support for acquisition frameworks"
]

# To prevent bug with verification of `depends_on` migrations associated with modules that are not installed
#   - See: https://github.com/PnX-SI/GeoNature/issues/3885
if is_module_installed("OCCHAB"):
    _depends_on.append("21f661247023")  # occhab-samples@2984569d5df6 - "insert occhab sample data"
if is_module_installed("OCCTAX"):
    _depends_on.append("2a0ab7644e1c")  # occtax-samples-test@2a0ab7644e1c - "occtax sample test"
if is_module_installed("OCCHAB") and is_module_installed("OCCTAX"):
    _depends_on.append("a81f74d0a518")  # import-samples@a81f74d0a518 - "insert_import_sample_data"

depends_on = tuple(_depends_on)


def upgrade():
    # Warn the user if any of 'OCCHAB' module or 'OCCTAX' module is not installed
    if not is_module_installed("OCCHAB"):
        logger.warning(
            "⚠️ OCCHAB module is not installed, thus the upgrade of `d17db834aca5, add sample data for frontend tests` will be performed without upgrading the `occhab-samples` branch."
        )
    if not is_module_installed("OCCTAX"):
        logger.warning(
            "⚠️ OCCTAX module is not installed, thus the upgrade of `d17db834aca5, add sample data for frontend tests` will be performed without upgrading the `occtax-samples-test` branch."
        )
    if not is_module_installed("OCCHAB") and not is_module_installed("OCCTAX"):
        logger.warning(
            "⚠️ OCCTAX and OCCHAB modules are not installed, thus the upgrade of `a81f74d0a518, add sample data for frontend tests` will be performed without upgrading the `import-samples-test` branch."
        )
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
