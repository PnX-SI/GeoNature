"""occtax sample test

Revision ID: 2a0ab7644e1c
Revises: 944072911ff7
Create Date: 2022-01-18 16:55:20.493967

"""
import importlib

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '2a0ab7644e1c'
down_revision = None
branch_labels = ('occtax-samples-test',)
depends_on = (
    '3d0bf4ee67d1',  # geonature samples data
    'addb71d8efad',  # occtax
)


def upgrade():
    operations = importlib.resources.read_text('occtax.migrations.data', 'sample_data_test.sql')
    op.execute(operations)
    

def downgrade():
    op.execute("""
    DELETE FROM gn_synthese.synthese s
    USING gn_meta.t_datasets ds, gn_meta.t_acquisition_frameworks taf
    WHERE s.id_dataset = ds.id_dataset
    AND ds.id_acquisition_framework = taf.id_acquisition_framework
    AND taf.unique_acquisition_framework_id='57b7d0f2-4183-4b7b-8f08-6e105d476dc5'
    """)
    op.execute("""
    DELETE FROM pr_occtax.t_releves_occtax tro
    USING gn_meta.t_datasets ds, gn_meta.t_acquisition_frameworks taf
    WHERE tro.id_dataset = ds.id_dataset
    AND ds.id_acquisition_framework = taf.id_acquisition_framework
    AND taf.unique_acquisition_framework_id='57b7d0f2-4183-4b7b-8f08-6e105d476dc5'    
    """)
    op.execute("""
    DELETE FROM gn_commons.cor_module_dataset cmd
    USING gn_meta.t_datasets ds, gn_meta.t_acquisition_frameworks taf
    WHERE cmd.id_dataset = ds.id_dataset
    AND ds.id_acquisition_framework = taf.id_acquisition_framework
    AND taf.unique_acquisition_framework_id='57b7d0f2-4183-4b7b-8f08-6e105d476dc5'
    """)
    op.execute("""
    DELETE FROM gn_meta.cor_dataset_protocol cdp
    USING gn_meta.t_datasets ds, gn_meta.t_acquisition_frameworks taf
    WHERE cdp.id_dataset = ds.id_dataset
    AND ds.id_acquisition_framework = taf.id_acquisition_framework
    AND taf.unique_acquisition_framework_id='57b7d0f2-4183-4b7b-8f08-6e105d476dc5'
    """)
    op.execute("""
    DELETE FROM gn_meta.cor_dataset_territory cdt
    USING gn_meta.t_datasets ds, gn_meta.t_acquisition_frameworks taf
    WHERE cdt.id_dataset = ds.id_dataset
    AND ds.id_acquisition_framework = taf.id_acquisition_framework
    AND taf.unique_acquisition_framework_id='57b7d0f2-4183-4b7b-8f08-6e105d476dc5'
    """)
    op.execute("""
    DELETE FROM gn_meta.cor_dataset_actor cda
    USING gn_meta.t_datasets ds, gn_meta.t_acquisition_frameworks taf
    WHERE cda.id_dataset = ds.id_dataset
    AND ds.id_acquisition_framework = taf.id_acquisition_framework
    AND taf.unique_acquisition_framework_id='57b7d0f2-4183-4b7b-8f08-6e105d476dc5'
    """)
    op.execute("""
    DELETE FROM gn_meta.cor_acquisition_framework_actor cafa
    USING gn_meta.t_acquisition_frameworks taf
    WHERE cafa.id_acquisition_framework = taf.id_acquisition_framework
    AND taf.unique_acquisition_framework_id='57b7d0f2-4183-4b7b-8f08-6e105d476dc5'
    """)
    op.execute("""
    DELETE FROM gn_meta.cor_acquisition_framework_objectif cafo
    USING gn_meta.t_acquisition_frameworks taf
    WHERE cafo.id_acquisition_framework = taf.id_acquisition_framework
    AND taf.unique_acquisition_framework_id='57b7d0f2-4183-4b7b-8f08-6e105d476dc5'
    """)
    op.execute("""
    DELETE FROM gn_meta.cor_acquisition_framework_voletsinp cafv
    USING gn_meta.t_acquisition_frameworks taf
    WHERE cafv.id_acquisition_framework = taf.id_acquisition_framework
    AND taf.unique_acquisition_framework_id='57b7d0f2-4183-4b7b-8f08-6e105d476dc5'
    """)
    op.execute("""
    DELETE FROM gn_meta.t_datasets d
    USING gn_meta.t_acquisition_frameworks af
    WHERE d.id_acquisition_framework = af.id_acquisition_framework
    AND af.unique_acquisition_framework_id = '57b7d0f2-4183-4b7b-8f08-6e105d476dc5'
    """)
    op.execute("""
    DELETE FROM gn_meta.t_acquisition_frameworks af
    WHERE af.unique_acquisition_framework_id = '57b7d0f2-4183-4b7b-8f08-6e105d476dc5'
    """)

    op.execute(
        """
         DELETE FROM gn_synthese.synthese 
        WHERE id_source = (SELECT id_source FROM gn_synthese.t_sources WHERE id_module = (
            SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'OCCTAX_DS'
        )
        )
        """
    )
    op.execute(
        """
         DELETE FROM gn_commons.cor_module_dataset
         WHERE id_module = (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'OCCTAX_DS') 
        """
    )
    op.execute(
        """
        DELETE FROM gn_commons.t_modules WHERE module_code = 'OCCTAX_DS'
        """
    )
