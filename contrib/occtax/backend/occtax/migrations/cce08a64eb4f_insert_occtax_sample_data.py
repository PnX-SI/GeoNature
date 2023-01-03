"""insert occtax sample data

Revision ID: cce08a64eb4f
Revises:
Create Date: 2021-10-04 11:31:50.957854

"""
import importlib

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "cce08a64eb4f"
down_revision = None
branch_labels = ("occtax-samples",)
depends_on = (
    "3d0bf4ee67d1",  # geonature samples data
    "addb71d8efad",  # occtax
    "023b0be41829",  # add id_module in t_releves_occtax
)


def upgrade():
    operations = importlib.resources.read_text("occtax.migrations.data", "sample_data.sql")
    op.execute(operations)


def downgrade():
    op.execute(
        """
    DELETE FROM pr_occtax.cor_counting_occtax cco
    USING pr_occtax.t_occurrences_occtax too
    WHERE cco.id_occurrence_occtax = too.id_occurrence_occtax
    AND too.unique_id_occurence_occtax = 'f303683c-2510-11ec-b93a-67b44043fe7d'
    """
    )
    op.execute(
        """
    DELETE FROM pr_occtax.cor_role_releves_occtax crro
    USING pr_occtax.t_releves_occtax tro
    WHERE crro.id_releve_occtax = tro.id_releve_occtax
    AND tro.unique_id_sinp_grp IN ('4f784326-2511-11ec-9fdd-23b0fb947058', '4fa06f7c-2511-11ec-93a1-eb4838107091')
    """
    )
    op.execute(
        """
    DELETE FROM pr_occtax.t_occurrences_occtax too
    USING pr_occtax.t_releves_occtax tro
    WHERE too.id_releve_occtax = tro.id_releve_occtax
    AND tro.unique_id_sinp_grp IN ('4f784326-2511-11ec-9fdd-23b0fb947058', '4fa06f7c-2511-11ec-93a1-eb4838107091')
    """
    )
    op.execute(
        """
    DELETE FROM pr_occtax.t_releves_occtax tro
    WHERE tro.unique_id_sinp_grp IN ('4f784326-2511-11ec-9fdd-23b0fb947058', '4fa06f7c-2511-11ec-93a1-eb4838107091')
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
    WHERE af.unique_acquisition_framework_id = '57b7d0f2-4183-4b7b-8f08-6e105d476dc5'
    """
    )
