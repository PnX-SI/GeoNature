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

-- Ajout du type de jeu de donnees

ALTER TABLE gn_meta.t_datasets add column
id_nomenclature_jdd_data_type integer NOT NULL DEFAULT ref_nomenclatures.get_default_nomenclature_value('JDD_DATA_TYPE');

ALTER TABLE only gn_meta.t_datasets add CONSTRAINT
fk_t_datasets_jdd_data_type FOREIGN KEY (id_nomenclature_jdd_data_type) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

-- Usage de la table vm_taxref_list_forautocomplete du schéma taxonomie
DROP TABLE taxonomie.taxons_synthese_autocomplete;

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
  select_col_name varchar,
  select_col_val varchar,
  table_name varchar
)
RETURNS boolean AS
$BODY$
  DECLARE
    select_sql text;
    import_rec record;
  BEGIN
    -- TODO transtypage en text pour des questions de généricité. A réflechir
    select_sql := 'SELECT row_to_json(c)::jsonb d
        FROM ' || table_name || ' c
        WHERE ' ||  select_col_name|| '::text = ''' || select_col_val || '''' ;

    FOR import_rec IN EXECUTE select_sql LOOP
        PERFORM gn_synthese.import_json_row(import_rec.d);
    END LOOP;

  RETURN TRUE;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
