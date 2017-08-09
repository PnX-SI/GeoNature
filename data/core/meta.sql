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
COMMENT ON TABLE cor_role_droit_entite IS 'Permet de gérer les droits d''un groupe ou d''un utilisateur sur les différentes entités (tables) gérées par le backoffice (CRUD selon droits).';


CREATE TABLE cor_role_lot_application (
    id_role integer NOT NULL,
    id_lot integer NOT NULL,
    id_application integer NOT NULL
);
COMMENT ON TABLE cor_role_lot_application IS 'Permet d''identifier pour chaque module GeoNature (un module = 1 application dans UsersHub) parmi quels lots l''utilisateur logué peut rattacher ses observations. Rappel : un lot est un jeu de données ou une étude et chaque observation est rattachée à un lot. Un backoffice de geonature V2 permet une gestion des lots.';


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
COMMENT ON TABLE t_lots IS 'Un lot est un jeu de données ou une étude et chaque observation est rattachée à un lot. Le lot permet de qualifier les données auxquelles il se rapporte (producteur, propriétaire, gestionnaire, financeur, donnée publique oui/non). Un lot peut être rattaché à un programme. Un backoffice de geonature V2 permet une gestion des lots.';


CREATE TABLE t_programmes (
    id_programme integer NOT NULL,
    nom_programme character varying(255),
    desc_programme text,
    actif boolean
);
COMMENT ON TABLE t_programmes IS 'Les programmes sont des objets généraux pouvant englober des lots de données et/ou des protocoles (à discuter pour les protocoles). Exemple : ATBI, rapaces, plan national d''action, etc... Un backoffice de geonature V2 permet une gestion des programmes.';


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