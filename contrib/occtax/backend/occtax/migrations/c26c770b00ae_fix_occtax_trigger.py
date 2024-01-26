"""fix occtax trigger additionnal data + trigger occ

Revision ID: c26c770b00ae
Revises: 22c2851bc387
Create Date: 2022-10-12 16:05:50.816962

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "c26c770b00ae"
down_revision = "023b0be41829"
branch_labels = None
depends_on = None


def upgrade():
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
        CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_counting()
        RETURNS trigger
        LANGUAGE plpgsql
        AS $function$DECLARE
        occurrence RECORD;
        releve RECORD;
        BEGIN

        -- Récupération de l'occurrence
        SELECT INTO occurrence * FROM pr_occtax.t_occurrences_occtax occ WHERE occ.id_occurrence_occtax = NEW.id_occurrence_occtax;
        -- Récupération du relevé
        SELECT INTO releve * FROM pr_occtax.t_releves_occtax rel WHERE occurrence.id_releve_occtax = rel.id_releve_occtax;
        
        -- Update dans la synthese
        UPDATE gn_synthese.synthese
        SET
        entity_source_pk_value = NEW.id_counting_occtax,
        id_nomenclature_life_stage = NEW.id_nomenclature_life_stage,
        id_nomenclature_sex = NEW.id_nomenclature_sex,
        id_nomenclature_obj_count = NEW.id_nomenclature_obj_count,
        id_nomenclature_type_count = NEW.id_nomenclature_type_count,
        count_min = NEW.count_min,
        count_max = NEW.count_max,
        last_action = 'U',
        --CHAMPS ADDITIONNELS OCCTAX
        additional_data = COALESCE(releve.additional_fields, '{}'::jsonb) || COALESCE(occurrence.additional_fields, '{}'::jsonb) || COALESCE(NEW.additional_fields, '{}'::jsonb)
        WHERE unique_id_sinp = NEW.unique_id_sinp_occtax;
        IF(NEW.unique_id_sinp_occtax <> OLD.unique_id_sinp_occtax) THEN
            RAISE EXCEPTION 'ATTENTION : %', 'Le champ "unique_id_sinp_occtax" est généré par GeoNature et ne doit pas être changé.'
                || chr(10) || 'Il est utilisé par le SINP pour identifier de manière unique une observation.'
                || chr(10) || 'Si vous le changez, le SINP considérera cette observation comme une nouvelle observation.'
                || chr(10) || 'Si vous souhaitez vraiment le changer, désactivez ce trigger, faite le changement, réactiez ce trigger'
                || chr(10) || 'ET répercutez manuellement les changements dans "gn_synthese.synthese".';
        END IF;
        RETURN NULL;
        END;
        $function$
        ;
        
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
    op.execute(
        """
        CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_releve()
        RETURNS trigger
        LANGUAGE plpgsql
        AS $function$
        DECLARE
        myobservers text;
        BEGIN

        --mise à jour en synthese des informations correspondant au relevé uniquement
        UPDATE gn_synthese.synthese s SET
            id_dataset = NEW.id_dataset,
            observers = COALESCE(NEW.observers_txt, observers),
            id_digitiser = NEW.id_digitiser,
            id_module = NEW.id_module,
            grp_method = NEW.grp_method,
            id_nomenclature_grp_typ = NEW.id_nomenclature_grp_typ,
            date_min = date_trunc('day',NEW.date_min)+COALESCE(NEW.hour_min,'00:00:00'::time),
            date_max = date_trunc('day',NEW.date_max)+COALESCE(NEW.hour_max,'00:00:00'::time), 
            altitude_min = NEW.altitude_min,
            altitude_max = NEW.altitude_max,
            depth_min = NEW.depth_min,
            depth_max = NEW.depth_max,
            place_name = NEW.place_name,
            precision = NEW.precision,
            the_geom_local = NEW.geom_local,
            the_geom_4326 = NEW.geom_4326,
            the_geom_point = ST_CENTROID(NEW.geom_4326),
            id_nomenclature_geo_object_nature = NEW.id_nomenclature_geo_object_nature,
            last_action = 'U',
            comment_context = NEW.comment,
            additional_data = COALESCE(NEW.additional_fields, '{}'::jsonb) || COALESCE(o.additional_fields, '{}'::jsonb) || COALESCE(c.additional_fields, '{}'::jsonb)
            FROM pr_occtax.cor_counting_occtax c
            INNER JOIN pr_occtax.t_occurrences_occtax o ON c.id_occurrence_occtax = o.id_occurrence_occtax
            WHERE c.unique_id_sinp_occtax = s.unique_id_sinp
                AND s.unique_id_sinp IN (SELECT unnest(pr_occtax.get_unique_id_sinp_from_id_releve(NEW.id_releve_occtax::integer)));

        RETURN NULL;
        END;
        $function$
        ;
        """
    )
    # correction des données de synthese suite au bug des dénombrement
    op.execute(
        """
        UPDATE gn_synthese.synthese s
        SET additional_data = COALESCE(rel.additional_fields, '{}'::jsonb) || COALESCE(occ.additional_fields, '{}'::jsonb) || COALESCE(cor.additional_fields, '{}'::jsonb)
        FROM pr_occtax.t_releves_occtax rel
        JOIN pr_occtax.t_occurrences_occtax occ ON rel.id_releve_occtax = occ.id_occurrence_occtax 
        JOIN pr_occtax.cor_counting_occtax cor ON cor.id_occurrence_occtax = occ.id_occurrence_occtax 
        WHERE s.unique_id_sinp = cor.unique_id_sinp_occtax 
        -- where un des trois additionnal data est null, mais qu'il ne sont pas tous les 3 null
        AND (rel.additional_fields IS NULL OR occ.additional_fields IS NULL OR cor.additional_fields IS NULL) AND NOT 
        (rel.additional_fields IS NULL AND occ.additional_fields IS NULL AND cor.additional_fields IS NULL);
        """
    )
    # correction des données de synthese suite au bug du trigger d'update occurrence (issue #1821)
    op.execute(
        """
        UPDATE gn_synthese.synthese s
        SET
        id_nomenclature_bio_condition = too.id_nomenclature_bio_condition, 
        id_nomenclature_bio_status = too.id_nomenclature_bio_status,
        id_nomenclature_naturalness  = too.id_nomenclature_naturalness, 
        id_nomenclature_exist_proof = too.id_nomenclature_exist_proof, 
        id_nomenclature_diffusion_level = too.id_nomenclature_diffusion_level, 
        id_nomenclature_observation_status = too.id_nomenclature_observation_status,
        id_nomenclature_blurring = too.id_nomenclature_blurring,
        id_nomenclature_source_status = too.id_nomenclature_source_status,
        id_nomenclature_behaviour = too.id_nomenclature_behaviour, 
        determiner = too.determiner, 
        id_nomenclature_determination_method = too.id_nomenclature_determination_method, 
        nom_cite = too.nom_cite, 
        sample_number_proof  = too.sample_number_proof
        FROM pr_occtax.cor_counting_occtax cco
        JOIN pr_occtax.t_occurrences_occtax too ON too.id_occurrence_occtax = cco.id_occurrence_occtax 
        WHERE s.unique_id_sinp  = cco.unique_id_sinp_occtax AND 
        (
            s.cd_nom != too.cd_nom  
            OR too.id_nomenclature_obs_technique != s.id_nomenclature_obs_technique 
            OR too.id_nomenclature_bio_condition != s.id_nomenclature_bio_condition 
            OR too.id_nomenclature_bio_status != s.id_nomenclature_bio_status 
            OR too.id_nomenclature_naturalness != s.id_nomenclature_naturalness 
            OR too.id_nomenclature_exist_proof != s.id_nomenclature_exist_proof 
            OR too.id_nomenclature_observation_status != s.id_nomenclature_observation_status 
            OR too.id_nomenclature_blurring != s.id_nomenclature_blurring 
            OR too.id_nomenclature_source_status != s.id_nomenclature_source_status
            OR too.id_nomenclature_behaviour != s.id_nomenclature_behaviour 
            OR too.determiner != s.determiner 
            OR too.id_nomenclature_determination_method != s.id_nomenclature_determination_method 
            OR too.nom_cite != s.nom_cite 
            OR too.sample_number_proof != s.sample_number_proof 
        );
        """
    )


def downgrade():
    pass
