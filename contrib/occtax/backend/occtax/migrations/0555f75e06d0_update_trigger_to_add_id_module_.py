"""update trigger to add id_module dynamicly

Revision ID: 0555f75e06d0
Revises: 023b0be41829
Create Date: 2022-04-06 16:27:28.250022

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "0555f75e06d0"
down_revision = "023b0be41829"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_releve()
        RETURNS trigger
        LANGUAGE plpgsql
        AS $function$
            DECLARE
            BEGIN
            --mise à jour en synthese des informations correspondant au relevé uniquement
            UPDATE gn_synthese.synthese s SET
                id_dataset = updated_rows.id_dataset,
                id_module = updated_rows.id_module,
                -- take observer_txt only if not null
                observers = COALESCE(updated_rows.observers_txt, observers),
                id_digitiser = updated_rows.id_digitiser,
                grp_method = updated_rows.grp_method,
                id_nomenclature_grp_typ = updated_rows.id_nomenclature_grp_typ,
                date_min = date_trunc('day',updated_rows.date_min)+COALESCE(updated_rows.hour_min,'00:00:00'::time),
                date_max = date_trunc('day',updated_rows.date_max)+COALESCE(updated_rows.hour_max,'00:00:00'::time), 
                altitude_min = updated_rows.altitude_min,
                altitude_max = updated_rows.altitude_max,
                depth_min = updated_rows.depth_min,
                depth_max = updated_rows.depth_max,
                place_name = updated_rows.place_name,
                precision = updated_rows.precision,
                the_geom_local = updated_rows.geom_local,
                the_geom_4326 = updated_rows.geom_4326,
                the_geom_point = ST_CENTROID(updated_rows.geom_4326),
                id_nomenclature_geo_object_nature = updated_rows.id_nomenclature_geo_object_nature,
                last_action = 'U',
                comment_context = updated_rows.comment,
                additional_data = COALESCE(updated_rows.additional_fields, '{}'::jsonb) || COALESCE(o.additional_fields, '{}'::jsonb) || COALESCE(c.additional_fields, '{}'::jsonb)
                FROM NEW as updated_rows  
                JOIN pr_occtax.t_occurrences_occtax o ON updated_rows.id_releve_occtax = o.id_releve_occtax
                JOIN  pr_occtax.cor_counting_occtax c ON o.id_occurrence_occtax = c.id_occurrence_occtax
                WHERE s.unique_id_sinp_grp  = updated_rows.unique_id_sinp_grp
                ;

            RETURN NULL;
            END;
            $function$
            ;
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
                occurrence.additional_fields || releve.additional_fields || new_count.additional_fields
            );

                RETURN myobservers.observers_id ;
            END;
            $function$
        ;
        """
    )


def downgrade():
    op.execute(
        """
        CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_releve()
        RETURNS trigger
        LANGUAGE plpgsql
        AS $function$
            DECLARE
            BEGIN
            --mise à jour en synthese des informations correspondant au relevé uniquement
            UPDATE gn_synthese.synthese s SET
                id_dataset = updated_rows.id_dataset,
                -- take observer_txt only if not null
                observers = COALESCE(updated_rows.observers_txt, observers),
                id_digitiser = updated_rows.id_digitiser,
                grp_method = updated_rows.grp_method,
                id_nomenclature_grp_typ = updated_rows.id_nomenclature_grp_typ,
                date_min = date_trunc('day',updated_rows.date_min)+COALESCE(updated_rows.hour_min,'00:00:00'::time),
                date_max = date_trunc('day',updated_rows.date_max)+COALESCE(updated_rows.hour_max,'00:00:00'::time), 
                altitude_min = updated_rows.altitude_min,
                altitude_max = updated_rows.altitude_max,
                depth_min = updated_rows.depth_min,
                depth_max = updated_rows.depth_max,
                place_name = updated_rows.place_name,
                precision = updated_rows.precision,
                the_geom_local = updated_rows.geom_local,
                the_geom_4326 = updated_rows.geom_4326,
                the_geom_point = ST_CENTROID(updated_rows.geom_4326),
                id_nomenclature_geo_object_nature = updated_rows.id_nomenclature_geo_object_nature,
                last_action = 'U',
                comment_context = updated_rows.comment,
                additional_data = COALESCE(updated_rows.additional_fields, '{}'::jsonb) || COALESCE(o.additional_fields, '{}'::jsonb) || COALESCE(c.additional_fields, '{}'::jsonb)
                FROM NEW as updated_rows  
                JOIN pr_occtax.t_occurrences_occtax o ON updated_rows.id_releve_occtax = o.id_releve_occtax
                JOIN  pr_occtax.cor_counting_occtax c ON o.id_occurrence_occtax = c.id_occurrence_occtax
                WHERE s.unique_id_sinp_grp  = updated_rows.unique_id_sinp_grp
                ;

            RETURN NULL;
            END;
            $function$
            ;
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
            id_module integer;
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

            -- Récupération de l'id_module
            SELECT INTO id_module gn_commons.get_id_module_bycode('OCCTAX');

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
                id_module,
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
                occurrence.additional_fields || releve.additional_fields || new_count.additional_fields
            );

                RETURN myobservers.observers_id ;
            END;
            $function$
        ;
    """
    )
