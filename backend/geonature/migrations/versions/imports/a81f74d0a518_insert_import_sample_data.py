"""insert_import_sample_data

Revision ID: a81f74d0a518
Revises: 2b0b3bd0248c
Create Date: 2024-06-04 14:57:59.428947

"""

import importlib

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "a81f74d0a518"
down_revision = None
branch_labels = ("import-samples",)
depends_on = "2b0b3bd0248c"


def upgrade():
    operations = importlib.resources.read_text(
        "geonature.migrations.data.imports", "sample_data.sql"
    )
    op.execute(operations)


def downgrade():
    # Delete the data from the gn_imports.t_imports table
    op.execute(
        """
        DELETE FROM gn_imports.t_imports
        WHERE id_dataset IN (
            (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id = 'a1b2c3d4-e5f6-4a3b-2c1d-e6f5a4b3c2d1'),
            (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id = '9f86d081-8292-466e-9e7b-16f3960d255f'),
            (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id = '2f543d86-ec4e-4f1a-b4d9-123456789abc'),
            (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id = '5f45d560-1ce3-420c-b45c-3d589eedaee1')
        );
        """
    )

    # Delete the data from the gn_meta.cor_dataset_protocol table
    op.execute(
        """
        DELETE FROM gn_meta.cor_dataset_protocol
        WHERE id_dataset IN (
            (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id = '9f86d081-8292-466e-9e7b-16f3960d255f'),
            (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id = '2f543d86-ec4e-4f1a-b4d9-123456789abc')
        );
        """
    )

    # Delete the data from the gn_meta.cor_dataset_territory table
    op.execute(
        """
        DELETE FROM gn_meta.cor_dataset_territory
        WHERE id_dataset IN (
            (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id = '9f86d081-8292-466e-9e7b-16f3960d255f'),
            (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id = '2f543d86-ec4e-4f1a-b4d9-123456789abc')
        );
        """
    )

    # Delete the data from the gn_meta.cor_dataset_actor table
    op.execute(
        """
        DELETE FROM gn_meta.cor_dataset_actor
        WHERE id_dataset IN (
            (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id = '9f86d081-8292-466e-9e7b-16f3960d255f'),
            (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id = '2f543d86-ec4e-4f1a-b4d9-123456789abc'),
            (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id = 'a1b2c3d4-e5f6-4a3b-2c1d-e6f5a4b3c2d1'),
            (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id = '5f45d560-1ce3-420c-b45c-3d589eedaee1')
        );
        """
    )

    # Delete the data from the gn_meta.cor_acquisition_framework_actor table
    op.execute(
        """
        DELETE FROM gn_meta.cor_acquisition_framework_actor
        WHERE id_acquisition_framework = (SELECT id_acquisition_framework FROM gn_meta.t_acquisition_frameworks WHERE unique_acquisition_framework_id = '5b054340-210c-4350-9034-300543210c43');
        """
    )

    # Delete the data from the gn_meta.cor_acquisition_framework_objectif table
    op.execute(
        """
        DELETE FROM gn_meta.cor_acquisition_framework_objectif
        WHERE id_acquisition_framework = (SELECT id_acquisition_framework FROM gn_meta.t_acquisition_frameworks WHERE unique_acquisition_framework_id = '5b054340-210c-4350-9034-300543210c43');
        """
    )

    # Delete the data from the gn_meta.cor_acquisition_framework_voletsinp table
    op.execute(
        """
        DELETE FROM gn_meta.cor_acquisition_framework_voletsinp
        WHERE id_acquisition_framework = (SELECT id_acquisition_framework FROM gn_meta.t_acquisition_frameworks WHERE unique_acquisition_framework_id = '5b054340-210c-4350-9034-300543210c43');
        """
    )

    # Delete the data from the gn_commons.cor_module_dataset table
    op.execute(
        """
        DELETE FROM gn_commons.cor_module_dataset
        WHERE id_dataset IN (
            (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id = '9f86d081-8292-466e-9e7b-16f3960d255f'),
            (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id = '2f543d86-ec4e-4f1a-b4d9-123456789abc'),
            (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id = 'a1b2c3d4-e5f6-4a3b-2c1d-e6f5a4b3c2d1'),
            (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id = '5f45d560-1ce3-420c-b45c-3d589eedaee1')
        );
        """
    )

    # Delete the data from the gn_meta.t_datasets table
    op.execute(
        """
        DELETE FROM gn_meta.t_datasets
        WHERE unique_dataset_id IN ('9f86d081-8292-466e-9e7b-16f3960d255f', '2f543d86-ec4e-4f1a-b4d9-123456789abc', 'a1b2c3d4-e5f6-4a3b-2c1d-e6f5a4b3c2d1', '5f45d560-1ce3-420c-b45c-3d589eedaee1');
        """
    )

    # Delete the data from the gn_meta.t_acquisition_frameworks table
    op.execute(
        """
        DELETE FROM gn_meta.t_acquisition_frameworks
        WHERE unique_acquisition_framework_id IN ('5b054340-210c-4350-9034-300543210c43', '7a2b3c4d-5e6f-4a3b-2c1d-e6f5a4b3c2d1');
        """
    )

    # Step 1: Create a temporary table to hold the filtered imports
    op.execute(
        """
    CREATE TEMP TABLE temp_filtered_imports AS
    SELECT ti.id_import
    FROM gn_imports.t_imports ti
    JOIN gn_meta.t_datasets td ON ti.id_dataset = td.id_dataset
    WHERE td.dataset_name ILIKE '%JDD-TEST-IMPORT%';
    """
    )

    # Step 2: Delete the relevant records from cor_role_import
    op.execute(
        """
    DELETE FROM gn_imports.cor_role_import cri
    USING temp_filtered_imports tfi
    WHERE cri.id_import in (tfi.id_import);
    """
    )

    # Clean up temporary table
    op.execute("DROP TABLE temp_filtered_imports;")

    ## Clean users test
    # Delete permissions for admin-test-import
    op.execute(
        """
        DELETE FROM gn_permissions.t_permissions
        WHERE id_role = (SELECT id_role FROM utilisateurs.t_roles WHERE identifiant = 'admin-test-import');
    """
    )

    #  Delete permissions for agent-test-import
    op.execute(
        """
       DELETE FROM gn_permissions.t_permissions
    WHERE id_role = (SELECT id_role FROM utilisateurs.t_roles WHERE identifiant = 'agent-test-import');
    """
    )

    #  Delete notifications for admin-test-import
    op.execute(
        """
            DELETE FROM gn_notifications.t_notifications
            WHERE id_role = (SELECT id_role FROM utilisateurs.t_roles WHERE identifiant = 'admin-test-import');
        """
    )

    #  Delete notifications for agent-test-import
    op.execute(
        """
            DELETE FROM gn_notifications.t_notifications
            WHERE id_role = (SELECT id_role FROM utilisateurs.t_roles WHERE identifiant = 'agent-test-import');
        """
    )

    #  Delete the  roles
    op.execute(
        """
    DELETE FROM utilisateurs.t_roles WHERE identifiant IN ('admin-test-import', 'agent-test-import');
    """
    )
