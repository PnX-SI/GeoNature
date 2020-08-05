-- Trigger générique de calcule de l'altitude (calcule si l'altitude n'est pas postée)
CREATE OR REPLACE FUNCTION ref_geo.fct_trg_calculate_alt_minmax()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	the4326geomcol text := quote_ident(TG_ARGV[0]);
  thelocalsrid int;
BEGIN
	-- si c'est un insert et que l'altitude min ou max est null -> on calcule
	IF (TG_OP = 'INSERT' and (new.altitude_min IS NULL or new.altitude_max IS NULL)) THEN
		--récupérer le srid local
		SELECT INTO thelocalsrid parameter_value::int FROM gn_commons.t_parameters WHERE parameter_name = 'local_srid';
		--Calcul de l'altitude

    SELECT (ref_geo.fct_get_altitude_intersection(st_transform(hstore(NEW)-> the4326geomcol,thelocalsrid))).*  INTO NEW.altitude_min, NEW.altitude_max;
    -- si c'est un update et que la geom a changé
  ELSIF (TG_OP = 'UPDATE' AND NOT public.ST_EQUALS(hstore(OLD)-> the4326geomcol, hstore(NEW)-> the4326geomcol)) then
	 -- on vérifie que les altitude ne sont pas null
   -- OU si les altitudes ont changé, si oui =  elles ont déjà été calculés - on ne relance pas le calcul
	   IF (new.altitude_min is null or new.altitude_max is null) OR (NOT OLD.altitude_min = NEW.altitude_min or NOT OLD.altitude_max = OLD.altitude_max) THEN
	   --récupérer le srid local
	   SELECT INTO thelocalsrid parameter_value::int FROM gn_commons.t_parameters WHERE parameter_name = 'local_srid';
		--Calcul de l'altitude
        SELECT (ref_geo.fct_get_altitude_intersection(st_transform(hstore(NEW)-> the4326geomcol,thelocalsrid))).*  INTO NEW.altitude_min, NEW.altitude_max;
	   end IF;
	 else
	 END IF;
  RETURN NEW;
END;
$function$
;

-- Application du trigger sur Occtax
CREATE TRIGGER tri_calculate_altitude
  BEFORE INSERT OR UPDATE
  ON pr_occtax.t_releves_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE ref_geo.fct_trg_calculate_alt_minmax('geom_4326');

-- Mise à jour des URL des documentations utilisateurs
UPDATE gn_commons.t_modules
   SET module_doc_url='http://docs.geonature.fr/user-manual.html'
   WHERE module_code='GEONATURE';
UPDATE gn_commons.t_modules
   SET module_doc_url='http://docs.geonature.fr/user-manual.html#admin'
   WHERE module_code='ADMIN';
UPDATE gn_commons.t_modules
   SET module_doc_url='http://docs.geonature.fr/user-manual.html#metadonnees'
   WHERE module_code='METADATA';
UPDATE gn_commons.t_modules
   SET module_doc_url='http://docs.geonature.fr/user-manual.html#synthese'
   WHERE module_code='SYNTHESE';
UPDATE gn_commons.t_modules
   SET module_doc_url='http://docs.geonature.fr/user-manual.html#occtax'
   WHERE module_code='OCCTAX';

-- Création de la table necessaire au MAJ mobiles
CREATE TABLE gn_commons.t_mobile_apps(
  id_mobile_app serial,
  app_code character varying(30),
  relative_path_apk character varying(255),
  url_apk character varying(255),
  package character varying(255),
  version_code character varying(10)
);

COMMENT ON COLUMN gn_commons.t_mobile_apps.app_code IS 'Code de l''application mobile. Pas de FK vers t_modules car une application mobile ne correspond pas forcement à un module GN';

ALTER TABLE ONLY gn_commons.t_mobile_apps
    ADD CONSTRAINT pk_t_moobile_apps PRIMARY KEY (id_mobile_app);

ALTER TABLE gn_commons.t_mobile_apps
    ADD CONSTRAINT unique_t_mobile_apps_app_code UNIQUE (app_code);

-- Ajout du champs reference_biblio dans la synthese
ALTER TABLE gn_synthese.synthese
ADD COLUMN reference_biblio character varying(255);

-- Amélioration des performances de la vue v_synthese_validation_forwebapp

DROP VIEW gn_commons.v_synthese_validation_forwebapp;
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
    s.id_nomenclature_obs_meth,
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
  WHERE d.validable = true;

DROP view gn_synthese.v_synthese_for_web_app;
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
    s.id_nomenclature_obs_meth,
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


-- Fonctions import dans la synthese

CREATE OR REPLACE FUNCTION gn_synthese.import_json_row(
	datain jsonb,
  datageojson text default NULL -- données géographique sous la forme d'un geojson TODO a voir le paramètre du type text ou json
)
RETURNS boolean AS
$BODY$
  DECLARE
    insert_columns text;
    select_columns text;
    update_columns text;

    geom geometry;
    geom_data jsonb;
    local_srid int;
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
      SELECT column_name, column_default, CASE WHEN data_type = 'USER-DEFINED' THEN NULL ELSE data_type END as data_type
      FROM information_schema.columns
      WHERE table_schema || '.' || table_name = 'gn_synthese.synthese'
  )
  SELECT
      string_agg(s.column_name, ',')  as insert_columns,
      string_agg(
          CASE
              WHEN NOT column_default IS NULL THEN 'COALESCE((datain->>''' || i.column_name  || ''')' || COALESCE('::' || data_type, '') || ', ' || column_default || ') as ' || i.column_name
          ELSE '(datain->>''' || i.column_name  || ''')' || COALESCE('::' || data_type, '')
          END, ','
      ) as select_columns ,
      string_agg(
          s.column_name || '=' || CASE
              WHEN NOT column_default IS NULL THEN 'COALESCE((datain->>''' || i.column_name  || ''')' || COALESCE('::' || data_type, '') || ', ' || column_default || ') '
          ELSE '(datain->>''' || i.column_name  || ''')' || COALESCE('::' || data_type, '')
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
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;




CREATE OR REPLACE FUNCTION gn_synthese.import_row_from_table(
    select_col_name character varying,
    select_col_val character varying,
    tbl_name character varying
)
RETURNS boolean AS
$BODY$
DECLARE
  select_sql text;
  import_rec record;
BEGIN

  --test que la table/vue existe bien
  --42P01 	undefined_table
  IF EXISTS (
      SELECT 1 FROM information_schema.tables t  WHERE t.table_schema ||'.'|| t.table_name = tbl_name
  ) IS FALSE THEN
      RAISE 'Undefined table: %', tbl_name USING ERRCODE = '42P01';
	END IF ;

  --test que la colonne existe bien
  --42703 	undefined_column
  IF EXISTS (
      SELECT * FROM information_schema.columns  t  WHERE  t.table_schema ||'.'|| t.table_name = tbl_name AND column_name = select_col_name
  ) IS FALSE THEN
      RAISE 'Undefined column: %', select_col_name USING ERRCODE = '42703';
	END IF ;


    -- TODO transtypage en text pour des questions de généricité. A réflechir
    select_sql := 'SELECT row_to_json(c)::jsonb d
        FROM ' || tbl_name || ' c
        WHERE ' ||  select_col_name|| '::text = ''' || select_col_val || '''' ;

    FOR import_rec IN EXECUTE select_sql LOOP
        PERFORM gn_synthese.import_json_row(import_rec.d);
    END LOOP;

  RETURN TRUE;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;



-- Correction des trigger / inversion jour et mois

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
id_nomenclature_obs_meth,
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
count_min,
count_max,
cd_nom,
nom_cite,
meta_v_taxref,
sample_number_proof,
digital_proof,
non_digital_proof,
altitude_min,
altitude_max,
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
  --nature de l'objet geo: id_nomenclature_geo_object_nature Le taxon observé est présent quelque part dans l'objet géographique - NSP par défault
  pr_occtax.get_default_nomenclature_value('NAT_OBJ_GEO'),
  releve.id_nomenclature_grp_typ,
  occurrence.id_nomenclature_obs_meth,
  releve.id_nomenclature_obs_technique,
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
  -- id_nomenclature_info_geo_type: type de rattachement = géoréferencement
  ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO', '1')	,
  new_count.count_min,
  new_count.count_max,
  occurrence.cd_nom,
  occurrence.nom_cite,
  occurrence.meta_v_taxref,
  occurrence.sample_number_proof,
  occurrence.digital_proof,
  occurrence.non_digital_proof,
  releve.altitude_min,
  releve.altitude_max,
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
      id_nomenclature_obs_technique = NEW.id_nomenclature_obs_technique,
      id_nomenclature_grp_typ = NEW.id_nomenclature_grp_typ,
      date_min = date_trunc('day',NEW.date_min)+COALESCE(NEW.hour_min,'00:00:00'::time),
      date_max = date_trunc('day',NEW.date_max)+COALESCE(NEW.hour_max,'00:00:00'::time),
      altitude_min = NEW.altitude_min,
      altitude_max = NEW.altitude_max,
      the_geom_4326 = NEW.geom_4326,
      the_geom_point = ST_CENTROID(NEW.geom_4326),
      last_action = 'U',
      comment_context = NEW.comment
  WHERE unique_id_sinp IN (SELECT unnest(pr_occtax.get_unique_id_sinp_from_id_releve(NEW.id_releve_occtax::integer)));
  RETURN NULL;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ##########################################################
-- Mise à jour de la vue gn_commons.v_meta_actions_on_object
-- ##########################################################

CREATE OR REPLACE VIEW gn_commons.v_meta_actions_on_object AS
WITH insert_a AS (
	SELECT
		id_history_action, id_table_location, uuid_attached_row, operation_type, operation_date, (table_content ->> 'id_digitiser')::int as id_creator
	FROM gn_commons.t_history_actions
	WHERE operation_type = 'I'
),
delete_a AS (
	SELECT
		id_history_action, id_table_location, uuid_attached_row, operation_type, operation_date
	FROM gn_commons.t_history_actions
	WHERE operation_type = 'D'
),
last_update_a AS (
	SELECT DISTINCT ON (uuid_attached_row)
		id_history_action, id_table_location, uuid_attached_row, operation_type, operation_date
	FROM gn_commons.t_history_actions
	WHERE operation_type = 'U'
	ORDER BY uuid_attached_row, operation_date DESC
)
SELECT
	i.id_table_location, i.uuid_attached_row, i.operation_date as meta_create_date, i.id_creator, u.operation_date as meta_update_date,
	d.operation_date as meta_delete_date
FROM insert_a i
LEFT OUTER JOIN last_update_a u ON i.uuid_attached_row = u.uuid_attached_row
LEFT OUTER JOIN delete_a d ON i.uuid_attached_row = d.uuid_attached_row;



-- Ne plus considérer les géométries parfaitement limitrophes comme intersectantes
CREATE OR REPLACE FUNCTION gn_synthese.fct_trig_insert_in_cor_area_synthese()
  RETURNS trigger AS
$BODY$
  DECLARE
  id_area_loop integer;
  geom_change boolean;
  BEGIN
  geom_change = false;
  IF(TG_OP = 'UPDATE') THEN
	SELECT INTO geom_change NOT public.ST_EQUALS(OLD.the_geom_local, NEW.the_geom_local);
  END IF;

  IF (geom_change) THEN
	DELETE FROM gn_synthese.cor_area_synthese WHERE id_synthese = NEW.id_synthese;
  END IF;

  -- intersection avec toutes les areas et écriture dans cor_area_synthese
    IF (TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND geom_change )) THEN
      INSERT INTO gn_synthese.cor_area_synthese SELECT
	      s.id_synthese AS id_synthese,
        a.id_area AS id_area
        FROM ref_geo.l_areas a
        JOIN gn_synthese.synthese s 
        	ON public.ST_INTERSECTS(s.the_geom_local, a.geom)  AND NOT public.ST_TOUCHES(s.the_geom_local,a.geom)
        WHERE s.id_synthese = NEW.id_synthese AND a.enable IS true;
    END IF;
  RETURN NULL;
  END;
  $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- suppression synthese autocomplete
DROP TRIGGER trg_refresh_taxons_forautocomplete ON gn_synthese.synthese;
DROP TABLE gn_synthese.taxons_synthese_autocomplete;
DROP FUNCTION gn_synthese.fct_trg_refresh_taxons_forautocomplete() CASCADE;
