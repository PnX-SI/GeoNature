
SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;


CREATE SCHEMA medias;


SET search_path = medias, pg_catalog;
SET default_with_oids = false;


CREATE OR REPLACE FUNCTION medias.check_entity_field_exist(myentity character varying)
  RETURNS boolean AS
$BODY$
--fonction permettant de vérifier si le champ d'un entité de type table existe. Param : 'schema.table.field'
--usage 
--SELECT medias.check_entity_field_exist('schema.table.field');
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
--USAGE SAMPLE
--SELECT medias.check_entity_field_exist('contactfaune.t_releves_cfaune.id_releve_cfaune');


CREATE OR REPLACE FUNCTION check_entity_value_exist(myentity character varying, myvalue integer)
  RETURNS boolean AS
$BODY$
--fonction permettant de vérifier si une valeur existe dans le champ d'une entité de type table.
--USAGE
--SELECT medias.check_entity_value_exist('schema.table.field', value);
  DECLARE
    entity_array character varying(255)[];
    r record;
    _row_ct integer;
  BEGIN
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
--SELECT medias.check_entity_value_exist('contactfaune.t_releves_cfaune.id_releve_cfaune', 1);

CREATE TABLE bib_types_media
(
  id_type integer NOT NULL,
  nom_type_media character varying(100) NOT NULL,
  desc_type_media text
);

--DROP TABLE medias.t_medias;
CREATE TABLE t_medias
(
  id_media integer NOT NULL,
  id_type integer NOT NULL,
  entity_name character varying(255) NOT NULL,
  entity_value integer NOT NULL,
  titre character varying(255) NOT NULL,
  url character varying(255),
  chemin character varying(255),
  auteur character varying(100),
  desc_media text,
  date_insert timestamp without time zone,
  date_update timestamp without time zone,
  is_public boolean NOT NULL DEFAULT true,
  supprime boolean NOT NULL DEFAULT false
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
ALTER TABLE ONLY bib_types_media
    ADD CONSTRAINT pk_types_media PRIMARY KEY (id_type);

ALTER TABLE ONLY t_medias
    ADD CONSTRAINT pk_t_medias PRIMARY KEY (id_media);


---------------
--FOREIGN KEY--
---------------
ALTER TABLE ONLY t_medias
  ADD CONSTRAINT fk_t_medias_bib_types_media FOREIGN KEY (id_type) REFERENCES bib_types_media (id_type) ON UPDATE CASCADE;


--------------
--CONSTRAINS--
--------------
ALTER TABLE ONLY t_medias
  ADD CONSTRAINT fk_t_medias_check_entity_exist CHECK (check_entity_field_exist(entity_name));

ALTER TABLE ONLY t_medias
  ADD CONSTRAINT fk_t_medias_check_entity_value CHECK (check_entity_value_exist(entity_name,entity_value));

---------
--DATAS--
---------
INSERT INTO bib_types_media (id_type, nom_type_media, desc_type_media) VALUES (2, 'Photo', 'photos');
INSERT INTO bib_types_media (id_type, nom_type_media, desc_type_media) VALUES (3, 'Page web', 'URL d''une page web');
INSERT INTO bib_types_media (id_type, nom_type_media, desc_type_media) VALUES (4, 'PDF', 'Document de type PDF');
INSERT INTO bib_types_media (id_type, nom_type_media, desc_type_media) VALUES (5, 'Audio', 'Fichier audio MP3');
INSERT INTO bib_types_media (id_type, nom_type_media, desc_type_media) VALUES (6, 'Video (fichier)', 'Fichier video hébergé');
INSERT INTO bib_types_media (id_type, nom_type_media, desc_type_media) VALUES (7, 'Video Youtube', 'ID d''une video hébergée sur Youtube');
INSERT INTO bib_types_media (id_type, nom_type_media, desc_type_media) VALUES (8, 'Video Dailymotion', 'ID d''une video hébergée sur Dailymotion');
INSERT INTO bib_types_media (id_type, nom_type_media, desc_type_media) VALUES (9, 'Video Vimeo', 'ID d''une video hébergée sur Vimeo');


SELECT pg_catalog.setval('t_medias_id_media_seq', 10, true);