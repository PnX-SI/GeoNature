SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;


CREATE SCHEMA IF NOT EXISTS gn_users;


SET search_path = gn_users, utilisateurs, pg_catalog;


----------
--TABLES--
----------
CREATE SEQUENCE t_tags_id_tag_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE TABLE IF NOT EXISTS t_tags (
    id_tag integer NOT NULL,
    id_tag_type integer NOT NULL,
    tag_code character varying(25),
    tag_name character varying(255),
    tag_label character varying(255),
    tag_desc text,
    meta_create_date timestamp without time zone,
    meta_update_date timestamp without time zone
);
COMMENT ON TABLE t_tags IS 'Permet de créer des étiquettes ou tags ou labels, qu''il est possible d''attacher à différents objects de la base. Cela peut permettre par exemple de créer des groupes ou des listes d''utilisateurs';
ALTER SEQUENCE t_tags_id_tag_seq OWNED BY t_tags.id_tag;
ALTER TABLE ONLY t_tags ALTER COLUMN id_tag SET DEFAULT nextval('t_tags_id_tag_seq'::regclass);


CREATE TABLE IF NOT EXISTS bib_tag_types (
    id_tag_type integer NOT NULL,
    tag_type_name character varying(100) NOT NULL,
    tag_type_desc character varying(255) NOT NULL
);
COMMENT ON TABLE bib_tag_types IS 'Permet de définir le type du tag';


CREATE TABLE IF NOT EXISTS cor_tags_relations (
    id_tag_l integer NOT NULL,
    id_tag_r integer NOT NULL,
    relation_type character varying(255) NOT NULL
);
COMMENT ON TABLE cor_tags_relations IS 'Permet de définir des relations nn entre tags en affectant des étiquettes à des tags';

CREATE TABLE IF NOT EXISTS cor_role_tag (
    id_role integer NOT NULL,
    id_tag integer NOT NULL
);
COMMENT ON TABLE cor_role_tag IS 'Permet d''attacher des étiquettes à des roles. Par exemple pour créer des listes d''observateurs';

CREATE TABLE IF NOT EXISTS cor_organism_tag (
    id_organism integer NOT NULL,
    id_tag integer NOT NULL
);
COMMENT ON TABLE cor_organism_tag IS 'Permet d''attacher des étiquettes à des organismes';


CREATE TABLE IF NOT EXISTS cor_application_tag (
    id_application integer NOT NULL,
    id_tag integer NOT NULL
);
COMMENT ON TABLE cor_organism_tag IS 'Permet d''attacher des étiquettes à des applications';


CREATE TABLE IF NOT EXISTS cor_app_privileges (
    id_tag_action integer NOT NULL,
    id_tag_object integer NOT NULL,
    id_application integer NOT NULL,
    id_role integer NOT NULL
);
COMMENT ON TABLE cor_app_privileges IS 'Cette table centrale, permet de gérer les droits d''usage des données en fonction du profil de l''utilisateur. Elle établi une correspondance entre l''affectation de tags génériques du schéma utilisateurs à un role pour une application avec les droits d''usage  (CREATE, READ, UPDATE, VALID, EXPORT, DELETE) et le type des données GeoNature (MY DATA, MY ORGANISM DATA, ALL DATA)';


DO
$$
BEGIN
ALTER TABLE utilisateurs.bib_organismes ADD COLUMN id_parent integer;
ALTER TABLE utilisateurs.t_applications ADD COLUMN id_parent integer;
ALTER TABLE utilisateurs.t_roles ADD COLUMN pass_sha text;
EXCEPTION WHEN duplicate_column  THEN
        RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;
----------------
--PRIMARY KEYS--
----------------
ALTER TABLE ONLY t_tags ADD CONSTRAINT pk_t_tags PRIMARY KEY (id_tag);

ALTER TABLE ONLY bib_tag_types ADD CONSTRAINT pk_bib_tag_types PRIMARY KEY (id_tag_type);

ALTER TABLE ONLY cor_tags_relations ADD CONSTRAINT pk_cor_tags_relations PRIMARY KEY (id_tag_l, id_tag_r);

ALTER TABLE ONLY cor_organism_tag ADD CONSTRAINT pk_cor_organism_tag PRIMARY KEY (id_organism, id_tag);

ALTER TABLE ONLY cor_role_tag ADD CONSTRAINT pk_cor_role_tag PRIMARY KEY (id_role, id_tag);

ALTER TABLE ONLY cor_application_tag ADD CONSTRAINT pk_cor_application_tag PRIMARY KEY (id_application, id_tag);

ALTER TABLE ONLY cor_app_privileges ADD CONSTRAINT pk_cor_app_privileges PRIMARY KEY (id_tag_object, id_tag_action, id_application, id_role);


------------
--TRIGGERS--
------------
CREATE TRIGGER tri_meta_dates_change_t_tags
  BEFORE INSERT OR UPDATE
  ON t_tags
  FOR EACH ROW
  EXECUTE PROCEDURE public.fct_trg_meta_dates_change();

----------------
--FOREIGN KEYS--
----------------
DO
$$
BEGIN
ALTER TABLE ONLY utilisateurs.bib_organismes ADD CONSTRAINT fk_bib_organismes_id_parent FOREIGN KEY (id_parent) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;
ALTER TABLE ONLY utilisateurs.t_applications ADD CONSTRAINT fk_t_applications_id_parent FOREIGN KEY (id_parent) REFERENCES utilisateurs.t_applications(id_application) ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object  THEN
        RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;
ALTER TABLE ONLY t_tags ADD CONSTRAINT fk_t_tags_id_tag_type FOREIGN KEY (id_tag_type) REFERENCES bib_tag_types(id_tag_type) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_tags_relations ADD CONSTRAINT fk_cor_tags_relations_id_tag_l FOREIGN KEY (id_tag_l) REFERENCES t_tags(id_tag) ON UPDATE CASCADE;
ALTER TABLE ONLY cor_tags_relations ADD CONSTRAINT fk_cor_tags_relations_id_tag_r FOREIGN KEY (id_tag_r) REFERENCES t_tags(id_tag) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_organism_tag ADD CONSTRAINT fk_cor_organism_tag_id_organism FOREIGN KEY (id_organism) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;
ALTER TABLE ONLY cor_organism_tag ADD CONSTRAINT fk_cor_organism_tag_id_tag FOREIGN KEY (id_tag) REFERENCES t_tags(id_tag) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_role_tag ADD CONSTRAINT fk_cor_role_tag_id_role FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;
ALTER TABLE ONLY cor_role_tag ADD CONSTRAINT fk_cor_role_tag_id_tag FOREIGN KEY (id_tag) REFERENCES t_tags(id_tag) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_application_tag ADD CONSTRAINT fk_cor_application_tag_t_applications_id_application FOREIGN KEY (id_application) REFERENCES utilisateurs.t_applications(id_application) ON UPDATE CASCADE;
ALTER TABLE ONLY cor_application_tag ADD CONSTRAINT fk_cor_application_tag_t_tags_id_tag FOREIGN KEY (id_tag) REFERENCES t_tags(id_tag) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_app_privileges ADD CONSTRAINT fk_cor_app_privileges_id_tag_object FOREIGN KEY (id_tag_object) REFERENCES t_tags(id_tag) ON UPDATE CASCADE;
ALTER TABLE ONLY cor_app_privileges ADD CONSTRAINT fk_cor_app_privileges_id_tag_action FOREIGN KEY (id_tag_action) REFERENCES t_tags(id_tag) ON UPDATE CASCADE;
ALTER TABLE ONLY cor_app_privileges ADD CONSTRAINT fk_cor_app_privileges_id_application FOREIGN KEY (id_application) REFERENCES t_applications(id_application) ON UPDATE CASCADE;
ALTER TABLE ONLY cor_app_privileges ADD CONSTRAINT fk_cor_app_privileges_id_role FOREIGN KEY (id_role) REFERENCES t_roles(id_role) ON UPDATE CASCADE;


---------
--VIEWS--
---------
CREATE OR REPLACE VIEW v_userslist_forall_menu AS 
 SELECT a.groupe,
    a.id_role,
    a.identifiant,
    a.nom_role,
    a.prenom_role,
    (upper(a.nom_role::text) || ' '::text) || a.prenom_role::text AS nom_complet,
    a.desc_role,
    a.pass,
    a.email,
    a.id_organisme,
    a.organisme,
    a.id_unite,
    a.remarques,
    a.pn,
    a.session_appli,
    a.date_insert,
    a.date_update,
    a.id_menu
   FROM ( SELECT u.groupe,
            u.id_role,
            u.identifiant,
            u.nom_role,
            u.prenom_role,
            u.desc_role,
            u.pass,
            u.email,
            u.id_organisme,
            u.organisme,
            u.id_unite,
            u.remarques,
            u.pn,
            u.session_appli,
            u.date_insert,
            u.date_update,
            c.id_menu
           FROM utilisateurs.t_roles u
             JOIN utilisateurs.cor_role_menu c ON c.id_role = u.id_role
          WHERE u.groupe = false
        UNION
         SELECT u.groupe,
            u.id_role,
            u.identifiant,
            u.nom_role,
            u.prenom_role,
            u.desc_role,
            u.pass,
            u.email,
            u.id_organisme,
            u.organisme,
            u.id_unite,
            u.remarques,
            u.pn,
            u.session_appli,
            u.date_insert,
            u.date_update,
            c.id_menu
           FROM utilisateurs.t_roles u
             JOIN utilisateurs.cor_roles g ON g.id_role_utilisateur = u.id_role
             JOIN utilisateurs.cor_role_menu c ON c.id_role = g.id_role_groupe
          WHERE u.groupe = false) a;


CREATE OR REPLACE VIEW gn_users.v_usersaction_forall_gn_modules AS
 WITH all_users_tags AS (
         WITH a1 AS (
                SELECT u.id_role,
                    u.identifiant,
                    u.nom_role,
                    u.prenom_role,
                    u.desc_role,
                    u.pass,
                    u.pass_sha,
                    u.email,
                    u.id_organisme,
                    c_1.id_tag_action,
                    c_1.id_tag_object,
                    a_1.id_application
                FROM utilisateurs.t_roles u
                     JOIN gn_users.cor_app_privileges c_1 ON c_1.id_role = u.id_role
                     JOIN ( SELECT a.id_application, a.id_parent
                            FROM utilisateurs.t_applications a
                            WHERE a.id_parent IS NOT NULL
                        ) a_1 ON a_1.id_parent = c_1.id_application
                WHERE u.groupe = false
                UNION
                SELECT u.id_role,
                    u.identifiant,
                    u.nom_role,
                    u.prenom_role,
                    u.desc_role,
                    u.pass,
                    u.pass_sha,
                    u.email,
                    u.id_organisme,
                    c_1.id_tag_action,
                    c_1.id_tag_object,
                    c_1.id_application
                FROM utilisateurs.t_roles u
                     JOIN gn_users.cor_app_privileges c_1 ON c_1.id_role = u.id_role
                WHERE u.groupe = false
                ), a2 AS (
                SELECT u.id_role,
                    u.identifiant,
                    u.nom_role,
                    u.prenom_role,
                    u.desc_role,
                    u.pass,
                    u.pass_sha,
                    u.email,
                    u.id_organisme,
                    c_1.id_tag_action,
                    c_1.id_tag_object,
                    a_1.id_application
                FROM utilisateurs.t_roles u
                     JOIN utilisateurs.cor_roles g ON g.id_role_utilisateur = u.id_role
                     JOIN gn_users.cor_app_privileges c_1 ON c_1.id_role = g.id_role_groupe
                     JOIN ( SELECT a.id_application, a.id_parent
                            FROM utilisateurs.t_applications a
                            WHERE a.id_parent IS NOT NULL
                        ) a_1 ON a_1.id_parent = c_1.id_application
                  WHERE (g.id_role_groupe IN ( SELECT DISTINCT id_role_groupe FROM utilisateurs.cor_roles))
                UNION
                 SELECT u.id_role,
                    u.identifiant,
                    u.nom_role,
                    u.prenom_role,
                    u.desc_role,
                    u.pass,
                    u.pass_sha,
                    u.email,
                    u.id_organisme,
                    c_1.id_tag_action,
                    c_1.id_tag_object,
                    c_1.id_application
                   FROM utilisateurs.t_roles u
                     JOIN utilisateurs.cor_roles g ON g.id_role_utilisateur = u.id_role
                     JOIN gn_users.cor_app_privileges c_1 ON c_1.id_role = g.id_role_groupe
                  WHERE (g.id_role_groupe IN ( SELECT DISTINCT id_role_groupe FROM utilisateurs.cor_roles))
                )
         SELECT a.id_role,
            a.identifiant,
            a.nom_role,
            a.prenom_role,
            a.desc_role,
            a.pass,
            a.pass_sha,
            a.email,
            a.id_organisme,
            a.id_tag_action,
            a.id_tag_object,
            a.id_application
           FROM ( SELECT a1.id_role,
                    a1.identifiant,
                    a1.nom_role,
                    a1.prenom_role,
                    a1.desc_role,
                    a1.pass,
                    a1.pass_sha,
                    a1.email,
                    a1.id_organisme,
                    a1.id_tag_action,
                    a1.id_tag_object,
                    a1.id_application
                   FROM a1
                UNION
                 SELECT a2.id_role,
                    a2.identifiant,
                    a2.nom_role,
                    a2.prenom_role,
                    a2.desc_role,
                    a2.pass,
                    a2.pass_sha,
                    a2.email,
                    a2.id_organisme,
                    a2.id_tag_action,
                    a2.id_tag_object,
                    a2.id_application
                   FROM a2) a
        )
 SELECT v.id_role,
    v.identifiant,
    v.nom_role,
    v.prenom_role,
    v.desc_role,
    v.pass,
    v.pass_sha,
    v.email,
    v.id_organisme,
    v.id_application,
    v.id_tag_action,
    v.id_tag_object,
    t1.tag_code AS tag_action_code,
    t2.tag_code AS tag_object_code
   FROM all_users_tags v
     JOIN gn_users.t_tags t1 ON t1.id_tag = v.id_tag_action
     JOIN gn_users.t_tags t2 ON t2.id_tag = v.id_tag_object;


-- -------------
-- --FUNCTIONS--
-- -------------
--With action id
CREATE OR REPLACE FUNCTION gn_users.can_user_do_in_module(
    myuser integer,
    mymodule integer,
    myaction integer,
    mydataextend integer)
  RETURNS boolean AS
$BODY$
-- the function say if the given user can do the requested action in the requested module on the resquested data
-- USAGE : SELECT gn_users.can_user_do_in_module(requested_userid,requested_actionid,requested_moduleid,requested_dataextendid);
-- SAMPLE :SELECT gn_users.can_user_do_in_module(2,15,14,22);
  BEGIN
    IF myaction IN (SELECT id_tag_action FROM gn_users.v_usersaction_forall_gn_modules WHERE id_role = myuser AND id_application = mymodule AND id_tag_object >= mydataextend) THEN
	    RETURN true;
    END IF;
    RETURN false;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;


--With action code
CREATE OR REPLACE FUNCTION gn_users.can_user_do_in_module(
    myuser integer,
    mymodule integer,
    myaction character varying,
    mydataextend integer)
  RETURNS boolean AS
$BODY$
-- the function say if the given user can do the requested action in the requested module on the resquested data
-- USAGE : SELECT gn_users.can_user_do_in_module(requested_userid,requested_actioncode,requested_moduleid,requested_dataextendid);
-- SAMPLE :SELECT gn_users.can_user_do_in_module(2,15,14,22);
  BEGIN
    IF myaction IN (SELECT tag_action_code FROM gn_users.v_usersaction_forall_gn_modules WHERE id_role = myuser AND id_application = mymodule AND id_tag_object >= mydataextend) THEN
	    RETURN true;
    END IF;
    RETURN false;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

--With action id
CREATE OR REPLACE FUNCTION gn_users.user_max_accessible_data_level_in_module(
    myuser integer,
    myaction integer,
    mymodule integer)
  RETURNS integer AS
$BODY$
DECLARE
	themaxleveldatatype integer;
-- the function return the max accessible extend of data the given user can access in the requested module
-- USAGE : SELECT gn_users.user_max_accessible_data_level_in_module(requested_userid,requested_actionid,requested_moduleid);
-- SAMPLE :SELECT gn_users.user_max_accessible_data_level_in_module(2,14,14);
  BEGIN
	SELECT max(tag_object_code::int) INTO themaxleveldatatype FROM gn_users.v_usersaction_forall_gn_modules WHERE id_role = myuser AND id_application = mymodule AND id_tag_action = myaction;
	RETURN themaxleveldatatype;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

--With action code
CREATE OR REPLACE FUNCTION gn_users.user_max_accessible_data_level_in_module(
    myuser integer,
    myaction character varying,
    mymodule integer)
  RETURNS integer AS
$BODY$
DECLARE
	themaxleveldatatype integer;
-- the function return the max accessible extend of data the given user can access in the requested module
-- USAGE : SELECT gn_users.user_max_accessible_data_level_in_module(requested_userid,requested_actioncode,requested_moduleid);
-- SAMPLE :SELECT gn_users.user_max_accessible_data_level_in_module(2,14,14);
  BEGIN
	SELECT max(tag_object_code::int) INTO themaxleveldatatype FROM gn_users.v_usersaction_forall_gn_modules WHERE id_role = myuser AND id_application = mymodule AND tag_action_code = myaction;
	RETURN themaxleveldatatype;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

CREATE OR REPLACE FUNCTION gn_users.find_all_modules_childs(myidapplication integer)
  RETURNS SETOF integer AS
$BODY$
 --Param : id_application d'un module ou d'une application quelque soit son rang
 --Retourne le id_application de tous les modules enfants + le module lui-même sous forme d'un jeu de données utilisable comme une table
 --Usage SELECT utilisateurs.find_all_modules_childs(14);
 --ou SELECT * FROM utilisateurs.t_applications WHERE id_application IN(SELECT * FROM gn_users.find_all_modules_childs(14))
  DECLARE
    inf RECORD;
    c integer;
  BEGIN
    SELECT INTO c count(*) FROM utilisateurs.t_applications WHERE id_parent = myidapplication;
    IF c > 0 THEN
      FOR inf IN
          WITH RECURSIVE modules AS (
          SELECT a1.id_application FROM utilisateurs.t_applications a1 WHERE a1.id_application = myidapplication
          UNION ALL
          SELECT a2.id_application FROM modules m JOIN utilisateurs.t_applications a2 ON a2.id_parent = m.id_application
	  )
          SELECT id_application FROM modules
  LOOP
      RETURN NEXT inf.id_application;
  END LOOP;
    END IF;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100
  ROWS 1000;