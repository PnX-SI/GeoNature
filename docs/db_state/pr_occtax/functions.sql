CREATE FUNCTION pr_occtax.fct_tri_delete_counting() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;
CREATE FUNCTION pr_occtax.fct_tri_delete_occ() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;
CREATE FUNCTION pr_occtax.fct_tri_synthese_delete_cor_role_releve() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;
CREATE FUNCTION pr_occtax.fct_tri_synthese_delete_counting() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
  -- suppression de l'obs dans le schéma gn_synthese
  DELETE FROM gn_synthese.synthese WHERE unique_id_sinp = OLD.unique_id_sinp_occtax;
  RETURN NULL;
END;
$$;
CREATE FUNCTION pr_occtax.fct_tri_synthese_delete_occ() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
  -- Suppression dans la synthese
    DELETE FROM gn_synthese.synthese WHERE unique_id_sinp IN (
      SELECT unique_id_sinp_occtax FROM pr_occtax.cor_counting_occtax WHERE id_occurrence_occtax = OLD.id_occurrence_occtax 
    );
  RETURN OLD;
END;
$$;
CREATE FUNCTION pr_occtax.fct_tri_synthese_delete_releve() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
    DELETE FROM gn_synthese.synthese WHERE unique_id_sinp IN (
      SELECT unnest(pr_occtax.get_unique_id_sinp_from_id_releve(OLD.id_releve_occtax::integer))
    );
  RETURN OLD;
END;
$$;
CREATE FUNCTION pr_occtax.fct_tri_synthese_insert_cor_role_releve() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;
CREATE FUNCTION pr_occtax.fct_tri_synthese_insert_counting() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
IF myobservers IS NOT NULL THEN
      INSERT INTO gn_synthese.cor_observer_synthese (id_synthese, id_role) 
      SELECT 
        id_synthese,
        unnest(myobservers)
      FROM gn_synthese.synthese WHERE unique_id_sinp = NEW.unique_id_sinp_occtax;
  END IF;
  RETURN NULL;
END;
$$;
CREATE FUNCTION pr_occtax.fct_tri_synthese_update_cor_role_releve() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;
CREATE FUNCTION pr_occtax.fct_tri_synthese_update_counting() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE
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
        $$;

ALTER FUNCTION pr_occtax.fct_tri_synthese_update_counting() OWNER TO geonatadmin;

CREATE FUNCTION pr_occtax.fct_tri_synthese_update_occ() RETURNS trigger
    LANGUAGE plpgsql
    AS $$  declare
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
        $$;

ALTER FUNCTION pr_occtax.fct_tri_synthese_update_occ() OWNER TO geonatadmin;

CREATE FUNCTION pr_occtax.fct_tri_synthese_update_releve() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
                $$;

ALTER FUNCTION pr_occtax.fct_tri_synthese_update_releve() OWNER TO geonatadmin;

CREATE FUNCTION pr_occtax.get_default_nomenclature_value(mytype character varying, myidorganism integer DEFAULT NULL::integer, myregne character varying DEFAULT '0'::character varying, mygroup2inpn character varying DEFAULT '0'::character varying) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE
    AS $$
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
    $$;

ALTER FUNCTION pr_occtax.get_default_nomenclature_value(mytype character varying, myidorganism integer, myregne character varying, mygroup2inpn character varying) OWNER TO geonatadmin;

CREATE FUNCTION pr_occtax.get_id_counting_from_id_releve(my_id_releve integer) RETURNS integer[]
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE the_array_id_counting integer[];
BEGIN
SELECT INTO the_array_id_counting array_agg(counting.id_counting_occtax)
FROM pr_occtax.cor_counting_occtax counting
JOIN pr_occtax.t_occurrences_occtax occ ON occ.id_occurrence_occtax = counting.id_occurrence_occtax
JOIN pr_occtax.t_releves_occtax rel ON rel.id_releve_occtax = occ.id_releve_occtax
WHERE rel.id_releve_occtax = my_id_releve;
RETURN the_array_id_counting;
END;
$$;
CREATE FUNCTION pr_occtax.get_unique_id_sinp_from_id_releve(my_id_releve integer) RETURNS uuid[]
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE the_array_uuid_sinp uuid[];
BEGIN
SELECT INTO the_array_uuid_sinp array_agg(counting.unique_id_sinp_occtax)
FROM pr_occtax.cor_counting_occtax counting
JOIN pr_occtax.t_occurrences_occtax occ ON occ.id_occurrence_occtax = counting.id_occurrence_occtax
JOIN pr_occtax.t_releves_occtax rel ON rel.id_releve_occtax = occ.id_releve_occtax
WHERE rel.id_releve_occtax = my_id_releve;
RETURN the_array_uuid_sinp;
END;
$$;
CREATE FUNCTION pr_occtax.id_releve_from_id_counting(my_id_counting integer) RETURNS SETOF bigint
    LANGUAGE plpgsql IMMUTABLE
    AS $$
begin
  return QUERY select rel.id_releve_occtax
  FROM pr_occtax.t_releves_occtax rel
  JOIN pr_occtax.t_occurrences_occtax occ ON occ.id_releve_occtax = rel.id_releve_occtax
  JOIN pr_occtax.cor_counting_occtax counting ON counting.id_occurrence_occtax = occ.id_occurrence_occtax
  WHERE counting.id_counting_occtax = my_id_counting;
END;
$$;
CREATE FUNCTION pr_occtax.insert_in_synthese(my_id_counting integer) RETURNS integer[]
    LANGUAGE plpgsql
    AS $$  DECLARE
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
            $$;

ALTER FUNCTION pr_occtax.insert_in_synthese(my_id_counting integer) OWNER TO geonatadmin;

SET default_tablespace = '';

SET default_table_access_method = heap;

CREATE TABLE pr_occtax.cor_counting_occtax (
    id_counting_occtax bigint NOT NULL,
    unique_id_sinp_occtax uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_occurrence_occtax bigint NOT NULL,
    id_nomenclature_life_stage integer DEFAULT pr_occtax.get_default_nomenclature_value('STADE_VIE'::character varying) NOT NULL,
    id_nomenclature_sex integer DEFAULT pr_occtax.get_default_nomenclature_value('SEXE'::character varying) NOT NULL,
    id_nomenclature_obj_count integer DEFAULT pr_occtax.get_default_nomenclature_value('OBJ_DENBR'::character varying) NOT NULL,
    id_nomenclature_type_count integer DEFAULT pr_occtax.get_default_nomenclature_value('TYP_DENBR'::character varying),
    count_min integer,
    count_max integer,
    additional_fields jsonb,
    CONSTRAINT check_cor_counting_occtax_count_max CHECK (((count_max >= count_min) AND (count_max >= 0))),
    CONSTRAINT check_cor_counting_occtax_count_min CHECK ((count_min >= 0))
);

ALTER TABLE pr_occtax.cor_counting_occtax OWNER TO geonatadmin;

COMMENT ON COLUMN pr_occtax.cor_counting_occtax.id_nomenclature_life_stage IS 'Correspondance nomenclature INPN = stade_vie (10)';

COMMENT ON COLUMN pr_occtax.cor_counting_occtax.id_nomenclature_sex IS 'Correspondance nomenclature INPN = sexe (9)';

COMMENT ON COLUMN pr_occtax.cor_counting_occtax.id_nomenclature_obj_count IS 'Correspondance nomenclature INPN = obj_denbr (6)';

COMMENT ON COLUMN pr_occtax.cor_counting_occtax.id_nomenclature_type_count IS 'Correspondance nomenclature INPN = typ_denbr (21)';

CREATE SEQUENCE pr_occtax.cor_counting_occtax_id_counting_occtax_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE pr_occtax.cor_counting_occtax_id_counting_occtax_seq OWNER TO geonatadmin;

ALTER SEQUENCE pr_occtax.cor_counting_occtax_id_counting_occtax_seq OWNED BY pr_occtax.cor_counting_occtax.id_counting_occtax;

CREATE TABLE pr_occtax.cor_role_releves_occtax (
    unique_id_cor_role_releve uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_releve_occtax bigint NOT NULL,
    id_role integer NOT NULL
);

ALTER TABLE pr_occtax.cor_role_releves_occtax OWNER TO geonatadmin;

CREATE TABLE pr_occtax.defaults_nomenclatures_value (
    mnemonique_type character varying(255) NOT NULL,
    id_organism integer DEFAULT 0 NOT NULL,
    regne character varying(20) DEFAULT '0'::character varying NOT NULL,
    group2_inpn character varying(255) DEFAULT '0'::character varying NOT NULL,
    id_nomenclature integer NOT NULL
);

ALTER TABLE pr_occtax.defaults_nomenclatures_value OWNER TO geonatadmin;

CREATE TABLE pr_occtax.t_occurrences_occtax (
    id_occurrence_occtax bigint NOT NULL,
    unique_id_occurence_occtax uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_releve_occtax bigint NOT NULL,
    id_nomenclature_obs_technique integer DEFAULT pr_occtax.get_default_nomenclature_value('METH_OBS'::character varying) NOT NULL,
    id_nomenclature_bio_condition integer DEFAULT pr_occtax.get_default_nomenclature_value('ETA_BIO'::character varying) NOT NULL,
    id_nomenclature_bio_status integer DEFAULT pr_occtax.get_default_nomenclature_value('STATUT_BIO'::character varying),
    id_nomenclature_naturalness integer DEFAULT pr_occtax.get_default_nomenclature_value('NATURALITE'::character varying),
    id_nomenclature_exist_proof integer DEFAULT pr_occtax.get_default_nomenclature_value('PREUVE_EXIST'::character varying),
    id_nomenclature_diffusion_level integer,
    id_nomenclature_observation_status integer DEFAULT pr_occtax.get_default_nomenclature_value('STATUT_OBS'::character varying),
    id_nomenclature_blurring integer DEFAULT pr_occtax.get_default_nomenclature_value('DEE_FLOU'::character varying),
    id_nomenclature_source_status integer DEFAULT pr_occtax.get_default_nomenclature_value('STATUT_SOURCE'::character varying),
    id_nomenclature_behaviour integer DEFAULT pr_occtax.get_default_nomenclature_value('OCC_COMPORTEMENT'::character varying),
    determiner character varying(255),
    id_nomenclature_determination_method integer DEFAULT pr_occtax.get_default_nomenclature_value('METH_DETERMIN'::character varying),
    cd_nom integer,
    nom_cite character varying(255) NOT NULL,
    meta_v_taxref character varying(50) DEFAULT 'SELECT gn_commons.get_default_parameter(''taxref_version'')'::character varying,
    sample_number_proof text,
    digital_proof text,
    non_digital_proof text,
    comment character varying,
    additional_fields jsonb
);

ALTER TABLE pr_occtax.t_occurrences_occtax OWNER TO geonatadmin;

COMMENT ON COLUMN pr_occtax.t_occurrences_occtax.id_nomenclature_obs_technique IS 'Correspondance champs standard occtax = obsTechnique. En raison d''un changement de nom, le code nomenclature associé reste ''METH_OBS'' ';

COMMENT ON COLUMN pr_occtax.t_occurrences_occtax.id_nomenclature_bio_condition IS 'Correspondance nomenclature INPN = etat_bio';

COMMENT ON COLUMN pr_occtax.t_occurrences_occtax.id_nomenclature_bio_status IS 'Correspondance nomenclature INPN = statut_bio';

COMMENT ON COLUMN pr_occtax.t_occurrences_occtax.id_nomenclature_naturalness IS 'Correspondance nomenclature INPN = naturalite';

COMMENT ON COLUMN pr_occtax.t_occurrences_occtax.id_nomenclature_exist_proof IS 'Correspondance nomenclature INPN = preuve_exist';

COMMENT ON COLUMN pr_occtax.t_occurrences_occtax.id_nomenclature_diffusion_level IS 'Correspondance nomenclature INPN = niv_precis';

COMMENT ON COLUMN pr_occtax.t_occurrences_occtax.id_nomenclature_observation_status IS 'Correspondance nomenclature INPN = statut_obs';

COMMENT ON COLUMN pr_occtax.t_occurrences_occtax.id_nomenclature_blurring IS 'Correspondance nomenclature INPN = dee_flou';

COMMENT ON COLUMN pr_occtax.t_occurrences_occtax.id_nomenclature_source_status IS 'Correspondance nomenclature INPN = statut_source: id = 19';

COMMENT ON COLUMN pr_occtax.t_occurrences_occtax.id_nomenclature_determination_method IS 'Correspondance nomenclature GEONATURE = meth_determin';

CREATE SEQUENCE pr_occtax.t_occurrences_occtax_id_occurrence_occtax_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE pr_occtax.t_occurrences_occtax_id_occurrence_occtax_seq OWNER TO geonatadmin;

ALTER SEQUENCE pr_occtax.t_occurrences_occtax_id_occurrence_occtax_seq OWNED BY pr_occtax.t_occurrences_occtax.id_occurrence_occtax;

CREATE TABLE pr_occtax.t_releves_occtax (
    id_releve_occtax bigint NOT NULL,
    unique_id_sinp_grp uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_dataset integer NOT NULL,
    id_digitiser integer,
    observers_txt character varying(500),
    id_nomenclature_tech_collect_campanule integer DEFAULT pr_occtax.get_default_nomenclature_value('TECHNIQUE_OBS'::character varying),
    id_nomenclature_grp_typ integer DEFAULT pr_occtax.get_default_nomenclature_value('TYP_GRP'::character varying) NOT NULL,
    grp_method character varying(255),
    date_min timestamp without time zone DEFAULT now() NOT NULL,
    date_max timestamp without time zone DEFAULT now() NOT NULL,
    hour_min time without time zone,
    hour_max time without time zone,
    cd_hab integer,
    altitude_min integer,
    altitude_max integer,
    depth_min integer,
    depth_max integer,
    place_name character varying(500),
    meta_device_entry character varying(20),
    comment text,
    geom_local public.geometry(Geometry,2154),
    geom_4326 public.geometry(Geometry,4326),
    id_nomenclature_geo_object_nature integer DEFAULT pr_occtax.get_default_nomenclature_value('NAT_OBJ_GEO'::character varying),
    "precision" integer,
    additional_fields jsonb,
    id_module integer NOT NULL,
    CONSTRAINT check_t_releves_occtax_altitude_max CHECK ((altitude_max >= altitude_min)),
    CONSTRAINT check_t_releves_occtax_date_max CHECK ((date_max >= date_min)),
    CONSTRAINT check_t_releves_occtax_depth CHECK ((depth_max >= depth_min)),
    CONSTRAINT check_t_releves_occtax_hour_max CHECK (((hour_min <= hour_max) OR (date_min < date_max))),
    CONSTRAINT enforce_dims_geom_4326 CHECK ((public.st_ndims(geom_4326) = 2)),
    CONSTRAINT enforce_dims_geom_local CHECK ((public.st_ndims(geom_local) = 2)),
    CONSTRAINT enforce_srid_geom_4326 CHECK ((public.st_srid(geom_4326) = 4326)),
    CONSTRAINT enforce_srid_geom_local CHECK ((public.st_srid(geom_local) = 2154))
);

ALTER TABLE pr_occtax.t_releves_occtax OWNER TO geonatadmin;

COMMENT ON COLUMN pr_occtax.t_releves_occtax.id_nomenclature_tech_collect_campanule IS 'Correspondance nomenclature CAMPANULE = technique_obs';

COMMENT ON COLUMN pr_occtax.t_releves_occtax.id_nomenclature_grp_typ IS 'Correspondance nomenclature INPN = Type de regroupement';

CREATE SEQUENCE pr_occtax.t_releves_occtax_id_releve_occtax_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE pr_occtax.t_releves_occtax_id_releve_occtax_seq OWNER TO geonatadmin;

ALTER SEQUENCE pr_occtax.t_releves_occtax_id_releve_occtax_seq OWNED BY pr_occtax.t_releves_occtax.id_releve_occtax;

CREATE VIEW pr_occtax.v_export_occtax AS
SELECT
    NULL::uuid AS "idSINPRegroupement",
    NULL::character varying AS "typGrp",
    NULL::character varying(255) AS "methGrp",
    NULL::uuid AS "permId",
    NULL::bigint AS "idOrigine",
    NULL::character varying AS "statObs",
    NULL::character varying(255) AS "nomCite",
    NULL::text AS "dateDebut",
    NULL::text AS "dateFin",
    NULL::time without time zone AS "heureDebut",
    NULL::time without time zone AS "heureFin",
    NULL::integer AS "altMax",
    NULL::integer AS "altMin",
    NULL::integer AS "profMin",
    NULL::integer AS "profMax",
    NULL::integer AS "cdNom",
    NULL::integer AS "cdRef",
    NULL::character varying AS "dSPublique",
    NULL::uuid AS "jddMetaId",
    NULL::character varying AS "statSource",
    NULL::character varying(255) AS "jddCode",
    NULL::uuid AS "jddId",
    NULL::character varying AS "obsTech",
    NULL::character varying AS "techCollect",
    NULL::character varying AS "ocEtatBio",
    NULL::character varying AS "ocNat",
    NULL::character varying AS "ocSex",
    NULL::character varying AS "ocStade",
    NULL::character varying AS "ocStatBio",
    NULL::character varying AS "preuveOui",
    NULL::character varying AS "ocMethDet",
    NULL::character varying AS "occComp",
    NULL::text AS "preuvNum",
    NULL::text AS "preuvNoNum",
    NULL::text AS "obsCtx",
    NULL::character varying AS "obsDescr",
    NULL::uuid AS "permIdGrp",
    NULL::integer AS "denbrMax",
    NULL::integer AS "denbrMin",
    NULL::character varying AS "objDenbr",
    NULL::character varying AS "typDenbr",
    NULL::text AS "obsId",
    NULL::text AS "obsNomOrg",
    NULL::character varying AS "detId",
    NULL::character varying AS "natObjGeo",
    NULL::text AS "WKT",
    NULL::character varying(250) AS "nomScienti",
    NULL::character varying(1000) AS "nomVern",
    NULL::character varying(50) AS "codeHab",
    NULL::character varying(500) AS "nomHab",
    NULL::integer AS cd_hab,
    NULL::timestamp without time zone AS date_min,
    NULL::timestamp without time zone AS date_max,
    NULL::integer AS id_dataset,
    NULL::bigint AS id_releve_occtax,
    NULL::bigint AS id_occurrence_occtax,
    NULL::integer AS id_digitiser,
    NULL::public.geometry(Geometry,4326) AS geom_4326,
    NULL::character varying(500) AS "nomLieu",
    NULL::integer AS "precision",
    NULL::jsonb AS additional_data;

ALTER VIEW pr_occtax.v_export_occtax OWNER TO geonatadmin;

ALTER TABLE ONLY pr_occtax.cor_counting_occtax ALTER COLUMN id_counting_occtax SET DEFAULT nextval('pr_occtax.cor_counting_occtax_id_counting_occtax_seq'::regclass);

ALTER TABLE ONLY pr_occtax.t_occurrences_occtax ALTER COLUMN id_occurrence_occtax SET DEFAULT nextval('pr_occtax.t_occurrences_occtax_id_occurrence_occtax_seq'::regclass);

ALTER TABLE ONLY pr_occtax.t_releves_occtax ALTER COLUMN id_releve_occtax SET DEFAULT nextval('pr_occtax.t_releves_occtax_id_releve_occtax_seq'::regclass);

ALTER TABLE pr_occtax.cor_counting_occtax
    ADD CONSTRAINT check_cor_counting_occtax_life_stage CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_life_stage, 'STADE_VIE'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.cor_counting_occtax
    ADD CONSTRAINT check_cor_counting_occtax_obj_count CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_obj_count, 'OBJ_DENBR'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.cor_counting_occtax
    ADD CONSTRAINT check_cor_counting_occtax_sexe CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_sex, 'SEXE'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.cor_counting_occtax
    ADD CONSTRAINT check_cor_counting_occtax_type_count CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_type_count, 'TYP_DENBR'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.defaults_nomenclatures_value
    ADD CONSTRAINT check_pr_occtax_defaults_nomenclatures_value_is_nomenclature_in CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature, mnemonique_type)) NOT VALID;

ALTER TABLE pr_occtax.defaults_nomenclatures_value
    ADD CONSTRAINT check_pr_occtax_defaults_nomenclatures_value_isgroup2inpn CHECK ((taxonomie.check_is_group2inpn((group2_inpn)::text) OR ((group2_inpn)::text = '0'::text))) NOT VALID;

ALTER TABLE pr_occtax.defaults_nomenclatures_value
    ADD CONSTRAINT check_pr_occtax_defaults_nomenclatures_value_isregne CHECK ((taxonomie.check_is_regne((regne)::text) OR ((regne)::text = '0'::text))) NOT VALID;

ALTER TABLE pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT check_t_occurrences_occtax_accur_level CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_diffusion_level, 'NIV_PRECIS'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT check_t_occurrences_occtax_behaviour CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_behaviour, 'OCC_COMPORTEMENT'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT check_t_occurrences_occtax_bio_condition CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_bio_condition, 'ETA_BIO'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT check_t_occurrences_occtax_bio_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_bio_status, 'STATUT_BIO'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT check_t_occurrences_occtax_blurring CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_blurring, 'DEE_FLOU'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT check_t_occurrences_occtax_determination_method CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_determination_method, 'METH_DETERMIN'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT check_t_occurrences_occtax_exist_proof CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_exist_proof, 'PREUVE_EXIST'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT check_t_occurrences_occtax_naturalness CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_naturalness, 'NATURALITE'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT check_t_occurrences_occtax_obs_meth CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_obs_technique, 'METH_OBS'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT check_t_occurrences_occtax_obs_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_observation_status, 'STATUT_OBS'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT check_t_occurrences_occtax_source_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_source_status, 'STATUT_SOURCE'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.t_releves_occtax
    ADD CONSTRAINT check_t_releves_occtax_geo_object_nature CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_geo_object_nature, 'NAT_OBJ_GEO'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.t_releves_occtax
    ADD CONSTRAINT check_t_releves_occtax_obs_technique CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_tech_collect_campanule, 'TECHNIQUE_OBS'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.t_releves_occtax
    ADD CONSTRAINT check_t_releves_occtax_regroupement_typ CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_grp_typ, 'TYP_GRP'::character varying)) NOT VALID;

ALTER TABLE ONLY pr_occtax.cor_counting_occtax
    ADD CONSTRAINT pk_cor_counting_occtax_occtax PRIMARY KEY (id_counting_occtax);

ALTER TABLE ONLY pr_occtax.cor_role_releves_occtax
    ADD CONSTRAINT pk_cor_role_releves_occtax PRIMARY KEY (id_releve_occtax, id_role);

ALTER TABLE ONLY pr_occtax.defaults_nomenclatures_value
    ADD CONSTRAINT pk_pr_occtax_defaults_nomenclatures_value PRIMARY KEY (mnemonique_type, id_organism, regne, group2_inpn);

ALTER TABLE ONLY pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT pk_t_occurrences_occtax PRIMARY KEY (id_occurrence_occtax);

ALTER TABLE ONLY pr_occtax.t_releves_occtax
    ADD CONSTRAINT pk_t_releves_occtax PRIMARY KEY (id_releve_occtax);

ALTER TABLE ONLY pr_occtax.cor_counting_occtax
    ADD CONSTRAINT unique_id_sinp_occtax_unique UNIQUE (unique_id_sinp_occtax);

CREATE INDEX i_cor_counting_occtax_id_nomenclature_life_stage ON pr_occtax.cor_counting_occtax USING btree (id_nomenclature_life_stage);

CREATE INDEX i_cor_counting_occtax_id_nomenclature_obj_count ON pr_occtax.cor_counting_occtax USING btree (id_nomenclature_obj_count);

CREATE INDEX i_cor_counting_occtax_id_nomenclature_sex ON pr_occtax.cor_counting_occtax USING btree (id_nomenclature_sex);

CREATE INDEX i_cor_counting_occtax_id_nomenclature_type_count ON pr_occtax.cor_counting_occtax USING btree (id_nomenclature_type_count);

CREATE INDEX i_cor_counting_occtax_id_occurrence_occtax ON pr_occtax.cor_counting_occtax USING btree (id_occurrence_occtax);

CREATE INDEX i_cor_role_releves_occtax_id_releve_occtax ON pr_occtax.cor_role_releves_occtax USING btree (id_releve_occtax);

CREATE INDEX i_cor_role_releves_occtax_id_role ON pr_occtax.cor_role_releves_occtax USING btree (id_role);

CREATE UNIQUE INDEX i_cor_role_releves_occtax_id_role_id_releve_occtax ON pr_occtax.cor_role_releves_occtax USING btree (id_role, id_releve_occtax);

CREATE INDEX i_t_occurrences_occtax_cd_nom ON pr_occtax.t_occurrences_occtax USING btree (cd_nom);

CREATE INDEX i_t_occurrences_occtax_id_nomenclature_bio_condition ON pr_occtax.t_occurrences_occtax USING btree (id_nomenclature_bio_condition);

CREATE INDEX i_t_occurrences_occtax_id_nomenclature_bio_status ON pr_occtax.t_occurrences_occtax USING btree (id_nomenclature_bio_status);

CREATE INDEX i_t_occurrences_occtax_id_nomenclature_blurring ON pr_occtax.t_occurrences_occtax USING btree (id_nomenclature_blurring);

CREATE INDEX i_t_occurrences_occtax_id_nomenclature_determination_method ON pr_occtax.t_occurrences_occtax USING btree (id_nomenclature_determination_method);

CREATE INDEX i_t_occurrences_occtax_id_nomenclature_exist_proof ON pr_occtax.t_occurrences_occtax USING btree (id_nomenclature_exist_proof);

CREATE INDEX i_t_occurrences_occtax_id_nomenclature_naturalness ON pr_occtax.t_occurrences_occtax USING btree (id_nomenclature_naturalness);

CREATE INDEX i_t_occurrences_occtax_id_nomenclature_obs_technique ON pr_occtax.t_occurrences_occtax USING btree (id_nomenclature_obs_technique);

CREATE INDEX i_t_occurrences_occtax_id_nomenclature_observation_status ON pr_occtax.t_occurrences_occtax USING btree (id_nomenclature_observation_status);

CREATE INDEX i_t_occurrences_occtax_id_nomenclature_source_status ON pr_occtax.t_occurrences_occtax USING btree (id_nomenclature_source_status);

CREATE INDEX i_t_occurrences_occtax_id_releve_occtax ON pr_occtax.t_occurrences_occtax USING btree (id_releve_occtax);

CREATE INDEX i_t_releves_occtax_date_max ON pr_occtax.t_releves_occtax USING btree (date_max);

CREATE INDEX i_t_releves_occtax_geom_4326 ON pr_occtax.t_releves_occtax USING gist (geom_4326);

CREATE INDEX i_t_releves_occtax_geom_local ON pr_occtax.t_releves_occtax USING gist (geom_local);

CREATE INDEX i_t_releves_occtax_id_dataset ON pr_occtax.t_releves_occtax USING btree (id_dataset);

CREATE INDEX i_t_releves_occtax_id_nomenclature_grp_typ ON pr_occtax.t_releves_occtax USING btree (id_nomenclature_grp_typ);

CREATE INDEX i_t_releves_occtax_id_nomenclature_tech_collect_campanule ON pr_occtax.t_releves_occtax USING btree (id_nomenclature_tech_collect_campanule);

CREATE OR REPLACE VIEW pr_occtax.v_export_occtax AS
 SELECT rel.unique_id_sinp_grp AS "idSINPRegroupement",
    ref_nomenclatures.get_cd_nomenclature(rel.id_nomenclature_grp_typ) AS "typGrp",
    rel.grp_method AS "methGrp",
    ccc.unique_id_sinp_occtax AS "permId",
    ccc.id_counting_occtax AS "idOrigine",
    ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_observation_status) AS "statObs",
    occ.nom_cite AS "nomCite",
    to_char(rel.date_min, 'YYYY-MM-DD'::text) AS "dateDebut",
    to_char(rel.date_max, 'YYYY-MM-DD'::text) AS "dateFin",
    rel.hour_min AS "heureDebut",
    rel.hour_max AS "heureFin",
    rel.altitude_max AS "altMax",
    rel.altitude_min AS "altMin",
    rel.depth_min AS "profMin",
    rel.depth_max AS "profMax",
    occ.cd_nom AS "cdNom",
    tax.cd_ref AS "cdRef",
    ref_nomenclatures.get_nomenclature_label(d.id_nomenclature_data_origin) AS "dSPublique",
    d.unique_dataset_id AS "jddMetaId",
    ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_source_status) AS "statSource",
    d.dataset_name AS "jddCode",
    d.unique_dataset_id AS "jddId",
    ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_obs_technique) AS "obsTech",
    ref_nomenclatures.get_nomenclature_label(rel.id_nomenclature_tech_collect_campanule) AS "techCollect",
    ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_bio_condition) AS "ocEtatBio",
    ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_naturalness) AS "ocNat",
    ref_nomenclatures.get_nomenclature_label(ccc.id_nomenclature_sex) AS "ocSex",
    ref_nomenclatures.get_nomenclature_label(ccc.id_nomenclature_life_stage) AS "ocStade",
    ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_bio_status) AS "ocStatBio",
    ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_exist_proof) AS "preuveOui",
    ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_determination_method) AS "ocMethDet",
    ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_behaviour) AS "occComp",
    occ.digital_proof AS "preuvNum",
    occ.non_digital_proof AS "preuvNoNum",
    rel.comment AS "obsCtx",
    occ.comment AS "obsDescr",
    rel.unique_id_sinp_grp AS "permIdGrp",
    ccc.count_max AS "denbrMax",
    ccc.count_min AS "denbrMin",
    ref_nomenclatures.get_nomenclature_label(ccc.id_nomenclature_obj_count) AS "objDenbr",
    ref_nomenclatures.get_nomenclature_label(ccc.id_nomenclature_type_count) AS "typDenbr",
    COALESCE(string_agg(DISTINCT (((r.nom_role)::text || ' '::text) || (r.prenom_role)::text), ','::text), (rel.observers_txt)::text) AS "obsId",
    COALESCE(string_agg(DISTINCT (o.nom_organisme)::text, ','::text), 'NSP'::text) AS "obsNomOrg",
    COALESCE(occ.determiner, 'Inconnu'::character varying) AS "detId",
    ref_nomenclatures.get_nomenclature_label(rel.id_nomenclature_geo_object_nature) AS "natObjGeo",
    public.st_astext(rel.geom_4326) AS "WKT",
    tax.lb_nom AS "nomScienti",
    tax.nom_vern AS "nomVern",
    hab.lb_code AS "codeHab",
    hab.lb_hab_fr AS "nomHab",
    hab.cd_hab,
    rel.date_min,
    rel.date_max,
    rel.id_dataset,
    rel.id_releve_occtax,
    occ.id_occurrence_occtax,
    rel.id_digitiser,
    rel.geom_4326,
    rel.place_name AS "nomLieu",
    rel."precision",
    ((COALESCE(rel.additional_fields, '{}'::jsonb) || COALESCE(occ.additional_fields, '{}'::jsonb)) || COALESCE(ccc.additional_fields, '{}'::jsonb)) AS additional_data
   FROM ((((((((pr_occtax.t_releves_occtax rel
     LEFT JOIN pr_occtax.t_occurrences_occtax occ ON ((rel.id_releve_occtax = occ.id_releve_occtax)))
     LEFT JOIN pr_occtax.cor_counting_occtax ccc ON ((ccc.id_occurrence_occtax = occ.id_occurrence_occtax)))
     LEFT JOIN taxonomie.taxref tax ON ((tax.cd_nom = occ.cd_nom)))
     LEFT JOIN gn_meta.t_datasets d ON ((d.id_dataset = rel.id_dataset)))
     LEFT JOIN pr_occtax.cor_role_releves_occtax cr ON ((cr.id_releve_occtax = rel.id_releve_occtax)))
     LEFT JOIN utilisateurs.t_roles r ON ((r.id_role = cr.id_role)))
     LEFT JOIN utilisateurs.bib_organismes o ON ((o.id_organisme = r.id_organisme)))
     LEFT JOIN ref_habitats.habref hab ON ((hab.cd_hab = rel.cd_hab)))
  GROUP BY ccc.id_counting_occtax, occ.id_occurrence_occtax, rel.id_releve_occtax, d.id_dataset, tax.cd_ref, tax.lb_nom, tax.nom_vern, hab.cd_hab, hab.lb_code, hab.lb_hab_fr;

CREATE TRIGGER tri_calculate_altitude BEFORE INSERT OR UPDATE OF geom_4326 ON pr_occtax.t_releves_occtax FOR EACH ROW EXECUTE FUNCTION ref_geo.fct_trg_calculate_alt_minmax('geom_4326');

CREATE TRIGGER tri_calculate_geom_local BEFORE INSERT OR UPDATE OF geom_4326 ON pr_occtax.t_releves_occtax FOR EACH ROW EXECUTE FUNCTION ref_geo.fct_trg_calculate_geom_local('geom_4326', 'geom_local');

CREATE TRIGGER tri_delete_cor_counting_occtax AFTER DELETE ON pr_occtax.cor_counting_occtax FOR EACH ROW EXECUTE FUNCTION pr_occtax.fct_tri_delete_counting();

CREATE TRIGGER tri_delete_synthese_cor_counting_occtax AFTER DELETE ON pr_occtax.cor_counting_occtax FOR EACH ROW EXECUTE FUNCTION pr_occtax.fct_tri_synthese_delete_counting();

CREATE TRIGGER tri_delete_synthese_cor_role_releves_occtax AFTER DELETE ON pr_occtax.cor_role_releves_occtax FOR EACH ROW EXECUTE FUNCTION pr_occtax.fct_tri_synthese_delete_cor_role_releve();

CREATE TRIGGER tri_delete_synthese_t_occurrence_occtax AFTER DELETE ON pr_occtax.t_occurrences_occtax FOR EACH ROW EXECUTE FUNCTION pr_occtax.fct_tri_synthese_delete_occ();

CREATE TRIGGER tri_delete_synthese_t_releve_occtax AFTER DELETE ON pr_occtax.t_releves_occtax FOR EACH ROW EXECUTE FUNCTION pr_occtax.fct_tri_synthese_delete_releve();

CREATE TRIGGER tri_delete_t_occurrence_occtax AFTER DELETE ON pr_occtax.t_occurrences_occtax FOR EACH ROW EXECUTE FUNCTION pr_occtax.fct_tri_delete_occ();

CREATE TRIGGER tri_insert_default_validation_status AFTER INSERT ON pr_occtax.cor_counting_occtax FOR EACH ROW EXECUTE FUNCTION gn_commons.fct_trg_add_default_validation_status();

CREATE TRIGGER tri_insert_synthese_cor_counting_occtax AFTER INSERT ON pr_occtax.cor_counting_occtax FOR EACH ROW EXECUTE FUNCTION pr_occtax.fct_tri_synthese_insert_counting();

CREATE TRIGGER tri_log_changes_cor_counting_occtax AFTER INSERT OR DELETE OR UPDATE ON pr_occtax.cor_counting_occtax FOR EACH ROW EXECUTE FUNCTION gn_commons.fct_trg_log_changes();

CREATE TRIGGER tri_log_changes_cor_role_releves_occtax AFTER INSERT OR DELETE OR UPDATE ON pr_occtax.cor_role_releves_occtax FOR EACH ROW EXECUTE FUNCTION gn_commons.fct_trg_log_changes();

CREATE TRIGGER tri_log_changes_t_occurrences_occtax AFTER INSERT OR DELETE OR UPDATE ON pr_occtax.t_occurrences_occtax FOR EACH ROW EXECUTE FUNCTION gn_commons.fct_trg_log_changes();

CREATE TRIGGER tri_log_changes_t_releves_occtax AFTER INSERT OR DELETE OR UPDATE ON pr_occtax.t_releves_occtax FOR EACH ROW EXECUTE FUNCTION gn_commons.fct_trg_log_changes();

CREATE TRIGGER tri_synthese_insert_cor_role_releve AFTER INSERT ON pr_occtax.cor_role_releves_occtax FOR EACH ROW EXECUTE FUNCTION pr_occtax.fct_tri_synthese_insert_cor_role_releve();

CREATE TRIGGER tri_update_synthese_cor_counting_occtax AFTER UPDATE ON pr_occtax.cor_counting_occtax FOR EACH ROW EXECUTE FUNCTION pr_occtax.fct_tri_synthese_update_counting();

CREATE TRIGGER tri_update_synthese_cor_role_releves_occtax AFTER UPDATE ON pr_occtax.cor_role_releves_occtax FOR EACH ROW EXECUTE FUNCTION pr_occtax.fct_tri_synthese_update_cor_role_releve();

CREATE TRIGGER tri_update_synthese_t_occurrence_occtax AFTER UPDATE ON pr_occtax.t_occurrences_occtax FOR EACH ROW EXECUTE FUNCTION pr_occtax.fct_tri_synthese_update_occ();

CREATE TRIGGER tri_update_synthese_t_releve_occtax AFTER UPDATE ON pr_occtax.t_releves_occtax FOR EACH ROW EXECUTE FUNCTION pr_occtax.fct_tri_synthese_update_releve();

ALTER TABLE ONLY pr_occtax.cor_counting_occtax
    ADD CONSTRAINT fk_cor_counting_occtax_life_stage FOREIGN KEY (id_nomenclature_life_stage) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.cor_counting_occtax
    ADD CONSTRAINT fk_cor_counting_occtax_obj_count FOREIGN KEY (id_nomenclature_obj_count) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.cor_counting_occtax
    ADD CONSTRAINT fk_cor_counting_occtax_sexe FOREIGN KEY (id_nomenclature_sex) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.cor_counting_occtax
    ADD CONSTRAINT fk_cor_counting_occtax_typ_count FOREIGN KEY (id_nomenclature_type_count) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.cor_role_releves_occtax
    ADD CONSTRAINT fk_cor_role_releves_occtax_t_releves_occtax FOREIGN KEY (id_releve_occtax) REFERENCES pr_occtax.t_releves_occtax(id_releve_occtax) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY pr_occtax.cor_role_releves_occtax
    ADD CONSTRAINT fk_cor_role_releves_occtax_t_roles FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.cor_counting_occtax
    ADD CONSTRAINT fk_cor_stage_number_id_taxon FOREIGN KEY (id_occurrence_occtax) REFERENCES pr_occtax.t_occurrences_occtax(id_occurrence_occtax) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY pr_occtax.t_releves_occtax
    ADD CONSTRAINT fk_id_module FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules(id_module) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.defaults_nomenclatures_value
    ADD CONSTRAINT fk_pr_occtax_defaults_nomenclatures_value_id_nomenclature FOREIGN KEY (id_nomenclature) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.defaults_nomenclatures_value
    ADD CONSTRAINT fk_pr_occtax_defaults_nomenclatures_value_id_organism FOREIGN KEY (id_organism) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.defaults_nomenclatures_value
    ADD CONSTRAINT fk_pr_occtax_defaults_nomenclatures_value_mnemonique_type FOREIGN KEY (mnemonique_type) REFERENCES ref_nomenclatures.bib_nomenclatures_types(mnemonique) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_behaviour FOREIGN KEY (id_nomenclature_behaviour) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_bio_condition FOREIGN KEY (id_nomenclature_bio_condition) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_bio_status FOREIGN KEY (id_nomenclature_bio_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_blurring FOREIGN KEY (id_nomenclature_blurring) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_determination_method FOREIGN KEY (id_nomenclature_determination_method) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_diffusion_level FOREIGN KEY (id_nomenclature_diffusion_level) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_exist_proof FOREIGN KEY (id_nomenclature_exist_proof) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_naturalness FOREIGN KEY (id_nomenclature_naturalness) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_obs_meth FOREIGN KEY (id_nomenclature_obs_technique) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_observation_status FOREIGN KEY (id_nomenclature_observation_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_source_status FOREIGN KEY (id_nomenclature_source_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_t_releves_occtax FOREIGN KEY (id_releve_occtax) REFERENCES pr_occtax.t_releves_occtax(id_releve_occtax) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_taxref FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_releves_occtax
    ADD CONSTRAINT fk_t_releves_occtax_cd_hab FOREIGN KEY (cd_hab) REFERENCES ref_habitats.habref(cd_hab) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_releves_occtax
    ADD CONSTRAINT fk_t_releves_occtax_id_nomenclature_geo_object_nature FOREIGN KEY (id_nomenclature_geo_object_nature) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_releves_occtax
    ADD CONSTRAINT fk_t_releves_occtax_obs_technique_campanule FOREIGN KEY (id_nomenclature_tech_collect_campanule) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_releves_occtax
    ADD CONSTRAINT fk_t_releves_occtax_regroupement_typ FOREIGN KEY (id_nomenclature_grp_typ) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_releves_occtax
    ADD CONSTRAINT fk_t_releves_occtax_t_datasets FOREIGN KEY (id_dataset) REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_releves_occtax
    ADD CONSTRAINT fk_t_releves_occtax_t_roles FOREIGN KEY (id_digitiser) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

