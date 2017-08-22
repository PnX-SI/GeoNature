SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

CREATE SCHEMA meta;

SET search_path = meta, pg_catalog;

SET default_with_oids = false;


----------
--TABLES--
----------
CREATE TABLE cor_role_privilege_entity (
    id_role integer NOT NULL,
    id_privilege integer NOT NULL,
    entity_name character varying(255) NOT NULL
);
COMMENT ON TABLE cor_role_privilege_entity IS 'Allow to manage privileges of a group or user on entities (tables) into backoffice (CRUD depending on privileges).';


CREATE TABLE cor_role_dataset_application (
    id_role integer NOT NULL,
    id_dataset integer NOT NULL,
    id_application integer NOT NULL
);
COMMENT ON TABLE cor_role_dataset_application IS 'Allow to identify for each GeoNature module (1 module = 1 application in UsersHub) among which dataset connected user can create observations. Reminder : A dataset is a dataset or a survey and each observation is attached to a dataset. GeoNature V2 backoffice allows to manage datasets.';


CREATE TABLE t_lots (
    id_dataset integer NOT NULL,
    dataset_name character varying(255),
    dataset_desc text,
    id_programme integer NOT NULL,
    id_organisme_owner integer NOT NULL,
    id_organisme_producer integer NOT NULL,
    id_organisme_administrator integer NOT NULL,
    id_organisme_funder integer NOT NULL,
    public_data boolean DEFAULT true NOT NULL,
    default_validity boolean,
    meta_create_date timestamp without time zone,
    meta_update_date timestamp without time zone
);
COMMENT ON TABLE t_lots IS 'A dataset is a dataset or a survey and each observation is attached to a dataset. A lot allows to qualify datas to which it is attached (producer, owner, manager, gestionnaire, financer, public data yes/no). A dataset can be attached to a program. GeoNature V2 backoffice allows to manage datasets.';


CREATE TABLE t_programmes (
    id_programme integer NOT NULL,
    programme_name character varying(255),
    programme_desc text,
    active boolean
);
COMMENT ON TABLE t_programmes IS 'Programs are general objects that can embed datasets and/or protocols. Example : ATBI, raptors, action national plan, etc... GeoNature V2 backoffice allows to manage datasets.';


---------------
--PRIMARY KEY--
---------------
ALTER TABLE ONLY cor_role_privilege_entity
    ADD CONSTRAINT pk_cor_role_privilege_entity PRIMARY KEY (id_role, id_privilege, entity_name);

ALTER TABLE ONLY cor_role_dataset_application
    ADD CONSTRAINT pk_cor_role_dataset_application PRIMARY KEY (id_role, id_dataset, id_application);

ALTER TABLE ONLY t_lots
    ADD CONSTRAINT pk_t_lots PRIMARY KEY (id_dataset);

ALTER TABLE ONLY t_programmes
    ADD CONSTRAINT pk_t_programmes PRIMARY KEY (id_programme);


---------------
--FOREIGN KEY--
---------------
ALTER TABLE ONLY cor_role_privilege_entity
    ADD CONSTRAINT fk_cor_role_droit_application_id_privilege FOREIGN KEY (id_privilege) REFERENCES utilisateurs.bib_droits(id_droit) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_role_privilege_entity
    ADD CONSTRAINT fk_cor_role_privilege_entity_t_roles FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;


ALTER TABLE ONLY cor_role_dataset_application
    ADD CONSTRAINT fk_cor_role_droit_application_id_role FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_role_dataset_application
    ADD CONSTRAINT fk_cor_role_dataset_application_id_application FOREIGN KEY (id_application) REFERENCES utilisateurs.t_applications(id_application) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_role_dataset_application
    ADD CONSTRAINT fk_cor_role_dataset_application_id_privilege FOREIGN KEY (id_dataset) REFERENCES t_lots(id_dataset) ON UPDATE CASCADE ON DELETE CASCADE;


ALTER TABLE ONLY t_lots
    ADD CONSTRAINT fk_bib_lots_financeur FOREIGN KEY (id_organisme_funder) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY t_lots
    ADD CONSTRAINT fk_bib_lots_gestionnaire FOREIGN KEY (id_organisme_administrator) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY t_lots
    ADD CONSTRAINT fk_bib_lots_producteur FOREIGN KEY (id_organisme_producer) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY t_lots
    ADD CONSTRAINT fk_bib_lots_proprietaire FOREIGN KEY (id_organisme_owner) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY t_lots
    ADD CONSTRAINT fk_bib_lots_t_programmes FOREIGN KEY (id_programme) REFERENCES t_programmes(id_programme) ON UPDATE CASCADE;


---------
--DATAS--
---------
INSERT INTO t_programmes VALUES (1, 'faune', 'programme faune', true);
INSERT INTO t_programmes VALUES (2, 'flore', 'programme flore', true);
