SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;


CREATE SCHEMA gn_medias;


SET search_path = gn_medias, pg_catalog;
SET default_with_oids = false;


CREATE OR REPLACE FUNCTION check_entity_field_exist(myentity character varying)
  RETURNS boolean AS
$BODY$
--Function that allows to check if the field of an entity of a table type exists. Parameter : 'schema.table.field'
--USAGE : SELECT gn_medias.check_entity_field_exist('schema.table.field');
  DECLARE
    entity_array character varying(255)[];
  BEGIN
    entity_array = string_to_array(myentity,'.');
      IF entity_array[3] IN(SELECT column_name FROM information_schema.columns WHERE table_schema = entity_array[1] AND table_name = entity_array[2] AND column_name = entity_array[3] ) THEN
        RETURN true;
      END IF;
    RETURN false;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;
--USAGE : SELECT gn_medias.check_entity_field_exist('pr_contact.t_releves_contact.id_releve_contact');


CREATE OR REPLACE FUNCTION check_entity_value_exist(myentity character varying, myvalue integer)
  RETURNS boolean AS
$BODY$
--Function that allows to check if a value exists in the field of a table type.
--USAGE : SELECT gn_medias.check_entity_value_exist('schema.table.field', value);
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
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;
--USAGE
--SELECT gn_medias.check_entity_value_exist('pr_contact.t_releves_contact.id_releve_contact', 2);

CREATE TABLE bib_media_types
(
  id_type integer NOT NULL,
  label_fr character varying(100),
  label_en character varying(100),
  label_it character varying(100),
  label_es character varying(100),
  label_de character varying(100),
  description_fr text,
  description_en text,
  description_it text,
  description_es text,
  description_de text
);

--DROP TABLE gn_medias.t_medias;
CREATE TABLE t_medias
(
  id_media integer NOT NULL,
  id_type integer NOT NULL,
  entity_name character varying(255) NOT NULL,
  entity_value integer NOT NULL,
  title_fr character varying(255),
  title_en character varying(255),
  title_it character varying(255),
  title_es character varying(255),
  title_de character varying(255),
  url character varying(255),
  path character varying(255),
  author character varying(100),
  description_fr text,
  description_en text,
  description_it text,
  description_es text,
  description_de text,
  meta_create_date timestamp without time zone,
  meta_update_date timestamp without time zone,
  is_public boolean NOT NULL DEFAULT true,
  deleted boolean NOT NULL DEFAULT false
);

CREATE SEQUENCE t_medias_id_media_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE t_medias_id_media_seq OWNED BY t_medias.id_media;
ALTER TABLE ONLY t_medias ALTER COLUMN id_media SET DEFAULT nextval('t_medias_id_media_seq'::regclass);
SELECT pg_catalog.setval('t_medias_id_media_seq', 1, false);



---------------
--PRIMARY KEY--
---------------
ALTER TABLE ONLY bib_media_types
    ADD CONSTRAINT pk_media_types PRIMARY KEY (id_type);

ALTER TABLE ONLY t_medias
    ADD CONSTRAINT pk_t_medias PRIMARY KEY (id_media);


----------------
--FOREIGN KEYS--
----------------
ALTER TABLE ONLY t_medias
  ADD CONSTRAINT fk_t_medias_bib_media_types FOREIGN KEY (id_type) REFERENCES bib_media_types (id_type) ON UPDATE CASCADE;


---------------
--CONSTRAINTS--
---------------
ALTER TABLE ONLY t_medias
  ADD CONSTRAINT fk_t_medias_check_entity_exist CHECK (check_entity_field_exist(entity_name));

ALTER TABLE ONLY t_medias
  ADD CONSTRAINT fk_t_medias_check_entity_value CHECK (check_entity_value_exist(entity_name,entity_value));

------------
--TRIGGERS--
------------
CREATE TRIGGER tri_meta_dates_change_t_medias
  BEFORE INSERT OR UPDATE
  ON t_medias
  FOR EACH ROW
  EXECUTE PROCEDURE public.fct_trg_meta_dates_change();


---------
--DATAS--
---------
INSERT INTO bib_media_types (id_type, label_fr, label_en, description_fr) VALUES
  (2, 'Photo', 'Photo', 'photos'),
  (3, 'Page web', 'Web page', 'URL d''une page web'),
  (4, 'PDF', 'PDF', 'Document de type PDF'),
  (5, 'Audio', 'Audio', 'Fichier audio MP3'),
  (6, 'Video (fichier)', 'Video (file)', 'Fichier video hébergé'),
  (7, 'Video Youtube', 'Youtube video', 'ID d''une video hébergée sur Youtube'),
  (8, 'Video Dailymotion', 'Dailymotion video', 'ID d''une video hébergée sur Dailymotion'),
  (9, 'Video Vimeo', 'Vimeo video', 'ID d''une video hébergée sur Vimeo');


SELECT pg_catalog.setval('t_medias_id_media_seq', 10, true);
