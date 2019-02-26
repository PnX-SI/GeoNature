SET statement_timeout
= 0;
SET lock_timeout
= 0;
SET client_encoding
= 'UTF8';
SET standard_conforming_strings
= on;
SET check_function_bodies
= false;
SET client_min_messages
= warning;

--DROP SCHEMA gn_permissions CASCADE;
CREATE SCHEMA gn_permissions;

SET search_path
= gn_permissions, pg_catalog;
SET default_with_oids
= false;

-------------
--FUNCTIONS--
-------------

CREATE OR REPLACE FUNCTION does_user_have_scope_permission
(
 myuser integer,
 mycodemodule character varying,
 myactioncode character varying,
 myscope integer
)
 RETURNS boolean AS
$BODY$
-- the function say if the given user can do the requested action in the requested module with its scope level
-- warning: NO heritage between parent and child module
-- USAGE : SELECT gn_persmissions.does_user_have_scope_permission(requested_userid,requested_actionid,requested_module_code,requested_scope);
-- SAMPLE : SELECT gn_permissions.does_user_have_scope_permission(2,'OCCTAX','R',3);
BEGIN
    IF myactioncode IN (
  SELECT code_action
    FROM gn_permissions.v_users_permissions
    WHERE id_role = myuser AND module_code = mycodemodule AND code_action = myactioncode AND value_filter::int >= myscope AND code_filter_type = 'SCOPE') THEN
    RETURN true;
END
IF;
 RETURN false;
END;
$BODY$
 LANGUAGE plpgsql IMMUTABLE
 COST 100;


CREATE OR REPLACE FUNCTION user_max_accessible_data_level_in_module
(
 myuser integer,
 myactioncode character varying,
 mymodulecode character varying)
 RETURNS integer AS
$BODY$
DECLARE
 themaxscopelevel integer;
-- the function return the max accessible extend of data the given user can access in the requested module
-- warning: NO heritage between parent and child module
-- USAGE : SELECT gn_permissions.user_max_accessible_data_level_in_module(requested_userid,requested_actionid,requested_moduleid);
-- SAMPLE :SELECT gn_permissions.user_max_accessible_data_level_in_module(2,'U','GEONATURE');
BEGIN
    SELECT max(value_filter::int)
    INTO themaxscopelevel
    FROM gn_permissions.v_users_permissions
    WHERE id_role = myuser AND module_code = mymodulecode AND code_action = myactioncode;
    RETURN themaxscopelevel;
END;
$BODY$
 LANGUAGE plpgsql IMMUTABLE
 COST 100;

CREATE OR REPLACE FUNCTION cruved_for_user_in_module
(
 myuser integer,
 mymodulecode character varying
)
 RETURNS json AS
$BODY$
-- the function return user's CRUVED in the requested module
-- warning: the function not return the parent CRUVED but only the module cruved - no heritage
-- USAGE : SELECT utilisateurs.cruved_for_user_in_module(requested_userid,requested_moduleid);
-- SAMPLE : SELECT utilisateurs.cruved_for_user_in_module(2,3);
DECLARE
 thecruved json;
BEGIN
    SELECT array_to_json(array_agg(row))
    INTO thecruved
    FROM (
  SELECT code_action AS action, max(value_filter::int) AS level
        FROM gn_permissions.v_users_permissions
        WHERE id_role = myuser AND module_code = mymodulecode AND code_filter_type = 'SCOPE'
        GROUP BY code_action) row;
    RETURN thecruved;
END;
$BODY$
 LANGUAGE plpgsql IMMUTABLE
 COST 100;


CREATE OR REPLACE FUNCTION gn_permissions.get_id_object (mycodeobject character varying)
  RETURNS int AS
$BODY$
BEGIN
RETURN (SELECT id_object
FROM gn_permissions.t_objects
WHERE code_object = mycodeobject);
END;
$BODY$
 LANGUAGE plpgsql IMMUTABLE
 COST 100;

CREATE OR REPLACE FUNCTION gn_permissions.fct_tri_does_user_have_already_scope_filter()
  RETURNS trigger AS
$BODY$
-- Check if a role has already a SCOPE permission for an action/module/object
-- use in constraint to force not set multiple scope permission on the same action/module/object
DECLARE 
the_code_filter_type character varying;
the_nb_permission integer;
BEGIN
 SELECT INTO the_code_filter_type bib.code_filter_type
 FROM gn_permissions.t_filters f
 JOIN gn_permissions.bib_filters_type bib ON bib.id_filter_type = f.id_filter_type
 WHERE f.id_filter = NEW.id_filter
;
-- if the filter type is NOT SCOPE, its OK to set multiple permissions
IF the_code_filter_type != 'SCOPE' THEN 
RETURN NEW;
-- if the new filter is 'SCOPE TYPE', check if there is not already a permission for this
-- action/module/object/role
ELSE
    SELECT INTO the_nb_permission count(perm.id_permission)
    FROM gn_permissions.cor_role_action_filter_module_object perm
    JOIN gn_permissions.t_filters f ON f.id_filter = perm.id_filter
    JOIN gn_permissions.bib_filters_type bib ON bib.id_filter_type = f.id_filter_type AND bib.code_filter_type = 'SCOPE' 
    WHERE id_role=NEW.id_role AND id_action=NEW.id_action AND id_module=NEW.id_module AND id_object=NEW.id_object;

 -- if its an insert 0 row must be present, if its an update 1 row must be present
  IF(TG_OP = 'INSERT' AND the_nb_permission = 0) OR (TG_OP = 'UPDATE' AND the_nb_permission = 1) THEN
        RETURN NEW;
    END IF;
    BEGIN
        RAISE EXCEPTION 'ATTENTION: il existe déjà un enregistrement de type SCOPE pour le role % l''action % sur le module % et l''objet % . Il est interdit de définir plusieurs portées à un role pour le même action sur un module et un objet', NEW.id_role, NEW.id_action, NEW.id_module, NEW.id_object ;
    END;
  

END IF;

END;

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;



---------
--TABLE--
---------

CREATE TABLE t_actions
(
    id_action serial NOT NULL,
    code_action character varying(50) NOT NULL,
    description_action text
);

CREATE TABLE bib_filters_type
(
    id_filter_type serial NOT NULL,
    code_filter_type character varying(50) NOT NULL,
    label_filter_type character varying(255) NOT NULL,
    description_filter_type text
);

CREATE TABLE t_filters
(
    id_filter serial NOT NULL,
    label_filter character varying(255) NOT NULL,
    value_filter text NOT NULL,
    description_filter text,
    id_filter_type integer NOT NULL
);

CREATE TABLE t_objects
(
    id_object serial NOT NULL,
    code_object character varying(50) NOT NULL,
    description_object text
);

-- un objet peut être utilisé dans plusieurs modules
-- ex: TDataset en lecture dans occtax, admin ...
CREATE TABLE cor_object_module
(
    id_cor_object_module serial NOT NULL,
    id_object integer NOT NULL,
    id_module integer NOT NULL
);

CREATE TABLE cor_role_action_filter_module_object
(
    id_permission serial NOT NULL,
    id_role integer NOT NULL,
    id_action integer NOT NULL,
    id_filter integer NOT NULL,
    id_module integer NOT NULL,
    id_object integer NOT NULL DEFAULT gn_permissions.get_id_object('ALL')
);

CREATE TABLE cor_filter_type_module
(
    id_filter_type integer NOT NULL,
    id_module integer NOT NULL
);


---------------
--PRIMARY KEY--
---------------

ALTER TABLE ONLY t_actions
ADD CONSTRAINT pk_t_actions PRIMARY KEY
(id_action);

ALTER TABLE ONLY t_filters
ADD CONSTRAINT pk_t_filters PRIMARY KEY
(id_filter);

ALTER TABLE ONLY bib_filters_type
ADD CONSTRAINT pk_bib_filters_type PRIMARY KEY
(id_filter_type);

ALTER TABLE ONLY t_objects
ADD CONSTRAINT pk_t_objects PRIMARY KEY
(id_object);

ALTER TABLE ONLY cor_object_module
ADD CONSTRAINT pk_cor_object_module PRIMARY KEY
(id_cor_object_module);

ALTER TABLE ONLY cor_role_action_filter_module_object
ADD CONSTRAINT pk_cor_r_a_f_m_o PRIMARY KEY
(id_permission);

ALTER TABLE ONLY cor_filter_type_module
ADD CONSTRAINT pk_cor_filter_module PRIMARY KEY
(id_filter_type, id_module);


---------------
--FOREIGN KEY--
---------------

ALTER TABLE ONLY t_filters
ADD CONSTRAINT  fk_t_filters_id_filter_type FOREIGN KEY
(id_filter_type) REFERENCES bib_filters_type
(id_filter_type) ON
UPDATE CASCADE;

ALTER TABLE ONLY cor_object_module
ADD CONSTRAINT  fk_cor_object_module_id_module FOREIGN KEY
(id_module) REFERENCES gn_commons.t_modules
(id_module) ON
UPDATE CASCADE ON
DELETE CASCADE;

ALTER TABLE ONLY cor_object_module
ADD CONSTRAINT  fk_cor_object_module_id_object FOREIGN KEY
(id_object) REFERENCES t_objects
(id_object) ON
UPDATE CASCADE ON
DELETE CASCADE;

ALTER TABLE ONLY cor_role_action_filter_module_object
ADD CONSTRAINT  fk_cor_r_a_f_m_o_id_role FOREIGN KEY
(id_role) REFERENCES utilisateurs.t_roles
(id_role) ON
UPDATE CASCADE ON
DELETE CASCADE;

ALTER TABLE ONLY cor_role_action_filter_module_object
ADD CONSTRAINT  fk_cor_r_a_f_m_o_id_action FOREIGN KEY
(id_action) REFERENCES t_actions
(id_action) ON
UPDATE CASCADE;

ALTER TABLE ONLY cor_role_action_filter_module_object
ADD CONSTRAINT  fk_cor_r_a_f_m_o_id_filter FOREIGN KEY
(id_filter) REFERENCES t_filters
(id_filter) ON
UPDATE CASCADE;

ALTER TABLE ONLY cor_role_action_filter_module_object
ADD CONSTRAINT  fk_cor_r_a_f_m_o_id_object FOREIGN KEY
(id_object) REFERENCES t_objects
(id_object) ON
UPDATE CASCADE;


ALTER TABLE ONLY cor_filter_type_module
ADD CONSTRAINT  fk_cor_filter_module_id_filter FOREIGN KEY
(id_filter_type) REFERENCES bib_filters_type
(id_filter_type) ON
UPDATE CASCADE;


ALTER TABLE ONLY cor_filter_type_module
ADD CONSTRAINT  fk_cor_filter_module_id_module FOREIGN KEY
(id_module) REFERENCES gn_commons.t_modules
(id_module) ON
UPDATE CASCADE;


-----------
-- VIEWS --
-----------

CREATE OR REPLACE VIEW gn_permissions.v_roles_permissions AS
WITH
    p_user_permission
    AS
    (
        SELECT u.id_role,
            u.nom_role,
            u.prenom_role,
            u.groupe,
            u.id_organisme,
            c_1.id_action,
            c_1.id_filter,
            c_1.id_module,
            c_1.id_object,
            c_1.id_permission
        FROM utilisateurs.t_roles u
            JOIN gn_permissions.cor_role_action_filter_module_object c_1 ON c_1.id_role = u.id_role
        WHERE u.groupe = false
    ),
    p_groupe_permission
    AS
    (
        SELECT u.id_role,
            u.nom_role,
            u.prenom_role,
            u.groupe,
            u.id_organisme,
            c_1.id_action,
            c_1.id_filter,
            c_1.id_module,
            c_1.id_object,
            c_1.id_permission
        FROM utilisateurs.t_roles u
            JOIN utilisateurs.cor_roles g ON g.id_role_utilisateur = u.id_role OR g.id_role_groupe = u.id_role
            JOIN gn_permissions.cor_role_action_filter_module_object c_1 ON c_1.id_role = g.id_role_groupe
        WHERE (g.id_role_groupe IN ( SELECT DISTINCT cor_roles.id_role_groupe
        FROM utilisateurs.cor_roles))
    ),
    all_user_permission
    AS
    (
                    SELECT p_user_permission.id_role,
                p_user_permission.nom_role,
                p_user_permission.prenom_role,
                p_user_permission.groupe,
                p_user_permission.id_organisme,
                p_user_permission.id_action,
                p_user_permission.id_filter,
                p_user_permission.id_module,
                p_user_permission.id_object,
                p_user_permission.id_permission
            FROM p_user_permission
        UNION
            SELECT p_groupe_permission.id_role,
                p_groupe_permission.nom_role,
                p_groupe_permission.prenom_role,
                p_groupe_permission.groupe,
                p_groupe_permission.id_organisme,
                p_groupe_permission.id_action,
                p_groupe_permission.id_filter,
                p_groupe_permission.id_module,
                p_groupe_permission.id_object,
                p_groupe_permission.id_permission
            FROM p_groupe_permission
    )
SELECT v.id_role,
    v.nom_role,
    v.prenom_role,
    v.id_organisme,
    v.id_module,
    modules.module_code,
    obj.code_object,
    v.id_action,
    v.id_filter,
    actions.code_action,
    actions.description_action,
    filters.value_filter,
    filters.label_filter,
    filter_type.code_filter_type,
    filter_type.id_filter_type,
    v.id_permission
FROM all_user_permission v
    JOIN gn_permissions.t_actions actions ON actions.id_action = v.id_action
    JOIN gn_permissions.t_filters filters ON filters.id_filter = v.id_filter
    JOIN gn_permissions.t_objects obj ON obj.id_object = v.id_object
    JOIN gn_permissions.bib_filters_type filter_type ON filters.id_filter_type = filter_type.id_filter_type
    JOIN gn_commons.t_modules modules ON modules.id_module = v.id_module;



---------------
-- TRIGGERS ---
---------------

DROP TRIGGER IF EXISTS tri_check_no_multiple_scope_perm ON gn_permissions.cor_role_action_filter_module_object;
CREATE TRIGGER tri_check_no_multiple_scope_perm
  BEFORE INSERT OR UPDATE
  ON gn_permissions.cor_role_action_filter_module_object
  FOR EACH ROW
  EXECUTE PROCEDURE gn_permissions.fct_tri_does_user_have_already_scope_filter();

