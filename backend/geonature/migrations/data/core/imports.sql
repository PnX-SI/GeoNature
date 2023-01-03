-- Création du schéma "gn_imports" en version 2.7.5
-- A partir de la version 2.8.0, les évolutions de la BDD sont gérées dans des migrations Alembic

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

CREATE SCHEMA gn_imports;

SET search_path = gn_imports, pg_catalog;
SET default_with_oids = false;

CREATE TABLE matching_tables
(
  id_matching_table serial NOT NULL,
  source_schema text NOT NULL,
  source_table text NOT NULL,
  target_schema text NOT NULL,
  target_table text NOT NULL,
  matching_comments text,
  CONSTRAINT pk_matching_tables PRIMARY KEY (id_matching_table)
);

CREATE TABLE matching_fields
(
  id_matching_field serial NOT NULL,
  source_field text,
  source_default_value text, -- Valeur par défaut à insérer si la valeur attendue dans le champ de la table de destination n'existe pas dans la table source
  target_field text NOT NULL,
  target_field_type text,
  field_comments text,
  id_matching_table integer NOT NULL,
  CONSTRAINT pk_matching_fields PRIMARY KEY (id_matching_field)
);
COMMENT ON COLUMN matching_fields.source_default_value IS 'Valeur par défaut à insérer si la valeur attendue dans le champ de la table de destination n''existe pas dans la table source';


CREATE TABLE matching_geoms
(
  id_matching_geom serial NOT NULL,	
  source_x_field text,
  source_y_field text,
  source_geom_field text,
  source_geom_format text,
  source_srid integer,
  target_geom_field text,
  target_geom_srid integer,
  geom_comments text,
  id_matching_table integer NOT NULL,
  CONSTRAINT pk_matching_synthese PRIMARY KEY (id_matching_geom)
);


----------------
--FOREIGN KEYS--
----------------
ALTER TABLE ONLY matching_geoms
    ADD CONSTRAINT fk_matching_geoms_matching_tables FOREIGN KEY (id_matching_table) REFERENCES matching_tables(id_matching_table) ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE ONLY matching_fields
    ADD CONSTRAINT fk_matching_fields_matching_tables FOREIGN KEY (id_matching_table) REFERENCES matching_tables(id_matching_table) ON UPDATE CASCADE ON DELETE NO ACTION;


--------------
--CONSTRAINS--
--------------
ALTER TABLE matching_fields
  ADD CONSTRAINT check_source_exists CHECK (source_field IS NOT NULL OR source_default_value IS NOT NULL);


-------------
--FUNCTIONS--
-------------
CREATE OR REPLACE FUNCTION load_csv_file(csv_file text, target_table text)
RETURNS text LANGUAGE plpgsql AS $$
--This function create a table and her structure according to the CSV structure and the passed name.
--CSV content is loaded in. 
--Then, the function tries to define the type of columns according to the content.
--You must check and adapt result.
--
--USAGE (due to 'copy' function usage, use it with a superuser only).
--SELECT gn_imports.load_csv_file('/path/to/file.csv', 'targetschema.targettable');
DECLARE
    col text; -- variable to keep the column name at each iteration
    sname text; --destination schema name
    tname text; --destination table name
BEGIN
    create temp table import (line text) on commit drop;
    --import all csv content
    EXECUTE format('copy import from %L', csv_file);
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
END $$;

CREATE OR REPLACE FUNCTION fct_generate_matching(
  mysource_table text, 
  mytarget_table text,
  forcedelete boolean DEFAULT false)  
RETURNS text LANGUAGE plpgsql AS
--This function prépare matching content in "matching_tables" and "matching_fields" tables from gn_imports schema.
--USE forcedelete (true or false) parameter to force the "matching_fields" and "matching_geoms" deletion
--USAGE : SELECT gn_imports.fct_generate_matching('table_source', 'table_cible', forcedelete);
$$
DECLARE
    thesql text; --prepared query to execute
    deletesql text; --prepared query to delete row in matching tables
    sqlinsertt text; --prepared query to insert row in gn_imports.matching_tables
    sqlinsertf text; --prepared query to insert row in gn_imports.matching_fields
    theidmatchingtable integer; --id_matching_table return after insert in gn_imports.matching_tables
    ssname text; --source schema name
    stname text; --source table name
    tsname text; --destination schema name
    ttname text; --destination table name
    r record;
BEGIN
    --test si la table source est fournie sinon on retourne un message d'erreur
    IF length(mysource_table) > 0 THEN
	--split schema.table n deux chaines
	SELECT split_part(mysource_table, '.', 1) into ssname;
	SELECT split_part(mysource_table, '.', 2) into stname;
    ELSE
        BEGIN
            RAISE EXCEPTION 'ATTENTION : %', 'Vous devez passer en paramètre une table source et une table de destination.';
        END;
    END IF;
    --test si la table destination est fournie sinon on retourne un message d'erreur
    IF length(mytarget_table) > 0 THEN
	--split schema.table en deux chaines
	SELECT split_part(mytarget_table, '.', 1) into tsname;
	SELECT split_part(mytarget_table, '.', 2) into ttname;
    ELSE
	BEGIN
            RAISE EXCEPTION 'ATTENTION : %', 'Vous devez passer en paramètre une table source et une table de destination.';
        END;
    END IF;
    --Test si le matching existe
    thesql= format('SELECT id_matching_table
		    FROM gn_imports.matching_tables
		    WHERE source_schema = %L AND source_table = %L AND target_schema = %L AND target_table = %L;'
	    ,ssname, stname,tsname, ttname);
    EXECUTE thesql INTO theidmatchingtable;
    --suppression du matching existant s'il existe et que le parametre forcedelete est à true
    IF forcedelete AND theidmatchingtable IS NOT NULL THEN
	thesql = format('DELETE FROM gn_imports.matching_fields WHERE id_matching_table = %L;'
		    ,theidmatchingtable);
	EXECUTE thesql;
	thesql = format('DELETE FROM gn_imports.matching_geoms WHERE id_matching_table = %L;'
		    ,theidmatchingtable);
	EXECUTE thesql;
    ELSIF theidmatchingtable IS NULL THEN
        --Do nothing and continue
    ELSE
	BEGIN
            RAISE EXCEPTION 'ATTENTION : %', 'Un enregistrement pour ce mapping existe et vous n''avez pas indiqué de le supprimer.'
			    || chr(10) || 'Utilisez le parametre forcedelete = true pour forcer la suppression du mapping existant';
	END;
    END IF;
    --s'il n'existe pas, insertion de l'enregistrement du matching dans la table gn_imports.matching_tables
    IF theidmatchingtable IS NULL THEN
        thesql= format('INSERT INTO gn_imports.matching_tables(
			   source_schema,
			   source_table,
			   target_schema,
			   target_table) VALUES(%L,%L,%L,%L) RETURNING id_matching_table;'
			   ,ssname, stname,tsname, ttname);
	EXECUTE thesql INTO theidmatchingtable;
    END IF;
    --préparation de la requete d'insertion dans la table gn_imports.matching_fields
    FOR r IN EXECUTE format('SELECT column_name,  data_type, is_nullable, column_default
			     FROM information_schema.columns
			     WHERE table_schema = %L
			     AND table_name   = %L
			     ORDER BY ordinal_position;'
		     ,tsname, ttname)
    LOOP
        thesql = format( 
			    'INSERT INTO gn_imports.matching_fields(
			       source_field,
			       source_default_value,
			       target_field, 
			       target_field_type, 
			       id_matching_table) 
			     VALUES(''replace me'',%L,%L,%L,%L);'
		     ,r.column_default, r.column_name, r.data_type, theidmatchingtable);
	EXECUTE thesql;
    END LOOP;
    RETURN 'Insertion de tous les champs de la table de destination dans "gn_imports.matching_fields" ; vous devez maintenant adapter le contenu de cette table.';
END $$;

CREATE OR REPLACE FUNCTION fct_generate_import_query(
  mysource_table text, 
  mytarget_table text) 
RETURNS text LANGUAGE plpgsql AS
--This function prépare a sql query to insert data from a table to another.
--Use the 3 matching tables in gn_imports schema.
--USAGE : gn_imports.fct_generate_import_query('table_source', 'table_cible');
$$
DECLARE
    insertfield text; --prepared field to insert
    selectfield text; --prepared field in select clause
    sqlimport text; --returned query as text
    virgule text;
    ssname text; --source schema name
    stname text; --source table name
    tsname text; --destination schema name
    ttname text; --destination table name
    r record;
    g record;
BEGIN
    --test si la table source est fournie sinon on retourne un message d'erreur
    IF length(mysource_table) > 0 THEN
	--split schema.table n deux chaines
	SELECT split_part(mysource_table, '.', 1) into ssname;
	SELECT split_part(mysource_table, '.', 2) into stname;
    ELSE
        BEGIN
            RAISE WARNING 'ERREUR : %', 'Vous devez passer en paramètre une table source et une table de destination.';
        END;
    END IF;
    --test si la table destination est fournie sinon on retourne un message d'erreur
    IF length(mytarget_table) > 0 THEN
	--split schema.table en deux chaines
	SELECT split_part(mytarget_table, '.', 1) into tsname;
	SELECT split_part(mytarget_table, '.', 2) into ttname;
    ELSE
	BEGIN
            RAISE WARNING 'ERREUR : %', 'Vous devez passer en paramètre une table source et une table de destination.';
        END;
    END IF;
    --test si la table source et de destination existe et si un maping des champs a été préparé.
    insertfield = format('INSERT INTO %I.%I(%s',tsname, ttname, chr(10));
    selectfield = concat('SELECT ',chr(10));
    FOR r IN EXECUTE format('SELECT source_field, source_default_value, target_field, target_field_type 
			     FROM gn_imports.matching_fields f
			     JOIN gn_imports.matching_tables t ON t.id_matching_table = f.id_matching_table
			     WHERE t.source_schema = %L 
			     AND t.source_table = %L
			     AND t.target_schema = %L
			     AND t.target_table = %L'
			     ,ssname, stname,tsname, ttname)
    LOOP
        insertfield := concat(insertfield, virgule, r.target_field, chr(10));
        selectfield := concat(
				selectfield, 
				virgule, 
				COALESCE('a.'||r.source_field, r.source_default_value),
				'::',
				r.target_field_type, 
				' AS ', 
				r.target_field,
				chr(10));
        virgule := ',';
    END LOOP;
    --gestion du geom avec la table gn_imports.matching_geoms
    FOR g IN EXECUTE format('SELECT g.* FROM gn_imports.matching_geoms g
			     JOIN gn_imports.matching_tables t ON t.id_matching_table = g.id_matching_table
			     WHERE t.source_schema = %L 
			     AND t.source_table = %L
			     AND t.target_schema = %L
			     AND t.target_table = %L'
			     ,ssname, stname,tsname, ttname)
    LOOP
	--on test si un matching de geom est déclaré
	IF g.id_matching_geom IS NOT NULL THEN
	    --si oui on contruit le mapping
	    insertfield := concat(insertfield, virgule, g.target_geom_field, chr(10));
	    IF((g.source_geom_format = 'xy') AND (g.source_x_field IS NOT NULL) AND (g.source_y_field IS NOT NULL)) THEN
	        selectfield := concat(selectfield, virgule
	        , 'ST_Transform(ST_GeomFromText('
	        ,'''POINT(''|| '
	        ,g.source_x_field
	        ,' || '
	        ,''' '''
	        ,' || '
	        ,g.source_y_field
	        ,' ||'')'''
	        ,', '
	        ,g.source_srid,'), '
	        ,g.target_geom_srid
	        ,')'
	        ,chr(10)
	        );
	    ELSIF (g.source_geom_format = 'wkt' AND length(g.source_geom_field)>0) THEN
	        selectfield := concat(selectfield, virgule
	        ,'ST_Transform(ST_GeomFromText('
	        ,''''
	        ,g.source_geom_field
	        ,''', '
	        ,g.source_srid,'), '
	        ,g.target_geom_srid
	        ,')'
	        ,chr(10)
	        );
	    ELSE
	        BEGIN
	            RAISE EXCEPTION 'ATTENTION %', 'Le format du champ "source_geom_format" dans la table "gn_imports.matching_geoms" 
	            doit être "xy" ou "wkt" 
	            ET les champs "source_x_field" et "source_y_field" doivent être complétés pour le format "xy"
	            OU le champs "source_geom_field" doit être complété pour le format "wkt".';
	        END;
	    END IF;
	END IF;
    END LOOP;
    --finalisation de la clause insert
    insertfield := concat(insertfield, ')', chr(10));
    selectfield := concat(selectfield, 'FROM ', ssname, '.', stname, ' a', chr(10));
    --construction de la requête complète
    sqlimport := concat(insertfield, ' ', selectfield, ';');
    RETURN sqlimport;
END $$;
