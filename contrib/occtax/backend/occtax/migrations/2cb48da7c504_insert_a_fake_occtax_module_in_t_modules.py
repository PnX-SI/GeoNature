"""insert a fake occtax module in t_modules

Revision ID: 2cb48da7c504
Revises: 2a0ab7644e1c
Create Date: 2022-01-26 10:10:59.100350

"""
from alembic import op
import sqlalchemy as sa

from geonature.core.gn_meta.models import TDatasets
from geonature.core.utils import DB


# revision identifiers, used by Alembic.
revision = '2cb48da7c504'
down_revision = '2a0ab7644e1c'
branch_labels = None
depends_on = None


def upgrade():
    id_dataset = op.get_bind().execute(
        "select id_dataset from gn_meta.t_datasets where unique_dataset_id = 'dadab32d-5f9e-4dba-aa1f-c06487d536e8'"
        ).scalar()
    conn = op.get_bind()
    conn.execute(
        sa.text("""
            INSERT INTO gn_commons.t_modules (module_code,module_label,module_picto,module_desc,module_group,module_path,module_external_url,module_target,module_comment,active_frontend,active_backend,module_doc_url,module_order,"type",meta_create_date,meta_update_date) VALUES
            	 ('OCCTAX_DS_2','OCCTAX DS 2','fa-paw',NULL,NULL,'occtax?id_dataset=:id_dataset&module_label=Occtax DS 2',NULL,NULL,NULL,true,false,NULL,NULL,NULL,'2022-01-24 14:11:39.825541','2022-01-24 16:43:46.486594');
        """,
        ),
        {"id_dataset": id_dataset}
    )


def downgrade():
    op.execute(
        """
        DELETE FROM gn_commons.t_modules WHERE module_code = 'OCCTAX_DS_2'
        """
    )
