"""add schema gn_profiles

Revision ID: 2aa558b1be3a
Revises: 5f4c4b644844
Create Date: 2021-08-24 11:10:08.973033

"""

import importlib.resources

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "2aa558b1be3a"
down_revision = "5f4c4b644844"
branch_labels = None
depends_on = ("98035939bc0d",)  # taxonomie.find_all_taxons_parents(mycdnom integer)


def upgrade():
    op.execute(importlib.resources.read_text("geonature.migrations.data.core", "profiles.sql"))
    op.execute(
        """
    DROP VIEW gn_commons.v_synthese_validation_forwebapp;
    CREATE VIEW gn_commons.v_synthese_validation_forwebapp
    WITH(security_barrier=false)
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
        s.the_geom_4326,
        s.date_min,
        s.date_max,
        s.depth_min,
        s.depth_max,
        s.place_name,
        s."precision",
        s.validator,
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
        s.id_nomenclature_obs_technique,
        s.id_nomenclature_bio_status,
        s.id_nomenclature_bio_condition,
        s.id_nomenclature_naturalness,
        s.id_nomenclature_exist_proof,
        s.id_nomenclature_diffusion_level,
        s.id_nomenclature_life_stage,
        s.id_nomenclature_sex,
        s.id_nomenclature_obj_count,
        s.id_nomenclature_type_count,
        s.id_nomenclature_sensitivity,
        s.id_nomenclature_observation_status,
        s.id_nomenclature_blurring,
        s.id_nomenclature_source_status,
        s.id_nomenclature_valid_status,
        s.id_nomenclature_behaviour,
        s.reference_biblio,
        t.cd_nom,
        t.cd_ref,
        t.nom_valide,
        t.lb_nom,
        t.nom_vern,
        n.mnemonique,
        n.cd_nomenclature AS cd_nomenclature_validation_status,
        n.label_default,
        v.validation_auto,
        v.validation_date,
        st_asgeojson(s.the_geom_4326) AS geojson,
        COALESCE(t.nom_vern, t.lb_nom) AS nom_vern_or_lb_nom,
        v2.valid_distribution,
        v2.valid_phenology,
        v2.valid_altitude
    FROM gn_synthese.synthese s
        JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
        JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
        JOIN gn_profiles.v_consistancy_data v2 ON v2.id_synthese = s.id_synthese
        LEFT JOIN ref_nomenclatures.t_nomenclatures n ON n.id_nomenclature = s.id_nomenclature_valid_status
        LEFT JOIN LATERAL ( SELECT v_1.validation_auto,
                v_1.validation_date
            FROM gn_commons.t_validations v_1
            WHERE v_1.uuid_attached_row = s.unique_id_sinp
            ORDER BY v_1.validation_date DESC
            LIMIT 1) v ON true
    WHERE d.validable = true AND NOT s.unique_id_sinp IS NULL;
    
    """
    )


def downgrade():
    op.execute(f"DROP SCHEMA gn_profiles CASCADE")
    op.execute(
        """
    DROP VIEW gn_commons.v_synthese_validation_forwebapp;
    CREATE VIEW gn_commons.v_synthese_validation_forwebapp
    WITH (security_barrier=false)
    AS
     SELECT s.id_synthese,
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
    s.the_geom_4326,
    s.date_min,
    s.date_max,
    s.depth_min,
    s.depth_max,
    s.place_name,
    s."precision",
    s.validator,
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
    s.id_nomenclature_obs_technique,
    s.id_nomenclature_bio_status,
    s.id_nomenclature_bio_condition,
    s.id_nomenclature_naturalness,
    s.id_nomenclature_exist_proof,
    s.id_nomenclature_diffusion_level,
    s.id_nomenclature_life_stage,
    s.id_nomenclature_sex,
    s.id_nomenclature_obj_count,
    s.id_nomenclature_type_count,
    s.id_nomenclature_sensitivity,
    s.id_nomenclature_observation_status,
    s.id_nomenclature_blurring,
    s.id_nomenclature_source_status,
    s.id_nomenclature_valid_status,
    s.id_nomenclature_behaviour,
    s.reference_biblio,
    t.cd_nom,
    t.cd_ref,
    t.nom_valide,
    t.lb_nom,
    t.nom_vern,
    n.mnemonique,
    n.cd_nomenclature AS cd_nomenclature_validation_status,
    n.label_default,
    v.validation_auto,
    v.validation_date,
    st_asgeojson(s.the_geom_4326) AS geojson,
    COALESCE(nom_vern, lb_nom) as nom_vern_or_lb_nom
    FROM gn_synthese.synthese s
        JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
        JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
        LEFT JOIN ref_nomenclatures.t_nomenclatures n ON n.id_nomenclature = s.id_nomenclature_valid_status
        LEFT JOIN LATERAL ( SELECT v_1.validation_auto,
                v_1.validation_date
            FROM gn_commons.t_validations v_1
            WHERE v_1.uuid_attached_row = s.unique_id_sinp
            ORDER BY v_1.validation_date DESC
            LIMIT 1) v ON true
    WHERE d.validable = true AND NOT s.unique_id_sinp IS NULL;

    COMMENT ON VIEW gn_commons.v_synthese_validation_forwebapp  IS 'Vue utilisée pour le module validation. Prend l''id_nomenclature dans la table synthese ainsi que toutes les colonnes de la synthese pour les filtres. On JOIN sur la vue latest_validation pour voir si la validation est auto';
    """
    )
