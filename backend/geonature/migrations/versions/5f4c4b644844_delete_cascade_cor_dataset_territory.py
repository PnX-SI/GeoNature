"""delete cascade on  cor_dataset_territory and cor_dataset_protocol

Revision ID: 5f4c4b644844
Revises: 2a2e5c519fd1
Create Date: 2021-10-07 15:27:06.364487

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "5f4c4b644844"
down_revision = "2a2e5c519fd1"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
       ALTER TABLE gn_meta.cor_dataset_territory 
        DROP CONSTRAINT IF EXISTS fk_cor_dataset_territory_id_dataset;
       ALTER TABLE gn_meta.cor_dataset_territory
        ADD CONSTRAINT fk_cor_dataset_territory_id_dataset FOREIGN KEY (id_dataset) 
        REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE ON DELETE CASCADE;
    
        ALTER TABLE gn_meta.cor_dataset_protocol 
         DROP CONSTRAINT IF EXISTS fk_cor_dataset_protocol_id_dataset;
        ALTER TABLE gn_meta.cor_dataset_protocol 
        ADD CONSTRAINT fk_cor_dataset_protocol_id_dataset FOREIGN KEY (id_dataset) 
         REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE ON DELETE CASCADE;
    """
    )


def downgrade():
    op.execute(
        """
        ALTER TABLE gn_meta.cor_dataset_territory 
        DROP CONSTRAINT IF EXISTS fk_cor_dataset_territory_id_dataset;
        ALTER TABLE ONLY gn_meta.cor_dataset_territory
        ADD CONSTRAINT fk_cor_dataset_territory_id_dataset FOREIGN KEY (id_dataset) 
        REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE ON DELETE NO ACTION;

        ALTER TABLE gn_meta.cor_dataset_protocol 
        DROP CONSTRAINT IF EXISTS fk_cor_dataset_protocol_id_dataset;
        ALTER TABLE gn_meta.cor_dataset_protocol 
        ADD CONSTRAINT fk_cor_dataset_protocol_id_dataset FOREIGN KEY (id_dataset) 
        REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE ON DELETE NO ACTION;
        """
    )
