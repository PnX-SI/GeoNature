CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_delete_counting()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
  nb_counting integer;
BEGIN
  -- suppression de l'occurrence s'il n'y a plus de dénomenbrement
  SELECT INTO nb_counting count(*) FROM pr_occtax.cor_counting_occtax WHERE id_occurrence_occtax = OLD.id_occurrence_occtax;
  IF nb_counting < 1 THEN
    DELETE FROM pr_occtax.t_occurrences_occtax WHERE id_occurrence_occtax = OLD.id_occurrence_occtax;
  END IF;
  RETURN NULL;
END;
$function$

CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_delete_occ()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
nb_occ integer;
BEGIN
  -- suppression du releve s'il n'y a plus d'occurrence
  SELECT INTO nb_occ count(*) FROM pr_occtax.t_occurrences_occtax WHERE id_releve_occtax = OLD.id_releve_occtax;
  IF nb_occ < 1 THEN
    DELETE FROM pr_occtax.t_releves_occtax WHERE id_releve_occtax = OLD.id_releve_occtax;
  END IF;

  RETURN OLD;
END;
$function$

CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_delete_cor_role_releve()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
  uuids_counting  uuid[];
BEGIN
  -- Récupération des id_counting à partir de l'id_releve
  SELECT INTO uuids_counting pr_occtax.get_unique_id_sinp_from_id_releve(OLD.id_releve_occtax::integer);
  IF uuids_counting IS NOT NULL THEN
      -- Suppression des enregistrements dans cor_observer_synthese
      DELETE FROM gn_synthese.cor_observer_synthese
      WHERE id_role = OLD.id_role 
      AND id_synthese IN (
          SELECT id_synthese 
          FROM gn_synthese.synthese
          WHERE unique_id_sinp IN (SELECT unnest(uuids_counting))
      );
  END IF;
RETURN NULL;
END;
$function$

CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_delete_counting()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
BEGIN
  -- suppression de l'obs dans le schéma gn_synthese
  DELETE FROM gn_synthese.synthese WHERE unique_id_sinp = OLD.unique_id_sinp_occtax;
  RETURN NULL;
END;
$function$

CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_delete_occ()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
BEGIN
  -- Suppression dans la synthese
    DELETE FROM gn_synthese.synthese WHERE unique_id_sinp IN (
      SELECT unique_id_sinp_occtax FROM pr_occtax.cor_counting_occtax WHERE id_occurrence_occtax = OLD.id_occurrence_occtax 
    );
  RETURN OLD;
END;
$function$

CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_delete_releve()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
BEGIN
    DELETE FROM gn_synthese.synthese WHERE unique_id_sinp IN (
      SELECT unnest(pr_occtax.get_unique_id_sinp_from_id_releve(OLD.id_releve_occtax::integer))
    );
  RETURN OLD;
END;
$function$

CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_insert_cor_role_releve()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
  uuids_counting  uuid[];
BEGIN
  -- Récupération des id_counting à partir de l'id_releve
  SELECT INTO uuids_counting pr_occtax.get_unique_id_sinp_from_id_releve(NEW.id_releve_occtax::integer);
  -- a l'insertion d'un relevé les uuid countin ne sont pas existants
  -- ce trigger se declenche à l'edition d'un releve
  IF uuids_counting IS NOT NULL THEN
      -- Insertion dans cor_observer_synthese pour chaque counting
      INSERT INTO gn_synthese.cor_observer_synthese(id_synthese, id_role) 
      SELECT id_synthese, NEW.id_role 
      FROM gn_synthese.synthese 
      WHERE unique_id_sinp IN(SELECT unnest(uuids_counting));
  END IF;
RETURN NULL;
END;
$function$

CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_insert_counting()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
  myobservers integer[];
  the_id_releve integer;
BEGIN
  -- recupération de l'id_releve_occtax
  SELECT INTO the_id_releve pr_occtax.id_releve_from_id_counting(NEW.id_counting_occtax::integer);
  -- recupération des observateurs
  SELECT INTO myobservers array_agg(id_role)
  FROM pr_occtax.cor_role_releves_occtax
  WHERE id_releve_occtax = the_id_releve;
  -- insertion en synthese du counting + occ + releve
  PERFORM pr_occtax.insert_in_synthese(NEW.id_counting_occtax::integer);
-- INSERTION DANS COR_ROLE_SYNTHESE
IF myobservers IS NOT NULL THEN
      INSERT INTO gn_synthese.cor_observer_synthese (id_synthese, id_role) 
      SELECT 
        id_synthese,
        unnest(myobservers)
      FROM gn_synthese.synthese WHERE unique_id_sinp = NEW.unique_id_sinp_occtax;
  END IF;
  RETURN NULL;
END;
$function$

CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_cor_role_releve()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
  uuids_counting  uuid[];
BEGIN
  -- Récupération des id_counting à partir de l'id_releve
  SELECT INTO uuids_counting pr_occtax.get_unique_id_sinp_from_id_releve(NEW.id_releve_occtax::integer);
  IF uuids_counting IS NOT NULL THEN
      UPDATE gn_synthese.cor_observer_synthese SET
        id_role = NEW.id_role
      WHERE id_role = OLD.id_role
      AND id_synthese IN (
          SELECT id_synthese 
          FROM gn_synthese.synthese
          WHERE unique_id_sinp IN (SELECT unnest(uuids_counting))
      );
  END IF;
RETURN NULL;
END;
$function$

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
        $function$

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
                    id_source = (SELECT id_source FROM gn_synthese.t_sources WHERE id_module = NEW.id_module),
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
                    additional_data = COALESCE(NEW.additional_fields, '{}'::jsonb) || COALESCE(o.additional_fields, '{}'::jsonb) || COALESCE(c.additional_fields, '{}'::jsonb),
                    cd_hab = NEW.cd_hab
                    FROM pr_occtax.cor_counting_occtax c
                    INNER JOIN pr_occtax.t_occurrences_occtax o ON c.id_occurrence_occtax = o.id_occurrence_occtax
                    WHERE c.unique_id_sinp_occtax = s.unique_id_sinp
                        AND s.unique_id_sinp IN (SELECT unnest(pr_occtax.get_unique_id_sinp_from_id_releve(NEW.id_releve_occtax::integer)));

                RETURN NULL;
                END;
                $function$

CREATE OR REPLACE FUNCTION pr_occtax.get_default_nomenclature_value(mytype character varying, myidorganism integer DEFAULT NULL::integer, myregne character varying DEFAULT '0'::character varying, mygroup2inpn character varying DEFAULT '0'::character varying)
 RETURNS integer
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
    --Function that return the default nomenclature id with wanteds nomenclature type, organism id, regne, group2_inpn
    --Return NULL if nothing matche with given parameters
      DECLARE
        thenomenclatureid integer;
      BEGIN
          SELECT INTO thenomenclatureid id_nomenclature FROM (
                SELECT
                    id_nomenclature,
                    regne,
                    group2_inpn,
                    CASE
                        WHEN n.id_organism = myidorganism THEN 1
                        ELSE 0
                    END prio_organisme
                FROM pr_occtax.defaults_nomenclatures_value n
                JOIN utilisateurs.bib_organismes o
                ON o.id_organisme = n.id_organism
                WHERE mnemonique_type = mytype
                AND (n.id_organism = myidorganism OR n.id_organism = NULL OR o.nom_organisme = 'ALL')
                AND (regne = myregne OR regne = '0')
                AND (group2_inpn = mygroup2inpn OR group2_inpn = '0')
            ) AS defaults_nomenclatures_value
            ORDER BY group2_inpn DESC, regne DESC, prio_organisme DESC LIMIT 1;
            RETURN thenomenclatureid;
      END;
    $function$

CREATE OR REPLACE FUNCTION pr_occtax.get_id_counting_from_id_releve(my_id_releve integer)
 RETURNS integer[]
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
-- Function which return the id_countings in an array (table pr_occtax.cor_counting_occtax) from the id_releve(integer)
DECLARE the_array_id_counting integer[];
BEGIN
SELECT INTO the_array_id_counting array_agg(counting.id_counting_occtax)
FROM pr_occtax.cor_counting_occtax counting
JOIN pr_occtax.t_occurrences_occtax occ ON occ.id_occurrence_occtax = counting.id_occurrence_occtax
JOIN pr_occtax.t_releves_occtax rel ON rel.id_releve_occtax = occ.id_releve_occtax
WHERE rel.id_releve_occtax = my_id_releve;
RETURN the_array_id_counting;
END;
$function$

CREATE OR REPLACE FUNCTION pr_occtax.get_unique_id_sinp_from_id_releve(my_id_releve integer)
 RETURNS uuid[]
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
-- Function which return the unique_id_sinp_occtax in an array (table pr_occtax.cor_counting_occtax) from the id_releve(integer)
DECLARE the_array_uuid_sinp uuid[];
BEGIN
SELECT INTO the_array_uuid_sinp array_agg(counting.unique_id_sinp_occtax)
FROM pr_occtax.cor_counting_occtax counting
JOIN pr_occtax.t_occurrences_occtax occ ON occ.id_occurrence_occtax = counting.id_occurrence_occtax
JOIN pr_occtax.t_releves_occtax rel ON rel.id_releve_occtax = occ.id_releve_occtax
WHERE rel.id_releve_occtax = my_id_releve;
RETURN the_array_uuid_sinp;
END;
$function$

CREATE OR REPLACE FUNCTION pr_occtax.id_releve_from_id_counting(my_id_counting integer)
 RETURNS SETOF bigint
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
-- Function which return the id_countings in an array (table pr_occtax.cor_counting_occtax) from the id_releve(integer)
begin
  return QUERY select rel.id_releve_occtax
  FROM pr_occtax.t_releves_occtax rel
  JOIN pr_occtax.t_occurrences_occtax occ ON occ.id_releve_occtax = rel.id_releve_occtax
  JOIN pr_occtax.cor_counting_occtax counting ON counting.id_occurrence_occtax = occ.id_occurrence_occtax
  WHERE counting.id_counting_occtax = my_id_counting;
END;
$function$

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
            SELECT INTO id_source s.id_source FROM gn_synthese.t_sources s WHERE id_module = releve.id_module;

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
            $function$

