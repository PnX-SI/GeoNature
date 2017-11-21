SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;


CREATE SCHEMA IF NOT EXISTS gn_users;


SET search_path = gn_users, pg_catalog;


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
    tag_name character varying(255),
    tag_desc text,
    meta_create_date timestamp without time zone,
    meta_update_date timestamp without time zone
);
COMMENT ON TABLE t_tags IS 'Permet de créer des étiquettes ou tags ou labels, qu''il est possible d''attacher à différents objects de la base. Cela peut permettre par exemple de créer des groupes ou des listes d''utilisateurs';
ALTER SEQUENCE t_tags_id_tag_seq OWNED BY t_tags.id_tag;
ALTER TABLE ONLY t_tags ALTER COLUMN id_tag SET DEFAULT nextval('t_tags_id_tag_seq'::regclass);


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


CREATE TABLE IF NOT EXISTS cor_applications_tag (
    id_application integer NOT NULL,
    id_tag integer NOT NULL
);
COMMENT ON TABLE cor_organism_tag IS 'Permet d''attacher des étiquettes à des applications';


CREATE TABLE IF NOT EXISTS cor_role_tag_application (
    id_role integer NOT NULL,
    id_tag integer NOT NULL,
    id_application integer NOT NULL,
    comment text
);
COMMENT ON TABLE cor_organism_tag IS 'Permet d''attacher des étiquettes à un role pour une application';


CREATE TABLE IF NOT EXISTS bib_gn_data_types (
    id_gn_data_type integer NOT NULL,
    gn_data_type_name character varying(255),
    gn_data_type_desc text
);


CREATE TABLE IF NOT EXISTS bib_gn_actions (
    id_gn_action integer NOT NULL,
    gn_action_code character varying(25),
    gn_action_name character varying(255),
    gn_action_desc text
);


CREATE TABLE IF NOT EXISTS cor_data_type_action_tag (
    id_gn_data_type integer NOT NULL,
    id_gn_action integer NOT NULL,
    id_tag integer NOT NULL,
    comment text
);
COMMENT ON TABLE cor_data_type_action_tag IS 'Cette table centrale, permet de gérer les droits d''usage des données en fonction du profil de l''utilisateur. Elle établi une correspondance entre l''affectation de tags génériques du schéma utilisateurs à un role pour une application avec les droits d''usage  (CREATE, READ, UPDATE, VALID, EXPORT, DELETE) et le type des données GeoNature (MY DATA, MY ORGANISM DATA, ALL DATA)';

ALTER TABLE utilisateurs.bib_organismes ADD COLUMN id_parent integer;
ALTER TABLE utilisateurs.t_applications ADD COLUMN id_parent integer;
ALTER TABLE utilisateurs.t_roles ADD COLUMN pass_sha text;

----------------
--PRIMARY KEYS--
----------------
ALTER TABLE ONLY t_tags ADD CONSTRAINT pk_t_tags PRIMARY KEY (id_tag);

ALTER TABLE ONLY cor_tags_relations ADD CONSTRAINT pk_cor_tags_relations PRIMARY KEY (id_tag_l, id_tag_r);

ALTER TABLE ONLY cor_organism_tag ADD CONSTRAINT pk_cor_organism_tag PRIMARY KEY (id_organism, id_tag);

ALTER TABLE ONLY cor_role_tag ADD CONSTRAINT pk_cor_role_tag PRIMARY KEY (id_role, id_tag);

ALTER TABLE ONLY cor_applications_tag ADD CONSTRAINT pk_cor_applications_tag PRIMARY KEY (id_application, id_tag);

ALTER TABLE ONLY cor_role_tag_application ADD CONSTRAINT pk_cor_role_tag_application PRIMARY KEY (id_role, id_tag, id_application);

ALTER TABLE ONLY bib_gn_data_types ADD CONSTRAINT pk_bib_gn_data_types PRIMARY KEY (id_gn_data_type);

ALTER TABLE ONLY bib_gn_actions ADD CONSTRAINT pk_bib_gn_actions PRIMARY KEY (id_gn_action);

ALTER TABLE ONLY cor_data_type_action_tag ADD CONSTRAINT pk_cor_data_type_action_tag PRIMARY KEY (id_gn_data_type, id_gn_action, id_tag);


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
ALTER TABLE ONLY utilisateurs.bib_organismes ADD CONSTRAINT fk_bib_organismes_id_parent FOREIGN KEY (id_parent) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY utilisateurs.t_applications ADD CONSTRAINT fk_t_applications_id_parent FOREIGN KEY (id_parent) REFERENCES utilisateurs.t_applications(id_application) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_tags_relations ADD CONSTRAINT fk_cor_tags_relations_id_tag_l FOREIGN KEY (id_tag_l) REFERENCES t_tags(id_tag) ON UPDATE CASCADE;
ALTER TABLE ONLY cor_tags_relations ADD CONSTRAINT fk_cor_tags_relations_id_tag_r FOREIGN KEY (id_tag_r) REFERENCES t_tags(id_tag) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_organism_tag ADD CONSTRAINT fk_cor_organism_tag_id_organism FOREIGN KEY (id_organism) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;
ALTER TABLE ONLY cor_organism_tag ADD CONSTRAINT fk_cor_organism_tag_id_tag FOREIGN KEY (id_tag) REFERENCES t_tags(id_tag) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_role_tag ADD CONSTRAINT fk_cor_role_tag_id_role FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;
ALTER TABLE ONLY cor_role_tag ADD CONSTRAINT fk_cor_role_tag_id_tag FOREIGN KEY (id_tag) REFERENCES t_tags(id_tag) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_applications_tag ADD CONSTRAINT fk_cor_applications_tag_t_applications_id_application FOREIGN KEY (id_application) REFERENCES utilisateurs.t_applications(id_application) ON UPDATE CASCADE;
ALTER TABLE ONLY cor_applications_tag ADD CONSTRAINT fk_cor_applications_tag_t_tags_id_tag FOREIGN KEY (id_tag) REFERENCES t_tags(id_tag) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_role_tag_application ADD CONSTRAINT fk_cor_role_tag_application_id_role FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY cor_role_tag_application ADD CONSTRAINT fk_cor_role_tag_application_id_tag FOREIGN KEY (id_tag) REFERENCES t_tags(id_tag) ON UPDATE CASCADE;
ALTER TABLE ONLY cor_role_tag_application ADD CONSTRAINT fk_cor_role_tag_application_id_application FOREIGN KEY (id_application) REFERENCES utilisateurs.t_applications(id_application) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_data_type_action_tag ADD CONSTRAINT fk_cor_data_type_action_tag_id_gn_data_types FOREIGN KEY (id_gn_data_type) REFERENCES bib_gn_data_types(id_gn_data_type) ON UPDATE CASCADE;
ALTER TABLE ONLY cor_data_type_action_tag ADD CONSTRAINT fk_cor_data_type_action_tag_id_gn_action FOREIGN KEY (id_gn_action) REFERENCES bib_gn_actions(id_gn_action) ON UPDATE CASCADE;
ALTER TABLE ONLY cor_data_type_action_tag ADD CONSTRAINT fk_cor_data_type_action_tag_id_tag FOREIGN KEY (id_tag) REFERENCES t_tags(id_tag) ON UPDATE CASCADE;


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
                    c_1.id_tag,
                    a_1.id_application,
                    c_1.comment
                FROM utilisateurs.t_roles u
                     JOIN gn_users.cor_role_tag_application c_1 ON c_1.id_role = u.id_role
                     JOIN ( SELECT a.id_application, a.id_parent
                            FROM utilisateurs.t_applications a
                            WHERE a.id_parent IS NOT NULL
                        ) a_1 ON a_1.id_parent = c_1.id_application
                WHERE NOT (u.id_role IN (SELECT DISTINCT id_role_groupe FROM utilisateurs.cor_roles))
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
                    c_1.id_tag,
                    c_1.id_application,
                    c_1.comment
                FROM utilisateurs.t_roles u
                     JOIN gn_users.cor_role_tag_application c_1 ON c_1.id_role = u.id_role
                WHERE NOT (u.id_role IN (SELECT DISTINCT id_role_groupe FROM utilisateurs.cor_roles))
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
                    c_1.id_tag,
                    a_1.id_application,
                    c_1.comment
                FROM utilisateurs.t_roles u
                     JOIN utilisateurs.cor_roles g ON g.id_role_utilisateur = u.id_role
                     JOIN gn_users.cor_role_tag_application c_1 ON c_1.id_role = g.id_role_groupe
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
                    c_1.id_tag,
                    c_1.id_application,
                    c_1.comment
                   FROM utilisateurs.t_roles u
                     JOIN utilisateurs.cor_roles g ON g.id_role_utilisateur = u.id_role
                     JOIN gn_users.cor_role_tag_application c_1 ON c_1.id_role = g.id_role_groupe
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
            a.id_tag,
            a.id_application,
            a.comment
           FROM ( SELECT a1.id_role,
                    a1.identifiant,
                    a1.nom_role,
                    a1.prenom_role,
                    a1.desc_role,
                    a1.pass,
                    a1.pass_sha,
                    a1.email,
                    a1.id_organisme,
                    a1.id_tag,
                    a1.id_application,
                    a1.comment
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
                    a2.id_tag,
                    a2.id_application,
                    a2.comment
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
    c.id_gn_action,
    bga.gn_action_code,
    max(c.id_gn_data_type) AS max_gn_data_type,
    c.comment
   FROM all_users_tags v
     JOIN gn_users.cor_data_type_action_tag c ON c.id_tag = v.id_tag
     JOIN gn_users.bib_gn_actions bga ON bga.id_gn_action = c.id_gn_action
  GROUP BY v.id_role, v.id_application, v.identifiant, v.nom_role, v.prenom_role, v.desc_role, v.pass, v.pass_sha, v.email, v.id_organisme, c.id_gn_action, bga.gn_action_code, c.comment;



-------------
--FUNCTIONS--
-------------
CREATE OR REPLACE FUNCTION can_user_do_in_module(
    myuser integer,
    myaction integer,
    mymodule integer)
  RETURNS boolean AS
$BODY$
-- the function say if the given user can do the requested action in the requested module
-- USAGE : SELECT gn_users.can_user_do_in_module(requested_userid,requested_actionid,requested_moduleid);
-- SAMPLE :SELECT gn_users.can_user_do_in_module(2,5,14);
  BEGIN
    IF myaction IN (SELECT id_gn_action FROM gn_users.v_usersaction_forall_gn_modules WHERE id_role = myuser AND id_application = mymodule) THEN
	    RETURN true;
    END IF;
    RETURN false;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

 CREATE OR REPLACE FUNCTION user_max_accessible_data_level_in_module(
    myuser integer,
    myaction integer,
    mymodule integer)
  RETURNS integer AS
$BODY$
DECLARE
	themaxleveldatatype integer;
-- the function return the max accessible extend of data the given user can access in the requested module
-- USAGE : SELECT gn_users.user_max_accessible_data_level_in_module(requested_userid,requested_actionid,requested_moduleid);
-- SAMPLE :SELECT gn_users.user_max_accessible_data_level_in_module(2,2,14);
  BEGIN
	SELECT max(max_gn_data_type) INTO themaxleveldatatype FROM gn_users.v_usersaction_forall_gn_modules WHERE id_role = myuser AND id_application = mymodule AND id_gn_action = myaction;
	RETURN themaxleveldatatype;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;


CREATE OR REPLACE FUNCTION find_all_modules_childs(myidapplication integer)
  RETURNS SETOF integer AS
$BODY$
 --Param : id_application d'un module ou d'une application quelque soit son rang
 --Retourne le id_application de tous les modules enfants sous forme d'un jeu de données utilisable comme une table
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
      SELECT a1.id_application FROM utilisateurs.t_applications a1 WHERE a1.id_parent = myidapplication
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