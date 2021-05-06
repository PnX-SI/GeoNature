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
  REFERENCES gn_commons.bib(id_field) ON UPDATE CASCADE ON DELETE CASCADE;


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

INSERT INTO gn_permissions.t_objects (code_object, description_object) VALUES 
  ('OCCTAX_RELEVE', 'Représente la table pr_occtax.t_releves_occtax'),
  ('OCCTAX_OCCURENCE', 'Représente la table pr_occtax.t_occurrences_occtax'),
  ('OCCTAX_DENOMBREMENT', 'Représente la table pr_occtax.cor_counting_occtax')
  ;

INSERT INTO gn_commons.bib_widgets (widget_name) VALUES ('select'),
	 ('checkbox'),
	 ('nomenclature'),
	 ('text'),
	 ('textarea'),
	 ('radio'),
	 ('time'),
	 ('medias'),
	 ('bool_radio'),
	 ('date'),
	 ('multiselect'),
	 ('number'),
	 ('taxonomy'),
	 ('observers'),
	 ('html');


-- META

ALTER TABLE gn_meta.t_datasets 
ADD COLUMN id_taxa_list integer;
COMMENT ON COLUMN gn_meta.t_datasets.id_taxa_list IS 'Identifiant de la liste de taxon associé au JDD. FK: taxonomie.bib_liste';

ALTER TABLE ONLY gn_meta.t_datasets
    ADD CONSTRAINT fk_t_datasets_id_taxa_list FOREIGN KEY (id_taxa_list) REFERENCES taxonomie.bib_listes ON UPDATE CASCADE;
