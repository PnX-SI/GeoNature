CREATE FUNCTION utilisateurs.check_is_default_group_for_app_is_grp_and_unique(id_app integer, id_grp integer, is_default boolean) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
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
$$;
CREATE FUNCTION utilisateurs.fct_trg_meta_dates_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
        if(TG_OP = 'INSERT') THEN
                NEW.meta_create_date = NOW();
        ELSIF(TG_OP = 'UPDATE') THEN
                NEW.meta_update_date = NOW();
                if(NEW.meta_create_date IS NULL) THEN
                        NEW.meta_create_date = NOW();
                END IF;
        end IF;
        return NEW;
end;
$$;
CREATE FUNCTION utilisateurs.get_id_role_by_name(rolename character varying) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE
    AS $$
        BEGIN
            RETURN (
                SELECT id_role
                FROM utilisateurs.t_roles
                WHERE nom_role = roleName
            );
        END;
    $$;

ALTER FUNCTION utilisateurs.get_id_role_by_name(rolename character varying) OWNER TO geonatadmin;

CREATE FUNCTION utilisateurs.modify_date_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.date_insert := now();
    NEW.date_update := now();
    RETURN NEW;
END;
$$;
CREATE FUNCTION utilisateurs.modify_date_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.date_update := now();
    RETURN NEW;
END;
$$;
