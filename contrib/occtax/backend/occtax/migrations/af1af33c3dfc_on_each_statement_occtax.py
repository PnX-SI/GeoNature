"""On each statement occtax

Revision ID: af1af33c3dfc
Revises: 944072911ff7
Create Date: 2022-02-16 16:05:41.693904

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'af1af33c3dfc'
down_revision = '944072911ff7'
branch_labels = None
depends_on = (
    "9b7b5cbd7931"
)


def upgrade():
    # update releve :
    op.execute(
        """
            DROP TRIGGER tri_update_synthese_t_releve_occtax ON pr_occtax.t_releves_occtax;
            CREATE TRIGGER tri_update_synthese_t_releve_occtax AFTER UPDATE ON pr_occtax.t_releves_occtax 
            REFERENCING NEW TABLE AS NEW FOR EACH STATEMENT EXECUTE FUNCTION pr_occtax.fct_tri_synthese_update_releve();

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

    # trigger occurrence 
    op.execute(
        """
        DROP TRIGGER tri_update_synthese_t_occurrence_occtax ON pr_occtax.t_occurrences_occtax;
        CREATE TRIGGER tri_update_synthese_t_occurrence_occtax AFTER UPDATE ON pr_occtax.t_occurrences_occtax 
        REFERENCING NEW TABLE AS updated_rows FOR EACH STATEMENT EXECUTE FUNCTION pr_occtax.fct_tri_synthese_update_occ();

            CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_occ()
                    RETURNS trigger
                    LANGUAGE plpgsql
                    AS $function$  declare
                begin
                    UPDATE gn_synthese.synthese SET
                    id_nomenclature_obs_technique = u.id_nomenclature_obs_technique,
                    id_nomenclature_bio_condition = u.id_nomenclature_bio_condition,
                    id_nomenclature_bio_status = u.id_nomenclature_bio_status,
                    id_nomenclature_naturalness = u.id_nomenclature_naturalness,
                    id_nomenclature_exist_proof = u.id_nomenclature_exist_proof,
                    id_nomenclature_diffusion_level = u.id_nomenclature_diffusion_level,
                    id_nomenclature_observation_status = u.id_nomenclature_observation_status,
                    id_nomenclature_blurring = u.id_nomenclature_blurring,
                    id_nomenclature_source_status = u.id_nomenclature_source_status,
                    determiner = u.determiner,
                    id_nomenclature_determination_method = u.id_nomenclature_determination_method,
                    id_nomenclature_behaviour = u.id_nomenclature_behaviour,
                    cd_nom = u.cd_nom,
                    nom_cite = u.nom_cite,
                    meta_v_taxref = u.meta_v_taxref,
                    sample_number_proof = u.sample_number_proof,
                    digital_proof = u.digital_proof,
                    non_digital_proof = u.non_digital_proof,
                    comment_description = u.comment,
                    last_action = 'U',
                    --CHAMPS ADDITIONNELS OCCTAX
                    additional_data = COALESCE(releve.additional_fields, '{}'::jsonb) || COALESCE(u.additional_fields, '{}'::jsonb) || COALESCE(counting.additional_fields, '{}'::jsonb)
                    FROM updated_rows as u
                    JOIN pr_occtax.t_releves_occtax releve ON releve.id_releve_occtax = u.id_releve_occtax
                    JOIN pr_occtax.cor_counting_occtax counting ON counting.id_occurrence_occtax = u.id_occurrence_occtax
                    WHERE unique_id_sinp = counting.unique_id_sinp_occtax;
                    
                    RETURN NULL;
            END;
            $function$
                ;

        """
    )
    # update counting 
    op.execute(
        """
        DROP TRIGGER tri_update_synthese_cor_counting_occtax ON pr_occtax.cor_counting_occtax;
        CREATE TRIGGER tri_update_synthese_cor_counting_occtax AFTER UPDATE ON pr_occtax.cor_counting_occtax 
        REFERENCING NEW TABLE AS updated_rows FOR EACH STATEMENT EXECUTE FUNCTION pr_occtax.fct_tri_synthese_update_counting();

        CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_counting()
        RETURNS trigger
        LANGUAGE plpgsql
        AS $function$DECLARE
                BEGIN
                    -- Update dans la synthese
                    UPDATE gn_synthese.synthese
                    SET
                    entity_source_pk_value = u.id_counting_occtax,
                    id_nomenclature_life_stage = u.id_nomenclature_life_stage,
                    id_nomenclature_sex = u.id_nomenclature_sex,
                    id_nomenclature_obj_count = u.id_nomenclature_obj_count,
                    id_nomenclature_type_count = u.id_nomenclature_type_count,
                    count_min = u.count_min,
                    count_max = u.count_max,
                    last_action = 'U',
                    --CHAMPS ADDITIONNELS OCCTAX
                    additional_data = COALESCE(rel.additional_fields, '{}'::jsonb) || COALESCE(occ.additional_fields, '{}'::jsonb) || COALESCE(u.additional_fields, '{}'::jsonb)
                    FROM updated_rows u
                    JOIN pr_occtax.t_occurrences_occtax occ ON occ.id_occurrence_occtax = u.id_occurrence_occtax
                    JOIN pr_occtax.t_releves_occtax rel ON occ.id_releve_occtax = rel.id_releve_occtax
                    WHERE unique_id_sinp = u.unique_id_sinp_occtax;
                RETURN NULL;
                END;
                $function$
        ;
        """
    )

    # trigger geom et altitude 
    op.execute(
        """
        -- passage de trigger de caclul de la geom local uniquement au changement de geom en update
        DROP TRIGGER tri_calculate_geom_local ON pr_occtax.t_releves_occtax;

        CREATE TRIGGER tri_insert_calculate_geom_local BEFORE
        INSERT ON pr_occtax.t_releves_occtax 
        FOR EACH ROW EXECUTE FUNCTION ref_geo.fct_trg_calculate_geom_local('geom_4326', 'geom_local');

        CREATE TRIGGER tri_update_calculate_geom_local 
        BEFORE UPDATE OF geom_4326 ON pr_occtax.t_releves_occtax 
        FOR EACH ROW EXECUTE FUNCTION ref_geo.fct_trg_calculate_geom_local('geom_4326', 'geom_local');

        -- passage de trigger de caclul des altitudes uniquement au changement de geom en update
        DROP TRIGGER tri_calculate_altitude ON pr_occtax.t_releves_occtax;

        CREATE TRIGGER tri_insert_calculate_altitude 
        BEFORE INSERT ON pr_occtax.t_releves_occtax 
        FOR EACH ROW EXECUTE FUNCTION ref_geo.fct_trg_calculate_alt_minmax('geom_4326');

        CREATE TRIGGER tri_update_calculate_altitude 
        BEFORE UPDATE OF geom_local, geom_4326 ON pr_occtax.t_releves_occtax 
        FOR EACH ROW EXECUTE FUNCTION ref_geo.fct_trg_calculate_alt_minmax('geom_4326');
        """
    )

    # trigger de log releve
    op.execute(
        """
        DROP TRIGGER tri_log_changes_t_releves_occtax ON pr_occtax.t_releves_occtax;

        CREATE TRIGGER tri_log_insert_changes_t_releves_occtax 
        AFTER INSERT ON pr_occtax.t_releves_occtax 
        REFERENCING NEW TABLE AS NEW
        FOR EACH STATEMENT EXECUTE FUNCTION gn_commons.fct_trg_log_changes_on_each_statement();

        CREATE TRIGGER tri_log_update_changes_t_releves_occtax 
        AFTER UPDATE ON pr_occtax.t_releves_occtax 
        REFERENCING NEW TABLE AS NEW
        FOR EACH STATEMENT EXECUTE FUNCTION gn_commons.fct_trg_log_changes_on_each_statement();

        CREATE TRIGGER tri_log_delete_changes_t_releves_occtax 
        AFTER DELETE ON pr_occtax.t_releves_occtax 
        REFERENCING OLD TABLE AS OLD
        FOR EACH STATEMENT EXECUTE FUNCTION gn_commons.fct_trg_log_changes_on_each_statement();
        """
    )

    # trigger log occurrence
    op.execute(
        """
        DROP TRIGGER tri_log_changes_t_occurrences_occtax ON pr_occtax.t_occurrences_occtax;

        CREATE TRIGGER tri_insert_log_changes_t_occurrences_occtax 
        AFTER INSERT ON pr_occtax.t_occurrences_occtax 
        REFERENCING NEW TABLE AS NEW
        FOR EACH STATEMENT EXECUTE FUNCTION gn_commons.fct_trg_log_changes_on_each_statement();

        CREATE TRIGGER tri_update_log_changes_t_occurrences_occtax 
        AFTER UPDATE ON pr_occtax.t_occurrences_occtax 
        REFERENCING NEW TABLE AS NEW
        FOR EACH STATEMENT EXECUTE FUNCTION gn_commons.fct_trg_log_changes_on_each_statement();

        CREATE TRIGGER tri_delete_log_changes_t_occurrences_occtax 
        AFTER DELETE ON pr_occtax.t_occurrences_occtax 
        REFERENCING OLD TABLE AS OLD
        FOR EACH STATEMENT EXECUTE FUNCTION gn_commons.fct_trg_log_changes_on_each_statement();
        """
    )
    # trigger log counting
    op.execute(
        """
        DROP TRIGGER tri_log_changes_cor_counting_occtax ON pr_occtax.cor_counting_occtax;

        CREATE TRIGGER tri_insert_log_changes_cor_counting_occtax 
        AFTER INSERT ON pr_occtax.cor_counting_occtax 
        REFERENCING NEW TABLE AS NEW
        FOR EACH STATEMENT EXECUTE FUNCTION gn_commons.fct_trg_log_changes_on_each_statement();

        CREATE TRIGGER tri_update_log_changes_cor_counting_occtax 
        AFTER UPDATE ON pr_occtax.cor_counting_occtax 
        REFERENCING NEW TABLE AS NEW
        FOR EACH STATEMENT EXECUTE FUNCTION gn_commons.fct_trg_log_changes_on_each_statement();

        CREATE TRIGGER tri_delete_log_changes_cor_counting_occtax 
        AFTER DELETE ON pr_occtax.cor_counting_occtax 
        REFERENCING OLD TABLE AS OLD
        FOR EACH STATEMENT EXECUTE FUNCTION gn_commons.fct_trg_log_changes_on_each_statement();
        """
    )



def downgrade():
    # update releve :
    op.execute(
        """
        DROP TRIGGER tri_update_synthese_t_releve_occtax ON pr_occtax.t_releves_occtax;
        CREATE TRIGGER tri_update_synthese_t_releve_occtax AFTER
        UPDATE ON pr_occtax.t_releves_occtax 
        FOR EACH ROW EXECUTE FUNCTION pr_occtax.fct_tri_synthese_update_releve();

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
            -- take observer_txt only if not null
            observers = COALESCE(NEW.observers_txt, observers),
            id_digitiser = NEW.id_digitiser,
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
            additional_data = NEW.additional_fields || o.additional_fields || c.additional_fields
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

    # update occurrence 
    op.execute(
        """
        DROP TRIGGER tri_update_synthese_t_occurrence_occtax ON pr_occtax.t_occurrences_occtax;
        CREATE TRIGGER tri_update_synthese_t_occurrence_occtax AFTER
        UPDATE ON pr_occtax.t_occurrences_occtax FOR EACH ROW EXECUTE FUNCTION pr_occtax.fct_tri_synthese_update_occ();

        CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_occ()
        RETURNS trigger
        LANGUAGE plpgsql
        AS $function$  declare
                    counting RECORD;
                    releve_add_fields jsonb;
                begin
                    select * into counting from pr_occtax.cor_counting_occtax c where id_occurrence_occtax = new.id_occurrence_occtax;
                    select r.additional_fields into releve_add_fields from pr_occtax.t_releves_occtax r where id_releve_occtax = new.id_releve_occtax;
                    UPDATE gn_synthese.synthese SET
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
                    additional_data = releve_add_fields || NEW.additional_fields || counting.additional_fields
                    WHERE unique_id_sinp = counting.unique_id_sinp_occtax;
                    
                    RETURN NULL;
            END;
            $function$
        ;

        """
    )

    # update counting : 

    op.execute(
        """  
            DROP TRIGGER tri_update_synthese_cor_counting_occtax ON pr_occtax.cor_counting_occtax;
            CREATE TRIGGER tri_update_synthese_cor_counting_occtax AFTER
            UPDATE ON pr_occtax.cor_counting_occtax FOR EACH ROW EXECUTE FUNCTION pr_occtax.fct_tri_synthese_update_counting();

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
                    additional_data = releve.additional_fields || occurrence.additional_fields || NEW.additional_fields
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
    # altitude et geom
    op.execute(
        """
        DROP TRIGGER tri_insert_calculate_geom_local ON pr_occtax.t_releves_occtax;
        DROP TRIGGER tri_update_calculate_geom_local ON pr_occtax.t_releves_occtax;
        CREATE TRIGGER tri_calculate_geom_local BEFORE INSERT OR UPDATE ON
        pr_occtax.t_releves_occtax FOR EACH ROW EXECUTE FUNCTION ref_geo.fct_trg_calculate_geom_local('geom_4326','geom_local');

        DROP TRIGGER tri_insert_calculate_altitude ON pr_occtax.t_releves_occtax;
        DROP TRIGGER tri_update_calculate_altitude ON pr_occtax.t_releves_occtax;
        CREATE TRIGGER tri_calculate_altitude BEFORE INSERT OR UPDATE ON
            pr_occtax.t_releves_occtax FOR EACH ROW EXECUTE FUNCTION ref_geo.fct_trg_calculate_alt_minmax('geom_4326')
        """
    )
    # log releve
    op.execute(
        """
        DROP TRIGGER tri_log_insert_changes_t_releves_occtax ON pr_occtax.t_releves_occtax;
        DROP TRIGGER tri_log_update_changes_t_releves_occtax ON pr_occtax.t_releves_occtax;
        DROP TRIGGER tri_log_delete_changes_t_releves_occtax ON pr_occtax.t_releves_occtax;
        CREATE TRIGGER tri_log_changes_t_releves_occtax AFTER
        INSERT OR DELETE OR UPDATE ON
        pr_occtax.t_releves_occtax FOR EACH ROW EXECUTE FUNCTION gn_commons.fct_trg_log_changes()
        """
    )
    # log occurrence
    op.execute(
        """
        DROP TRIGGER tri_insert_log_changes_t_occurrences_occtax ON pr_occtax.t_occurrences_occtax;
        DROP TRIGGER tri_update_log_changes_t_occurrences_occtax ON pr_occtax.t_occurrences_occtax;
        DROP TRIGGER tri_delete_log_changes_t_occurrences_occtax ON pr_occtax.t_occurrences_occtax;

        CREATE TRIGGER tri_log_changes_t_occurrences_occtax AFTER
        INSERT OR DELETE OR UPDATE ON
        pr_occtax.t_occurrences_occtax FOR EACH ROW EXECUTE FUNCTION gn_commons.fct_trg_log_changes()
        """
    )
    # log counting 
    op.execute(
        """
        DROP TRIGGER tri_insert_log_changes_cor_counting_occtax ON pr_occtax.cor_counting_occtax;
        DROP TRIGGER tri_update_log_changes_cor_counting_occtax ON pr_occtax.cor_counting_occtax;
        DROP TRIGGER tri_delete_log_changes_cor_counting_occtax ON pr_occtax.cor_counting_occtax;
        CREATE TRIGGER tri_log_changes_cor_counting_occtax AFTER
        INSERT OR DELETE OR UPDATE ON
        pr_occtax.cor_counting_occtax FOR EACH ROW EXECUTE FUNCTION gn_commons.fct_trg_log_changes()
        """
    )

