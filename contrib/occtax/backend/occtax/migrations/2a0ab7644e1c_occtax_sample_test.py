"""occtax sample test

Revision ID: 2a0ab7644e1c
Revises: 944072911ff7
Create Date: 2022-01-18 16:55:20.493967

"""
import importlib

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "2a0ab7644e1c"
down_revision = None
branch_labels = ("occtax-samples-test",)
depends_on = (
    "3d0bf4ee67d1",  # geonature samples data
    "addb71d8efad",  # occtax
)


def upgrade():
    operations = importlib.resources.read_text("occtax.migrations.data", "sample_data_test.sql")
    op.execute(operations)


def downgrade():
    op.execute(
        """
    DELETE FROM pr_occtax.cor_counting_occtax cco
    USING pr_occtax.t_occurrences_occtax too
    WHERE cco.id_occurrence_occtax = too.id_occurrence_occtax
    AND too.unique_id_occurence_occtax IN (
        'f303683c-2510-11ec-b93a-67b44043fe7d',
        'fb106f34-2510-11ec-a3ff-6fb52354595c',
        'fcdf2c24-2510-11ec-9995-fb27008e2817',
        '8db83b16-3d88-4af3-85ca-44464daf32c0'
    )
    """
    )
    op.execute(
        """
    DELETE FROM pr_occtax.cor_role_releves_occtax crro
    USING pr_occtax.t_releves_occtax tro
    WHERE crro.id_releve_occtax = tro.id_releve_occtax
    AND tro.unique_id_sinp_grp IN (
        '4f784326-2511-11ec-9fdd-23b0fb947058', 
        '4fa06f7c-2511-11ec-93a1-eb4838107091',
        '297106a0-4dad-4d44-ae59-2e44a419e11f'
        )
    """
    )
    op.execute(
        """
    DELETE FROM pr_occtax.t_occurrences_occtax too
    USING pr_occtax.t_releves_occtax tro
    WHERE too.id_releve_occtax = tro.id_releve_occtax
    AND tro.unique_id_sinp_grp IN (
        '4f784326-2511-11ec-9fdd-23b0fb947058', 
        '4fa06f7c-2511-11ec-93a1-eb4838107091',
        '297106a0-4dad-4d44-ae59-2e44a419e11f'
    )
    """
    )
    op.execute(
        """
    DELETE FROM pr_occtax.t_releves_occtax tro
    WHERE tro.unique_id_sinp_grp IN (
        '4f784326-2511-11ec-9fdd-23b0fb947058', 
        '4fa06f7c-2511-11ec-93a1-eb4838107091',
        '297106a0-4dad-4d44-ae59-2e44a419e11f'
        )
    """
    )
    op.execute(
        """
    DELETE FROM gn_commons.cor_module_dataset cmd
    USING gn_meta.t_datasets ds, gn_meta.t_acquisition_frameworks taf
    WHERE cmd.id_dataset = ds.id_dataset
    AND ds.id_acquisition_framework = taf.id_acquisition_framework
    AND taf.unique_acquisition_framework_id='57b7d0f2-4183-4b7b-8f08-6e105d476dc5'
    """
    )
    op.execute(
        """
    DELETE FROM gn_meta.cor_dataset_protocol cdp
    USING gn_meta.t_datasets ds, gn_meta.t_acquisition_frameworks taf
    WHERE cdp.id_dataset = ds.id_dataset
    AND ds.id_acquisition_framework = taf.id_acquisition_framework
    AND taf.unique_acquisition_framework_id='57b7d0f2-4183-4b7b-8f08-6e105d476dc5'
    """
    )
    op.execute(
        """
    DELETE FROM gn_meta.cor_dataset_territory cdt
    USING gn_meta.t_datasets ds, gn_meta.t_acquisition_frameworks taf
    WHERE cdt.id_dataset = ds.id_dataset
    AND ds.id_acquisition_framework = taf.id_acquisition_framework
    AND taf.unique_acquisition_framework_id='57b7d0f2-4183-4b7b-8f08-6e105d476dc5'
    """
    )
    op.execute(
        """
    DELETE FROM gn_meta.cor_dataset_actor cda
    USING gn_meta.t_datasets ds, gn_meta.t_acquisition_frameworks taf
    WHERE cda.id_dataset = ds.id_dataset
    AND ds.id_acquisition_framework = taf.id_acquisition_framework
    AND taf.unique_acquisition_framework_id='57b7d0f2-4183-4b7b-8f08-6e105d476dc5'
    """
    )
    op.execute(
        """
    DELETE FROM gn_meta.cor_acquisition_framework_actor cafa
    USING gn_meta.t_acquisition_frameworks taf
    WHERE cafa.id_acquisition_framework = taf.id_acquisition_framework
    AND taf.unique_acquisition_framework_id='57b7d0f2-4183-4b7b-8f08-6e105d476dc5'
    """
    )
    op.execute(
        """
    DELETE FROM gn_meta.cor_acquisition_framework_objectif cafo
    USING gn_meta.t_acquisition_frameworks taf
    WHERE cafo.id_acquisition_framework = taf.id_acquisition_framework
    AND taf.unique_acquisition_framework_id='57b7d0f2-4183-4b7b-8f08-6e105d476dc5'
    """
    )
    op.execute(
        """
    DELETE FROM gn_meta.cor_acquisition_framework_voletsinp cafv
    USING gn_meta.t_acquisition_frameworks taf
    WHERE cafv.id_acquisition_framework = taf.id_acquisition_framework
    AND taf.unique_acquisition_framework_id='57b7d0f2-4183-4b7b-8f08-6e105d476dc5'
    """
    )
    op.execute(
        """
    DELETE FROM gn_meta.t_datasets d
    USING gn_meta.t_acquisition_frameworks af
    WHERE d.id_acquisition_framework = af.id_acquisition_framework
    AND af.unique_acquisition_framework_id = '57b7d0f2-4183-4b7b-8f08-6e105d476dc5'
    """
    )
    op.execute(
        """
    DELETE FROM gn_meta.t_acquisition_frameworks af
    WHERE af.unique_acquisition_framework_id in (
        '57b7d0f2-4183-4b7b-8f08-6e105d476dc5',
        '48b7d0f2-4183-4b7b-8f08-6e105d476dd8'
        )
    """
    )
    op.execute(
        """
        DELETE FROM gn_commons.t_modules
        WHERE module_code = 'OCCTAX_DS'
        """
    )
