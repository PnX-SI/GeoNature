"""add database default value

Revision ID: 22c2851bc387
Revises: 944072911ff7
Create Date: 2022-04-25 13:52:16.016035

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "22c2851bc387"
down_revision = "944072911ff7"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        ALTER TABLE pr_occtax.t_releves_occtax 
        ALTER COLUMN id_nomenclature_tech_collect_campanule SET DEFAULT pr_occtax.get_default_nomenclature_value('TECHNIQUE_OBS');

        ALTER TABLE pr_occtax.t_releves_occtax 
        ALTER COLUMN id_nomenclature_grp_typ SET DEFAULT pr_occtax.get_default_nomenclature_value('TYP_GRP');

        ALTER TABLE pr_occtax.t_releves_occtax 
        ALTER COLUMN id_nomenclature_geo_object_nature SET DEFAULT pr_occtax.get_default_nomenclature_value('NAT_OBJ_GEO');

       -- t_occurrence
       ALTER TABLE pr_occtax.t_occurrences_occtax  
       ALTER COLUMN id_nomenclature_obs_technique SET DEFAULT pr_occtax.get_default_nomenclature_value('METH_OBS');

	   ALTER TABLE pr_occtax.t_occurrences_occtax  
       ALTER COLUMN id_nomenclature_bio_condition SET DEFAULT pr_occtax.get_default_nomenclature_value('ETA_BIO');   

       ALTER TABLE pr_occtax.t_occurrences_occtax  
       ALTER COLUMN id_nomenclature_bio_status SET DEFAULT pr_occtax.get_default_nomenclature_value('STATUT_BIO');   

       ALTER TABLE pr_occtax.t_occurrences_occtax  
       ALTER COLUMN id_nomenclature_naturalness SET DEFAULT pr_occtax.get_default_nomenclature_value('NATURALITE');     

       ALTER TABLE pr_occtax.t_occurrences_occtax  
       ALTER COLUMN id_nomenclature_exist_proof SET DEFAULT pr_occtax.get_default_nomenclature_value('PREUVE_EXIST');

       ALTER TABLE pr_occtax.t_occurrences_occtax  
       ALTER COLUMN id_nomenclature_observation_status SET DEFAULT pr_occtax.get_default_nomenclature_value('STATUT_OBS');

       ALTER TABLE pr_occtax.t_occurrences_occtax  
       ALTER COLUMN id_nomenclature_blurring SET DEFAULT pr_occtax.get_default_nomenclature_value('DEE_FLOU');

       ALTER TABLE pr_occtax.t_occurrences_occtax  
       ALTER COLUMN id_nomenclature_source_status SET DEFAULT pr_occtax.get_default_nomenclature_value('STATUT_SOURCE');

       ALTER TABLE pr_occtax.t_occurrences_occtax  
       ALTER COLUMN id_nomenclature_determination_method SET DEFAULT pr_occtax.get_default_nomenclature_value('METH_DETERMIN');

       ALTER TABLE pr_occtax.t_occurrences_occtax  
       ALTER COLUMN id_nomenclature_behaviour SET DEFAULT pr_occtax.get_default_nomenclature_value('OCC_COMPORTEMENT');

      -- counting
	   ALTER TABLE pr_occtax.cor_counting_occtax  
       ALTER COLUMN id_nomenclature_life_stage SET DEFAULT pr_occtax.get_default_nomenclature_value('STADE_VIE');

	   ALTER TABLE pr_occtax.cor_counting_occtax  
       ALTER COLUMN id_nomenclature_obj_count SET DEFAULT pr_occtax.get_default_nomenclature_value('SEXE');

	   ALTER TABLE pr_occtax.cor_counting_occtax  
       ALTER COLUMN id_nomenclature_sex SET DEFAULT pr_occtax.get_default_nomenclature_value('OBJ_DENBR');

       ALTER TABLE pr_occtax.cor_counting_occtax  
       ALTER COLUMN id_nomenclature_type_count SET DEFAULT pr_occtax.get_default_nomenclature_value('TYP_DENBR');

        """
    )


def downgrade():
    op.execute(
        """
        ALTER TABLE pr_occtax.t_releves_occtax 
        ALTER COLUMN id_nomenclature_tech_collect_campanule DROP DEFAULT;

        ALTER TABLE pr_occtax.t_releves_occtax 
        ALTER COLUMN id_nomenclature_grp_typ DROP DEFAULT;

        ALTER TABLE pr_occtax.t_releves_occtax 
        ALTER COLUMN id_nomenclature_geo_object_nature DROP DEFAULT;

       -- t_occurrence
       ALTER TABLE pr_occtax.t_occurrences_occtax  
       ALTER COLUMN id_nomenclature_obs_technique DROP DEFAULT;

	   ALTER TABLE pr_occtax.t_occurrences_occtax  
       ALTER COLUMN id_nomenclature_bio_condition DROP DEFAULT;   

       ALTER TABLE pr_occtax.t_occurrences_occtax  
       ALTER COLUMN id_nomenclature_bio_status SET DROP DEFAULT;   

       ALTER TABLE pr_occtax.t_occurrences_occtax  
       ALTER COLUMN id_nomenclature_naturalness DROP DEFAULT;     

       ALTER TABLE pr_occtax.t_occurrences_occtax  
       ALTER COLUMN id_nomenclature_exist_proof DROP DEFAULT;

       ALTER TABLE pr_occtax.t_occurrences_occtax  
       ALTER COLUMN id_nomenclature_observation_status DROP DEFAULT;

       ALTER TABLE pr_occtax.t_occurrences_occtax  
       ALTER COLUMN id_nomenclature_blurring DROP DEFAULT;

       ALTER TABLE pr_occtax.t_occurrences_occtax  
       ALTER COLUMN id_nomenclature_source_status DROP DEFAULT;

       ALTER TABLE pr_occtax.t_occurrences_occtax  
       ALTER COLUMN id_nomenclature_determination_method DROP DEFAULT;

       ALTER TABLE pr_occtax.t_occurrences_occtax  
       ALTER COLUMN id_nomenclature_behaviour DROP DEFAULT;

      -- counting
	   ALTER TABLE pr_occtax.cor_counting_occtax  
       ALTER COLUMN id_nomenclature_life_stage DROP DEFAULT;

	   ALTER TABLE pr_occtax.cor_counting_occtax  
       ALTER COLUMN id_nomenclature_obj_count DROP DEFAULT;

	   ALTER TABLE pr_occtax.cor_counting_occtax  
       ALTER COLUMN id_nomenclature_sex DROP DEFAULT;

       ALTER TABLE pr_occtax.cor_counting_occtax  
       ALTER COLUMN id_nomenclature_type_count DROP DEFAULT;
        """
    )
