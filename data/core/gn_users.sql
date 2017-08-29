DROP SCHEMA IF EXISTS gn_users CASCADE;

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;


CREATE SCHEMA IF NOT EXISTS gn_users;


SET search_path = gn_users, pg_catalog;


CREATE SEQUENCE t_roles_id_role_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE TABLE IF NOT EXISTS t_roles (
    id_role integer DEFAULT nextval('t_roles_id_role_seq'::regclass) NOT NULL,
    identifiant character varying(100),
    first_name character varying(50),
    last_name character varying(50),
    desc_role text,
    pass_md5 character varying(100),
    pass_sha character varying(255),
    email character varying(250),
    id_organism integer,
    comment text,
    meta_create_date timestamp without time zone,
    meta_update_date timestamp without time zone
);
ALTER SEQUENCE t_roles_id_role_seq OWNED BY t_roles.id_role;
ALTER TABLE ONLY t_roles ALTER COLUMN id_role SET DEFAULT nextval('t_roles_id_role_seq'::regclass);


CREATE SEQUENCE t_organisms_id_organism_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE TABLE IF NOT EXISTS t_organisms (
    id_organism integer DEFAULT nextval('t_organisms_id_organism_seq'::regclass) NOT NULL,
    organism_name character varying(100) NOT NULL,
    adresse character varying(128),
    organism_code character varying(5),
    city character varying(100),
    tel character varying(14),
    fax character varying(14),
    email character varying(100),
    id_parent integer,
    meta_create_date timestamp without time zone,
    meta_update_date timestamp without time zone
);
ALTER SEQUENCE t_organisms_id_organism_seq OWNED BY t_organisms.id_organism;
ALTER TABLE ONLY t_organisms ALTER COLUMN id_organism SET DEFAULT nextval('t_organisms_id_organism_seq'::regclass);


CREATE SEQUENCE t_applications_id_application_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE TABLE IF NOT EXISTS t_applications (
    id_application integer NOT NULL,
    nom_application character varying(50) NOT NULL,
    desc_application text,
    id_parent integer,
    meta_create_date timestamp without time zone,
    meta_update_date timestamp without time zone
);
ALTER SEQUENCE t_applications_id_application_seq OWNED BY t_applications.id_application;
ALTER TABLE ONLY t_applications ALTER COLUMN id_application SET DEFAULT nextval('t_applications_id_application_seq'::regclass);


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


CREATE TABLE IF NOT EXISTS cor_roles (
    id_role_groupe integer NOT NULL,
    id_role_utilisateur integer NOT NULL
);
COMMENT ON TABLE cor_roles IS 'Permet de constituer des groupes en affectant un ou des roles à un role existant';


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


CREATE TABLE IF NOT EXISTS bib_gn_privileges (
    id_gn_privilege integer NOT NULL,
    gn_privilege_name character varying(255),
    gn_privilege_desc text
);


CREATE TABLE IF NOT EXISTS cor_data_type_privilege_tag (
    id_gn_data_type integer NOT NULL,
    id_gn_privilege integer NOT NULL,
    id_tag integer NOT NULL,
    comment text
);
COMMENT ON TABLE cor_data_type_privilege_tag IS 'Cette table centrale, permet de gérer les droits d''usage des données en fonction du profil de l''utilisateur. Elle établi une correspondance entre l''affectation de tags génériques du schéma utilisateurs à un role pour une application avec les droits d''usage  (CREATE, READ, UPDATE, VALID, EXPORT, DELETE) et le type des données GeoNature (MY DATA, MY ORGANISM DATA, ALL DATA)';


----------------
--PRIMARY KEYS--
----------------
ALTER TABLE ONLY t_roles ADD CONSTRAINT pk_t_roles PRIMARY KEY (id_role);

ALTER TABLE ONLY t_organisms ADD CONSTRAINT pk_t_organisms PRIMARY KEY (id_organism);

ALTER TABLE ONLY t_applications ADD CONSTRAINT pk_t_applications PRIMARY KEY (id_application);

ALTER TABLE ONLY t_tags ADD CONSTRAINT pk_t_tags PRIMARY KEY (id_tag);

ALTER TABLE ONLY cor_tags_relations ADD CONSTRAINT pk_cor_tags_relations PRIMARY KEY (id_tag_l, id_tag_r);

ALTER TABLE ONLY cor_organism_tag ADD CONSTRAINT pk_cor_organism_tag PRIMARY KEY (id_organism, id_tag);

ALTER TABLE ONLY cor_role_tag ADD CONSTRAINT pk_cor_role_tag PRIMARY KEY (id_role, id_tag);

ALTER TABLE ONLY cor_applications_tag ADD CONSTRAINT pk_cor_applications_tag PRIMARY KEY (id_application, id_tag);

ALTER TABLE ONLY cor_roles ADD CONSTRAINT pk_cor_roles PRIMARY KEY (id_role_groupe, id_role_utilisateur);

ALTER TABLE ONLY cor_role_tag_application ADD CONSTRAINT pk_cor_role_tag_application PRIMARY KEY (id_role, id_tag, id_application);

ALTER TABLE ONLY bib_gn_data_types ADD CONSTRAINT pk_bib_gn_data_types PRIMARY KEY (id_gn_data_type);

ALTER TABLE ONLY bib_gn_privileges ADD CONSTRAINT pk_bib_gn_privileges PRIMARY KEY (id_gn_privilege);

ALTER TABLE ONLY cor_data_type_privilege_tag ADD CONSTRAINT pk_cor_data_type_privilege_tag PRIMARY KEY (id_gn_data_type, id_gn_privilege, id_tag);


------------
--TRIGGERS--
------------
CREATE TRIGGER tri_meta_dates_change_t_roles
  BEFORE INSERT OR UPDATE
  ON t_roles
  FOR EACH ROW
  EXECUTE PROCEDURE public.fct_trg_meta_dates_change();

  CREATE TRIGGER tri_meta_dates_change_t_organisms
  BEFORE INSERT OR UPDATE
  ON t_organisms
  FOR EACH ROW
  EXECUTE PROCEDURE public.fct_trg_meta_dates_change();

  CREATE TRIGGER tri_meta_dates_change_t_applications
  BEFORE INSERT OR UPDATE
  ON t_applications
  FOR EACH ROW
  EXECUTE PROCEDURE public.fct_trg_meta_dates_change();

  CREATE TRIGGER tri_meta_dates_change_t_tags
  BEFORE INSERT OR UPDATE
  ON t_tags
  FOR EACH ROW
  EXECUTE PROCEDURE public.fct_trg_meta_dates_change();

----------------
--FOREIGN KEYS--
----------------
ALTER TABLE ONLY t_roles ADD CONSTRAINT fk_t_roles_t_organisms_id_organism FOREIGN KEY (id_organism) REFERENCES t_organisms(id_organism) ON UPDATE CASCADE;

ALTER TABLE ONLY t_organisms ADD CONSTRAINT fk_t_organisms_id_parent FOREIGN KEY (id_parent) REFERENCES t_organisms(id_organism) ON UPDATE CASCADE;

ALTER TABLE ONLY t_applications ADD CONSTRAINT fk_t_applications_id_parent FOREIGN KEY (id_parent) REFERENCES t_applications(id_application) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_tags_relations ADD CONSTRAINT fk_cor_tags_relations_id_tag_l FOREIGN KEY (id_tag_l) REFERENCES t_tags(id_tag) ON UPDATE CASCADE;
ALTER TABLE ONLY cor_tags_relations ADD CONSTRAINT fk_cor_tags_relations_id_tag_r FOREIGN KEY (id_tag_r) REFERENCES t_tags(id_tag) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_organism_tag ADD CONSTRAINT fk_cor_organism_tag_id_organism FOREIGN KEY (id_organism) REFERENCES t_organisms(id_organism) ON UPDATE CASCADE;
ALTER TABLE ONLY cor_organism_tag ADD CONSTRAINT fk_cor_organism_tag_id_tag FOREIGN KEY (id_tag) REFERENCES t_tags(id_tag) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_role_tag ADD CONSTRAINT fk_cor_role_tag_id_role FOREIGN KEY (id_role) REFERENCES t_roles(id_role) ON UPDATE CASCADE;
ALTER TABLE ONLY cor_role_tag ADD CONSTRAINT fk_cor_role_tag_id_tag FOREIGN KEY (id_tag) REFERENCES t_tags(id_tag) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_applications_tag ADD CONSTRAINT fk_cor_applications_tag_t_applications_id_application FOREIGN KEY (id_application) REFERENCES t_applications(id_application) ON UPDATE CASCADE;
ALTER TABLE ONLY cor_applications_tag ADD CONSTRAINT fk_cor_applications_tag_t_tags_id_tag FOREIGN KEY (id_tag) REFERENCES t_tags(id_tag) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_roles ADD CONSTRAINT fk_cor_roles_id_role_groupe FOREIGN KEY (id_role_groupe) REFERENCES t_roles(id_role) ON UPDATE CASCADE;
ALTER TABLE ONLY cor_roles ADD CONSTRAINT fk_cor_roles_id_role_utilisateur FOREIGN KEY (id_role_utilisateur) REFERENCES t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_role_tag_application ADD CONSTRAINT fk_cor_role_tag_application_id_role FOREIGN KEY (id_role) REFERENCES t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY cor_role_tag_application ADD CONSTRAINT fk_cor_role_tag_application_id_tag FOREIGN KEY (id_tag) REFERENCES t_tags(id_tag) ON UPDATE CASCADE;
ALTER TABLE ONLY cor_role_tag_application ADD CONSTRAINT fk_cor_role_tag_application_id_application FOREIGN KEY (id_application) REFERENCES t_applications(id_application) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_data_type_privilege_tag ADD CONSTRAINT fk_cor_data_type_privilege_tag_id_gn_data_types FOREIGN KEY (id_gn_data_type) REFERENCES bib_gn_data_types(id_gn_data_type) ON UPDATE CASCADE;
ALTER TABLE ONLY cor_data_type_privilege_tag ADD CONSTRAINT fk_cor_data_type_privilege_tag_id_gn_privilege FOREIGN KEY (id_gn_privilege) REFERENCES bib_gn_privileges(id_gn_privilege) ON UPDATE CASCADE;
ALTER TABLE ONLY cor_data_type_privilege_tag ADD CONSTRAINT fk_cor_data_type_privilege_tag_id_tag FOREIGN KEY (id_tag) REFERENCES t_tags(id_tag) ON UPDATE CASCADE;


---------
--VIEWS--
---------
CREATE OR REPLACE VIEW gn_users.v_usersprivilege_forall_gn_modules AS 
 WITH all_users_tags AS (SELECT 
    a.id_role,
    a.identifiant,
    a.last_name,
    a.first_name,
    a.desc_role,
    a.pass_md5,
    a.pass_sha,
    a.email,
    a.id_organism,
    a.id_tag,
    a.id_application,
    a.comment
   FROM ( SELECT
            u.id_role,
	    u.identifiant,
            u.last_name,
            u.first_name,
            u.desc_role,
            u.pass_md5,
            u.pass_sha,
            u.email,
            u.id_organism,
            c.id_tag,
            c.id_application,
            c.comment
           FROM gn_users.t_roles u
             JOIN gn_users.cor_role_tag_application c ON c.id_role = u.id_role
          WHERE u.id_role NOT IN (select DISTINCT id_role_groupe FROM gn_users.cor_roles)
        UNION
         SELECT 
            u.id_role,
	    u.identifiant,
            u.last_name,
            u.first_name,
            u.desc_role,
            u.pass_md5,
            u.pass_sha,
            u.email,
            u.id_organism,
            c.id_tag,
            c.id_application,
            c.comment
           FROM gn_users.t_roles u
             JOIN gn_users.cor_roles g ON g.id_role_utilisateur = u.id_role
             JOIN gn_users.cor_role_tag_application c ON c.id_role = g.id_role_groupe
          WHERE g.id_role_groupe IN (select DISTINCT id_role_groupe FROM gn_users.cor_roles)
          ) a
)
SELECT 
	v.id_role,
	v.identifiant,
        v.last_name,
        v.first_name,
        v.desc_role,
        v.pass_md5,
        v.pass_sha,
        v.email,
        v.id_organism, 
	v.id_application,
	c.id_gn_privilege,
	max(c.id_gn_data_type) AS max_gn_data_type,
	c.comment
FROM all_users_tags v
JOIN gn_users.cor_data_type_privilege_tag c ON c.id_tag = v.id_tag
GROUP BY v.id_role, 
	v.id_application, 
	v.identifiant,
        v.last_name,
        v.first_name,
        v.desc_role,
        v.pass_md5,
        v.pass_sha,
        v.email,
        v.id_organism,
        c.id_gn_privilege, 
        c.comment;


-------------
--FUNCTIONS--
-------------
CREATE OR REPLACE FUNCTION can_user_do_in_module(
    myuser integer,
    myprivilege integer,
    mymodule integer)
  RETURNS boolean AS
$BODY$
-- the function say if the given user can do the requested action in the requested module
-- USAGE : SELECT gn_users.can_user_do_in_module(requested_userid,requested_privilegeid,requested_moduleid);
-- SAMPLE :SELECT gn_users.can_user_do_in_module(2,5,14);
  BEGIN
    IF myprivilege IN (
	SELECT id_gn_privilege FROM gn_users.v_usersprivilege_forall_gn_modules WHERE id_role = myuser AND id_application = mymodule) 
	THEN
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
	SELECT max(max_gn_data_type) INTO themaxleveldatatype FROM gn_users.v_usersprivilege_forall_gn_modules WHERE id_role = myuser AND id_application = mymodule AND id_gn_privilege = myaction; 
	RETURN themaxleveldatatype;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

--------
--DATA--
--------
DO
$$
BEGIN
INSERT INTO bib_gn_data_types (id_gn_data_type, gn_data_type_name, gn_data_type_desc) VALUES 
(1,'my data','user data')
,(2,'my organization data', 'data that''s owned by the user''s organization')
,(3,'all data', 'All the data that is contained in this GeoNaute instance')
;
EXCEPTION WHEN unique_violation  THEN
        RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;


DO
$$
BEGIN
INSERT INTO bib_gn_privileges (id_gn_privilege, gn_privilege_name, gn_privilege_desc) VALUES 
(1,'create','can create/add new data')
,(2,'read', 'can read data')
,(3,'update', 'can edit data')
,(4,'validate', 'can validate data')
,(5,'export', 'can export data')
,(6,'delete', 'can delete data')
;
EXCEPTION WHEN unique_violation  THEN
        RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;


DO
$$
BEGIN
INSERT INTO t_organisms (id_organism, organism_name, adresse, organism_code, city, tel, fax, email, id_parent) VALUES 
(1,'PNF', NULL, NULL, 'Montpellier', NULL, NULL, NULL,NULL)
,(2,'Parc National des Ecrins', 'Domaine de Charance', '05000', 'GAP', '04 92 40 20 10', NULL, NULL, NULL)
,(99,'Autre', NULL, NULL, NULL, NULL, NULL, NULL, NULL)
;
PERFORM pg_catalog.setval('t_organisms_id_organism_seq', 99, true);
EXCEPTION WHEN unique_violation  THEN
        RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;


DO
$$
BEGIN
INSERT INTO t_roles (id_role, identifiant, last_name, first_name, desc_role, pass_md5, pass_sha, email, id_organism, comment) VALUES 
(20001, NULL, 'grp_bureau_etude', NULL, 'Bureau d''étude', NULL, NULL, NULL, 99, 'groupe test à modifier ou supprimer')
,(20002, NULL, 'grp_en_poste', NULL, 'Tous les agents en poste', NULL, NULL, NULL, 99, 'groupe test à modifier ou supprimer')
,(1, 'admin', 'Administrateur', 'test', NULL, '21232f297a57a5a743894a0e4a801fc3', NULL, NULL, 99, 'utilisateur test à modifier')
,(2, 'agent', 'Agent', 'test', NULL, 'b33aed8f3134996703dc39f9a7c95783', NULL, NULL, 99,'utilisateur test à modifier ou supprimer')
,(3, 'partenaire', 'Partenaire', 'test', NULL, '5bd40a8524882d75f3083903f2c912fc', NULL, NULL, 99,'utilisateur test à modifier ou supprimer')
,(4, 'pierre.paul', 'Paul', 'Pierre', NULL, '21232f297a57a5a743894a0e4a801fc3', NULL, NULL, 99,'utilisateur test à modifier ou supprimer')
,(5, 'validateur', 'validateur', 'test', NULL, '21232f297a57a5a743894a0e4a801fc3', NULL, NULL, 99,'utilisateur test à modifier ou supprimer')
;
PERFORM pg_catalog.setval('t_roles_id_role_seq', 20002, true);
EXCEPTION WHEN unique_violation  THEN
        RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;


DO
$$
BEGIN
INSERT INTO cor_roles (id_role_groupe, id_role_utilisateur) VALUES 
(20002, 1)
,(20002, 2)
,(20002, 5)
,(20001, 4)
;
EXCEPTION WHEN unique_violation  THEN
        RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;


DO
$$
BEGIN
INSERT INTO t_applications (id_application, nom_application, desc_application, id_parent) VALUES 
(1, 'UsersHub', 'application permettant d''administrer le contenu du schéma utilisateurs de usershub.', NULL)
,(2, 'TaxHub', 'application permettant d''administrer la liste des taxons.', NULL)
,(14, 'application geonature', 'Application permettant la consultation et la gestion des relevés faune et flore.', NULL)
,(15, 'contact (GeoNature)', 'Module contact faune-flore-fonge de GeoNature', 14);
PERFORM pg_catalog.setval('t_applications_id_application_seq', 15, true);
EXCEPTION WHEN unique_violation  THEN
        RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;


DO
$$
BEGIN
INSERT INTO t_tags (id_tag, tag_name, tag_desc) VALUES 
(1, 'utilisateur', 'Ne peut que consulter')
,(2, 'rédacteur', 'Il possède des droit d''écriture pour créer des enregistrements')
,(3, 'référent', 'utilisateur ayant des droits complémentaires au rédacteur (par exemple exporter des données ou autre)')
,(4, 'modérateur', 'Peu utilisé')
,(5, 'validateur', 'Il valide bien sur')
,(6, 'administrateur', 'Il a tous les droits')
,(10,'CREATE new data', 'This user can create/add new data')
,(11,'READ my data', 'This user can read only his own data')
,(12,'READ my organism data', 'This user can read only the data of his organization')
,(13,'READ all data', 'This user can read all data')
,(14,'UPDATE my data', 'This user can edit only his own data')
,(15,'UPDATE my organism data', 'This user can edit only the data of his organization')
,(16,'UPDATE all data', 'This user can edit all data')
,(17,'VALID my data', 'This user can validate only his own data')
,(18,'VALID my organism data', 'This user can validate only the data of his organization')
,(19,'VALID all data', 'This user can validate all data')
,(20,'EXPORT my data', 'This user can export only his own data')
,(21,'EXPORT my organism data', 'This user can export only the data of his organization')
,(22,'EXPORT all data', 'This user can export all data')
,(23,'DELETE my data', 'This user can delete only his own data')
,(24,'DELETE my organism data', 'This user can delete only the data of his organization')
,(25,'DELETE all data', 'This user can delete all data')

,(100,'observateurs flore', 'liste des observateurs pour les protocoles flore')
,(101,'observateurs faune', 'liste des observateurs pour les protocoles faune')
,(102,'observateurs aigle', 'liste des observateurs pour le protocole suivi de la reproduction de l''aigle royal')

,(1000,'Geonature', 'Etiquette définissant l''appartenance au domaine "GeoNature"')
,(1001,'Privileges', 'Etiquette définissant un type "privilèges"')
,(1002,'Data types', 'Etiquette définissant un type "data_type". Plus précisément, l''étendue des données GeoNature accessibles (my data, my organism data, all data)')
,(1003,'listes', 'Etiquette définissant un type "listes"')

;
PERFORM pg_catalog.setval('t_tags_id_tag_seq', 10003, true);
EXCEPTION WHEN unique_violation  THEN
        RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;


DO
$$
BEGIN 
INSERT INTO cor_role_tag_application (id_role, id_tag, id_application) VALUES 
--administrateur sur UsersHub et TaxHub
(1, 6, 1)
,(1, 6, 2)
--administrateur sur GeoNature
,(1, 6, 14)
,(1, 10, 14)
,(1, 13, 14)
,(1, 16, 14)
,(1, 19, 14)
,(1, 22, 14)
,(1, 25, 14)
--validateur sur contact
,(5, 5, 15)
,(5, 19, 15)
--groupe en poste
,(20002, 10, 14)
,(20002, 13, 14)
,(20002, 14, 14)
,(20002, 21, 14)
,(20002, 23, 14)
--groupe bureau d''étude
,(20001, 10, 14)
,(20001, 11, 14)
,(20001, 14, 14)
,(20001, 17, 14)
,(20001, 20, 14)
,(20001, 23, 14)
--liste des observateurs faune
,(20002, 101, 15)
,(3, 101, 15)
--liste des observateurs flore
,(2, 100, 15)
,(5, 100, 15)
;
EXCEPTION WHEN unique_violation  THEN
        RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;


DO
$$
BEGIN 
INSERT INTO gn_users.cor_data_type_privilege_tag (id_gn_data_type, id_gn_privilege, id_tag, comment) VALUES
(3,6,25,'This user can delete all data')
,(2,6,24,'This user can delete only the data of his organization')
,(1,6,23,'This user can delete only his own data')
,(3,5,22,'This user can export all data')
,(2,5,21,'This user can export only the data of his organization')
,(1,5,20,'This user can export only his own data')
,(3,4,19,'This user can validate all data')
,(2,4,18,'This user can validate only the data of his organization')
,(1,4,17,'This user can validate only his own data')
,(3,3,16,'This user can edit all data')
,(2,3,15,'This user can edit only the data of his organization')
,(1,3,14,'This user can edit only his own data')
,(3,2,13,'This user can read all data')
,(2,2,12,'This user can read only the data of his organization')
,(1,2,11,'This user can read only his own data')
,(3,1,10,'This user can create/add new data')
,(2,1,10,'This user can create/add new data')
,(1,1,10,'This user can create/add new data')
;
EXCEPTION WHEN unique_violation  THEN
        RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;


DO
$$
BEGIN 
INSERT INTO cor_tags_relations (id_tag_l, id_tag_r, relation_type) VALUES 
(100, 1003, 'est de type')
, (101, 1003, 'est de type')
, (102, 1003, 'est de type')
, (1, 1001, 'est de type')
, (2, 1001, 'est de type')
, (3, 1001, 'est de type')
, (4, 1001, 'est de type')
, (5, 1001, 'est de type')
, (6, 1001, 'est de type')
, (10, 1001, 'est de type')
, (11, 1001, 'est de type')
, (12, 1001, 'est de type')
, (13, 1001, 'est de type')
, (14, 1001, 'est de type')
, (15, 1001, 'est de type')
, (16, 1001, 'est de type')
, (17, 1001, 'est de type')
, (18, 1001, 'est de type')
, (19, 1001, 'est de type')
, (20, 1001, 'est de type')
, (21, 1001, 'est de type')
, (22, 1001, 'est de type')
, (23, 1001, 'est de type')
, (24, 1001, 'est de type')
, (25, 1001, 'est de type')
, (11, 1002, 'est de type')
, (12, 1002, 'est de type')
, (13, 1002, 'est de type')
, (14, 1002, 'est de type')
, (15, 1002, 'est de type')
, (16, 1002, 'est de type')
, (17, 1002, 'est de type')
, (18, 1002, 'est de type')
, (19, 1002, 'est de type')
, (20, 1002, 'est de type')
, (21, 1002, 'est de type')
, (22, 1002, 'est de type')
, (23, 1002, 'est de type')
, (24, 1002, 'est de type')
, (25, 1002, 'est de type')
;
EXCEPTION WHEN unique_violation  THEN
        RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;
