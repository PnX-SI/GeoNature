CREATE FUNCTION gn_imports.check_nomenclature_type_consistency(_target_field character varying, _id_target_value integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
        BEGIN
            RETURN EXISTS (
                SELECT 1
                FROM gn_imports.dict_fields df
                INNER JOIN ref_nomenclatures.bib_nomenclatures_types bnt ON bnt.mnemonique = df.mnemonique
                INNER JOIN ref_nomenclatures.t_nomenclatures tn ON tn.id_type = bnt.id_type
                WHERE df.name_field = _target_field AND tn.id_nomenclature = _id_target_value
            );
        END
        $$;

ALTER FUNCTION gn_imports.check_nomenclature_type_consistency(_target_field character varying, _id_target_value integer) OWNER TO geonatadmin;

CREATE FUNCTION gn_imports.fct_generate_import_query(mysource_table text, mytarget_table text) RETURNS text
    LANGUAGE plpgsql
    AS $$
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

ALTER FUNCTION gn_imports.fct_generate_import_query(mysource_table text, mytarget_table text) OWNER TO geonatadmin;

CREATE FUNCTION gn_imports.fct_generate_matching(mysource_table text, mytarget_table text, forcedelete boolean DEFAULT false) RETURNS text
    LANGUAGE plpgsql
    AS $$
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

ALTER FUNCTION gn_imports.fct_generate_matching(mysource_table text, mytarget_table text, forcedelete boolean) OWNER TO geonatadmin;

CREATE FUNCTION gn_imports.isinnamefields(fields text[], destination_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
        DECLARE
            name_field_other TEXT;
        BEGIN
            IF fields IS DISTINCT FROM NULL THEN
                FOREACH name_field_other IN ARRAY fields LOOP
                    IF NOT EXISTS (
                        SELECT * 
                        FROM gn_imports.bib_fields 
                        WHERE name_field = name_field_other AND id_destination = destination_id
                        ) then
                        return FALSE;
                    END IF;
                END LOOP;
            END IF;
            return TRUE;
        END;
        $$;

ALTER FUNCTION gn_imports.isinnamefields(fields text[], destination_id integer) OWNER TO geonatadmin;

CREATE FUNCTION gn_imports.load_csv_file(csv_file text, target_table text) RETURNS text
    LANGUAGE plpgsql
    AS $$
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

ALTER FUNCTION gn_imports.load_csv_file(csv_file text, target_table text) OWNER TO geonatadmin;

SET default_tablespace = '';

SET default_table_access_method = heap;

CREATE TABLE gn_imports.bib_destinations (
    id_destination integer NOT NULL,
    id_module integer,
    code character varying(64),
    label character varying(128),
    table_name character varying(64)
);

ALTER TABLE gn_imports.bib_destinations OWNER TO geonatadmin;

CREATE SEQUENCE gn_imports.bib_destinations_id_destination_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_imports.bib_destinations_id_destination_seq OWNER TO geonatadmin;

ALTER SEQUENCE gn_imports.bib_destinations_id_destination_seq OWNED BY gn_imports.bib_destinations.id_destination;

CREATE TABLE gn_imports.bib_entities (
    id_entity integer NOT NULL,
    id_destination integer,
    code character varying(16),
    label character varying(64),
    "order" integer,
    validity_column character varying(64),
    destination_table_schema character varying(63),
    destination_table_name character varying(63),
    id_unique_column integer,
    id_parent integer
);

ALTER TABLE gn_imports.bib_entities OWNER TO geonatadmin;

CREATE SEQUENCE gn_imports.bib_entities_id_entity_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_imports.bib_entities_id_entity_seq OWNER TO geonatadmin;

ALTER SEQUENCE gn_imports.bib_entities_id_entity_seq OWNED BY gn_imports.bib_entities.id_entity;

CREATE TABLE gn_imports.bib_errors_types (
    id_error integer NOT NULL,
    error_type character varying(100) NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    error_level character varying(25)
);

ALTER TABLE gn_imports.bib_errors_types OWNER TO geonatadmin;

CREATE TABLE gn_imports.bib_fields (
    id_field integer NOT NULL,
    name_field character varying(100) NOT NULL,
    fr_label character varying(100) NOT NULL,
    eng_label character varying(100),
    type_field character varying(50),
    mandatory boolean NOT NULL,
    autogenerated boolean NOT NULL,
    display boolean NOT NULL,
    mnemonique character varying,
    source_field character varying,
    dest_field character varying,
    multi boolean DEFAULT false NOT NULL,
    id_destination integer NOT NULL,
    mandatory_conditions character varying[],
    optional_conditions character varying[]
);

ALTER TABLE gn_imports.bib_fields OWNER TO geonatadmin;

COMMENT ON COLUMN gn_imports.bib_fields.mandatory_conditions IS 'Contient la liste de champs qui rendent le champ obligatoire.';

COMMENT ON COLUMN gn_imports.bib_fields.optional_conditions IS 'Contient la liste de champs qui rendent le champ optionnel.';

CREATE TABLE gn_imports.bib_themes (
    id_theme integer NOT NULL,
    name_theme character varying(100) NOT NULL,
    fr_label_theme character varying(100) NOT NULL,
    eng_label_theme character varying(100),
    desc_theme character varying(1000),
    order_theme integer NOT NULL
);

ALTER TABLE gn_imports.bib_themes OWNER TO geonatadmin;

CREATE TABLE gn_imports.cor_entity_field (
    id_entity integer NOT NULL,
    id_field integer NOT NULL,
    desc_field character varying(1000),
    id_theme integer NOT NULL,
    order_field integer NOT NULL,
    comment character varying
);

ALTER TABLE gn_imports.cor_entity_field OWNER TO geonatadmin;

CREATE TABLE gn_imports.cor_role_import (
    id_role integer NOT NULL,
    id_import integer NOT NULL
);

ALTER TABLE gn_imports.cor_role_import OWNER TO geonatadmin;

CREATE TABLE gn_imports.cor_role_mapping (
    id_role integer NOT NULL,
    id_mapping integer NOT NULL
);

ALTER TABLE gn_imports.cor_role_mapping OWNER TO geonatadmin;

CREATE SEQUENCE gn_imports.dict_fields_id_field_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_imports.dict_fields_id_field_seq OWNER TO geonatadmin;

ALTER SEQUENCE gn_imports.dict_fields_id_field_seq OWNED BY gn_imports.bib_fields.id_field;

CREATE SEQUENCE gn_imports.dict_themes_id_theme_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_imports.dict_themes_id_theme_seq OWNER TO geonatadmin;

ALTER SEQUENCE gn_imports.dict_themes_id_theme_seq OWNED BY gn_imports.bib_themes.id_theme;

CREATE TABLE gn_imports.matching_fields (
    id_matching_field integer NOT NULL,
    source_field text,
    source_default_value text,
    target_field text NOT NULL,
    target_field_type text,
    field_comments text,
    id_matching_table integer NOT NULL,
    CONSTRAINT check_source_exists CHECK (((source_field IS NOT NULL) OR (source_default_value IS NOT NULL)))
);

ALTER TABLE gn_imports.matching_fields OWNER TO geonatadmin;

COMMENT ON COLUMN gn_imports.matching_fields.source_default_value IS 'Valeur par défaut à insérer si la valeur attendue dans le champ de la table de destination n''existe pas dans la table source';

CREATE SEQUENCE gn_imports.matching_fields_id_matching_field_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_imports.matching_fields_id_matching_field_seq OWNER TO geonatadmin;

ALTER SEQUENCE gn_imports.matching_fields_id_matching_field_seq OWNED BY gn_imports.matching_fields.id_matching_field;

CREATE TABLE gn_imports.matching_geoms (
    id_matching_geom integer NOT NULL,
    source_x_field text,
    source_y_field text,
    source_geom_field text,
    source_geom_format text,
    source_srid integer,
    target_geom_field text,
    target_geom_srid integer,
    geom_comments text,
    id_matching_table integer NOT NULL
);

ALTER TABLE gn_imports.matching_geoms OWNER TO geonatadmin;

CREATE SEQUENCE gn_imports.matching_geoms_id_matching_geom_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_imports.matching_geoms_id_matching_geom_seq OWNER TO geonatadmin;

ALTER SEQUENCE gn_imports.matching_geoms_id_matching_geom_seq OWNED BY gn_imports.matching_geoms.id_matching_geom;

CREATE TABLE gn_imports.matching_tables (
    id_matching_table integer NOT NULL,
    source_schema text NOT NULL,
    source_table text NOT NULL,
    target_schema text NOT NULL,
    target_table text NOT NULL,
    matching_comments text
);

ALTER TABLE gn_imports.matching_tables OWNER TO geonatadmin;

CREATE SEQUENCE gn_imports.matching_tables_id_matching_table_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_imports.matching_tables_id_matching_table_seq OWNER TO geonatadmin;

ALTER SEQUENCE gn_imports.matching_tables_id_matching_table_seq OWNED BY gn_imports.matching_tables.id_matching_table;

CREATE TABLE gn_imports.t_contentmappings (
    id integer NOT NULL,
    "values" json
);

ALTER TABLE gn_imports.t_contentmappings OWNER TO geonatadmin;

CREATE TABLE gn_imports.t_fieldmappings (
    id integer NOT NULL,
    "values" json
);

ALTER TABLE gn_imports.t_fieldmappings OWNER TO geonatadmin;

CREATE TABLE gn_imports.t_imports (
    id_import integer NOT NULL,
    format_source_file character varying(10),
    srid integer,
    separator character varying,
    encoding character varying,
    full_file_name character varying(255),
    id_dataset integer,
    date_create_import timestamp without time zone DEFAULT now(),
    date_update_import timestamp without time zone DEFAULT now(),
    date_end_import timestamp without time zone,
    source_count integer,
    uuid_autogenerated boolean,
    altitude_autogenerated boolean,
    date_min_data timestamp without time zone,
    date_max_data timestamp without time zone,
    processed boolean DEFAULT false NOT NULL,
    need_fix boolean DEFAULT false,
    fix_comment text,
    detected_encoding character varying,
    source_file bytea,
    columns character varying[],
    fieldmapping json,
    contentmapping json,
    detected_separator character varying,
    task_id character varying(155),
    erroneous_rows integer[],
    loaded boolean DEFAULT false NOT NULL,
    id_destination integer NOT NULL,
    statistics json DEFAULT '{}'::jsonb NOT NULL
);

ALTER TABLE gn_imports.t_imports OWNER TO geonatadmin;

CREATE SEQUENCE gn_imports.t_imports_id_import_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_imports.t_imports_id_import_seq OWNER TO geonatadmin;

ALTER SEQUENCE gn_imports.t_imports_id_import_seq OWNED BY gn_imports.t_imports.id_import;

CREATE TABLE gn_imports.t_imports_occhab (
    id_import integer NOT NULL,
    line_no integer NOT NULL,
    station_valid boolean DEFAULT false,
    habitat_valid boolean DEFAULT false,
    id_station integer,
    id_station_source character varying,
    src_unique_id_sinp_station character varying,
    unique_id_sinp_station uuid,
    src_unique_dataset_id character varying,
    unique_dataset_id uuid,
    id_dataset integer,
    src_date_min character varying,
    date_min timestamp without time zone,
    src_date_max character varying,
    date_max timestamp without time zone,
    observers_txt character varying,
    station_name character varying,
    src_id_nomenclature_exposure character varying,
    id_nomenclature_exposure integer,
    src_altitude_min character varying,
    altitude_min integer,
    src_altitude_max character varying,
    altitude_max integer,
    src_depth_min character varying,
    depth_min integer,
    src_depth_max character varying,
    depth_max integer,
    src_area character varying,
    area integer,
    src_id_nomenclature_area_surface_calculation character varying,
    id_nomenclature_area_surface_calculation integer,
    comment character varying,
    "src_WKT" character varying,
    src_latitude character varying,
    src_longitude character varying,
    geom_local public.geometry,
    geom_4326 public.geometry(Geometry,4326),
    src_precision character varying,
    "precision" integer,
    src_id_digitiser character varying,
    id_digitiser integer,
    src_numerization_scale character varying,
    numerization_scale character varying(15),
    src_id_nomenclature_geographic_object character varying,
    id_nomenclature_geographic_object integer,
    station_line_no integer,
    src_id_habitat character varying,
    id_habitat integer,
    src_unique_id_sinp_hab character varying,
    unique_id_sinp_hab uuid,
    src_cd_hab character varying,
    cd_hab integer,
    nom_cite character varying,
    src_id_nomenclature_determination_type character varying,
    id_nomenclature_determination_type integer,
    determiner character varying,
    src_id_nomenclature_collection_technique character varying,
    id_nomenclature_collection_technique integer,
    src_recovery_percentage character varying,
    recovery_percentage integer,
    src_id_nomenclature_abundance character varying,
    id_nomenclature_abundance integer,
    technical_precision character varying,
    src_unique_id_sinp_grp_occtax character varying,
    unique_id_sinp_grp_occtax uuid,
    src_unique_id_sinp_grp_phyto character varying,
    unique_id_sinp_grp_phyto uuid,
    src_id_nomenclature_sensitivity character varying,
    id_nomenclature_sensitivity integer,
    src_id_nomenclature_community_interest character varying,
    id_nomenclature_community_interest integer,
    src_id_nomenclature_type_mosaique_habitat character varying,
    id_nomenclature_type_mosaique_habitat integer
);

ALTER TABLE gn_imports.t_imports_occhab OWNER TO geonatadmin;

CREATE TABLE gn_imports.t_imports_synthese (
    id_import integer NOT NULL,
    line_no integer NOT NULL,
    valid boolean,
    "src_WKT" character varying,
    src_codecommune character varying,
    src_codedepartement character varying,
    src_codemaille character varying,
    src_hour_max character varying,
    src_hour_min character varying,
    src_latitude character varying,
    src_longitude character varying,
    src_unique_id_sinp character varying,
    src_unique_id_sinp_grp character varying,
    src_id_nomenclature_geo_object_nature character varying,
    src_id_nomenclature_grp_typ character varying,
    src_id_nomenclature_obs_technique character varying,
    src_id_nomenclature_bio_status character varying,
    src_id_nomenclature_bio_condition character varying,
    src_id_nomenclature_naturalness character varying,
    src_id_nomenclature_valid_status character varying,
    src_id_nomenclature_exist_proof character varying,
    src_id_nomenclature_diffusion_level character varying,
    src_id_nomenclature_life_stage character varying,
    src_id_nomenclature_sex character varying,
    src_id_nomenclature_obj_count character varying,
    src_id_nomenclature_type_count character varying,
    src_id_nomenclature_sensitivity character varying,
    src_id_nomenclature_observation_status character varying,
    src_id_nomenclature_blurring character varying,
    src_id_nomenclature_source_status character varying,
    src_id_nomenclature_info_geo_type character varying,
    src_id_nomenclature_behaviour character varying,
    src_id_nomenclature_biogeo_status character varying,
    src_id_nomenclature_determination_method character varying,
    src_count_min character varying,
    src_count_max character varying,
    src_cd_nom character varying,
    src_cd_hab character varying,
    src_altitude_min character varying,
    src_altitude_max character varying,
    src_depth_min character varying,
    src_depth_max character varying,
    src_precision character varying,
    src_id_area_attachment character varying,
    src_date_min character varying,
    src_date_max character varying,
    src_id_digitiser character varying,
    src_meta_validation_date character varying,
    src_meta_create_date character varying,
    src_meta_update_date character varying,
    extra_fields public.hstore,
    unique_id_sinp uuid,
    unique_id_sinp_grp uuid,
    entity_source_pk_value character varying,
    grp_method character varying(255),
    id_nomenclature_geo_object_nature integer,
    id_nomenclature_grp_typ integer,
    id_nomenclature_obs_technique integer,
    id_nomenclature_bio_status integer,
    id_nomenclature_bio_condition integer,
    id_nomenclature_naturalness integer,
    id_nomenclature_valid_status integer,
    id_nomenclature_exist_proof integer,
    id_nomenclature_diffusion_level integer,
    id_nomenclature_life_stage integer,
    id_nomenclature_sex integer,
    id_nomenclature_obj_count integer,
    id_nomenclature_type_count integer,
    id_nomenclature_sensitivity integer,
    id_nomenclature_observation_status integer,
    id_nomenclature_blurring integer,
    id_nomenclature_source_status integer,
    id_nomenclature_info_geo_type integer,
    id_nomenclature_behaviour integer,
    id_nomenclature_biogeo_status integer,
    id_nomenclature_determination_method integer,
    reference_biblio character varying,
    count_min integer,
    count_max integer,
    cd_nom integer,
    cd_hab integer,
    nom_cite character varying,
    meta_v_taxref character varying,
    digital_proof text,
    non_digital_proof text,
    altitude_min integer,
    altitude_max integer,
    depth_min integer,
    depth_max integer,
    place_name character varying,
    the_geom_4326 public.geometry(Geometry,4326),
    the_geom_point public.geometry(Geometry,4326),
    the_geom_local public.geometry,
    "precision" integer,
    date_min timestamp without time zone,
    date_max timestamp without time zone,
    validator character varying,
    validation_comment character varying,
    observers character varying,
    determiner character varying,
    id_digitiser integer,
    comment_context text,
    comment_description text,
    additional_data jsonb,
    meta_validation_date timestamp without time zone,
    meta_create_date timestamp without time zone,
    meta_update_date timestamp without time zone,
    id_area_attachment integer,
    src_unique_dataset_id character varying,
    unique_dataset_id uuid,
    id_dataset integer
);

ALTER TABLE gn_imports.t_imports_synthese OWNER TO geonatadmin;

CREATE TABLE gn_imports.t_mappings (
    id integer NOT NULL,
    label character varying(255) NOT NULL,
    type character varying(10) NOT NULL,
    active boolean DEFAULT true NOT NULL,
    public boolean DEFAULT false NOT NULL,
    id_destination integer NOT NULL,
    CONSTRAINT check_mapping_type_in_t_mappings CHECK (((type)::text = ANY ((ARRAY['FIELD'::character varying, 'CONTENT'::character varying])::text[])))
);

ALTER TABLE gn_imports.t_mappings OWNER TO geonatadmin;

CREATE SEQUENCE gn_imports.t_mappings_id_mapping_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_imports.t_mappings_id_mapping_seq OWNER TO geonatadmin;

ALTER SEQUENCE gn_imports.t_mappings_id_mapping_seq OWNED BY gn_imports.t_mappings.id;

CREATE TABLE gn_imports.t_user_errors (
    id_user_error integer NOT NULL,
    id_import integer NOT NULL,
    id_error integer NOT NULL,
    column_error character varying(100) NOT NULL,
    id_rows integer[],
    comment text,
    id_entity integer
);

ALTER TABLE gn_imports.t_user_errors OWNER TO geonatadmin;

CREATE SEQUENCE gn_imports.t_user_error_list_id_user_error_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_imports.t_user_error_list_id_user_error_seq OWNER TO geonatadmin;

ALTER SEQUENCE gn_imports.t_user_error_list_id_user_error_seq OWNED BY gn_imports.t_user_errors.id_user_error;

CREATE SEQUENCE gn_imports.t_user_errors_id_error_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_imports.t_user_errors_id_error_seq OWNER TO geonatadmin;

ALTER SEQUENCE gn_imports.t_user_errors_id_error_seq OWNED BY gn_imports.bib_errors_types.id_error;

ALTER TABLE ONLY gn_imports.bib_destinations ALTER COLUMN id_destination SET DEFAULT nextval('gn_imports.bib_destinations_id_destination_seq'::regclass);

ALTER TABLE ONLY gn_imports.bib_entities ALTER COLUMN id_entity SET DEFAULT nextval('gn_imports.bib_entities_id_entity_seq'::regclass);

ALTER TABLE ONLY gn_imports.bib_errors_types ALTER COLUMN id_error SET DEFAULT nextval('gn_imports.t_user_errors_id_error_seq'::regclass);

ALTER TABLE ONLY gn_imports.bib_fields ALTER COLUMN id_field SET DEFAULT nextval('gn_imports.dict_fields_id_field_seq'::regclass);

ALTER TABLE ONLY gn_imports.bib_themes ALTER COLUMN id_theme SET DEFAULT nextval('gn_imports.dict_themes_id_theme_seq'::regclass);

ALTER TABLE ONLY gn_imports.matching_fields ALTER COLUMN id_matching_field SET DEFAULT nextval('gn_imports.matching_fields_id_matching_field_seq'::regclass);

ALTER TABLE ONLY gn_imports.matching_geoms ALTER COLUMN id_matching_geom SET DEFAULT nextval('gn_imports.matching_geoms_id_matching_geom_seq'::regclass);

ALTER TABLE ONLY gn_imports.matching_tables ALTER COLUMN id_matching_table SET DEFAULT nextval('gn_imports.matching_tables_id_matching_table_seq'::regclass);

ALTER TABLE ONLY gn_imports.t_imports ALTER COLUMN id_import SET DEFAULT nextval('gn_imports.t_imports_id_import_seq'::regclass);

ALTER TABLE ONLY gn_imports.t_mappings ALTER COLUMN id SET DEFAULT nextval('gn_imports.t_mappings_id_mapping_seq'::regclass);

ALTER TABLE ONLY gn_imports.t_user_errors ALTER COLUMN id_user_error SET DEFAULT nextval('gn_imports.t_user_error_list_id_user_error_seq'::regclass);

ALTER TABLE ONLY gn_imports.bib_destinations
    ADD CONSTRAINT bib_destinations_code_key UNIQUE (code);

ALTER TABLE ONLY gn_imports.bib_destinations
    ADD CONSTRAINT bib_destinations_pkey PRIMARY KEY (id_destination);

ALTER TABLE ONLY gn_imports.bib_entities
    ADD CONSTRAINT bib_entities_pkey PRIMARY KEY (id_entity);

ALTER TABLE ONLY gn_imports.cor_entity_field
    ADD CONSTRAINT cor_entity_field_pkey PRIMARY KEY (id_entity, id_field);

ALTER TABLE gn_imports.bib_fields
    ADD CONSTRAINT mandatory_conditions_field_exists CHECK (gn_imports.isinnamefields((mandatory_conditions)::text[], id_destination)) NOT VALID;

ALTER TABLE gn_imports.bib_fields
    ADD CONSTRAINT optional_conditions_field_exists CHECK (gn_imports.isinnamefields((optional_conditions)::text[], id_destination)) NOT VALID;

ALTER TABLE ONLY gn_imports.cor_role_import
    ADD CONSTRAINT pk_cor_role_import PRIMARY KEY (id_role, id_import);

ALTER TABLE ONLY gn_imports.cor_role_mapping
    ADD CONSTRAINT pk_cor_role_mapping PRIMARY KEY (id_role, id_mapping);

ALTER TABLE ONLY gn_imports.bib_fields
    ADD CONSTRAINT pk_dict_fields_id_theme PRIMARY KEY (id_field);

ALTER TABLE ONLY gn_imports.bib_themes
    ADD CONSTRAINT pk_dict_themes_id_theme PRIMARY KEY (id_theme);

ALTER TABLE ONLY gn_imports.t_imports
    ADD CONSTRAINT pk_gn_imports_t_imports PRIMARY KEY (id_import);

ALTER TABLE ONLY gn_imports.matching_fields
    ADD CONSTRAINT pk_matching_fields PRIMARY KEY (id_matching_field);

ALTER TABLE ONLY gn_imports.matching_geoms
    ADD CONSTRAINT pk_matching_synthese PRIMARY KEY (id_matching_geom);

ALTER TABLE ONLY gn_imports.matching_tables
    ADD CONSTRAINT pk_matching_tables PRIMARY KEY (id_matching_table);

ALTER TABLE ONLY gn_imports.t_mappings
    ADD CONSTRAINT pk_t_mappings PRIMARY KEY (id);

ALTER TABLE ONLY gn_imports.t_user_errors
    ADD CONSTRAINT pk_t_user_error_list PRIMARY KEY (id_user_error);

ALTER TABLE ONLY gn_imports.bib_errors_types
    ADD CONSTRAINT pk_user_errors PRIMARY KEY (id_error);

ALTER TABLE ONLY gn_imports.t_contentmappings
    ADD CONSTRAINT t_contentmappings_pkey PRIMARY KEY (id);

ALTER TABLE ONLY gn_imports.t_fieldmappings
    ADD CONSTRAINT t_fieldmappings_pkey PRIMARY KEY (id);

ALTER TABLE ONLY gn_imports.t_imports_occhab
    ADD CONSTRAINT t_imports_occhab_pkey PRIMARY KEY (id_import, line_no);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_pkey PRIMARY KEY (id_import, line_no);

ALTER TABLE ONLY gn_imports.t_mappings
    ADD CONSTRAINT t_mappings_un UNIQUE (label, type);

ALTER TABLE ONLY gn_imports.bib_errors_types
    ADD CONSTRAINT t_user_errors_name_key UNIQUE (name);

ALTER TABLE ONLY gn_imports.bib_fields
    ADD CONSTRAINT unicity_bib_fields_dest_name_field UNIQUE (id_destination, name_field);

CREATE INDEX idx_t_imports_occhab_geom_4326 ON gn_imports.t_imports_occhab USING gist (geom_4326);

CREATE INDEX idx_t_imports_occhab_geom_local ON gn_imports.t_imports_occhab USING gist (geom_local);

CREATE INDEX idx_t_imports_synthese_the_geom_4326 ON gn_imports.t_imports_synthese USING gist (the_geom_4326);

CREATE INDEX idx_t_imports_synthese_the_geom_local ON gn_imports.t_imports_synthese USING gist (the_geom_local);

CREATE INDEX idx_t_imports_synthese_the_geom_point ON gn_imports.t_imports_synthese USING gist (the_geom_point);

CREATE UNIQUE INDEX t_user_errors_entity_un ON gn_imports.t_user_errors USING btree (id_import, id_entity, id_error, column_error) WHERE (id_entity IS NOT NULL);

CREATE UNIQUE INDEX t_user_errors_un ON gn_imports.t_user_errors USING btree (id_import, id_error, column_error) WHERE (id_entity IS NULL);

ALTER TABLE ONLY gn_imports.bib_destinations
    ADD CONSTRAINT bib_destinations_id_module_fkey FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules(id_module) ON DELETE CASCADE;

ALTER TABLE ONLY gn_imports.bib_entities
    ADD CONSTRAINT bib_entities_id_destination_fkey FOREIGN KEY (id_destination) REFERENCES gn_imports.bib_destinations(id_destination) ON DELETE CASCADE;

ALTER TABLE ONLY gn_imports.bib_entities
    ADD CONSTRAINT bib_entities_id_parent_fkey FOREIGN KEY (id_parent) REFERENCES gn_imports.bib_entities(id_entity);

ALTER TABLE ONLY gn_imports.bib_entities
    ADD CONSTRAINT bib_entities_id_unique_column_fkey FOREIGN KEY (id_unique_column) REFERENCES gn_imports.bib_fields(id_field);

ALTER TABLE ONLY gn_imports.bib_fields
    ADD CONSTRAINT bib_fields_id_destination_fkey FOREIGN KEY (id_destination) REFERENCES gn_imports.bib_destinations(id_destination) ON DELETE CASCADE;

ALTER TABLE ONLY gn_imports.cor_entity_field
    ADD CONSTRAINT cor_entity_field_id_entity_fkey FOREIGN KEY (id_entity) REFERENCES gn_imports.bib_entities(id_entity) ON DELETE CASCADE;

ALTER TABLE ONLY gn_imports.cor_entity_field
    ADD CONSTRAINT cor_entity_field_id_field_fkey FOREIGN KEY (id_field) REFERENCES gn_imports.bib_fields(id_field) ON DELETE CASCADE;

ALTER TABLE ONLY gn_imports.cor_entity_field
    ADD CONSTRAINT cor_entity_field_id_theme_fkey FOREIGN KEY (id_theme) REFERENCES gn_imports.bib_themes(id_theme);

ALTER TABLE ONLY gn_imports.cor_role_import
    ADD CONSTRAINT fk_cor_role_import_import FOREIGN KEY (id_import) REFERENCES gn_imports.t_imports(id_import) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_imports.cor_role_import
    ADD CONSTRAINT fk_cor_role_import_role FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_imports.bib_fields
    ADD CONSTRAINT fk_gn_imports_dict_fields_nomenclature FOREIGN KEY (mnemonique) REFERENCES ref_nomenclatures.bib_nomenclatures_types(mnemonique) ON UPDATE SET NULL ON DELETE SET NULL;

ALTER TABLE ONLY gn_imports.cor_role_mapping
    ADD CONSTRAINT fk_gn_imports_t_mappings_id_mapping FOREIGN KEY (id_mapping) REFERENCES gn_imports.t_mappings(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_imports.t_imports
    ADD CONSTRAINT fk_gn_meta_t_datasets FOREIGN KEY (id_dataset) REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_imports.matching_fields
    ADD CONSTRAINT fk_matching_fields_matching_tables FOREIGN KEY (id_matching_table) REFERENCES gn_imports.matching_tables(id_matching_table) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_imports.matching_geoms
    ADD CONSTRAINT fk_matching_geoms_matching_tables FOREIGN KEY (id_matching_table) REFERENCES gn_imports.matching_tables(id_matching_table) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_imports.t_user_errors
    ADD CONSTRAINT fk_t_user_error_list_id_error FOREIGN KEY (id_error) REFERENCES gn_imports.bib_errors_types(id_error) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_imports.t_user_errors
    ADD CONSTRAINT fk_t_user_error_list_id_import FOREIGN KEY (id_import) REFERENCES gn_imports.t_imports(id_import) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_imports.cor_role_import
    ADD CONSTRAINT fk_utilisateurs_t_roles FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_imports.cor_role_mapping
    ADD CONSTRAINT fk_utilisateurs_t_roles FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_imports.t_contentmappings
    ADD CONSTRAINT t_contentmappings_id_fkey FOREIGN KEY (id) REFERENCES gn_imports.t_mappings(id) ON DELETE CASCADE;

ALTER TABLE ONLY gn_imports.t_fieldmappings
    ADD CONSTRAINT t_fieldmappings_id_fkey FOREIGN KEY (id) REFERENCES gn_imports.t_mappings(id) ON DELETE CASCADE;

ALTER TABLE ONLY gn_imports.t_imports
    ADD CONSTRAINT t_imports_id_destination_fkey FOREIGN KEY (id_destination) REFERENCES gn_imports.bib_destinations(id_destination) ON DELETE RESTRICT;

ALTER TABLE ONLY gn_imports.t_imports_occhab
    ADD CONSTRAINT t_imports_occhab_id_import_fkey FOREIGN KEY (id_import) REFERENCES gn_imports.t_imports(id_import) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_imports.t_imports_occhab
    ADD CONSTRAINT t_imports_occhab_id_import_station_line_no_fkey FOREIGN KEY (id_import, station_line_no) REFERENCES gn_imports.t_imports_occhab(id_import, line_no);

ALTER TABLE ONLY gn_imports.t_imports_occhab
    ADD CONSTRAINT t_imports_occhab_id_nomenclature_abundance_fkey FOREIGN KEY (id_nomenclature_abundance) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_occhab
    ADD CONSTRAINT t_imports_occhab_id_nomenclature_area_surface_calculation_fkey FOREIGN KEY (id_nomenclature_area_surface_calculation) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_occhab
    ADD CONSTRAINT t_imports_occhab_id_nomenclature_collection_technique_fkey FOREIGN KEY (id_nomenclature_collection_technique) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_occhab
    ADD CONSTRAINT t_imports_occhab_id_nomenclature_community_interest_fkey FOREIGN KEY (id_nomenclature_community_interest) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_occhab
    ADD CONSTRAINT t_imports_occhab_id_nomenclature_determination_type_fkey FOREIGN KEY (id_nomenclature_determination_type) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_occhab
    ADD CONSTRAINT t_imports_occhab_id_nomenclature_exposure_fkey FOREIGN KEY (id_nomenclature_exposure) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_occhab
    ADD CONSTRAINT t_imports_occhab_id_nomenclature_geographic_object_fkey FOREIGN KEY (id_nomenclature_geographic_object) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_occhab
    ADD CONSTRAINT t_imports_occhab_id_nomenclature_sensitivity_fkey FOREIGN KEY (id_nomenclature_sensitivity) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_occhab
    ADD CONSTRAINT t_imports_occhab_id_nomenclature_type_mosaique_habitat_fkey FOREIGN KEY (id_nomenclature_type_mosaique_habitat) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_area_attachment_fkey FOREIGN KEY (id_area_attachment) REFERENCES ref_geo.l_areas(id_area);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_digitiser_fkey FOREIGN KEY (id_digitiser) REFERENCES utilisateurs.t_roles(id_role);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_import_fkey FOREIGN KEY (id_import) REFERENCES gn_imports.t_imports(id_import) ON DELETE CASCADE;

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_behaviour_fkey FOREIGN KEY (id_nomenclature_behaviour) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_bio_condition_fkey FOREIGN KEY (id_nomenclature_bio_condition) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_bio_status_fkey FOREIGN KEY (id_nomenclature_bio_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_biogeo_status_fkey FOREIGN KEY (id_nomenclature_biogeo_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_blurring_fkey FOREIGN KEY (id_nomenclature_blurring) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_determination_method_fkey FOREIGN KEY (id_nomenclature_determination_method) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_diffusion_level_fkey FOREIGN KEY (id_nomenclature_diffusion_level) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_exist_proof_fkey FOREIGN KEY (id_nomenclature_exist_proof) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_geo_object_nature_fkey FOREIGN KEY (id_nomenclature_geo_object_nature) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_grp_typ_fkey FOREIGN KEY (id_nomenclature_grp_typ) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_info_geo_type_fkey FOREIGN KEY (id_nomenclature_info_geo_type) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_life_stage_fkey FOREIGN KEY (id_nomenclature_life_stage) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_naturalness_fkey FOREIGN KEY (id_nomenclature_naturalness) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_obj_count_fkey FOREIGN KEY (id_nomenclature_obj_count) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_obs_technique_fkey FOREIGN KEY (id_nomenclature_obs_technique) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_observation_status_fkey FOREIGN KEY (id_nomenclature_observation_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_sensitivity_fkey FOREIGN KEY (id_nomenclature_sensitivity) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_sex_fkey FOREIGN KEY (id_nomenclature_sex) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_source_status_fkey FOREIGN KEY (id_nomenclature_source_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_type_count_fkey FOREIGN KEY (id_nomenclature_type_count) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_valid_status_fkey FOREIGN KEY (id_nomenclature_valid_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_mappings
    ADD CONSTRAINT t_mappings_id_destination_fkey FOREIGN KEY (id_destination) REFERENCES gn_imports.bib_destinations(id_destination) ON DELETE CASCADE;

ALTER TABLE ONLY gn_imports.t_user_errors
    ADD CONSTRAINT t_user_errors_id_entity_fkey FOREIGN KEY (id_entity) REFERENCES gn_imports.bib_entities(id_entity) ON UPDATE CASCADE ON DELETE CASCADE;

