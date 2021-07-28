-- Update script from GeoNature 2.6.2 to 2.7.0

BEGIN;

  -------------
  -- VARIOUS --
  -------------

  -- REF_GEO - Add missing unique contraints
  CREATE UNIQUE INDEX IF NOT EXISTS i_unique_l_areas_id_type_area_code ON ref_geo.l_areas (id_type, area_code);
  ALTER TABLE ONLY ref_geo.l_areas DROP CONSTRAINT IF EXISTS unique_l_areas_id_type_area_code;
  ALTER TABLE ONLY ref_geo.l_areas
      ADD CONSTRAINT  unique_l_areas_id_type_area_code UNIQUE (id_type, area_code);
  CREATE UNIQUE INDEX IF NOT EXISTS  i_unique_bib_areas_types_type_code ON ref_geo.bib_areas_types(type_code);
  ALTER TABLE ONLY ref_geo.bib_areas_types DROP CONSTRAINT IF EXISTS unique_bib_areas_types_type_code;
  ALTER TABLE ONLY ref_geo.bib_areas_types
      ADD CONSTRAINT unique_bib_areas_types_type_code UNIQUE (type_code);

  -- Paramètre oublié de la 2.6.0
    INSERT INTO gn_commons.t_parameters
    (id_organism, parameter_name, parameter_desc, parameter_value, parameter_extra_value)
    VALUES(0, 'ref_sensi_version', 'Version du referentiel de sensibilité', 'Referentiel de sensibilite taxref v13 2020', '')
    ON CONFLICT DO NOTHING;


  -- Ajout de contraintes d'unicité sur les permissions
  ALTER TABLE gn_permissions.t_objects ADD CONSTRAINT unique_t_objects UNIQUE (code_object);

  -- Ajout de champs à la table t_modules
  ALTER TABLE gn_commons.t_modules ADD type CHARACTER VARYING(255);  -- polymorphisme
  ALTER TABLE gn_commons.t_modules ADD meta_create_date timestamp without time zone DEFAULT now();
  ALTER TABLE gn_commons.t_modules ADD meta_update_date timestamp without time zone DEFAULT now();
  CREATE TRIGGER tri_meta_dates_change_t_modules
        BEFORE INSERT OR UPDATE
        ON gn_commons.t_modules
        FOR EACH ROW
        EXECUTE PROCEDURE public.fct_trg_meta_dates_change();

  -- Datasets - Ajout d'un champs pour lier un JDD à une liste de taxons
  ALTER TABLE gn_meta.t_datasets
      ADD COLUMN id_taxa_list integer;
  COMMENT ON COLUMN gn_meta.t_datasets.id_taxa_list IS 'Identifiant de la liste de taxon associé au JDD. FK: taxonomie.bib_liste';

  ALTER TABLE ONLY gn_meta.t_datasets
      ADD CONSTRAINT fk_t_datasets_id_taxa_list FOREIGN KEY (id_taxa_list) REFERENCES taxonomie.bib_listes ON UPDATE CASCADE;

  --------------------------------------------
  -- METADATA - DELETE CASCADE ON DS AND AF --
  --------------------------------------------

  -- cor module dataset
  ALTER TABLE gn_commons.cor_module_dataset
      DROP constraint fk_cor_module_dataset_id_module;
  ALTER TABLE gn_commons.cor_module_dataset
      DROP constraint fk_cor_module_dataset_id_dataset;

  ALTER TABLE gn_commons.cor_module_dataset
      ADD constraint fk_cor_module_dataset_id_dataset FOREIGN KEY (id_dataset) REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE cascade on delete cascade,
      ADD constraint fk_cor_module_dataset_id_module FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules(id_module) ON UPDATE cascade on delete cascade;

  -- cor dataset actor
  ALTER TABLE ONLY gn_meta.cor_dataset_actor
      DROP constraint fk_cor_dataset_actor_id_dataset;
  ALTER TABLE ONLY gn_meta.cor_dataset_actor
      DROP constraint fk_dataset_actor_id_role;

  ALTER TABLE ONLY gn_meta.cor_dataset_actor
      ADD CONSTRAINT fk_cor_dataset_actor_id_dataset FOREIGN KEY (id_dataset)
      REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE ON DELETE CASCADE,
      ADD CONSTRAINT fk_dataset_actor_id_role FOREIGN KEY (id_role)
      REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;

  -- territory
  ALTER TABLE ONLY gn_meta.cor_dataset_territory
      DROP constraint fk_cor_dataset_territory_id_dataset;
  ALTER TABLE ONLY gn_meta.cor_dataset_protocol
      ADD CONSTRAINT fk_cor_dataset_territory_id_dataset FOREIGN KEY (id_dataset)
      REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE ON DELETE CASCADE;

  -- protocol
  ALTER TABLE ONLY gn_meta.cor_dataset_protocol
      DROP constraint fk_cor_dataset_protocol_id_dataset;
  ALTER TABLE ONLY gn_meta.cor_dataset_protocol
      ADD CONSTRAINT fk_cor_dataset_protocol_id_dataset FOREIGN KEY (id_dataset)
      REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE ON DELETE CASCADE;

  -- AF
  ALTER TABLE ONLY gn_meta.cor_acquisition_framework_objectif
      DROP constraint fk_cor_acquisition_framework_objectif_id_acquisition_framework;
  ALTER TABLE ONLY gn_meta.cor_acquisition_framework_objectif
      ADD CONSTRAINT fk_cor_acquisition_framework_objectif_id_acquisition_framework FOREIGN KEY (id_acquisition_framework)
      REFERENCES gn_meta.t_acquisition_frameworks(id_acquisition_framework) ON UPDATE CASCADE ON DELETE CASCADE;

  ALTER TABLE ONLY gn_meta.cor_acquisition_framework_actor
      DROP constraint fk_cor_acquisition_framework_actor_id_acquisition_framework;
  ALTER TABLE ONLY gn_meta.cor_acquisition_framework_actor
      ADD CONSTRAINT fk_cor_acquisition_framework_actor_id_acquisition_framework FOREIGN KEY (id_acquisition_framework)
      REFERENCES gn_meta.t_acquisition_frameworks(id_acquisition_framework) ON UPDATE CASCADE ON DELETE CASCADE;

  ALTER TABLE ONLY gn_meta.cor_acquisition_framework_actor
  drop  constraint fk_cor_acquisition_framework_actor_id_role;
  ALTER TABLE ONLY gn_meta.cor_acquisition_framework_actor
      ADD CONSTRAINT fk_cor_acquisition_framework_actor_id_role FOREIGN KEY (id_role)
      REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;

  ALTER TABLE ONLY gn_meta.cor_acquisition_framework_actor
      DROP constraint fk_cor_acquisition_framework_actor_id_organism;
  ALTER TABLE ONLY gn_meta.cor_acquisition_framework_actor
      ADD CONSTRAINT fk_cor_acquisition_framework_actor_id_organism FOREIGN KEY (id_organism)
      REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE ON DELETE CASCADE;

  ALTER TABLE ONLY gn_meta.cor_acquisition_framework_voletsinp
      DROP constraint fk_cor_acquisition_framework_voletsinp_id_acquisition_framework;
  ALTER TABLE ONLY gn_meta.cor_acquisition_framework_voletsinp
      ADD CONSTRAINT fk_cor_acquisition_framework_voletsinp_id_acquisition_framework FOREIGN KEY (id_acquisition_framework)
      REFERENCES gn_meta.t_acquisition_frameworks(id_acquisition_framework) ON UPDATE CASCADE ON DELETE NO ACTION;

  ALTER TABLE ONLY gn_meta.cor_acquisition_framework_publication
      DROP constraint fk_cor_acquisition_framework_publication_id_publication;
  ALTER TABLE ONLY gn_meta.cor_acquisition_framework_publication
      ADD CONSTRAINT fk_cor_acquisition_framework_publication_id_publication FOREIGN KEY (id_acquisition_framework)
      REFERENCES gn_meta.t_acquisition_frameworks(id_acquisition_framework) ON UPDATE CASCADE ON DELETE CASCADE;

  ---------------------------------------
  -- OCCTAX - ADDITIONAL FIELDS & DATA --
  ---------------------------------------
  DO $$
    BEGIN
      IF EXISTS (
        SELECT 1
        FROM information_schema.schemata
        WHERE schema_name = 'pr_occtax'
      ) IS TRUE THEN
        -- Ajout des tables pour les données additionnels dans Occtax
        ALTER TABLE pr_occtax.t_releves_occtax
            ADD COLUMN additional_fields jsonb;

        ALTER TABLE pr_occtax.t_occurrences_occtax
            ADD COLUMN additional_fields jsonb;

        ALTER TABLE pr_occtax.cor_counting_occtax
            ADD COLUMN additional_fields jsonb;

        -- Révision de la fonction insérant les données d'Occtax vers la synthèse, pour y ajouter les champs additionnels
        CREATE OR REPLACE FUNCTION pr_occtax.insert_in_synthese(my_id_counting integer)
            RETURNS integer[]
        AS $BODY$  DECLARE
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
          --CHAMPS ADDITIONNELS OCCTAX
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
            --CHAMPS ADDITIONNELS OCCTAX
            releve.additional_fields || occurrence.additional_fields || new_count.additional_fields
          );

            RETURN myobservers.observers_id ;
          END;
          $BODY$
            LANGUAGE plpgsql VOLATILE
          COST 100;

        -- Révision de la fonction mettant à jour les données d'Occtax vers la synthèse, pour y ajouter les champs additionnels
        CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_counting()
          RETURNS trigger
          LANGUAGE 'plpgsql'
          VOLATILE
          COST 100
        AS $BODY$DECLARE
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
        $BODY$;

        CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_occ()
          RETURNS trigger
        AS $BODY$  declare
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
            id_nomenclature_behaviour = id_nomenclature_behaviour,
            cd_nom = NEW.cd_nom,
            nom_cite = NEW.nom_cite,
            meta_v_taxref = NEW.meta_v_taxref,
            sample_number_proof = NEW.sample_number_proof,
            digital_proof = NEW.digital_proof,
            non_digital_proof = NEW.non_digital_proof,
            comment_description = NEW.comment,
            last_action = 'U',
          --CHAMPS ADDITIONNELS OCCTAX
          additional_data =  releve_add_fields || NEW.additional_fields || counting.additional_fields
          WHERE unique_id_sinp = counting.unique_id_sinp_occtax;

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
      $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;


        DROP FUNCTION pr_occtax.id_releve_from_id_counting(my_id_counting integer);
        CREATE OR REPLACE FUNCTION pr_occtax.id_releve_from_id_counting(my_id_counting integer)
          RETURNS setof bigint AS
        $BODY$
        -- Function which return the id_countings in an array (table pr_occtax.cor_counting_occtax) from the id_releve(integer)
        begin
          return QUERY select rel.id_releve_occtax
          FROM pr_occtax.t_releves_occtax rel
          JOIN pr_occtax.t_occurrences_occtax occ ON occ.id_releve_occtax = rel.id_releve_occtax
          JOIN pr_occtax.cor_counting_occtax counting ON counting.id_occurrence_occtax = occ.id_occurrence_occtax
          WHERE counting.id_counting_occtax = my_id_counting;
        END;
        $BODY$
          LANGUAGE plpgsql IMMUTABLE
          COST 100;


      CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_insert_cor_role_releve()
        RETURNS trigger AS
      $BODY$
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
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;

        DROP TRIGGER IF EXISTS tri_synthese_insert_cor_role_releve ON pr_occtax.cor_role_releves_occtax;
        CREATE TRIGGER tri_synthese_insert_cor_role_releve
          AFTER INSERT
          ON pr_occtax.cor_role_releves_occtax
          FOR EACH ROW
          EXECUTE PROCEDURE pr_occtax.fct_tri_synthese_insert_cor_role_releve();

        -- Ajout des champs additionnels dans l'export Occtax
        DROP view if exists pr_occtax.v_export_occtax;
        CREATE OR REPLACE VIEW pr_occtax.v_export_occtax
        AS SELECT rel.unique_id_sinp_grp AS "idSINPRegroupement",
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
            (occ.additional_fields || rel.additional_fields) || ccc.additional_fields AS additional_data
          FROM pr_occtax.t_releves_occtax rel
            LEFT JOIN pr_occtax.t_occurrences_occtax occ ON rel.id_releve_occtax = occ.id_releve_occtax
            LEFT JOIN pr_occtax.cor_counting_occtax ccc ON ccc.id_occurrence_occtax = occ.id_occurrence_occtax
            LEFT JOIN taxonomie.taxref tax ON tax.cd_nom = occ.cd_nom
            LEFT JOIN gn_meta.t_datasets d ON d.id_dataset = rel.id_dataset
            LEFT JOIN pr_occtax.cor_role_releves_occtax cr ON cr.id_releve_occtax = rel.id_releve_occtax
            LEFT JOIN utilisateurs.t_roles r ON r.id_role = cr.id_role
            LEFT JOIN utilisateurs.bib_organismes o ON o.id_organisme = r.id_organisme
            LEFT JOIN ref_habitats.habref hab ON hab.cd_hab = rel.cd_hab
          GROUP BY ccc.id_counting_occtax, occ.id_occurrence_occtax, rel.id_releve_occtax, d.id_dataset, tax.cd_ref, tax.lb_nom, tax.nom_vern, hab.cd_hab, hab.lb_code, hab.lb_hab_fr;


        -- Insertion des données de référence pour les champs additionnels
        INSERT INTO gn_permissions.t_objects (code_object, description_object) VALUES
          ('OCCTAX_RELEVE', 'Représente la table pr_occtax.t_releves_occtax'),
          ('OCCTAX_OCCURENCE', 'Représente la table pr_occtax.t_occurrences_occtax'),
          ('OCCTAX_DENOMBREMENT', 'Représente la table pr_occtax.cor_counting_occtax')
        ;


        -- Correction des données des observateurs de la synthèse, liée au bug du trigger sur pr_occtax.cor_role
        DELETE FROM gn_synthese.cor_observer_synthese
        WHERE id_synthese IN (
          SELECT id_synthese
          FROM gn_synthese.synthese s
          JOIN gn_synthese.t_sources t ON s.id_source = t.id_source
          WHERE t.name_source ILIKE 'Occtax'
        );

        INSERT INTO gn_synthese.cor_observer_synthese(id_synthese, id_role)
          SELECT s.id_synthese, obs.id_role
          FROM pr_occtax.cor_role_releves_occtax obs
          JOIN pr_occtax.t_occurrences_occtax occ ON occ.id_releve_occtax = obs.id_releve_occtax
          JOIN pr_occtax.cor_counting_occtax _count ON _count.id_occurrence_occtax = occ.id_occurrence_occtax
          JOIN gn_synthese.synthese s ON _count.unique_id_sinp_occtax = s.unique_id_sinp
        ;

      ELSE
        RAISE NOTICE 'Schema pr_occtax does not exists';
      END IF;
    END
  $$;

  -------------------------------------------------------
  -- GN_COMMONS - GENERIC ADDITIONAL FIELDS MANAGEMENT --
  -------------------------------------------------------

  -- Ajout des tables de gestion des champs additionnels
  CREATE TABLE gn_commons.bib_widgets (
    id_widget serial NOT NULL,
    widget_name varchar(50) NOT NULL
  );

  CREATE TABLE gn_commons.t_additional_fields (
    id_field serial NOT NULL,
    field_name varchar(255) NOT NULL,
    field_label varchar(50) NOT NULL,
    required bool NOT NULL DEFAULT false,
    description text NULL,
    id_widget int4 NOT NULL,
    quantitative bool NULL DEFAULT false,
    unity varchar(50) NULL,
    additional_attributes jsonb NULL,
    code_nomenclature_type varchar(255) NULL,
    field_values jsonb NULL,
    multiselect boolean NULL,
    id_list integer,
    key_label varchar(250),
    key_value varchar(250),
    api varchar(250),
    exportable boolean default TRUE,
    field_order integer NULL
  );

  CREATE TABLE gn_commons.cor_field_object(
  id_field integer,
  id_object integer
  );

  CREATE TABLE gn_commons.cor_field_module(
  id_field integer,
  id_module integer
  );

  CREATE TABLE gn_commons.cor_field_dataset(
  id_field integer,
  id_dataset integer
  );

  ALTER TABLE ONLY gn_commons.bib_widgets
      ADD CONSTRAINT pk_bib_widgets PRIMARY KEY (id_widget);

  ALTER TABLE ONLY gn_commons.t_additional_fields
      ADD CONSTRAINT pk_t_additional_fields PRIMARY KEY (id_field);

  ALTER TABLE ONLY gn_commons.cor_field_module
      ADD CONSTRAINT pk_cor_field_module PRIMARY KEY (id_field, id_module);

  ALTER TABLE ONLY gn_commons.cor_field_object
      ADD CONSTRAINT pk_cor_field_object PRIMARY KEY (id_field, id_object);

  ALTER TABLE ONLY gn_commons.cor_field_dataset
      ADD CONSTRAINT pk_cor_field_dataset PRIMARY KEY (id_field, id_dataset);

  ALTER TABLE ONLY gn_commons.t_additional_fields
    ADD CONSTRAINT fk_t_additional_fields_id_widget FOREIGN KEY (id_widget)
    REFERENCES gn_commons.bib_widgets(id_widget) ON UPDATE CASCADE ON DELETE CASCADE;

  ALTER TABLE ONLY gn_commons.cor_field_object
    ADD CONSTRAINT fk_cor_field_obj_field FOREIGN KEY (id_field)
    REFERENCES gn_commons.t_additional_fields(id_field) ON UPDATE CASCADE ON DELETE CASCADE;

  ALTER TABLE ONLY gn_commons.cor_field_object
    ADD CONSTRAINT fk_cor_field_object FOREIGN KEY (id_object)
    REFERENCES gn_permissions.t_objects(id_object) ON UPDATE CASCADE ON DELETE CASCADE;

  ALTER TABLE ONLY gn_commons.cor_field_module
    ADD CONSTRAINT fk_cor_field_module_field FOREIGN KEY (id_field)
    REFERENCES gn_commons.t_additional_fields(id_field) ON UPDATE CASCADE ON DELETE CASCADE;

  ALTER TABLE ONLY gn_commons.cor_field_module
    ADD CONSTRAINT fk_cor_field_module FOREIGN KEY (id_module)
    REFERENCES gn_commons.t_modules(id_module) ON UPDATE CASCADE ON DELETE CASCADE;

  ALTER TABLE ONLY gn_commons.cor_field_dataset
    ADD CONSTRAINT fk_cor_field_dataset_field FOREIGN KEY (id_field)
    REFERENCES gn_commons.t_additional_fields(id_field) ON UPDATE CASCADE ON DELETE CASCADE;

  ALTER TABLE ONLY gn_commons.cor_field_dataset
    ADD CONSTRAINT fk_cor_field_dataset FOREIGN KEY (id_dataset)
    REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE ON DELETE CASCADE;

  INSERT INTO gn_commons.bib_widgets (widget_name) VALUES ('select'),
    ('checkbox'),
    ('nomenclature'),
    ('text'),
    ('textarea'),
    ('radio'),
    ('time'),
    ('bool_radio'),
    ('date'),
    ('multiselect'),
    ('number'),
    ('taxonomy'),
    ('html');


  ----------------------------------
  -- MONITORING - DATES & HISTORY --
  ----------------------------------

  -- Ajout trigger sur date_max de la visite

  -- Mise à jour des données
  UPDATE  gn_monitoring.t_base_visits SET visit_date_max = visit_date_max
  WHERE visit_date_max < visit_date_min;

  CREATE OR REPLACE FUNCTION gn_monitoring.fct_trg_visite_date_max()
  RETURNS trigger
  LANGUAGE plpgsql
  AS $function$
  BEGIN
    -- Si la date max de la visite est nulle ou inférieure à la date_min
    --	Modification de date max pour garder une cohérence des données
    IF
      NEW.visit_date_max IS NULL
      OR NEW.visit_date_max < NEW.visit_date_min
    THEN
        NEW.visit_date_max := NEW.visit_date_min;
      END IF;
    RETURN NEW;
  END;
  $function$
  ;

  CREATE TRIGGER tri_visite_date_max
    BEFORE INSERT OR UPDATE OF visit_date_min
    ON gn_monitoring.t_base_visits
    FOR EACH ROW
    EXECUTE FUNCTION gn_monitoring.fct_trg_visite_date_max();


  --- Historisation de la table cor_visit_observer
  ALTER TABLE gn_monitoring.cor_visit_observer ADD unique_id_core_visit_observer uuid  NOT NULL DEFAULT uuid_generate_v4();

  INSERT INTO gn_commons.bib_tables_location(table_desc, schema_name, table_name, pk_field, uuid_field_name)
  VALUES
  ('Liste des observateurs d''une visite', 'gn_monitoring', 'cor_visit_observer', 'unique_id_core_visit_observer', 'unique_id_core_visit_observer');

  CREATE TRIGGER tri_log_changes_cor_visit_observer
  AFTER INSERT OR DELETE OR UPDATE
  ON gn_monitoring.cor_visit_observer
  FOR EACH ROW EXECUTE FUNCTION gn_commons.fct_trg_log_changes();

  -- Révision de la vue des exports de la synthèse, pour y ajouter les champs additionnels (champs JSON unique)
  DROP VIEW gn_synthese.v_synthese_for_export ;

  CREATE OR REPLACE VIEW gn_synthese.v_synthese_for_export AS
  SELECT
      s.id_synthese AS id_synthese,
      s.date_min::date AS date_debut,
      s.date_max::date AS date_fin,
      s.date_min::time AS heure_debut,
      s.date_max::time AS heure_fin,
      t.cd_nom AS cd_nom,
      t.cd_ref AS cd_ref,
      t.nom_valide AS nom_valide,
      t.nom_vern as nom_vernaculaire,
      s.nom_cite AS nom_cite,
      t.regne AS regne,
      t.group1_inpn AS group1_inpn,
      t.group2_inpn AS group2_inpn,
      t.classe AS classe,
      t.ordre AS ordre,
      t.famille AS famille,
      t.id_rang AS rang_taxo,
      s.count_min AS nombre_min,
      s.count_max AS nombre_max,
      s.altitude_min AS alti_min,
      s.altitude_max AS alti_max,
      s.depth_min AS prof_min,
      s.depth_max AS prof_max,
      s.observers AS observateurs,
      s.id_digitiser AS id_digitiser, -- Utile pour le CRUVED
      s.determiner AS determinateur,
      communes AS communes,
      public.ST_astext(s.the_geom_4326) AS geometrie_wkt_4326,
      public.ST_x(s.the_geom_point) AS x_centroid_4326,
      public.ST_y(s.the_geom_point) AS y_centroid_4326,
      public.ST_asgeojson(s.the_geom_4326) AS geojson_4326,-- Utile pour la génération de l'export en SHP
      public.ST_asgeojson(s.the_geom_local) AS geojson_local,-- Utile pour la génération de l'export en SHP
      s.place_name AS nom_lieu,
      s.comment_context AS comment_releve,
      s.comment_description AS comment_occurrence,
      s.validator AS validateur,
      n21.label_default AS niveau_validation,
      s.meta_validation_date as date_validation,
      s.validation_comment AS comment_validation,
      s.digital_proof AS preuve_numerique_url,
      s.non_digital_proof AS preuve_non_numerique,
      d.dataset_name AS jdd_nom,
      d.unique_dataset_id AS jdd_uuid,
      d.id_dataset AS jdd_id, -- Utile pour le CRUVED
      af.acquisition_framework_name AS ca_nom,
      af.unique_acquisition_framework_id AS ca_uuid,
      d.id_acquisition_framework AS ca_id,
      s.cd_hab AS cd_habref,
      hab.lb_code AS cd_habitat,
      hab.lb_hab_fr AS nom_habitat,
      s.precision as precision_geographique,
      n1.label_default AS nature_objet_geo,
      n2.label_default AS type_regroupement,
      s.grp_method AS methode_regroupement,
      n3.label_default AS technique_observation,
      n5.label_default AS biologique_statut,
      n6.label_default AS etat_biologique,
      n22.label_default AS biogeographique_statut,
      n7.label_default AS naturalite,
      n8.label_default AS preuve_existante,
      n9.label_default AS niveau_precision_diffusion,
      n10.label_default AS stade_vie,
      n11.label_default AS sexe,
      n12.label_default AS objet_denombrement,
      n13.label_default AS type_denombrement,
      n14.label_default AS niveau_sensibilite,
      n15.label_default AS statut_observation,
      n16.label_default AS floutage_dee,
      n17.label_default AS statut_source,
      n18.label_default AS type_info_geo,
      n19.label_default AS methode_determination,
      n20.label_default AS comportement,
      s.reference_biblio AS reference_biblio,
      s.entity_source_pk_value AS id_origine,
      s.unique_id_sinp AS uuid_perm_sinp,
      s.unique_id_sinp_grp AS uuid_perm_grp_sinp,
      s.meta_create_date AS date_creation,
      s.meta_update_date AS date_modification,
      COALESCE(s.meta_update_date, s.meta_create_date) AS derniere_action,
      s.additional_data as champs_additionnels
    FROM gn_synthese.synthese s
      JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
      JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
      JOIN gn_meta.t_acquisition_frameworks af ON d.id_acquisition_framework = af.id_acquisition_framework
      LEFT OUTER JOIN (
          SELECT id_synthese, string_agg(DISTINCT area_name, ', ') AS communes
          FROM gn_synthese.cor_area_synthese cas
          LEFT OUTER JOIN ref_geo.l_areas a_1 ON cas.id_area = a_1.id_area
          JOIN ref_geo.bib_areas_types ta ON ta.id_type = a_1.id_type AND ta.type_code ='COM'
          GROUP BY id_synthese
      ) sa ON sa.id_synthese = s.id_synthese
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
      LEFT JOIN ref_nomenclatures.t_nomenclatures n21 ON s.id_nomenclature_valid_status = n21.id_nomenclature
      LEFT JOIN ref_nomenclatures.t_nomenclatures n22 ON s.id_nomenclature_biogeo_status = n22.id_nomenclature
      LEFT JOIN ref_habitats.habref hab ON hab.cd_hab = s.cd_hab;


  -- Mise à jour MTD
  -- Ajout de commentaires et de 2 tables

COMMENT ON TABLE gn_meta.cor_dataset_territory
    IS 'A dataset must have 1 or n "territoire". Implement 1.3.10 SINP metadata standard : Cible géographique du jeu de données, ou zone géographique visée par le jeu. Défini par une valeur dans la nomenclature TerritoireValue. - OBLIGATOIRE';

COMMENT ON TABLE gn_meta.cor_acquisition_framework_publication
    IS 'A acquisition framework can have 0 or n "publication". Implement 1.3.10 SINP metadata standard : Référence(s) bibliographique(s) éventuelle(s) concernant le cadre d''acquisition - RECOMMANDE';

COMMENT ON TABLE gn_meta.cor_acquisition_framework_objectif
    IS 'A acquisition framework can have 1 or n "objectif". Implement 1.3.10 SINP metadata standard : Objectif du cadre d''acquisition, tel que défini par la nomenclature TypeDispositifValue - OBLIGATOIRE';

COMMENT ON TABLE gn_meta.cor_acquisition_framework_actor
    IS 'A acquisition framework must have a principal actor "acteurPrincipal" and can have 0 or n other actor "acteurAutre". Implement 1.3.10 SINP metadata standard : Contact principal pour le cadre d''acquisition (Règle : RoleActeur prendra la valeur 1) - OBLIGATOIRE. Autres contacts pour le cadre d''acquisition (exemples : maître d''oeuvre, d''ouvrage...).- RECOMMANDE';

COMMENT ON TABLE gn_meta.cor_acquisition_framework_voletsinp
    IS 'A acquisition framework can have 0 or n "voletSINP". Implement 1.3.10 SINP metadata standard : Volet du SINP concerné par le dispositif de collecte, tel que défini dans la nomenclature voletSINPValue - FACULTATIF';

COMMENT ON TABLE gn_meta.cor_dataset_actor
    IS 'A dataset must have 1 or n actor ""pointContactJdd"". Implement 1.3.10 SINP metadata standard : Point de contact principal pour les données du jeu de données, et autres éventuels contacts (fournisseur ou producteur). (Règle : Un contact au moins devra avoir roleActeur à 1 - Les autres types possibles pour roleActeur sont 5 et 6 (fournisseur et producteur)) - OBLIGATOIRE';

COMMENT ON TABLE gn_meta.cor_dataset_protocol
    IS 'A dataset can have 0 or n "protocole". Implement 1.3.10 SINP metadata standard : Protocole(s) rattaché(s) au jeu de données (protocole de synthèse et/ou de collecte). On se rapportera au type "Protocole Type". - RECOMMANDE';

COMMENT ON TABLE gn_meta.t_acquisition_frameworks
    IS 'Define a acquisition framework that embed datasets. Implement 1.3.10 SINP metadata standard';


CREATE TABLE gn_meta.cor_acquisition_framework_territory
(
    id_acquisition_framework integer NOT NULL,
    id_nomenclature_territory integer NOT NULL,
    CONSTRAINT pk_cor_acquisition_framework_territory PRIMARY KEY (id_acquisition_framework, id_nomenclature_territory),
    CONSTRAINT fk_cor_af_territory_id_af FOREIGN KEY (id_acquisition_framework)
        REFERENCES gn_meta.t_acquisition_frameworks (id_acquisition_framework) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE NO ACTION,
    CONSTRAINT fk_cor_af_territory_id_nomenclature_territory FOREIGN KEY (id_nomenclature_territory)
        REFERENCES ref_nomenclatures.t_nomenclatures (id_nomenclature) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE NO ACTION,
    CONSTRAINT check_cor_af_territory CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_territory, 'TERRITOIRE'::character varying)) NOT VALID
);

COMMENT ON TABLE gn_meta.cor_acquisition_framework_territory
    IS 'A acquisition_framework must have 1 or n "territoire". Implement 1.3.10 SINP metadata standard : Cible géographique du jeu de données, ou zone géographique visée par le jeu. Défini par une valeur dans la nomenclature TerritoireValue. - OBLIGATOIRE';


CREATE TABLE gn_meta.t_bibliographical_references
(
    id_bibliographic_reference serial,
    id_acquisition_framework integer NOT NULL,
    publication_url character varying COLLATE pg_catalog."default",
    publication_reference character varying COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT t_bibliographical_references_pkey PRIMARY KEY (id_bibliographic_reference),
    CONSTRAINT t_bibliographical_references_id_acquisition_framework_fkey FOREIGN KEY (id_acquisition_framework)
        REFERENCES gn_meta.t_acquisition_frameworks (id_acquisition_framework) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

COMMENT ON TABLE gn_meta.t_bibliographical_references
    IS 'A acquisition_framework must have 0 or n "publical references". Implement 1.3.10 SINP metadata standard : Référence(s) bibliographique(s) éventuelle(s) concernant le cadre d''acquisition. - RECOMMANDE';

COMMIT;
