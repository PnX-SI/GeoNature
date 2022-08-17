"""remove v_synthese_decode_nomenclatures

Revision ID: ca0fe5d21ea2
Revises: 829a376daa52
Create Date: 2022-04-04 14:59:57.340518

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "ca0fe5d21ea2"
down_revision = "829a376daa52"
branch_labels = None
depends_on = None


def upgrade():
    op.execute("DROP VIEW  gn_exports.v_synthese_sinp_dee")
    op.execute("DROP VIEW gn_synthese.v_synthese_decode_nomenclatures")


def downgrade():
    op.execute(
        """
    CREATE OR REPLACE VIEW gn_synthese.v_synthese_decode_nomenclatures AS
    SELECT
    s.id_synthese,
    ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_geo_object_nature) AS nat_obj_geo,
    ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_grp_typ) AS grp_typ,
    ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_obs_technique) AS obs_technique,
    ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_bio_status) AS bio_status,
    ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_bio_condition) AS bio_condition,
    ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_naturalness) AS naturalness,
    ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_exist_proof) AS exist_proof ,
    ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_valid_status) AS valid_status,
    ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_diffusion_level) AS diffusion_level,
    ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_life_stage) AS life_stage,
    ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_sex) AS sex,
    ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_obj_count) AS obj_count,
    ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_type_count) AS type_count,
    ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_sensitivity) AS sensitivity,
    ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_observation_status) AS observation_status,
    ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_blurring) AS blurring,
    ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_source_status) AS source_status,
    ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_info_geo_type) AS info_geo_type,
    ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_determination_method) AS determination_method,
    ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_behaviour) AS occ_behaviour,
    ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_biogeo_status) AS occ_stat_biogeo
    FROM gn_synthese.synthese s;
    """
    )
