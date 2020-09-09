 DO $$
   BEGIN
    IF (
        SELECT count(*)
        FROM information_schema.view_column_usage
        WHERE table_name = 'synthese' AND table_schema = 'gn_synthese' AND column_name = 'id_nomenclature_obs_technique'
        AND NOT view_schema || '.' || view_name IN (
            'gn_synthese.v_synthese_for_export',
            'pr_occtax.v_releve_occtax',
            'gn_synthese.v_synthese_decode_nomenclatures',
            'gn_synthese.v_synthese_for_web_app',
            'gn_commons.v_synthese_validation_forwebapp'
          )
        ) > 0
    THEN
        RAISE EXCEPTION 'Des vues doivent supprimées puis recrééer avant de relancer le script car elles dépendent de la colonne id_nomenclature_obs_technique ';
    ELSE
        CREATE OR REPLACE FUNCTION gn_sensitivity.get_id_nomenclature_sensitivity(my_date_obs date, my_cd_ref integer, my_geom geometry, my_criterias jsonb)
        RETURNS integer
        LANGUAGE plpgsql
        IMMUTABLE
        AS $function$
        DECLARE
            niv_precis integer;
            niv_precis_null integer;
        BEGIN

            niv_precis_null := (SELECT ref_nomenclatures.get_id_nomenclature('SENSIBILITE'::text, '0'::text));

            -- ##########################################
            -- TESTS unicritère
            --    => Permet de voir si un critère est remplis ou non de façon à limiter au maximum
            --      la requete globale qui croise l'ensemble des critères
            -- ##########################################

            -- Paramètres cd_ref
            IF NOT EXISTS (
                SELECT 1
                FROM gn_sensitivity.t_sensitivity_rules_cd_ref s
                WHERE s.cd_ref = my_cd_ref
            ) THEN
                return niv_precis_null;
            END IF;

            -- Paramètres durée de validité de la règle
            IF NOT EXISTS (
                SELECT 1
                FROM gn_sensitivity.t_sensitivity_rules_cd_ref s
                WHERE s.cd_ref = my_cd_ref
                AND (date_part('year', CURRENT_TIMESTAMP) - sensitivity_duration) <= date_part('year', my_date_obs)
            ) THEN
                return niv_precis_null;
            END IF;

            -- Paramètres période d'observation
            IF NOT EXISTS (
                SELECT 1
                FROM gn_sensitivity.t_sensitivity_rules_cd_ref s
                WHERE s.cd_ref = my_cd_ref
                AND (to_char(my_date_obs, 'MMDD') between to_char(s.date_min, 'MMDD') and to_char(s.date_max, 'MMDD') )
            ) THEN
                return niv_precis_null;
            END IF;

            -- Paramètres critères biologiques
            -- S'il existe un critère pour ce taxon
            IF EXISTS (
                SELECT 1
                FROM gn_sensitivity.t_sensitivity_rules_cd_ref s
                JOIN gn_sensitivity.cor_sensitivity_criteria c USING(id_sensitivity)
                WHERE s.cd_ref = my_cd_ref
            ) THEN
                -- Si le critère est remplis
                niv_precis := (

              WITH RECURSIVE h_val(KEY, value, id_broader) AS  (
                SELECT KEY, value::int, id_broader
                FROM (SELECT * FROM jsonb_each_text(my_criterias)) d
                JOIN ref_nomenclatures.t_nomenclatures tn
                ON tn.id_nomenclature = d.value::int
                UNION
                SELECT KEY, id_nomenclature , tn.id_broader
                FROM ref_nomenclatures.t_nomenclatures tn
                JOIN h_val
                ON tn.id_nomenclature = h_val.id_broader
                WHERE NOT id_nomenclature = 0
              )
              SELECT DISTINCT id_nomenclature_sensitivity
              FROM gn_sensitivity.t_sensitivity_rules_cd_ref s
              JOIN gn_sensitivity.cor_sensitivity_criteria c USING(id_sensitivity)
              JOIN h_val a
              ON c.id_criteria = a.value
              WHERE s.cd_ref = my_cd_ref
              LIMIT 1
                );
                IF niv_precis IS NULL THEN
                    niv_precis := (SELECT ref_nomenclatures.get_id_nomenclature('SENSIBILITE'::text, '0'::text));
                    return niv_precis;
                END IF;
            END IF;



            -- ##########################################
            -- TESTS multicritères
            --    => Permet de voir si l'ensemble des critères sont remplis
            -- ##########################################

            -- Paramètres durée, zone géographique, période de l'observation et critères biologique
          SELECT INTO niv_precis s.id_nomenclature_sensitivity
          FROM (
            SELECT s.*, l.geom, c.id_criteria, c.id_type_nomenclature
            FROM gn_sensitivity.t_sensitivity_rules_cd_ref s
            LEFT OUTER JOIN gn_sensitivity.cor_sensitivity_area  USING(id_sensitivity)
                LEFT OUTER JOIN gn_sensitivity.cor_sensitivity_criteria c USING(id_sensitivity)
            LEFT OUTER JOIN ref_geo.l_areas l USING(id_area)
          ) s
          WHERE my_cd_ref = s.cd_ref
            AND (st_intersects(my_geom, s.geom) OR s.geom IS NULL) -- paramètre géographique
            AND (-- paramètre période
              (to_char(my_date_obs, 'MMDD') between to_char(s.date_min, 'MMDD') and to_char(s.date_max, 'MMDD') )
            )
            AND ( -- paramètre duré de validité de la règle
              (date_part('year', CURRENT_TIMESTAMP) - sensitivity_duration) <= date_part('year', my_date_obs)
            )
            AND ( -- paramètre critères
                    s.id_criteria IN (SELECT  value::int FROM jsonb_each_text(my_criterias)) OR s.id_criteria IS NULL
            );

          IF niv_precis IS NULL THEN
            niv_precis := niv_precis_null;
          END IF;


          return niv_precis;

        END;
        $function$
        ;

        -- correction de fonctions permissions (nom de la vue a changé)

        CREATE OR REPLACE FUNCTION does_user_have_scope_permission
        (
        myuser integer,
        mycodemodule character varying,
        myactioncode character varying,
        myscope integer
        )
        RETURNS boolean AS
        $BODY$
        -- the function say if the given user can do the requested action in the requested module with its scope level
        -- warning: NO heritage between parent and child module
        -- USAGE : SELECT gn_persmissions.does_user_have_scope_permission(requested_userid,requested_actionid,requested_module_code,requested_scope);
        -- SAMPLE : SELECT gn_permissions.does_user_have_scope_permission(2,'OCCTAX','R',3);
        BEGIN
            IF myactioncode IN (
          SELECT code_action
            FROM gn_permissions.v_roles_permissions
            WHERE id_role = myuser AND module_code = mycodemodule AND code_action = myactioncode AND value_filter::int >= myscope AND code_filter_type = 'SCOPE') THEN
            RETURN true;
        END
        IF;
        RETURN false;
        END;
        $BODY$
        LANGUAGE plpgsql IMMUTABLE
        COST 100;


        CREATE OR REPLACE FUNCTION user_max_accessible_data_level_in_module
        (
        myuser integer,
        myactioncode character varying,
        mymodulecode character varying)
        RETURNS integer AS
        $BODY$
        DECLARE
        themaxscopelevel integer;
        -- the function return the max accessible extend of data the given user can access in the requested module
        -- warning: NO heritage between parent and child module
        -- USAGE : SELECT gn_permissions.user_max_accessible_data_level_in_module(requested_userid,requested_actionid,requested_moduleid);
        -- SAMPLE :SELECT gn_permissions.user_max_accessible_data_level_in_module(2,'U','GEONATURE');
        BEGIN
            SELECT max(value_filter::int)
            INTO themaxscopelevel
            FROM gn_permissions.v_roles_permissions
            WHERE id_role = myuser AND module_code = mymodulecode AND code_action = myactioncode;
            RETURN themaxscopelevel;
        END;
        $BODY$
        LANGUAGE plpgsql IMMUTABLE
        COST 100;

        CREATE OR REPLACE FUNCTION cruved_for_user_in_module
        (
        myuser integer,
        mymodulecode character varying
        )
        RETURNS json AS
        $BODY$
        -- the function return user's CRUVED in the requested module
        -- warning: the function not return the parent CRUVED but only the module cruved - no heritage
        -- USAGE : SELECT utilisateurs.cruved_for_user_in_module(requested_userid,requested_moduleid);
        -- SAMPLE : SELECT utilisateurs.cruved_for_user_in_module(2,3);
        DECLARE
        thecruved json;
        BEGIN
            SELECT array_to_json(array_agg(row))
            INTO thecruved
            FROM (
          SELECT code_action AS action, max(value_filter::int) AS level
                FROM gn_permissions.v_roles_permissions
                WHERE id_role = myuser AND module_code = mymodulecode AND code_filter_type = 'SCOPE'
                GROUP BY code_action) row;
            RETURN thecruved;
        END;
        $BODY$
        LANGUAGE plpgsql IMMUTABLE
        COST 100;




        --- DROP id_nomenclature_obs_technique depend view
        DROP VIEW IF EXISTS gn_synthese.v_synthese_for_export;
        DROP VIEW IF EXISTS pr_occtax.v_releve_occtax;
        DROP VIEW IF EXISTS gn_synthese.v_synthese_decode_nomenclatures;
        DROP VIEW IF EXISTS gn_synthese.v_synthese_for_web_app;
        DROP VIEW IF EXISTS gn_commons.v_synthese_validation_forwebapp;


        -- OCCTAX V2

        ALTER TABLE pr_occtax.t_releves_occtax
          ADD COLUMN id_nomenclature_geo_object_nature integer,
          ADD COLUMN depth_min integer,
          ADD COLUMN depth_max integer,
          ADD COLUMN place_name character varying(500),
          ADD CONSTRAINT check_t_releves_occtax_geo_object_nature CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_geo_object_nature,'NAT_OBJ_GEO')) NOT VALID,
          ADD CONSTRAINT check_t_releves_occtax_depth CHECK (depth_max >= depth_min),
          ADD CONSTRAINT fk_t_releves_occtax_id_nomenclature_geo_object_nature FOREIGN KEY (id_nomenclature_geo_object_nature) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE,
          ADD COLUMN cd_hab integer,
          ADD CONSTRAINT fk_t_releves_occtax_cd_hab FOREIGN KEY (cd_hab) REFERENCES ref_habitats.habref(cd_hab) ON UPDATE CASCADE,
          ADD COLUMN grp_method character varying(255),
          ALTER COLUMN precision DROP DEFAULT
        ;

        ALTER TABLE pr_occtax.t_releves_occtax
          RENAME COLUMN id_nomenclature_obs_technique TO id_nomenclature_tech_collect_campanule;

        ALTER TABLE pr_occtax.t_releves_occtax
          ALTER column id_nomenclature_tech_collect_campanule DROP NOT NULL;

        ALTER TABLE pr_occtax.t_occurrences_occtax
          --delete sensi
          DROP COLUMN id_nomenclature_diffusion_level,
          -- comportement
          ADD COLUMN id_nomenclature_behaviour integer,
          ADD CONSTRAINT fk_t_occurrences_occtax_behaviour FOREIGN KEY (id_nomenclature_behaviour) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE,
          ADD CONSTRAINT check_t_occurrences_occtax_behaviour CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_behaviour,'OCC_COMPORTEMENT')) NOT VALID
        ;

        ALTER TABLE pr_occtax.t_occurrences_occtax
          RENAME COLUMN id_nomenclature_obs_meth TO id_nomenclature_obs_technique
        ;
        COMMENT ON COLUMN pr_occtax.t_occurrences_occtax.id_nomenclature_obs_technique
          IS 'Correspondance champs standard occtax = obsTechnique. En raison d''un changement de nom, le code nomenclature associé reste ''METH_OBS'' ';

        INSERT INTO pr_occtax.defaults_nomenclatures_value(mnemonique_type, id_nomenclature)
        VALUES
        ('OCC_COMPORTEMENT', ref_nomenclatures.get_id_nomenclature('OCC_COMPORTEMENT', '0'))
        ;

        INSERT INTO gn_synthese.defaults_nomenclatures_value(mnemonique_type, id_nomenclature)
        VALUES ('OCC_COMPORTEMENT', ref_nomenclatures.get_id_nomenclature('OCC_COMPORTEMENT', '0'))
        ;

        CREATE OR REPLACE VIEW pr_occtax.v_releve_occtax AS
        SELECT rel.id_releve_occtax,
            rel.id_dataset,
            rel.id_digitiser,
            rel.date_min,
            rel.date_max,
            rel.altitude_min,
            rel.altitude_max,
            rel.depth_min,
            rel.depth_max,
            rel.place_name,
            rel.meta_device_entry,
            rel.comment,
            rel.geom_4326,
            rel."precision",
            occ.id_occurrence_occtax,
            occ.cd_nom,
            occ.nom_cite,
            t.lb_nom,
            t.nom_valide,
            t.nom_vern,
            (((t.nom_complet_html::text || ' '::text) || rel.date_min::date) || '<br/>'::text) || string_agg(DISTINCT(obs.nom_role::text || ' '::text) || obs.prenom_role::text, ', '::text) AS leaflet_popup,
            COALESCE ( string_agg(DISTINCT(obs.nom_role::text || ' '::text) || obs.prenom_role::text, ', '::text),rel.observers_txt) AS observateurs
          FROM pr_occtax.t_releves_occtax rel
            LEFT JOIN pr_occtax.t_occurrences_occtax occ ON rel.id_releve_occtax = occ.id_releve_occtax
            LEFT JOIN taxonomie.taxref t ON occ.cd_nom = t.cd_nom
            LEFT JOIN pr_occtax.cor_role_releves_occtax cor_role ON cor_role.id_releve_occtax = rel.id_releve_occtax
            LEFT JOIN utilisateurs.t_roles obs ON cor_role.id_role = obs.id_role
          GROUP BY rel.id_releve_occtax, rel.id_dataset, rel.id_digitiser, rel.date_min, rel.date_max, rel.altitude_min, rel.altitude_max, rel.depth_min, rel.depth_max, rel.place_name, rel.meta_device_entry, rel.comment, rel.geom_4326, rel."precision", t.cd_nom, occ.nom_cite, occ.id_occurrence_occtax, t.lb_nom, t.nom_valide, t.nom_complet_html, t.nom_vern;

        ALTER TABLE gn_synthese.synthese
            ADD COLUMN cd_hab integer,
            ADD CONSTRAINT fk_synthese_cd_hab FOREIGN KEY (cd_hab) REFERENCES ref_habitats.habref(cd_hab) ON UPDATE CASCADE,
            ADD COLUMN grp_method character varying(255),
            ADD COLUMN id_nomenclature_behaviour integer,
            ADD COLUMN depth_min integer,
            ADD COLUMN depth_max integer,
            ADD COLUMN place_name character varying(500),
            ADD COLUMN precision integer,
            ADD COLUMN additional_data jsonb,
            ALTER COLUMN id_nomenclature_behaviour SET DEFAULT gn_synthese.get_default_nomenclature_value('OCC_COMPORTEMENT'),
            ADD CONSTRAINT fk_synthese_id_nomenclature_behaviour FOREIGN KEY (id_nomenclature_behaviour) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE,
            ADD CONSTRAINT check_synthese_behaviour CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_behaviour, 'OCC_COMPORTEMENT')) NOT VALID,
            ADD CONSTRAINT check_synthese_depth_max CHECK (depth_max >= depth_min),
            DROP COLUMN id_nomenclature_obs_technique
        ;
        ALTER TABLE gn_synthese.synthese
            RENAME id_nomenclature_obs_meth TO id_nomenclature_obs_technique
        ;

        COMMENT ON COLUMN gn_synthese.synthese.id_nomenclature_obs_technique
          IS 'Correspondance champs standard occtax = obsTechnique. En raison d''un changement de nom, le code nomenclature associé reste ''METH_OBS'' ';



        CREATE OR REPLACE FUNCTION pr_occtax.insert_in_synthese(my_id_counting integer)
          RETURNS integer[] AS
        $BODY$
        DECLARE
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
        last_action
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
          'I'
        );

          RETURN myobservers.observers_id ;
        END;
        $BODY$
          LANGUAGE plpgsql VOLATILE
          COST 100;



        CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_occ()
          RETURNS trigger AS
        $BODY$
        DECLARE
        BEGIN
          UPDATE gn_synthese.synthese SET
            id_nomenclature_obs_technique = NEW.id_nomenclature_obs_technique,
            id_nomenclature_bio_condition = NEW.id_nomenclature_bio_condition,
            id_nomenclature_bio_status = NEW.id_nomenclature_bio_status,
            id_nomenclature_naturalness = NEW.id_nomenclature_naturalness,
            id_nomenclature_exist_proof = NEW.id_nomenclature_exist_proof,
            id_nomenclature_observation_status = NEW.id_nomenclature_observation_status,
            id_nomenclature_blurring = NEW.id_nomenclature_blurring,
            id_nomenclature_source_status = NEW.id_nomenclature_source_status,
            determiner = NEW.determiner,
            id_nomenclature_determination_method = NEW.id_nomenclature_determination_method,
            id_nomenclature_behaviour = id_nomenclature_behaviour,
            cd_nom = NEW.cd_nom,
            nom_cite = NEW.nom_cite,
            meta_v_taxref = NEW.meta_v_taxref,
            sample_number_proof = NEW.sample_number_proof,
            digital_proof = NEW.digital_proof,
            non_digital_proof = NEW.non_digital_proof,
            comment_description = NEW.comment,
            last_action = 'U'
          WHERE unique_id_sinp IN (SELECT unique_id_sinp_occtax FROM pr_occtax.cor_counting_occtax WHERE id_occurrence_occtax = NEW.id_occurrence_occtax);
          RETURN NULL;
        END;
        $BODY$
          LANGUAGE plpgsql VOLATILE
          COST 100;



        CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_releve()
          RETURNS trigger AS
        $BODY$
        DECLARE
          myobservers text;
        BEGIN
          --calcul de l'observateur. On privilégie le ou les observateur(s) de cor_role_releves_occtax
          --Récupération et formatage des observateurs
          SELECT INTO myobservers array_to_string(array_agg(rol.nom_role || ' ' || rol.prenom_role), ', ')
          FROM pr_occtax.cor_role_releves_occtax cor
          JOIN utilisateurs.t_roles rol ON rol.id_role = cor.id_role
          WHERE cor.id_releve_occtax = NEW.id_releve_occtax;
          IF myobservers IS NULL THEN
            myobservers = NEW.observers_txt;
          END IF;
          --mise à jour en synthese des informations correspondant au relevé uniquement
          UPDATE gn_synthese.synthese SET
              id_dataset = NEW.id_dataset,
              observers = myobservers,
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
              the_geom_4326 = NEW.geom_4326,
              the_geom_point = ST_CENTROID(NEW.geom_4326),
              id_nomenclature_geo_object_nature = NEW.id_nomenclature_geo_object_nature,
              last_action = 'U',
              comment_context = NEW.comment
          WHERE unique_id_sinp IN (SELECT unnest(pr_occtax.get_unique_id_sinp_from_id_releve(NEW.id_releve_occtax::integer)));
          RETURN NULL;
        END;
        $BODY$
          LANGUAGE plpgsql VOLATILE
          COST 100;


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
        ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_behaviour) AS occ_behaviour
        FROM gn_synthese.synthese s;


        CREATE OR REPLACE VIEW gn_synthese.v_synthese_for_web_app AS
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
            s.depth_min,
            s.depth_max,
            s.place_name,
            s.precision,
            s.the_geom_4326,
            public.ST_asgeojson(the_geom_4326),
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

        DROP VIEW gn_synthese.v_metadata_for_export;
        CREATE OR REPLACE VIEW gn_synthese.v_metadata_for_export AS
        WITH count_nb_obs AS (
                SELECT count(*) AS nb_obs,
                    synthese.id_dataset
                  FROM gn_synthese.synthese
                  GROUP BY synthese.id_dataset
                )
        SELECT d.dataset_name AS jeu_donnees,
            d.id_dataset AS jdd_id,
            d.unique_dataset_id AS "idSINPJdd",
            af.acquisition_framework_name AS cadre_acquisition,
            string_agg(DISTINCT concat(COALESCE(orga.nom_organisme, ((roles.nom_role::text || ' '::text) || roles.prenom_role::text)::character varying), ': ', nomencl.label_default), ' | '::text) AS acteurs,
            count_nb_obs.nb_obs AS nombre_obs
          FROM gn_meta.t_datasets d
            JOIN gn_meta.t_acquisition_frameworks af ON af.id_acquisition_framework = d.id_acquisition_framework
            JOIN gn_meta.cor_dataset_actor act ON act.id_dataset = d.id_dataset
            JOIN ref_nomenclatures.t_nomenclatures nomencl ON nomencl.id_nomenclature = act.id_nomenclature_actor_role
            LEFT JOIN utilisateurs.bib_organismes orga ON orga.id_organisme = act.id_organism
            LEFT JOIN utilisateurs.t_roles roles ON roles.id_role = act.id_role
            JOIN count_nb_obs ON count_nb_obs.id_dataset = d.id_dataset
          GROUP BY d.id_dataset, d.unique_dataset_id, d.dataset_name, af.acquisition_framework_name, count_nb_obs.nb_obs;


        -- Migration des données de la colonne statubio vers comportement
        UPDATE pr_occtax.t_occurrences_occtax AS occ
        SET id_nomenclature_behaviour = sub.new_id_nomenc
        FROM (
          SELECT
            id_occurrence_occtax,
          CASE
            WHEN ref_nomenclatures.get_cd_nomenclature(id_nomenclature_bio_status) = 'OLD_6' THEN ref_nomenclatures.get_id_nomenclature('OCC_COMPORTEMENT', '6')
            WHEN ref_nomenclatures.get_cd_nomenclature(id_nomenclature_bio_status) = 'OLD_7' THEN ref_nomenclatures.get_id_nomenclature('OCC_COMPORTEMENT', '7')
            WHEN ref_nomenclatures.get_cd_nomenclature(id_nomenclature_bio_status) = 'OLD_8' THEN ref_nomenclatures.get_id_nomenclature('OCC_COMPORTEMENT', '8')
            WHEN ref_nomenclatures.get_cd_nomenclature(id_nomenclature_bio_status) = 'OLD_10' THEN ref_nomenclatures.get_id_nomenclature('OCC_COMPORTEMENT', '10')
            WHEN ref_nomenclatures.get_cd_nomenclature(id_nomenclature_bio_status) = 'OLD_11' THEN ref_nomenclatures.get_id_nomenclature('OCC_COMPORTEMENT', '11')
            WHEN ref_nomenclatures.get_cd_nomenclature(id_nomenclature_bio_status) = 'OLD_12' THEN ref_nomenclatures.get_id_nomenclature('OCC_COMPORTEMENT', '12')
            END as new_id_nomenc
          FROM pr_occtax.t_occurrences_occtax
          WHERE ref_nomenclatures.get_cd_nomenclature(id_nomenclature_bio_status) IN ('OLD_6', 'OLD_7', 'OLD_8', 'OLD_10', 'OLD_11', 'OLD_12')
        ) AS sub
        WHERE occ.id_occurrence_occtax = sub.id_occurrence_occtax
        ;

        ALTER TABLE pr_occtax.t_occurrences_occtax
        ALTER COLUMN nom_cite SET NOT NULL;

        CREATE OR REPLACE VIEW gn_commons.v_synthese_validation_forwebapp AS
        SELECT  s.id_synthese,
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
            s.precision,
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
            ST_asgeojson(s.the_geom_4326) as geojson
          FROM gn_synthese.synthese s
            JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
            JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
            LEFT JOIN ref_nomenclatures.t_nomenclatures n ON n.id_nomenclature = s.id_nomenclature_valid_status
            LEFT JOIN LATERAL (
                SELECT v.validation_auto, v.validation_date
                FROM gn_commons.t_validations v
                WHERE v.uuid_attached_row = s.unique_id_sinp
                ORDER BY v.validation_date DESC
                LIMIT 1
            ) v ON true
          WHERE d.validable = true AND NOT s.unique_id_sinp IS NULL;

        COMMENT ON VIEW gn_commons.v_synthese_validation_forwebapp  IS 'Vue utilisée pour le module validation. Prend l''id_nomenclature dans la table synthese ainsi que toutes les colonnes de la synthese pour les filtres. On JOIN sur la vue latest_validation pour voir si la validation est auto';


        -- add date on medias

        ALTER TABLE gn_commons.t_medias ADD COLUMN meta_create_date timestamp without time zone DEFAULT now();
        ALTER TABLE gn_commons.t_medias ADD COLUMN meta_update_date timestamp without time zone DEFAULT now();

        CREATE TRIGGER tri_meta_dates_change_t_medias
          BEFORE INSERT OR UPDATE
          ON gn_commons.t_medias
          FOR EACH ROW
          EXECUTE PROCEDURE public.fct_trg_meta_dates_change();


        -- check if uuid in table

        CREATE OR REPLACE FUNCTION gn_commons.check_entity_uuid_exist(myentity character varying, myvalue uuid)
          RETURNS boolean AS
        $BODY$
        --Function that allows to check if a uuid exists in the field of a table type.
        --USAGE : SELECT gn_commons.check_entity_uuid_exist('schema.table.field', uuid);
          DECLARE
            entity_array character varying(255)[];
            r record;
            _row_ct integer;
          BEGIN


            entity_array = string_to_array(myentity,'.');
            EXECUTE 'SELECT '||entity_array[3]|| ' FROM '||entity_array[1]||'.'||entity_array[2]||' WHERE '||entity_array[3]||'=''' ||myvalue || '''' INTO r;
            GET DIAGNOSTICS _row_ct = ROW_COUNT;
              IF _row_ct > 0 THEN
                RETURN true;
              END IF;
            RETURN false;
          END;
        $BODY$
          LANGUAGE plpgsql IMMUTABLE
          COST 100;
        CREATE OR REPLACE VIEW pr_occtax.export_occtax AS
        SELECT
            rel.unique_id_sinp_grp as "idSINPRegroupement",
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
            COALESCE(string_agg(DISTINCT (r.nom_role::text || ' '::text) || r.prenom_role::text, ','::text), rel.observers_txt::text) AS "obsId",
            COALESCE(string_agg(DISTINCT o.nom_organisme::text, ','::text), 'NSP'::text) AS "obsNomOrg",
            COALESCE(occ.determiner, 'Inconnu'::character varying) AS "detId",
            ref_nomenclatures.get_nomenclature_label(rel.id_nomenclature_geo_object_nature) AS "natObjGeo",
            st_astext(rel.geom_4326) AS "WKT",
            -- 'In'::text AS "natObjGeo",
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
            rel.precision
          FROM pr_occtax.t_releves_occtax rel
            LEFT JOIN pr_occtax.t_occurrences_occtax occ ON rel.id_releve_occtax = occ.id_releve_occtax
            LEFT JOIN pr_occtax.cor_counting_occtax ccc ON ccc.id_occurrence_occtax = occ.id_occurrence_occtax
            LEFT JOIN taxonomie.taxref tax ON tax.cd_nom = occ.cd_nom
            LEFT JOIN gn_meta.t_datasets d ON d.id_dataset = rel.id_dataset
            LEFT JOIN pr_occtax.cor_role_releves_occtax cr ON cr.id_releve_occtax = rel.id_releve_occtax
            LEFT JOIN utilisateurs.t_roles r ON r.id_role = cr.id_role
            LEFT JOIN utilisateurs.bib_organismes o ON o.id_organisme = r.id_organisme
            LEFT JOIN ref_habitats.habref hab ON hab.cd_hab = rel.cd_hab
          GROUP BY ccc.id_counting_occtax,occ.id_occurrence_occtax,rel.id_releve_occtax,d.id_dataset
          ,tax.cd_ref , tax.lb_nom, tax.nom_vern , hab.cd_hab, hab.lb_code, hab.lb_hab_fr
          ;


        CREATE OR REPLACE VIEW gn_synthese.v_synthese_for_export AS
        SELECT s.id_synthese AS "idSynthese",
            s.entity_source_pk_value AS "idOrigine",
            s.unique_id_sinp AS "permId",
            s.unique_id_sinp_grp AS "permIdGrp",
            s.grp_method,
            s.count_min AS "denbrMin",
            s.count_max AS "denbrMax",
            s.sample_number_proof AS "sampleNumb",
            s.digital_proof AS "preuvNum",
            s.non_digital_proof AS "preuvNoNum",
            s.altitude_min AS "altMin",
            s.altitude_max AS "altMax",
            s.depth_min AS "profMin",
            s.depth_max AS "profMax",
            s.precision,
            public.ST_astext(s.the_geom_4326) AS wkt,
            to_char(s.date_min, 'YYYY-MM-DD') AS "dateDebut",
            to_char(s.date_max, 'YYYY-MM-DD') AS "dateFin",
            s.date_min::time AS "heureFin",
            s.date_max::time AS "heureDebut",
            s.validator AS validateur,
            s.observers AS observer,
            s.id_digitiser AS id_digitiser,
            s.determiner AS detminer,
            s.comment_context AS "obsCtx",
            s.comment_description AS "obsDescr",
            s.meta_create_date,
            s.meta_update_date,
            d.dataset_name AS "jddName", -- champs non standard (pas le nom du JDD dans le standard)
            d.unique_dataset_id AS "idSINPJdd",
            d.id_acquisition_framework,
            t.cd_nom AS "cdNom",
            t.cd_ref AS "cdRef",
            s.cd_hab AS "codeHabRef",
            t.nom_valide AS "nomValide",
            s.nom_cite AS "nomCite",
            hab.lb_code AS "codeHab",
            hab.lb_hab_fr AS "nomHab",
            s.cd_hab AS "cdHab",
            public.ST_x(public.ST_transform(s.the_geom_point, 2154)) AS x_centroid,
            public.ST_y(public.ST_transform(s.the_geom_point, 2154)) AS y_centroid,
            COALESCE(s.meta_update_date, s.meta_create_date) AS lastact,
            public.ST_asgeojson(s.the_geom_4326) AS geojson_4326,
            public.ST_asgeojson(s.the_geom_local) AS geojson_local,
            s.place_name AS "nomLieu",
            n1.label_default AS "natObjGeo",
            n2.label_default AS "typGrp",
            s.grp_method AS "methGrp",
            n3.label_default AS "obsTech",
            n5.label_default AS "ocStatutBio",
            n6.label_default AS "ocEtatBio",
            n7.label_default AS "ocNat",
            n8.label_default AS "preuveOui",
            n9.label_default AS "difNivPrec",
            n10.label_default AS "ocStade",
            n11.label_default AS "ocSex",
            n12.label_default AS "objDenbr",
            n13.label_default AS "denbrTyp",
            n14.label_default AS"sensiNiv",
            n15.label_default AS "statObs",
            n16.label_default AS "dEEFlou",
            n17.label_default AS "statSource",
            n18.label_default AS "typInfGeo",
            n19.label_default AS "ocMethDet",
            n20.label_default AS "occComportement"
          FROM gn_synthese.synthese s
            JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
            JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
            JOIN gn_synthese.t_sources sources ON sources.id_source = s.id_source
            LEFT JOIN ref_nomenclatures.t_nomenclatures n1 ON s.id_nomenclature_geo_object_nature = n1.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n2 ON s.id_nomenclature_grp_typ = n2.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n3 ON s.id_nomenclature_obs_technique = n3.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n5 ON s.id_nomenclature_bio_status = n5.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n6 ON s.id_nomenclature_bio_condition = n6.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n7 ON s.id_nomenclature_naturalness = n7.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n8 ON s.id_nomenclature_exist_proof = n8.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n9 ON s.id_nomenclature_diffusion_level = n9.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n10 ON s.id_nomenclature_life_stage = n10.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n11 ON s.id_nomenclature_sex = n11.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n12 ON s.id_nomenclature_obj_count = n12.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n13 ON s.id_nomenclature_type_count = n13.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n14 ON s.id_nomenclature_sensitivity = n14.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n15 ON s.id_nomenclature_observation_status = n15.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n16 ON s.id_nomenclature_blurring = n16.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n17 ON s.id_nomenclature_source_status = n17.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n18 ON s.id_nomenclature_info_geo_type = n18.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n19 ON s.id_nomenclature_determination_method = n19.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n20 ON s.id_nomenclature_behaviour = n20.id_nomenclature
            LEFT JOIN ref_habitats.habref hab ON hab.cd_hab = s.cd_hab;
        -- correction de fonctions permissions (nom de la vue a changé)

        CREATE OR REPLACE FUNCTION does_user_have_scope_permission
        (
        myuser integer,
        mycodemodule character varying,
        myactioncode character varying,
        myscope integer
        )
        RETURNS boolean AS
        $BODY$
        -- the function say if the given user can do the requested action in the requested module with its scope level
        -- warning: NO heritage between parent and child module
        -- USAGE : SELECT gn_persmissions.does_user_have_scope_permission(requested_userid,requested_actionid,requested_module_code,requested_scope);
        -- SAMPLE : SELECT gn_permissions.does_user_have_scope_permission(2,'OCCTAX','R',3);
        BEGIN
            IF myactioncode IN (
          SELECT code_action
            FROM gn_permissions.v_roles_permissions
            WHERE id_role = myuser AND module_code = mycodemodule AND code_action = myactioncode AND value_filter::int >= myscope AND code_filter_type = 'SCOPE') THEN
            RETURN true;
        END
        IF;
        RETURN false;
        END;
        $BODY$
        LANGUAGE plpgsql IMMUTABLE
        COST 100;


        CREATE OR REPLACE FUNCTION user_max_accessible_data_level_in_module
        (
        myuser integer,
        myactioncode character varying,
        mymodulecode character varying)
        RETURNS integer AS
        $BODY$
        DECLARE
        themaxscopelevel integer;
        -- the function return the max accessible extend of data the given user can access in the requested module
        -- warning: NO heritage between parent and child module
        -- USAGE : SELECT gn_permissions.user_max_accessible_data_level_in_module(requested_userid,requested_actionid,requested_moduleid);
        -- SAMPLE :SELECT gn_permissions.user_max_accessible_data_level_in_module(2,'U','GEONATURE');
        BEGIN
            SELECT max(value_filter::int)
            INTO themaxscopelevel
            FROM gn_permissions.v_roles_permissions
            WHERE id_role = myuser AND module_code = mymodulecode AND code_action = myactioncode;
            RETURN themaxscopelevel;
        END;
        $BODY$
        LANGUAGE plpgsql IMMUTABLE
        COST 100;

        CREATE OR REPLACE FUNCTION cruved_for_user_in_module
        (
        myuser integer,
        mymodulecode character varying
        )
        RETURNS json AS
        $BODY$
        -- the function return user's CRUVED in the requested module
        -- warning: the function not return the parent CRUVED but only the module cruved - no heritage
        -- USAGE : SELECT utilisateurs.cruved_for_user_in_module(requested_userid,requested_moduleid);
        -- SAMPLE : SELECT utilisateurs.cruved_for_user_in_module(2,3);
        DECLARE
        thecruved json;
        BEGIN
            SELECT array_to_json(array_agg(row))
            INTO thecruved
            FROM (
          SELECT code_action AS action, max(value_filter::int) AS level
                FROM gn_permissions.v_roles_permissions
                WHERE id_role = myuser AND module_code = mymodulecode AND code_filter_type = 'SCOPE'
                GROUP BY code_action) row;
            RETURN thecruved;
        END;
        $BODY$
        LANGUAGE plpgsql IMMUTABLE
        COST 100;


        -- UNIQUE TABLE LOCATION
        ALTER TABLE gn_commons.bib_tables_location
          ADD CONSTRAINT unique_bib_table_location_schema_name_table_name UNIQUE (schema_name, table_name);


        -- Monitoring

        ALTER TABLE gn_monitoring.t_base_visits
          RENAME COLUMN id_nomenclature_obs_technique TO id_nomenclature_tech_collect_campanule;

        -- Import dans la synthese : prise en compte de postgis 3

        CREATE OR REPLACE FUNCTION gn_synthese.import_json_row_format_insert_data(column_name varchar, data_type varchar, postgis_maj_num_version int)
        RETURNS text
        LANGUAGE plpgsql
        AS $function$
        DECLARE
          col_srid int;
        BEGIN
          -- Gestion de postgis 3
          IF ((postgis_maj_num_version > 2) AND (data_type = 'geometry')) THEN
            col_srid := (SELECT find_srid('gn_synthese', 'synthese', column_name));
            RETURN '(st_setsrid(ST_GeomFromGeoJSON(datain->>''' || column_name  || '''), ' || col_srid::text || '))' || COALESCE('::' || data_type, '');
          ELSE
            RETURN '(datain->>''' || column_name  || ''')' || COALESCE('::' || data_type, '');
          END IF;

        END;
        $function$
        ;

          CREATE OR REPLACE FUNCTION gn_synthese.import_json_row(datain jsonb, datageojson text DEFAULT NULL::text)
        RETURNS boolean
        LANGUAGE plpgsql
        AS $function$
          DECLARE
            insert_columns text;
            select_columns text;
            update_columns text;

            geom geometry;
            geom_data jsonb;
            local_srid int;

          postgis_maj_num_version int;
        BEGIN


          -- Import des données dans une table temporaire pour faciliter le traitement
          DROP TABLE IF EXISTS tmp_process_import;
          CREATE TABLE tmp_process_import (
              id_synthese int,
              datain jsonb,
              action char(1)
          );
          INSERT INTO tmp_process_import (datain)
          SELECT datain;

          postgis_maj_num_version := (SELECT split_part(version, '.', 1)::int FROM pg_available_extension_versions WHERE name = 'postgis' AND installed = true);

          -- Cas ou la geométrie est passé en geojson
          IF NOT datageojson IS NULL THEN
            geom := (SELECT ST_setsrid(ST_GeomFromGeoJSON(datageojson), 4326));
            local_srid := (SELECT parameter_value FROM gn_commons.t_parameters WHERE parameter_name = 'local_srid');
            geom_data := (
                SELECT json_build_object(
                    'the_geom_4326',geom,
                    'the_geom_point',(SELECT ST_centroid(geom)),
                    'the_geom_local',(SELECT ST_transform(geom, local_srid))
                )
            );

            UPDATE tmp_process_import d
              SET datain = d.datain || geom_data;
          END IF;

        -- ############ TEST

          -- colonne unique_id_sinp exists
          IF EXISTS (
                SELECT 1 FROM jsonb_object_keys(datain) column_name WHERE column_name =  'unique_id_sinp'
            ) IS FALSE THEN
                RAISE NOTICE 'Column unique_id_sinp is mandatory';
                RETURN FALSE;
          END IF ;

        -- ############ mapping colonnes

          WITH import_col AS (
            SELECT jsonb_object_keys(datain) AS column_name
          ), synt_col AS (
              SELECT column_name, column_default, CASE WHEN data_type = 'USER-DEFINED' THEN udt_name ELSE data_type END as data_type
              FROM information_schema.columns
              WHERE table_schema || '.' || table_name = 'gn_synthese.synthese'
          )
          SELECT
              string_agg(s.column_name, ',')  as insert_columns,
              string_agg(
                  CASE
                      WHEN NOT column_default IS NULL THEN
                      'COALESCE(' || gn_synthese.import_json_row_format_insert_data(i.column_name, data_type::varchar, postgis_maj_num_version) || ', ' || column_default || ') as ' || i.column_name
                  ELSE gn_synthese.import_json_row_format_insert_data(i.column_name, data_type::varchar, postgis_maj_num_version)
                  END, ','
              ) as select_columns ,
              string_agg(
                  s.column_name || '=' ||
                  CASE
                    WHEN NOT column_default IS NULL
                      THEN  'COALESCE(' || gn_synthese.import_json_row_format_insert_data(i.column_name, data_type::varchar, postgis_maj_num_version) || ', ' || column_default || ') '
                ELSE gn_synthese.import_json_row_format_insert_data(i.column_name, data_type::varchar, postgis_maj_num_version)
                  END
              , ',')
          INTO insert_columns, select_columns, update_columns
          FROM synt_col s
          JOIN import_col i
          ON i.column_name = s.column_name;

          -- ############# IMPORT DATA
          IF EXISTS (
              SELECT 1
              FROM   gn_synthese.synthese
              WHERE  unique_id_sinp = (datain->>'unique_id_sinp')::uuid
          ) IS TRUE THEN
            -- Update
            EXECUTE ' WITH i_row AS (
                  UPDATE gn_synthese.synthese s SET ' || update_columns ||
                  ' FROM  tmp_process_import
                  WHERE s.unique_id_sinp =  (datain->>''unique_id_sinp'')::uuid
                  RETURNING s.id_synthese, s.unique_id_sinp
                  )
                  UPDATE tmp_process_import d SET id_synthese = i_row.id_synthese
                  FROM i_row
                  WHERE unique_id_sinp = i_row.unique_id_sinp
                  ' ;
          ELSE
            -- Insert
            EXECUTE 'WITH i_row AS (
                  INSERT INTO gn_synthese.synthese ( ' || insert_columns || ')
                  SELECT ' || select_columns ||
                  ' FROM tmp_process_import
                  RETURNING id_synthese, unique_id_sinp
                  )
                  UPDATE tmp_process_import d SET id_synthese = i_row.id_synthese
                  FROM i_row
                  WHERE unique_id_sinp = i_row.unique_id_sinp
                  ' ;
          END IF;

          -- Import des cor_observers
          DELETE FROM gn_synthese.cor_observer_synthese
          USING tmp_process_import
          WHERE cor_observer_synthese.id_synthese = tmp_process_import.id_synthese;

          IF jsonb_typeof(datain->'ids_observers') = 'array' THEN
            INSERT INTO gn_synthese.cor_observer_synthese (id_synthese, id_role)
            SELECT DISTINCT id_synthese, (jsonb_array_elements(t.datain->'ids_observers'))::text::int
            FROM tmp_process_import t;
          END IF;

          RETURN TRUE;
          END;
        $function$
        ;

         -- suppression trigger en double #762
        DROP TRIGGER tri_insert_synthese_cor_role_releves_occtax ON pr_occtax.cor_role_releves_occtax;
        DROP FUNCTION pr_occtax.fct_tri_synthese_insert_cor_role_releve();

        -- Add module order column
        ALTER TABLE gn_commons.t_modules ADD module_order integer NULL;

        -- add id_digitizer 

        ALTER TABLE gn_meta.t_datasets
          ADD COLUMN id_digitizer integer;
        ALTER TABLE ONLY gn_meta.t_datasets
          ADD CONSTRAINT fk_t_datasets_id_digitizer FOREIGN KEY (id_digitizer) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;
        
        ALTER TABLE gn_meta.t_acquisition_frameworks
          ADD COLUMN id_digitizer integer;
        ALTER TABLE ONLY gn_meta.t_acquisition_frameworks
          ADD CONSTRAINT fk_t_acquisition_frameworks_id_digitizer FOREIGN KEY (id_digitizer) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

    END IF;
   END
 $$ language plpgsql;


