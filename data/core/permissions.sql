SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--DROP SCHEMA gn_permissions CASCADE;
CREATE SCHEMA gn_permissions;

SET search_path = gn_permissions, pg_catalog;
SET default_with_oids = false;


---------
--TABLE--
---------

CREATE TABLE t_actions(
    id_action serial NOT NULL,
    code_action character varying(50) NOT NULL,
    description_action text
);

CREATE TABLE bib_filters_type(
    id_filter_type serial NOT NULL,
    code_filter_type character varying(50) NOT NULL,
    description_filter_type text
);

CREATE TABLE t_filters(
    id_filter serial NOT NULL,
    code_filter character varying(50) NOT NULL,
    description_filter text,
    id_filter_type integer NOT NULL
);


CREATE TABLE t_objects(
    id_object serial NOT NULL,
    code_object character varying(50) NOT NULL,
    description_object text
);

-- un objet peut être utilisé dans plusieurs modules
-- ex: TDataset en lecture dans occtax, admin ...
CREATE TABLE cor_object_module(
    id_cor_object_module serial NOT NULL,
    id_object integer NOT NULL,
    id_module integer NOT NULL
);

CREATE TABLE cor_role_action_filter_module_object(
    id_role integer NOT NULL,
    id_action integer NOT NULL,
    id_filter integer NOT NULL,
    id_module integer NOT NULL,
    id_object integer NOT NULL
);


---------------
--PRIMARY KEY--
---------------

ALTER TABLE ONLY t_actions
    ADD CONSTRAINT pk_t_actions PRIMARY KEY (id_action);

ALTER TABLE ONLY t_filters
    ADD CONSTRAINT pk_t_filters PRIMARY KEY (id_filter);

ALTER TABLE ONLY bib_filters_type
    ADD CONSTRAINT pk_bib_filters_type PRIMARY KEY (id_filter_type);

ALTER TABLE ONLY t_objects
    ADD CONSTRAINT pk_t_objects PRIMARY KEY (id_object);

ALTER TABLE ONLY cor_object_module
    ADD CONSTRAINT pk_cor_object_module PRIMARY KEY (id_cor_object_module);

ALTER TABLE ONLY cor_role_action_filter_module_object
    ADD CONSTRAINT pk_cor_r_a_f_m_o PRIMARY KEY (id_role, id_action, id_filter, id_module, id_object);


---------------
--FOREIGN KEY--
---------------

ALTER TABLE ONLY t_filters
  ADD CONSTRAINT  fk_t_filters_id_filter_type FOREIGN KEY (id_filter_type) REFERENCES bib_filters_type(id_filter_type) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_object_module
  ADD CONSTRAINT  fk_cor_object_module_id_module FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules(id_module) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_object_module
  ADD CONSTRAINT  fk_cor_object_module_id_object FOREIGN KEY (id_object) REFERENCES t_objects(id_object) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_role_action_filter_module_object
  ADD CONSTRAINT  fk_cor_r_a_f_m_o_id_role FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_role_action_filter_module_object
  ADD CONSTRAINT  fk_cor_r_a_f_m_o_id_action FOREIGN KEY (id_action) REFERENCES t_actions(id_action) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_role_action_filter_module_object
  ADD CONSTRAINT  fk_cor_r_a_f_m_o_id_filter FOREIGN KEY (id_filter) REFERENCES t_filters(id_filter) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_role_action_filter_module_object
  ADD CONSTRAINT  fk_cor_r_a_f_m_o_id_object FOREIGN KEY (id_object) REFERENCES t_objects(id_object) ON UPDATE CASCADE;