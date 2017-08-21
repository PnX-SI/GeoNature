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
CREATE TABLE cor_role_droit_entite (
    id_role integer NOT NULL,
    id_droit integer NOT NULL,
    nom_entite character varying(255) NOT NULL
);
COMMENT ON TABLE cor_role_droit_entite IS 'Allow to manage rights of a group or user on entities (tables) into backoffice (CRUD depending on rights).';


CREATE TABLE cor_role_lot_application (
    id_role integer NOT NULL,
    id_lot integer NOT NULL,
    id_application integer NOT NULL
);
COMMENT ON TABLE cor_role_lot_application IS 'Allow to identify for each GeoNature module (1 module = 1 application in UsersHub) among which dataset connected user can create observations. Reminder : A dataset is a dataset or a survey and each observation is attached to a dataset. GeoNature V2 backoffice allows to manage datasets.';


CREATE TABLE t_lots (
    id_lot integer NOT NULL,
    nom_lot character varying(255),
    desc_lot text,
    id_programme integer NOT NULL,
    id_organisme_proprietaire integer NOT NULL,
    id_organisme_producteur integer NOT NULL,
    id_organisme_gestionnaire integer NOT NULL,
    id_organisme_financeur integer NOT NULL,
    donnees_publiques boolean DEFAULT true NOT NULL,
    validite_par_defaut boolean,
    date_create timestamp without time zone,
    date_update timestamp without time zone
);
COMMENT ON TABLE t_lots IS 'A dataset is a dataset or a survey and each observation is attached to a dataset. A lot allows to qualify datas to which it is attached (producer, owner, manager, gestionnaire, financer, public data yes/no). A dataset can be attached to a program. GeoNature V2 backoffice allows to manage datasets.';


CREATE TABLE t_programmes (
    id_programme integer NOT NULL,
    nom_programme character varying(255),
    desc_programme text,
    actif boolean
);
COMMENT ON TABLE t_programmes IS 'Programs are general objects that can embed datasets and/or protocols. Example : ATBI, raptors, action national plan, etc... GeoNature V2 backoffice allows to manage datasets.';


---------------
--PRIMARY KEY--
---------------
ALTER TABLE ONLY cor_role_droit_entite
    ADD CONSTRAINT cor_role_droit_entite_pkey PRIMARY KEY (id_role, id_droit, nom_entite);

ALTER TABLE ONLY cor_role_lot_application
    ADD CONSTRAINT cor_role_lot_application_pkey PRIMARY KEY (id_role, id_lot, id_application);

ALTER TABLE ONLY t_lots
    ADD CONSTRAINT t_lots_pkey PRIMARY KEY (id_lot);

ALTER TABLE ONLY t_programmes
    ADD CONSTRAINT t_programmes_pkey PRIMARY KEY (id_programme);


---------------
--FOREIGN KEY--
---------------
ALTER TABLE ONLY cor_role_droit_entite
    ADD CONSTRAINT cor_role_droit_application_id_droit_fkey FOREIGN KEY (id_droit) REFERENCES utilisateurs.bib_droits(id_droit) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_role_droit_entite
    ADD CONSTRAINT cor_role_droit_entite_t_roles_fkey FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;


ALTER TABLE ONLY cor_role_lot_application
    ADD CONSTRAINT cor_role_droit_application_id_role_fkey FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_role_lot_application
    ADD CONSTRAINT cor_role_lot_application_id_application_fkey FOREIGN KEY (id_application) REFERENCES utilisateurs.t_applications(id_application) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_role_lot_application
    ADD CONSTRAINT cor_role_lot_application_id_droit_fkey FOREIGN KEY (id_lot) REFERENCES t_lots(id_lot) ON UPDATE CASCADE ON DELETE CASCADE;


ALTER TABLE ONLY t_lots
    ADD CONSTRAINT fk_bib_lots_financeur FOREIGN KEY (id_organisme_financeur) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY t_lots
    ADD CONSTRAINT fk_bib_lots_gestionnaire FOREIGN KEY (id_organisme_gestionnaire) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY t_lots
    ADD CONSTRAINT fk_bib_lots_producteur FOREIGN KEY (id_organisme_producteur) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY t_lots
    ADD CONSTRAINT fk_bib_lots_proprietaire FOREIGN KEY (id_organisme_proprietaire) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY t_lots
    ADD CONSTRAINT fk_bib_lots_t_programmes FOREIGN KEY (id_programme) REFERENCES t_programmes(id_programme) ON UPDATE CASCADE;

---------
--DATAS--
---------
INSERT INTO t_programmes VALUES (1, 'faune', 'programme faune', true);
INSERT INTO t_programmes VALUES (2, 'flore', 'programme flore', true);
