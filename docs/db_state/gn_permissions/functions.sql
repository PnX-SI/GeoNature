CREATE FUNCTION gn_permissions.cruved_for_user_in_module(myuser integer, mymodulecode character varying) RETURNS json
    LANGUAGE plpgsql IMMUTABLE
    AS $$
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
$$;
CREATE FUNCTION gn_permissions.does_user_have_scope_permission(myuser integer, mycodemodule character varying, myactioncode character varying, myscope integer) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
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
$$;
CREATE FUNCTION gn_permissions.get_id_object(mycodeobject character varying) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
RETURN (SELECT id_object
FROM gn_permissions.t_objects
WHERE code_object = mycodeobject);
END;
$$;
CREATE FUNCTION gn_permissions.user_max_accessible_data_level_in_module(myuser integer, myactioncode character varying, mymodulecode character varying) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
 themaxscopelevel integer;
BEGIN
    SELECT max(value_filter::int)
    INTO themaxscopelevel
    FROM gn_permissions.v_roles_permissions
    WHERE id_role = myuser AND module_code = mymodulecode AND code_action = myactioncode;
    RETURN themaxscopelevel;
END;
$$;
