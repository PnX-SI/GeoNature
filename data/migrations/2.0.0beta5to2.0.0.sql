CREATE OR REPLACE FUNCTION gn_commons.is_in_period(
    dateobs date,
    datebegin date,
    dateend date)
  RETURNS boolean
IMMUTABLE
LANGUAGE plpgsql
AS $$
DECLARE
day_obs int;
begin_day int;
end_day int;
test int; 

--Function to check if a date (dateobs) is in a period (datebegin, dateend)
--USAGE : SELECT gn_commons.is_in_period(dateobs, datebegin, dateend);
 
 
BEGIN
day_obs = extract(doy FROM dateobs);--jour de la date passée
begin_day = extract(doy FROM datebegin);--jour début
end_day = extract(doy FROM dateend); --jour fin
test = end_day - begin_day; --test si la période est sur 2 année ou pas
 
--si on est sur 2 années
IF test < 0 then
	IF day_obs BETWEEN begin_day AND 366 OR day_obs BETWEEN 1 AND end_day THEN RETURN true;
	END IF;
-- si on est dans la même année
else 
	IF day_obs BETWEEN begin_day AND end_day THEN RETURN true;
	END IF;
END IF;
	RETURN false;	
END;
$$;


CREATE OR REPLACE FUNCTION gn_commons.fct_trg_add_default_validation_status()
  RETURNS trigger AS
$BODY$
DECLARE
	theschema text := quote_ident(TG_TABLE_SCHEMA);
	thetable text := quote_ident(TG_TABLE_NAME);
	theidtablelocation int;
	theuuidfieldname character varying(50);
	theuuid uuid;
  thecomment text := 'auto = default value';
BEGIN
	--retrouver l'id de la table source stockant l'enregistrement en cours de validation
	SELECT INTO theidtablelocation gn_commons.get_table_location_id(theschema,thetable);
  --retouver le nom du champ stockant l'uuid de l'enregistrement en cours de validation
	SELECT INTO theuuidfieldname gn_commons.get_uuid_field_name(theschema,thetable);
  --récupérer l'uuid de l'enregistrement en cours de validation
	EXECUTE format('SELECT $1.%I', theuuidfieldname) INTO theuuid USING NEW;
  --insertion du statut de validation et des informations associées dans t_validations
  INSERT INTO gn_commons.t_validations (id_table_location,uuid_attached_row,id_nomenclature_valid_status,id_validator,validation_comment,validation_date)
  VALUES(
    theidtablelocation,
    theuuid,
    ref_nomenclatures.get_default_nomenclature_value('STATUT_VALID'), --comme la fonction est générique, cette valeur par défaut doit exister et est la même pour tous les modules
    null,
    thecomment,
    NOW()
  );
  RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

--fonction générique d'import csv
CREATE OR REPLACE FUNCTION gn_commons.load_csv_file(csv_file text, target_table text)
RETURNS text LANGUAGE plpgsql AS $$
--This function create a table and her structure according to the CSV structure and the passed name.
--CSV content is loaded in. 
--Then, the function tries to define the type of columns according to the content.
--You must check and adapt result.
--
--USAGE (due to 'copy' function usage, use it with a superuser only).
--SELECT gn_commons.load_csv_file('/path/to/file.csv', 'targetschema.targettable');
DECLARE
    col text; -- variable to keep the column name at each iteration
    sname text; --destination schema name
    tname text; --destination table name
begin
    create temp table import (line text) on commit drop;
    --import all csv content
    execute format('copy import from %L', csv_file);
    -- if not blank, change the csv_temp_table name to the name given as parameter
    IF length(target_table) > 0 THEN
	--split schema.table to 2 strings
	SELECT split_part(target_table, '.', 1) into sname;
	SELECT split_part(target_table, '.', 2) into tname;
	--if a schema name is given
	IF(tname IS NOT NULL) THEN
	    --drop if exists and create table with first line as columns name in given schema (before point in target_table string)
	    EXECUTE format('DROP TABLE IF EXISTS %I.%I', sname, tname);
	    EXECUTE format('create table %I.%I (%s);', 
	        sname, tname, concat(replace(line, ';', ' text, '), ' text'))
            from import limit 1;
	    -- load data in target table
	    EXECUTE format('copy %I.%I from %L WITH DELIMITER '';'' quote ''"'' csv header', sname, tname, csv_file);
	--if no schema is given working with public schema
	ELSE
	    --drop if exists and create table with first line as columns name in public schema
	    EXECUTE format('DROP TABLE IF EXISTS %I', target_table);
	    EXECUTE format('create table %I (%s);', 
	        target_table, concat(replace(line, ';', ' text, '), ' text'))
            from import limit 1;
            -- load data in target table
	    EXECUTE format('copy %I from %L WITH DELIMITER '';'' quote ''"'' csv ', target_table, csv_file);
        END IF;
        --try to change convert numeric and date columns type. If error throw, do nothing, continue and keep 'text' type.
        FOR col IN EXECUTE format('SELECT column_name FROM information_schema.columns WHERE table_schema  = %L AND table_name = %L', sname, tname)
        LOOP
	    BEGIN
	        EXECUTE format('ALTER TABLE %I.%I ALTER COLUMN %s TYPE integer USING %s::integer', sname, tname, col, col);
	        EXCEPTION WHEN OTHERS THEN 
		    BEGIN
		        EXECUTE format('ALTER TABLE %I.%I ALTER COLUMN %s TYPE real USING %s::real', sname, tname, col, col);
		        EXCEPTION WHEN OTHERS THEN
			    BEGIN
			        EXECUTE format('ALTER TABLE %I.%I ALTER COLUMN %s TYPE date USING %s::date', sname, tname, col, col);
			        EXCEPTION WHEN OTHERS THEN -- keep looping
			    END;
		    END;
            END;
        END LOOP;
    END IF;
    RETURN format('CREATE TABLE %I.%I FROM %L', sname, tname, csv_file);
end $$;

--Passage de t_parameters en serial
CREATE SEQUENCE gn_commons.t_parameters_id_parameter_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE gn_commons.t_parameters_id_parameter_seq OWNED BY gn_commons.t_parameters.id_parameter;
ALTER TABLE ONLY gn_commons.t_parameters ALTER COLUMN id_parameter SET DEFAULT nextval('gn_commons.t_parameters_id_parameter_seq'::regclass);
SELECT pg_catalog.setval('gn_commons.t_parameters_id_parameter_seq', (SELECT max(id_parameter)+1 FROM gn_commons.t_parameters), false);


-- modification de la table gn_commons.t_modules
ALTER TABLE gn_commons.t_modules RENAME COLUMN module_url TO module_path;
ALTER TABLE gn_commons.t_modules ADD COLUMN module_external_url character varying(255);

-- passage a fontawesome
UPDATE gn_commons.t_modules SET module_picto = 
CASE 
  WHEN module_picto='extension' THEN 'fa-puzzle-piece'
  WHEN module_picto='place' THEN 'fa-map-marker'
  WHEN module_picto='file_download' THEN 'fa-download'
END;

UPDATE gn_commons.t_modules SET module_path = 
CASE 
  WHEN module_name='occtax' THEN 'occtax'
  WHEN module_name='admin' THEN 'admin'
  WHEN module_name='suivi_chiro' THEN 'suivi_chiro'
  WHEN module_name='suivi_flore_territoire' THEN 'suivi_flore_territoire'
END;

-- Ajout de synthese dans t_applications et t_modules
INSERT INTO utilisateurs.t_applications (nom_application, desc_application, id_parent)
SELECT 'synthese', 'Application synthese de GeoNature', id_application
FROM utilisateurs.t_applications WHERE nom_application = 'application geonature';

INSERT INTO gn_commons.t_modules (id_module, module_name, module_label, module_picto, module_desc, module_path, module_target, module_comment, active_frontend, active_backend)
SELECT id_application ,'synthese', 'Synthese', 'fa-search', 'Application synthese', 'synthese', '_self', '', 'true', 'true'
FROM utilisateurs.t_applications WHERE nom_application = 'synthese';

