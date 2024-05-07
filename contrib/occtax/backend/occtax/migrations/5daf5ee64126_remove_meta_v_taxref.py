"""remove_meta_v_taxref

Revision ID: 5daf5ee64126
Revises: 43ecf0836b4a
Create Date: 2024-05-07 14:49:40.386726

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "5daf5ee64126"
down_revision = "43ecf0836b4a"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
       CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_occ()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$  declare
                releve_add_fields jsonb;
            BEGIN
                select r.additional_fields into releve_add_fields from pr_occtax.t_releves_occtax r where id_releve_occtax = new.id_releve_occtax;
                UPDATE gn_synthese.synthese s SET
                id_nomenclature_obs_technique = NEW.id_nomenclature_obs_technique,
                id_nomenclature_bio_condition = NEW.id_nomenclature_bio_condition,
                id_nomenclature_bio_status = NEW.id_nomenclature_bio_status,
                id_nomenclature_naturalness = NEW.id_nomenclature_naturalness,
                id_nomenclature_exist_proof = NEW.id_nomenclature_exist_proof,
                id_nomenclature_diffusion_level = NEW.id_nomenclature_diffusion_level,
                id_nomenclature_observation_status = NEW.id_nomenclature_observation_status,
                id_nomenclature_blurring = NEW.id_nomenclature_blurring,
                id_nomenclature_source_status = NEW.id_nomenclature_source_status,
                determiner = NEW.determiner,
                id_nomenclature_determination_method = NEW.id_nomenclature_determination_method,
                id_nomenclature_behaviour = NEW.id_nomenclature_behaviour,
                cd_nom = NEW.cd_nom,
                nom_cite = NEW.nom_cite,
                sample_number_proof = NEW.sample_number_proof,
                digital_proof = NEW.digital_proof,
                non_digital_proof = NEW.non_digital_proof,
                comment_description = NEW.comment,
                last_action = 'U',
                --CHAMPS ADDITIONNELS OCCTAX
                additional_data = COALESCE(releve_add_fields, '{}'::jsonb) || COALESCE(NEW.additional_fields, '{}'::jsonb) || COALESCE(c.additional_fields, '{}'::jsonb)
                FROM pr_occtax.cor_counting_occtax c
                WHERE s.unique_id_sinp = c.unique_id_sinp_occtax AND NEW.id_occurrence_occtax = c.id_occurrence_occtax ;
                RETURN NULL;
        END;
        $function$;
        """
    )
    op.execute(
        """
        CREATE OR REPLACE FUNCTION pr_occtax.insert_in_synthese(my_id_counting integer)
            RETURNS integer[]
            LANGUAGE plpgsql
            AS $function$  DECLARE
            new_count RECORD;
            occurrence RECORD;
            releve RECORD;
            id_source integer;
            id_nomenclature_source_status integer;
            myobservers RECORD;
            id_role_loop integer;

            BEGIN
            --recupération du counting à partir de son ID
            SELECT INTO new_count * FROM pr_occtax.cor_counting_occtax WHERE id_counting_occtax = my_id_counting;

            -- Récupération de l'occurrence
            SELECT INTO occurrence * FROM pr_occtax.t_occurrences_occtax occ WHERE occ.id_occurrence_occtax = new_count.id_occurrence_occtax;

            -- Récupération du relevé
            SELECT INTO releve * FROM pr_occtax.t_releves_occtax rel WHERE occurrence.id_releve_occtax = rel.id_releve_occtax;

            -- Récupération de la source
            SELECT INTO id_source s.id_source FROM gn_synthese.t_sources s WHERE name_source ILIKE 'occtax';

            -- Récupération du status_source depuis le JDD
            SELECT INTO id_nomenclature_source_status d.id_nomenclature_source_status FROM gn_meta.t_datasets d WHERE id_dataset = releve.id_dataset;

            --Récupération et formatage des observateurs
            SELECT INTO myobservers array_to_string(array_agg(rol.nom_role || ' ' || rol.prenom_role), ', ') AS observers_name,
            array_agg(rol.id_role) AS observers_id
            FROM pr_occtax.cor_role_releves_occtax cor
            JOIN utilisateurs.t_roles rol ON rol.id_role = cor.id_role
            WHERE cor.id_releve_occtax = releve.id_releve_occtax;

            -- insertion dans la synthese
            INSERT INTO gn_synthese.synthese (
            unique_id_sinp,
            unique_id_sinp_grp,
            id_source,
            entity_source_pk_value,
            id_dataset,
            id_module,
            id_nomenclature_geo_object_nature,
            id_nomenclature_grp_typ,
            grp_method,
            id_nomenclature_obs_technique,
            id_nomenclature_bio_status,
            id_nomenclature_bio_condition,
            id_nomenclature_naturalness,
            id_nomenclature_exist_proof,
            id_nomenclature_diffusion_level,
            id_nomenclature_life_stage,
            id_nomenclature_sex,
            id_nomenclature_obj_count,
            id_nomenclature_type_count,
            id_nomenclature_observation_status,
            id_nomenclature_blurring,
            id_nomenclature_source_status,
            id_nomenclature_info_geo_type,
            id_nomenclature_behaviour,
            count_min,
            count_max,
            cd_nom,
            cd_hab,
            nom_cite,
            sample_number_proof,
            digital_proof,
            non_digital_proof,
            altitude_min,
            altitude_max,
            depth_min,
            depth_max,
            place_name,
            precision,
            the_geom_4326,
            the_geom_point,
            the_geom_local,
            date_min,
            date_max,
            observers,
            determiner,
            id_digitiser,
            id_nomenclature_determination_method,
            comment_context,
            comment_description,
            last_action,
            additional_data
            )
            VALUES(
                new_count.unique_id_sinp_occtax,
                releve.unique_id_sinp_grp,
                id_source,
                new_count.id_counting_occtax,
                releve.id_dataset,
                releve.id_module,
                releve.id_nomenclature_geo_object_nature,
                releve.id_nomenclature_grp_typ,
                releve.grp_method,
                occurrence.id_nomenclature_obs_technique,
                occurrence.id_nomenclature_bio_status,
                occurrence.id_nomenclature_bio_condition,
                occurrence.id_nomenclature_naturalness,
                occurrence.id_nomenclature_exist_proof,
                occurrence.id_nomenclature_diffusion_level,
                new_count.id_nomenclature_life_stage,
                new_count.id_nomenclature_sex,
                new_count.id_nomenclature_obj_count,
                new_count.id_nomenclature_type_count,
                occurrence.id_nomenclature_observation_status,
                occurrence.id_nomenclature_blurring,
                -- status_source récupéré depuis le JDD
                id_nomenclature_source_status,
                -- id_nomenclature_info_geo_type: type de rattachement = non saisissable: georeferencement
                ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO', '1'),
                occurrence.id_nomenclature_behaviour,
                new_count.count_min,
                new_count.count_max,
                occurrence.cd_nom,
                releve.cd_hab,
                occurrence.nom_cite,
                occurrence.sample_number_proof,
                occurrence.digital_proof,
                occurrence.non_digital_proof,
                releve.altitude_min,
                releve.altitude_max,
                releve.depth_min,
                releve.depth_max,
                releve.place_name,
                releve.precision,
                releve.geom_4326,
                ST_CENTROID(releve.geom_4326),
                releve.geom_local,
                date_trunc('day',releve.date_min)+COALESCE(releve.hour_min,'00:00:00'::time),
                date_trunc('day',releve.date_max)+COALESCE(releve.hour_max,'00:00:00'::time),
                COALESCE (myobservers.observers_name, releve.observers_txt),
                occurrence.determiner,
                releve.id_digitiser,
                occurrence.id_nomenclature_determination_method,
                releve.comment,
                occurrence.comment,
                'I',
                COALESCE(releve.additional_fields, '{}'::jsonb) || COALESCE(occurrence.additional_fields, '{}'::jsonb) || COALESCE(new_count.additional_fields, '{}'::jsonb)
            );

                RETURN myobservers.observers_id ;
            END;
            $function$;
        """
    )
    op.execute("DROP VIEW IF EXISTS gn_synthese.v_synthese_for_web_app;")
    op.execute(
        """
-- gn_synthese.v_synthese_for_web_app source

CREATE OR REPLACE VIEW gn_synthese.v_synthese_for_web_app
AS SELECT s.id_synthese,
    s.unique_id_sinp,
    s.unique_id_sinp_grp,
    s.id_source,
    s.entity_source_pk_value,
    s.count_min,
    s.count_max,
    s.nom_cite,
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
    s.id_module,
    t.group1_inpn,
    t.group2_inpn,
    t.group3_inpn
   FROM gn_synthese.synthese s
     JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
     JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
     JOIN gn_synthese.t_sources sources ON sources.id_source = s.id_source;
    """
    )
    op.drop_column("synthese", "meta_v_taxref", schema="gn_synthese")
    op.drop_column("t_occurrences_occtax", "meta_v_taxref", schema="pr_occtax")


def downgrade():
    op.add_column(
        "t_occurrences_occtax",
        sa.Column("meta_v_taxref", sa.String(), nullable=True),
        schema="pr_occtax",
    )
    op.add_column(
        "synthese", sa.Column("meta_v_taxref", sa.String(), nullable=True), schema="gn_synthese"
    )
    op.execute("DROP VIEW IF EXISTS gn_synthese.v_synthese_for_web_app;")
    op.execute(
        """

-- gn_synthese.v_synthese_for_web_app source

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
    s.id_module,
    t.group1_inpn,
    t.group2_inpn,
    t.group3_inpn
   FROM gn_synthese.synthese s
     JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
     JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
     JOIN gn_synthese.t_sources sources ON sources.id_source = s.id_source;
"""
    )

    op.execute(
        """
        CREATE OR REPLACE FUNCTION pr_occtax.insert_in_synthese(my_id_counting integer)
            RETURNS integer[]
            LANGUAGE plpgsql
            AS $function$  DECLARE
            new_count RECORD;
            occurrence RECORD;
            releve RECORD;
            id_source integer;
            id_nomenclature_source_status integer;
            myobservers RECORD;
            id_role_loop integer;

            BEGIN
            --recupération du counting à partir de son ID
            SELECT INTO new_count * FROM pr_occtax.cor_counting_occtax WHERE id_counting_occtax = my_id_counting;

            -- Récupération de l'occurrence
            SELECT INTO occurrence * FROM pr_occtax.t_occurrences_occtax occ WHERE occ.id_occurrence_occtax = new_count.id_occurrence_occtax;

            -- Récupération du relevé
            SELECT INTO releve * FROM pr_occtax.t_releves_occtax rel WHERE occurrence.id_releve_occtax = rel.id_releve_occtax;

            -- Récupération de la source
            SELECT INTO id_source s.id_source FROM gn_synthese.t_sources s WHERE name_source ILIKE 'occtax';

            -- Récupération du status_source depuis le JDD
            SELECT INTO id_nomenclature_source_status d.id_nomenclature_source_status FROM gn_meta.t_datasets d WHERE id_dataset = releve.id_dataset;

            --Récupération et formatage des observateurs
            SELECT INTO myobservers array_to_string(array_agg(rol.nom_role || ' ' || rol.prenom_role), ', ') AS observers_name,
            array_agg(rol.id_role) AS observers_id
            FROM pr_occtax.cor_role_releves_occtax cor
            JOIN utilisateurs.t_roles rol ON rol.id_role = cor.id_role
            WHERE cor.id_releve_occtax = releve.id_releve_occtax;

            -- insertion dans la synthese
            INSERT INTO gn_synthese.synthese (
            unique_id_sinp,
            unique_id_sinp_grp,
            id_source,
            entity_source_pk_value,
            id_dataset,
            id_module,
            id_nomenclature_geo_object_nature,
            id_nomenclature_grp_typ,
            grp_method,
            id_nomenclature_obs_technique,
            id_nomenclature_bio_status,
            id_nomenclature_bio_condition,
            id_nomenclature_naturalness,
            id_nomenclature_exist_proof,
            id_nomenclature_diffusion_level,
            id_nomenclature_life_stage,
            id_nomenclature_sex,
            id_nomenclature_obj_count,
            id_nomenclature_type_count,
            id_nomenclature_observation_status,
            id_nomenclature_blurring,
            id_nomenclature_source_status,
            id_nomenclature_info_geo_type,
            id_nomenclature_behaviour,
            count_min,
            count_max,
            cd_nom,
            cd_hab,
            nom_cite,
            meta_v_taxref,
            sample_number_proof,
            digital_proof,
            non_digital_proof,
            altitude_min,
            altitude_max,
            depth_min,
            depth_max,
            place_name,
            precision,
            the_geom_4326,
            the_geom_point,
            the_geom_local,
            date_min,
            date_max,
            observers,
            determiner,
            id_digitiser,
            id_nomenclature_determination_method,
            comment_context,
            comment_description,
            last_action,
            additional_data
            )
            VALUES(
                new_count.unique_id_sinp_occtax,
                releve.unique_id_sinp_grp,
                id_source,
                new_count.id_counting_occtax,
                releve.id_dataset,
                releve.id_module,
                releve.id_nomenclature_geo_object_nature,
                releve.id_nomenclature_grp_typ,
                releve.grp_method,
                occurrence.id_nomenclature_obs_technique,
                occurrence.id_nomenclature_bio_status,
                occurrence.id_nomenclature_bio_condition,
                occurrence.id_nomenclature_naturalness,
                occurrence.id_nomenclature_exist_proof,
                occurrence.id_nomenclature_diffusion_level,
                new_count.id_nomenclature_life_stage,
                new_count.id_nomenclature_sex,
                new_count.id_nomenclature_obj_count,
                new_count.id_nomenclature_type_count,
                occurrence.id_nomenclature_observation_status,
                occurrence.id_nomenclature_blurring,
                -- status_source récupéré depuis le JDD
                id_nomenclature_source_status,
                -- id_nomenclature_info_geo_type: type de rattachement = non saisissable: georeferencement
                ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO', '1'),
                occurrence.id_nomenclature_behaviour,
                new_count.count_min,
                new_count.count_max,
                occurrence.cd_nom,
                releve.cd_hab,
                occurrence.nom_cite,
                occurrence.meta_v_taxref,
                occurrence.sample_number_proof,
                occurrence.digital_proof,
                occurrence.non_digital_proof,
                releve.altitude_min,
                releve.altitude_max,
                releve.depth_min,
                releve.depth_max,
                releve.place_name,
                releve.precision,
                releve.geom_4326,
                ST_CENTROID(releve.geom_4326),
                releve.geom_local,
                date_trunc('day',releve.date_min)+COALESCE(releve.hour_min,'00:00:00'::time),
                date_trunc('day',releve.date_max)+COALESCE(releve.hour_max,'00:00:00'::time),
                COALESCE (myobservers.observers_name, releve.observers_txt),
                occurrence.determiner,
                releve.id_digitiser,
                occurrence.id_nomenclature_determination_method,
                releve.comment,
                occurrence.comment,
                'I',
                COALESCE(releve.additional_fields, '{}'::jsonb) || COALESCE(occurrence.additional_fields, '{}'::jsonb) || COALESCE(new_count.additional_fields, '{}'::jsonb)
            );

                RETURN myobservers.observers_id ;
            END;
            $function$;
        """
    )
    op.execute(
        """
       CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_occ()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$  declare
                releve_add_fields jsonb;
            BEGIN
                select r.additional_fields into releve_add_fields from pr_occtax.t_releves_occtax r where id_releve_occtax = new.id_releve_occtax;
                UPDATE gn_synthese.synthese s SET
                id_nomenclature_obs_technique = NEW.id_nomenclature_obs_technique,
                id_nomenclature_bio_condition = NEW.id_nomenclature_bio_condition,
                id_nomenclature_bio_status = NEW.id_nomenclature_bio_status,
                id_nomenclature_naturalness = NEW.id_nomenclature_naturalness,
                id_nomenclature_exist_proof = NEW.id_nomenclature_exist_proof,
                id_nomenclature_diffusion_level = NEW.id_nomenclature_diffusion_level,
                id_nomenclature_observation_status = NEW.id_nomenclature_observation_status,
                id_nomenclature_blurring = NEW.id_nomenclature_blurring,
                id_nomenclature_source_status = NEW.id_nomenclature_source_status,
                determiner = NEW.determiner,
                id_nomenclature_determination_method = NEW.id_nomenclature_determination_method,
                id_nomenclature_behaviour = NEW.id_nomenclature_behaviour,
                cd_nom = NEW.cd_nom,
                nom_cite = NEW.nom_cite,
                meta_v_taxref = NEW.meta_v_taxref,
                sample_number_proof = NEW.sample_number_proof,
                digital_proof = NEW.digital_proof,
                non_digital_proof = NEW.non_digital_proof,
                comment_description = NEW.comment,
                last_action = 'U',
                --CHAMPS ADDITIONNELS OCCTAX
                additional_data = COALESCE(releve_add_fields, '{}'::jsonb) || COALESCE(NEW.additional_fields, '{}'::jsonb) || COALESCE(c.additional_fields, '{}'::jsonb)
                FROM pr_occtax.cor_counting_occtax c
                WHERE s.unique_id_sinp = c.unique_id_sinp_occtax AND NEW.id_occurrence_occtax = c.id_occurrence_occtax ;
                RETURN NULL;
        END;
        $function$;
        """
    )
