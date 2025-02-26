CREATE OR REPLACE FUNCTION gn_commons.check_entity_field_exist(myentity character varying)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
--Function that allows to check if the field of an entity of a table type exists. Parameter : 'schema.table.field'
--USAGE : SELECT gn_commons.check_entity_field_exist('schema.table.field');
  DECLARE
    entity_array character varying(255)[];
  BEGIN
    entity_array = string_to_array(myentity,'.');
      IF entity_array[3] IN(SELECT column_name FROM information_schema.columns WHERE table_schema = entity_array[1] AND table_name = entity_array[2] AND column_name = entity_array[3] ) THEN
        RETURN true;
      END IF;
    RETURN false;
  END;
$function$

CREATE OR REPLACE FUNCTION gn_commons.check_entity_uuid_exist(myentity character varying, myvalue uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
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
$function$

CREATE OR REPLACE FUNCTION gn_commons.check_entity_value_exist(myentity character varying, myvalue integer)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
--Function that allows to check if a value exists in the field of a table type.
--USAGE : SELECT gn_commons.check_entity_value_exist('schema.table.field', value);
  DECLARE
    entity_array character varying(255)[];
    r record;
    _row_ct integer;
  BEGIN
    -- Cas particulier quand on insère le média avant l'entité
    IF myvalue = -1 Then
	    RETURN TRUE;
    END IF;

    entity_array = string_to_array(myentity,'.');
    EXECUTE 'SELECT '||entity_array[3]|| ' FROM '||entity_array[1]||'.'||entity_array[2]||' WHERE '||entity_array[3]||'=' ||myvalue INTO r;
    GET DIAGNOSTICS _row_ct = ROW_COUNT;
      IF _row_ct > 0 THEN
        RETURN true;
      END IF;
    RETURN false;
  END;
$function$

CREATE OR REPLACE FUNCTION gn_commons.fct_trg_add_default_validation_status()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	theschema text := quote_ident(TG_TABLE_SCHEMA);
	thetable text := quote_ident(TG_TABLE_NAME);
	theuuidfieldname character varying(50);
	theuuid uuid;
  thecomment text := 'auto = default value';
BEGIN
  --Retouver le nom du champ stockant l'uuid de l'enregistrement en cours de validation
	SELECT INTO theuuidfieldname gn_commons.get_uuid_field_name(theschema,thetable);
  --Récupérer l'uuid de l'enregistrement en cours de validation
	EXECUTE format('SELECT $1.%I', theuuidfieldname) INTO theuuid USING NEW;
  --Insertion du statut de validation et des informations associées dans t_validations
  INSERT INTO gn_commons.t_validations (uuid_attached_row,id_nomenclature_valid_status,id_validator,validation_comment,validation_date)
  VALUES(
    theuuid,
    ref_nomenclatures.get_default_nomenclature_value('STATUT_VALID'), --comme la fonction est générique, cette valeur par défaut doit exister et est la même pour tous les modules
    null,
    thecomment,
    NOW()
  );
  RETURN NEW;
END;
$function$

CREATE OR REPLACE FUNCTION gn_commons.fct_trg_log_changes()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	theschema text := quote_ident(TG_TABLE_SCHEMA);
	thetable text := quote_ident(TG_TABLE_NAME);
	theidtablelocation int;
	theuuidfieldname character varying(50);
	theuuid uuid;
	theoperation character(1);
	thecontent json;
BEGIN
	--Retrouver l'id de la table source stockant l'enregistrement à tracer
	SELECT INTO theidtablelocation gn_commons.get_table_location_id(theschema,thetable);
	--Retouver le nom du champ stockant l'uuid de l'enregistrement à tracer
	SELECT INTO theuuidfieldname gn_commons.get_uuid_field_name(theschema,thetable);
	--Retrouver la première lettre du type d'opération (C, U, ou D)
	SELECT INTO theoperation LEFT(TG_OP,1);
	--Construction du JSON du contenu de l'enregistrement tracé
	IF(TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
		--Construction du JSON
		thecontent :=  row_to_json(NEW.*);
		--Récupérer l'uuid de l'enregistrement à tracer
		EXECUTE format('SELECT $1.%I', theuuidfieldname) INTO theuuid USING NEW;
	ELSIF (TG_OP = 'DELETE') THEN
		--Construction du JSON
		thecontent :=  row_to_json(OLD.*);
		--Récupérer l'uuid de l'enregistrement à tracer
		EXECUTE format('SELECT $1.%I', theuuidfieldname) INTO theuuid USING OLD;
	END IF;
  --Insertion du statut de validation et des informations associées dans t_validations
  INSERT INTO gn_commons.t_history_actions (id_table_location,uuid_attached_row,operation_type,operation_date,table_content)
  VALUES(
    theidtablelocation,
    theuuid,
    theoperation,
    NOW(),
    thecontent
  );
  RETURN NEW;
END;
$function$

CREATE OR REPLACE FUNCTION gn_commons.fct_trg_update_synthese_validation_status()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    -- This trigger function update validation informations in corresponding row in synthese table
    BEGIN
        UPDATE gn_synthese.synthese 
        SET id_nomenclature_valid_status = NEW.id_nomenclature_valid_status,
        validation_comment = NEW.validation_comment,
        meta_validation_date = NEW.validation_date,
        validator = (SELECT nom_role || ' ' || prenom_role FROM utilisateurs.t_roles WHERE id_role = NEW.id_validator)::text
        WHERE unique_id_sinp = NEW.uuid_attached_row;
        RETURN NEW;
    END;
    $function$

CREATE OR REPLACE FUNCTION gn_commons.get_default_parameter(myparamname text, myidorganisme integer DEFAULT 0)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
    DECLARE
        theparamvalue text;
-- Function that allows to get value of a parameter depending on his name and organism
-- USAGE : SELECT gn_commons.get_default_parameter('taxref_version');
-- OR      SELECT gn_commons.get_default_parameter('uuid_url_value', 2);
  BEGIN
    IF myidorganisme IS NOT NULL THEN
      SELECT INTO theparamvalue parameter_value FROM gn_commons.t_parameters WHERE parameter_name = myparamname AND id_organism = myidorganisme LIMIT 1;
    ELSE
      SELECT INTO theparamvalue parameter_value FROM gn_commons.t_parameters WHERE parameter_name = myparamname LIMIT 1;
    END IF;
    RETURN theparamvalue;
  END;
$function$

CREATE OR REPLACE FUNCTION gn_commons.get_id_module_bycode(mymodule text)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
	theidmodule integer;
BEGIN
  --Retrouver l'id du module par son code
  SELECT INTO theidmodule id_module FROM gn_commons.t_modules
	WHERE "module_code" ILIKE mymodule;
  RETURN theidmodule;
END;
$function$

CREATE OR REPLACE FUNCTION gn_commons.get_table_location_id(myschema text, mytable text)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
	theidtablelocation int;
BEGIN
--Retrouver dans gn_commons.bib_tables_location l'id (PK) de la table passée en paramètre
  SELECT INTO theidtablelocation id_table_location FROM gn_commons.bib_tables_location
	WHERE "schema_name" = myschema AND "table_name" = mytable;
  RETURN theidtablelocation;
END;
$function$

CREATE OR REPLACE FUNCTION gn_commons.get_uuid_field_name(myschema text, mytable text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
	theuuidfieldname character varying(50);
BEGIN
--Retrouver dans gn_commons.bib_tables_location le nom du champs UUID de la table passée en paramètre
  SELECT INTO theuuidfieldname uuid_field_name FROM gn_commons.bib_tables_location
	WHERE "schema_name" = myschema AND "table_name" = mytable;
  RETURN theuuidfieldname;
END;
$function$

CREATE OR REPLACE FUNCTION gn_commons.is_in_period(dateobs date, datebegin date, dateend date)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
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
$function$

CREATE OR REPLACE FUNCTION gn_commons.role_is_group(myidrole integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	is_group boolean;
BEGIN
  SELECT INTO is_group groupe FROM utilisateurs.t_roles
	WHERE id_role = myidrole;
  RETURN is_group;
END;
$function$

