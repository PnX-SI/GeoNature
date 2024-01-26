"""insert occhab sample data

Revision ID: 21f661247023
Revises:
Create Date: 2021-10-04 10:15:40.419932

"""

import importlib

from alembic import op
import sqlalchemy as sa
from sqlalchemy.sql import text

from geonature.core.gn_commons.models import TParameters


# revision identifiers, used by Alembic.
revision = "21f661247023"
down_revision = None
branch_labels = ("occhab-samples",)
depends_on = ("2984569d5df6",)  # occhab


def upgrade():
    operations = importlib.resources.read_text(
        "gn_module_occhab.migrations.data", "sample_data.sql"
    )
    op.execute(operations)


def downgrade():
    op.execute(
        """
    DELETE FROM gn_commons.cor_module_dataset cmd
    USING gn_meta.t_datasets ds
    WHERE cmd.id_dataset = ds.id_dataset
    AND dataset_name='Carto d''habitat X'
    """
    )
    op.execute(
        """
    DELETE FROM gn_meta.cor_dataset_actor cda
    USING gn_meta.t_datasets ds
    WHERE cda.id_dataset = ds.id_dataset
    AND dataset_name='Carto d''habitat X'
    """
    )
    op.execute(
        """
    DELETE FROM gn_meta.t_datasets ds
    USING gn_meta.t_acquisition_frameworks af
    WHERE ds.id_acquisition_framework = af.id_acquisition_framework
    AND acquisition_framework_name = 'Données d''habitats'
    """
    )
    op.execute(
        """
    DELETE FROM gn_meta.t_acquisition_frameworks
    WHERE acquisition_framework_name = 'Données d''habitats'
    """
    )
    op.execute(
        """
    DELETE FROM ref_habitats.cor_list_habitat clh
    USING ref_habitats.bib_list_habitat lh
    WHERE clh.id_list = lh.id_list
    AND list_name = 'Liste test occhab'
    """
    )
    op.execute(
        """
    DELETE FROM ref_habitats.bib_list_habitat WHERE list_name = 'Liste test occhab'
    """
    )
