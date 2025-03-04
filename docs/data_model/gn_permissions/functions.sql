CREATE OR REPLACE FUNCTION gn_permissions.cruved_for_user_in_module(myuser integer, mymodulecode character varying)
 RETURNS json
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
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
        FROM gn_permissions.v_roles_permissions
        WHERE id_role = myuser AND module_code = mymodulecode AND code_filter_type = 'SCOPE'
        GROUP BY code_action) row;
    RETURN thecruved;
END;
$function$

CREATE OR REPLACE FUNCTION gn_permissions.does_user_have_scope_permission(myuser integer, mycodemodule character varying, myactioncode character varying, myscope integer)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
-- the function say if the given user can do the requested action in the requested module with its scope level
-- warning: NO heritage between parent and child module
-- USAGE : SELECT gn_persmissions.does_user_have_scope_permission(requested_userid,requested_actionid,requested_module_code,requested_scope);
-- SAMPLE : SELECT gn_permissions.does_user_have_scope_permission(2,'OCCTAX','R',3);
BEGIN
    IF myactioncode IN (
  SELECT code_action
    FROM gn_permissions.v_roles_permissions
    WHERE id_role = myuser AND module_code = mycodemodule AND code_action = myactioncode AND value_filter::int >= myscope AND code_filter_type = 'SCOPE') THEN
    RETURN true;
END
IF;
 RETURN false;
END;
$function$

CREATE OR REPLACE FUNCTION gn_permissions.get_id_object(mycodeobject character varying)
 RETURNS integer
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
RETURN (SELECT id_object
FROM gn_permissions.t_objects
WHERE code_object = mycodeobject);
END;
$function$

CREATE OR REPLACE FUNCTION gn_permissions.user_max_accessible_data_level_in_module(myuser integer, myactioncode character varying, mymodulecode character varying)
 RETURNS integer
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
DECLARE
 themaxscopelevel integer;
-- the function return the max accessible extend of data the given user can access in the requested module
-- warning: NO heritage between parent and child module
-- USAGE : SELECT gn_permissions.user_max_accessible_data_level_in_module(requested_userid,requested_actionid,requested_moduleid);
-- SAMPLE : SELECT gn_permissions.user_max_accessible_data_level_in_module(2,'U','GEONATURE');
BEGIN
    SELECT max(value_filter::int)
    INTO themaxscopelevel
    FROM gn_permissions.v_roles_permissions
    WHERE id_role = myuser AND module_code = mymodulecode AND code_action = myactioncode;
    RETURN themaxscopelevel;
END;
$function$

