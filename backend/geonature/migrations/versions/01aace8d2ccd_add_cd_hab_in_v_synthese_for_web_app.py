"""add_cd_hab_in_v_synthese_for_web_app

Revision ID: 01aace8d2ccd
Revises: e2a94808cf76
Create Date: 2023-04-18 12:05:53.496655

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "01aace8d2ccd"
down_revision = "e2a94808cf76"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        CREATE OR REPLACE VIEW gn_synthese.v_synthese_for_web_app
        AS SELECT s.id_synthese,
            s.unique_id_sinp,
            s.unique_id_sinp_grp,
            s.id_source,
            s.entity_source_pk_value,
            s.count_min,
            s.count_max,
            s.nom_cite,
            s.meta_v_taxref,
            s.sample_number_proof,
            s.digital_proof,
            s.non_digital_proof,
            s.altitude_min,
            s.altitude_max,
            s.depth_min,
            s.depth_max,
            s.place_name,
            s."precision",
            s.the_geom_4326,
            st_asgeojson(s.the_geom_4326) AS st_asgeojson,
            s.date_min,
            s.date_max,
            s.validator,
            s.validation_comment,
            s.observers,
            s.id_digitiser,
            s.determiner,
            s.comment_context,
            s.comment_description,
            s.meta_validation_date,
            s.meta_create_date,
            s.meta_update_date,
            s.last_action,
            d.id_dataset,
            d.dataset_name,
            d.id_acquisition_framework,
            s.id_nomenclature_geo_object_nature,
            s.id_nomenclature_info_geo_type,
            s.id_nomenclature_grp_typ,
            s.grp_method,
            s.id_nomenclature_obs_technique,
            s.id_nomenclature_bio_status,
            s.id_nomenclature_bio_condition,
            s.id_nomenclature_naturalness,
            s.id_nomenclature_exist_proof,
            s.id_nomenclature_valid_status,
            s.id_nomenclature_diffusion_level,
            s.id_nomenclature_life_stage,
            s.id_nomenclature_sex,
            s.id_nomenclature_obj_count,
            s.id_nomenclature_type_count,
            s.id_nomenclature_sensitivity,
            s.id_nomenclature_observation_status,
            s.id_nomenclature_blurring,
            s.id_nomenclature_source_status,
            s.id_nomenclature_determination_method,
            s.id_nomenclature_behaviour,
            s.reference_biblio,
            sources.name_source,
            sources.url_source,
            t.cd_nom,
            t.cd_ref,
            t.nom_valide,
            t.lb_nom,
            t.nom_vern,
            s.cd_hab
        FROM gn_synthese.synthese s
            JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
            JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
            JOIN gn_synthese.t_sources sources ON sources.id_source = s.id_source;
        """
    )


def downgrade():
    op.execute(
        """
        CREATE OR REPLACE VIEW gn_synthese.v_synthese_for_web_app
        AS SELECT s.id_synthese,
            s.unique_id_sinp,
            s.unique_id_sinp_grp,
            s.id_source,
            s.entity_source_pk_value,
            s.count_min,
            s.count_max,
            s.nom_cite,
            s.meta_v_taxref,
            s.sample_number_proof,
            s.digital_proof,
            s.non_digital_proof,
            s.altitude_min,
            s.altitude_max,
            s.depth_min,
            s.depth_max,
            s.place_name,
            s."precision",
            s.the_geom_4326,
            st_asgeojson(s.the_geom_4326) AS st_asgeojson,
            s.date_min,
            s.date_max,
            s.validator,
            s.validation_comment,
            s.observers,
            s.id_digitiser,
            s.determiner,
            s.comment_context,
            s.comment_description,
            s.meta_validation_date,
            s.meta_create_date,
            s.meta_update_date,
            s.last_action,
            d.id_dataset,
            d.dataset_name,
            d.id_acquisition_framework,
            s.id_nomenclature_geo_object_nature,
            s.id_nomenclature_info_geo_type,
            s.id_nomenclature_grp_typ,
            s.grp_method,
            s.id_nomenclature_obs_technique,
            s.id_nomenclature_bio_status,
            s.id_nomenclature_bio_condition,
            s.id_nomenclature_naturalness,
            s.id_nomenclature_exist_proof,
            s.id_nomenclature_valid_status,
            s.id_nomenclature_diffusion_level,
            s.id_nomenclature_life_stage,
            s.id_nomenclature_sex,
            s.id_nomenclature_obj_count,
            s.id_nomenclature_type_count,
            s.id_nomenclature_sensitivity,
            s.id_nomenclature_observation_status,
            s.id_nomenclature_blurring,
            s.id_nomenclature_source_status,
            s.id_nomenclature_determination_method,
            s.id_nomenclature_behaviour,
            s.reference_biblio,
            sources.name_source,
            sources.url_source,
            t.cd_nom,
            t.cd_ref,
            t.nom_valide,
            t.lb_nom,
            t.nom_vern
        FROM gn_synthese.synthese s
            JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
            JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
            JOIN gn_synthese.t_sources sources ON sources.id_source = s.id_source;
        """
    )
