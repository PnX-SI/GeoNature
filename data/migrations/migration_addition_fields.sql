ALTER TABLE pr_occtax.t_releves_occtax
    ADD COLUMN additional_fields jsonb;
	
ALTER TABLE pr_occtax.t_occurrences_occtax
    ADD COLUMN additional_fields jsonb;
	
ALTER TABLE pr_occtax.cor_counting_occtax
    ADD COLUMN additional_fields jsonb;


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
	  new_count.additional_fields || occurrence.additional_fields || releve.additional_fields
  );

    RETURN myobservers.observers_id ;
  END;
  $BODY$
    LANGUAGE plpgsql VOLATILE
  COST 100;

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
  additional_data = NEW.additional_fields || occurrence.additional_fields || releve.additional_fields
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
    LANGUAGE 'plpgsql'
    VOLATILE
    COST 100
AS $BODY$  DECLARE
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
      last_action = 'U',
	  additional_data = NEW.additional_fields || pr_occtax.t_releves_occtax.additional_fields || pr_occtax.cor_counting_occtax.additional_fields
	FROM pr_occtax.t_releves_occtax 
	JOIN pr_occtax.cor_counting_occtax ON NEW.id_occurrence_occtax = pr_occtax.cor_counting_occtax.id_occurrence_occtax
    WHERE unique_id_sinp = pr_occtax.cor_counting_occtax.unique_id_sinp_occtax;
	
    RETURN NULL;
  END;
  $BODY$;

CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_releve()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    VOLATILE
    COST 100
AS $BODY$  DECLARE
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
        comment_context = NEW.comment,
		additional_data = NEW.additional_fields || occurrence.additional_fields || counting.additional_fields
	FROM pr_occtax.t_occurrences_occtax occurrence 
	JOIN pr_occtax.cor_counting_occtax counting
		ON counting.id_occurrence_occtax = occurrence.id_occurrence_occtax
		AND NEW.id_releve_occtax = occurrence.id_releve_occtax
	WHERE unique_id_sinp IN (SELECT unnest(pr_occtax.get_unique_id_sinp_from_id_releve(NEW.id_releve_occtax::integer)));
    RETURN NULL;
  END;
  $BODY$;
  


  -- Révision de la vue des exports Occtax
  CREATE OR REPLACE VIEW pr_occtax.v_export_occtax AS
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
      rel.precision,
      (occ.additional_fields || rel.additional_fields || ccc.additional_fields) AS additional_data
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


  -- ( SELECT string_agg(media.title_fr::text, ' - '::text) AS string_agg
  --          FROM gn_commons.t_medias media
  --            JOIN gn_commons.bib_tables_location tab_loc ON tab_loc.id_table_location = media.id_table_location
  --         WHERE tab_loc.table_name::text = 'cor_counting_occtax'::text AND ccc.unique_id_sinp_occtax = media.uuid_attached_row) AS "titreMedias",
  --   ( SELECT string_agg(media.description_fr, ' - '::text) AS string_agg
  --          FROM gn_commons.t_medias media
  --            JOIN gn_commons.bib_tables_location tab_loc ON tab_loc.id_table_location = media.id_table_location
  --         WHERE tab_loc.table_name::text = 'cor_counting_occtax'::text AND ccc.unique_id_sinp_occtax = media.uuid_attached_row) AS "descriptionMedias",
  --   ( SELECT string_agg(
  --               CASE
  --                   WHEN media.media_path IS NOT NULL THEN concat(gn_commons.get_default_parameter('url_api'::text), '/', media.media_path)::character varying
  --                   ELSE media.media_url
  --               END::text, ' - '::text) AS string_agg
  --          FROM gn_commons.t_medias media
  --            JOIN gn_commons.bib_tables_location tab_loc ON tab_loc.id_table_location = media.id_table_location
  --         WHERE tab_loc.table_name::text = 'cor_counting_occtax'::text AND ccc.unique_id_sinp_occtax = media.uuid_attached_row) AS "URLMedias"

INSERT INTO gn_permissions.t_objects (code_object, description_object) VALUES 
  ('OCCTAX_RELEVE', 'Représente la table pr_occtax.t_releves_occtax'),
  ('OCCTAX_OCCURENCE', 'Représente la table pr_occtax.t_occurrences_occtax'),
  ('OCCTAX_DENOMBREMENT', 'Représente la table pr_occtax.cor_counting_occtax')
  ;