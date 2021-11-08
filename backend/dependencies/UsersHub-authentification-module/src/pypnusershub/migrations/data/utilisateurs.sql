SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET search_path = utilisateurs, pg_catalog, public;


CREATE SCHEMA utilisateurs;


-------------
--FUNCTIONS--
-------------

CREATE OR REPLACE FUNCTION modify_date_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.date_insert := now();
    NEW.date_update := now();
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION modify_date_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.date_update := now();
    RETURN NEW;
END;
$$;

SET default_tablespace = '';
SET default_with_oids = false;

----------------------
--TABLES & SEQUENCES--
----------------------

CREATE TABLE IF NOT EXISTS t_roles (
    groupe boolean DEFAULT false NOT NULL,
    id_role serial NOT NULL,
    uuid_role uuid NOT NULL DEFAULT public.uuid_generate_v4(),
    identifiant character varying(100),
    nom_role character varying(50),
    prenom_role character varying(50),
    desc_role text,
    pass character varying(100),
    pass_plus text,
    email character varying(250),
    id_organisme integer,
    remarques text,
    active boolean DEFAULT true,
    champs_addi jsonb,
    date_insert timestamp without time zone,
    date_update timestamp without time zone
);

CREATE TABLE IF NOT EXISTS bib_organismes (
    id_organisme serial NOT NULL,
    uuid_organisme uuid NOT NULL DEFAULT public.uuid_generate_v4(),
    nom_organisme character varying(500) NOT NULL,
    adresse_organisme character varying(128),
    cp_organisme character varying(5),
    ville_organisme character varying(100),
    tel_organisme character varying(14),
    fax_organisme character varying(14),
    email_organisme character varying(100),
    url_organisme character varying(255),
    url_logo character varying(255),
    id_parent integer
);

CREATE TABLE  IF NOT EXISTS t_listes
(
  id_liste serial NOT NULL,
  code_liste character varying(20) NOT NULL,
  nom_liste character varying(50) NOT NULL,
  desc_liste text
);
COMMENT ON TABLE t_listes IS 'Table des listes déroulantes des applications. Les roles (groupes ou utilisateurs) devant figurer dans une liste sont gérés dans la table cor_role_liste';

CREATE TABLE IF NOT EXISTS t_applications (
    id_application integer NOT NULL,
    code_application character varying(20) NOT NULL,
    nom_application character varying(50) NOT NULL,
    desc_application text,
    id_parent integer
);

CREATE SEQUENCE t_applications_id_application_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE t_applications_id_application_seq OWNED BY t_applications.id_application;
ALTER TABLE ONLY t_applications ALTER COLUMN id_application SET DEFAULT nextval('t_applications_id_application_seq'::regclass);

CREATE TABLE IF NOT EXISTS t_profils (
    id_profil serial NOT NULL,
    code_profil character varying(20),
    nom_profil character varying(255),
    desc_profil text
);
COMMENT ON TABLE t_profils IS 'Table des profils d''utilisateurs génériques ou applicatifs, qui seront ensuite attachés à des roles et des applications';

CREATE TABLE IF NOT EXISTS cor_role_liste (
    id_role integer NOT NULL,
    id_liste integer NOT NULL
);
COMMENT ON TABLE cor_role_liste IS 'Equivalent de l''ancienne cor_role_menu. Permet de créer des listes de roles (observateurs par ex.), sans notion de permission';

CREATE TABLE IF NOT EXISTS cor_roles (
    id_role_groupe integer NOT NULL,
    id_role_utilisateur integer NOT NULL
);

CREATE TABLE IF NOT EXISTS cor_profil_for_app (
    id_profil integer NOT NULL,
    id_application integer NOT NULL
);
COMMENT ON TABLE cor_profil_for_app IS 'Permet d''attribuer et limiter les profils disponibles pour chacune des applications';

CREATE TABLE IF NOT EXISTS cor_role_app_profil (
    id_role integer NOT NULL,
    id_application integer NOT NULL,
    id_profil integer NOT NULL,
    is_default_group_for_app boolean NOT NULL DEFAULT (FALSE)
);
COMMENT ON TABLE cor_role_app_profil IS 'Cette table centrale, permet d''associer des roles à des profils par application';


CREATE TABLE IF NOT EXISTS cor_role_token
(
    id_role INTEGER,
    token text
);

CREATE TABLE IF NOT EXISTS utilisateurs.temp_users
(
    id_temp_user SERIAL NOT NULL,
    token_role text,
    organisme character(32),
    id_application integer NOT NULL,
    confirmation_url character varying(250),
    groupe boolean NOT NULL DEFAULT false,
    identifiant character varying(100),
    nom_role character varying(50),
    prenom_role character varying(50),
    desc_role text,
    pass_md5 text,
    password text,
    email character varying(250),
    id_organisme integer,
    remarques text,
    champs_addi jsonb,
    date_insert timestamp without time zone,
    date_update timestamp without time zone
);

----------------
--PRIMARY KEYS--
----------------

ALTER TABLE ONLY bib_organismes ADD CONSTRAINT pk_bib_organismes PRIMARY KEY (id_organisme);

ALTER TABLE ONLY t_roles ADD CONSTRAINT pk_t_roles PRIMARY KEY (id_role);

ALTER TABLE ONLY t_listes ADD CONSTRAINT pk_t_listes PRIMARY KEY (id_liste);

ALTER TABLE ONLY t_applications ADD CONSTRAINT pk_t_applications PRIMARY KEY (id_application);

ALTER TABLE ONLY t_profils ADD CONSTRAINT pk_t_profils PRIMARY KEY (id_profil);

ALTER TABLE ONLY cor_roles ADD CONSTRAINT cor_roles_pkey PRIMARY KEY (id_role_groupe, id_role_utilisateur);

ALTER TABLE ONLY cor_role_liste ADD CONSTRAINT pk_cor_role_liste PRIMARY KEY (id_liste, id_role);

ALTER TABLE ONLY cor_profil_for_app ADD CONSTRAINT pk_cor_profil_for_app PRIMARY KEY (id_application, id_profil);

ALTER TABLE ONLY cor_role_app_profil ADD CONSTRAINT pk_cor_role_app_profil PRIMARY KEY (id_role, id_application, id_profil);

ALTER TABLE ONLY cor_role_token ADD CONSTRAINT cor_role_token_pk_id_role PRIMARY KEY (id_role);

ALTER TABLE ONLY temp_users ADD CONSTRAINT pk_temp_users PRIMARY KEY (id_temp_user);


------------
--TRIGGERS--
------------

CREATE TRIGGER tri_modify_date_insert_t_roles BEFORE INSERT ON t_roles FOR EACH ROW EXECUTE PROCEDURE modify_date_insert();

CREATE TRIGGER tri_modify_date_update_t_roles BEFORE UPDATE ON t_roles FOR EACH ROW EXECUTE PROCEDURE modify_date_update();

CREATE TRIGGER tri_modify_date_insert_temp_roles
    BEFORE INSERT
    ON temp_users
    FOR EACH ROW
    EXECUTE PROCEDURE utilisateurs.modify_date_insert();


----------------
--FOREIGN KEYS--
----------------

ALTER TABLE ONLY t_roles ADD CONSTRAINT t_roles_id_organisme_fkey FOREIGN KEY (id_organisme) REFERENCES bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_roles ADD CONSTRAINT cor_roles_id_role_groupe_fkey FOREIGN KEY (id_role_groupe) REFERENCES t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY cor_roles ADD CONSTRAINT cor_roles_id_role_utilisateur_fkey FOREIGN KEY (id_role_utilisateur) REFERENCES t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY bib_organismes ADD CONSTRAINT fk_bib_organismes_id_parent FOREIGN KEY (id_parent) REFERENCES bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY t_applications ADD CONSTRAINT fk_t_applications_id_parent FOREIGN KEY (id_parent) REFERENCES t_applications(id_application) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_role_liste ADD CONSTRAINT fk_cor_role_liste_id_liste FOREIGN KEY (id_liste) REFERENCES t_listes(id_liste) ON UPDATE CASCADE;
ALTER TABLE ONLY cor_role_liste ADD CONSTRAINT fk_cor_role_liste_id_role FOREIGN KEY (id_role) REFERENCES t_roles(id_role) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_profil_for_app ADD CONSTRAINT fk_cor_profil_for_app_id_application FOREIGN KEY (id_application) REFERENCES t_applications(id_application) ON UPDATE CASCADE;
ALTER TABLE ONLY cor_profil_for_app ADD CONSTRAINT fk_cor_profil_for_app_id_profil FOREIGN KEY (id_profil) REFERENCES t_profils(id_profil) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_role_app_profil ADD CONSTRAINT fk_cor_role_app_profil_id_role FOREIGN KEY (id_role) REFERENCES t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY cor_role_app_profil ADD CONSTRAINT fk_cor_role_app_profil_id_application FOREIGN KEY (id_application) REFERENCES t_applications(id_application) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY cor_role_app_profil ADD CONSTRAINT fk_cor_role_app_profil_id_profil FOREIGN KEY (id_profil) REFERENCES t_profils(id_profil) ON UPDATE CASCADE ON DELETE CASCADE;


ALTER TABLE ONLY cor_role_token ADD CONSTRAINT cor_role_token_fk_id_role FOREIGN KEY (id_role)
    REFERENCES t_roles (id_role) MATCH SIMPLE
    ON UPDATE CASCADE ON DELETE CASCADE;


ALTER TABLE ONLY temp_users ADD CONSTRAINT temp_user_id_organisme_fkey FOREIGN KEY (id_application)
    REFERENCES t_applications (id_application) MATCH SIMPLE
    ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY temp_users ADD CONSTRAINT temp_user_id_application_fkey FOREIGN KEY (id_organisme)
    REFERENCES bib_organismes (id_organisme) MATCH SIMPLE
    ON UPDATE CASCADE ON DELETE CASCADE;

----------------
------INDEX-----
----------------
CREATE INDEX i_utilisateurs_groupe
  ON utilisateurs.t_roles
  USING btree
  (groupe);

CREATE INDEX i_utilisateurs_nom_prenom
  ON utilisateurs.t_roles
  USING btree
  (nom_role, prenom_role);

CREATE INDEX i_utilisateurs_active
  ON utilisateurs.t_roles
  USING btree
  (active);
  
---------------
--CONSTRAINTS--
---------------
CREATE OR REPLACE FUNCTION utilisateurs.check_is_default_group_for_app_is_grp_and_unique(id_app integer, id_grp integer, is_default boolean)
RETURNS boolean AS
$BODY$
BEGIN
    -- Fonction de vérification
    -- Test : si le role est un groupe et qu'il n'y a qu'un seul groupe par défaut définit par application
    IF is_default IS TRUE THEN
        IF (
            SELECT DISTINCT TRUE
            FROM utilisateurs.cor_role_app_profil
            WHERE id_application = id_app AND is_default_group_for_app IS TRUE
        ) IS TRUE THEN
            RETURN FALSE;
        ELSIF (SELECT TRUE FROM utilisateurs.t_roles WHERE id_role = id_grp AND groupe IS TRUE) IS NULL THEN
            RETURN FALSE;
        ELSE
          RETURN TRUE;
        END IF;
    END IF;
    RETURN TRUE;
  END
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;


ALTER TABLE utilisateurs.cor_role_app_profil ADD CONSTRAINT check_is_default_group_for_app_is_grp_and_unique
    CHECK (utilisateurs.check_is_default_group_for_app_is_grp_and_unique(id_application, id_role, is_default_group_for_app)) NOT VALID;


---------
--VIEWS--
---------
-- Vue permettant de retourner les utilisateurs des listes
CREATE OR REPLACE VIEW v_userslist_forall_menu AS
 SELECT a.groupe,
    a.id_role,
    a.uuid_role,
    a.identifiant,
    a.nom_role,
    a.prenom_role,
    (upper(a.nom_role::text) || ' '::text) || a.prenom_role::text AS nom_complet,
    a.desc_role,
    a.pass,
    a.pass_plus,
    a.email,
    a.id_organisme,
    a.organisme,
    a.id_unite,
    a.remarques,
    a.date_insert,
    a.date_update,
    a.id_menu
   FROM ( SELECT u.groupe,
            u.id_role,
            u.uuid_role,
            u.identifiant,
            u.nom_role,
            u.prenom_role,
            u.desc_role,
            u.pass,
            u.pass_plus,
            u.email,
            u.id_organisme,
            o.nom_organisme AS organisme,
            0 AS id_unite,
            u.remarques,
            u.date_insert,
            u.date_update,
            c.id_liste AS id_menu
           FROM utilisateurs.t_roles u
             JOIN utilisateurs.cor_role_liste c ON c.id_role = u.id_role
             LEFT JOIN utilisateurs.bib_organismes o ON o.id_organisme = u.id_organisme
          WHERE u.groupe = false AND u.active = true
        UNION
         SELECT u.groupe,
            u.id_role,
            u.uuid_role,
            u.identifiant,
            u.nom_role,
            u.prenom_role,
            u.desc_role,
            u.pass,
            u.pass_plus,
            u.email,
            u.id_organisme,
            o.nom_organisme AS organisme,
            0 AS id_unite,
            u.remarques,
            u.date_insert,
            u.date_update,
            c.id_liste AS id_menu
           FROM utilisateurs.t_roles u
             JOIN utilisateurs.cor_roles g ON g.id_role_utilisateur = u.id_role
             JOIN utilisateurs.cor_role_liste c ON c.id_role = g.id_role_groupe
             LEFT JOIN utilisateurs.bib_organismes o ON o.id_organisme = u.id_organisme
          WHERE u.groupe = false AND u.active = true) a;

-- Vue permettant de retourner les roles et leurs droits maximum pour chaque application
CREATE OR REPLACE VIEW utilisateurs.v_roleslist_forall_applications AS
SELECT a.groupe,
    a.active,
    a.id_role,
    a.identifiant,
    a.nom_role,
    a.prenom_role,
    a.desc_role,
    a.pass,
    a.pass_plus,
    a.email,
    a.id_organisme,
    a.organisme,
    a.id_unite,
    a.remarques,
    a.date_insert,
    a.date_update,
    max(a.id_droit) AS id_droit_max,
    a.id_application
   FROM ( SELECT u.groupe,
            u.id_role,
            u.identifiant,
            u.nom_role,
            u.prenom_role,
            u.desc_role,
            u.pass,
            u.pass_plus,
            u.email,
            u.id_organisme,
	    u.active,
            o.nom_organisme AS organisme,
            0 AS id_unite,
            u.remarques,
            u.date_insert,
            u.date_update,
            c.id_profil AS id_droit,
            c.id_application
           FROM utilisateurs.t_roles u
             JOIN utilisateurs.cor_role_app_profil c ON c.id_role = u.id_role
             JOIN utilisateurs.bib_organismes o ON o.id_organisme = u.id_organisme
        UNION
         SELECT u.groupe,
            u.id_role,
            u.identifiant,
            u.nom_role,
            u.prenom_role,
            u.desc_role,
            u.pass,
            u.pass_plus,
            u.email,
            u.id_organisme,
            u.active,
            o.nom_organisme AS organisme,
            0 AS id_unite,
            u.remarques,
            u.date_insert,
            u.date_update,
            c.id_profil AS id_droit,
            c.id_application
           FROM utilisateurs.t_roles u
             JOIN utilisateurs.cor_roles g ON g.id_role_utilisateur = u.id_role OR g.id_role_groupe = u.id_role
             JOIN utilisateurs.cor_role_app_profil c ON c.id_role = g.id_role_groupe
             LEFT JOIN utilisateurs.bib_organismes o ON o.id_organisme = u.id_organisme
          ) a
  WHERE a.active = true
  GROUP BY a.groupe, a.active, a.id_role, a.identifiant, a.nom_role, a.prenom_role, a.desc_role, a.pass, a.pass_plus, a.email, a.id_organisme, a.organisme, a.id_unite, a.remarques, a.date_insert, a.date_update, a.id_application;

-- Vue permettant de retourner les utilisateurs (pas les roles) et leurs droits maximum pour chaque application
CREATE OR REPLACE VIEW utilisateurs.v_userslist_forall_applications AS
SELECT * FROM utilisateurs.v_roleslist_forall_applications
WHERE groupe = false;

----------
---DATA---
----------

--- Profils
INSERT INTO t_profils (id_profil, code_profil, nom_profil, desc_profil) VALUES
(0, '0', 'Aucun', 'Aucun droit')
,(1, '1', 'Lecteur', 'Ne peut que consulter/ou acceder')
,(2, '2', 'Rédacteur', 'Il possède des droit d''écriture pour créer des enregistrements')
,(3, '3', 'Référent', 'Utilisateur ayant des droits complémentaires au rédacteur (par exemple exporter des données ou autre)')
,(4, '4', 'Modérateur', 'Peu utilisé')
,(5, '5', 'Validateur', 'Il valide bien sur')
,(6, '6', 'Administrateur', 'Il a tous les droits');
SELECT pg_catalog.setval('t_profils_id_profil_seq', (SELECT max(id_profil)+1 FROM utilisateurs.t_profils), false);
