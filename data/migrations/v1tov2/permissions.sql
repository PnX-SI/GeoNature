WITH 
id_app_geonature AS (
    SELECT id_application
    FROM utilisateurs.t_application 
    WHERE code_application = 'GN'
)

droit_2 AS (
    SELECT id_role
    FROM utilisateurs.cor_role_droit_application
    WHERE id_application = id_app_geonature.id_application AND id_droit = 2
) droit_1 AS (
    SELECT id_role
    FROM utilisateurs.cor_role_droit_application
    WHERE id_application = id_app_geonature.id_application AND id_droit = 1
),
-- droit 6 = cellule SI + chargé de missions (ID à adapter au contexte)
droit_6 AS (
    SELECT id_role
    FROM utilisateurs.cor_role_droit_application
    WHERE id_application = id_app_geonature.id_application AND id_droit = 6
)
mod_admin AS (
    SELECT id_module
    FROM gn_commons.t_module
    WHERE module_code = 'ADMIN'
),
mod_metadata AS (
    SELECT id_module
    FROM gn_commons.t_module
    WHERE module_code = 'METADATA'
)

INSERT INTO gn_permission.cor_role_action_filter_module_object
    (
    id_role,
    id_action,
    id_filter,
    id_module,
    id_object
    )
VALUES
    -- droit 6 pour tout GeoNature
    (droit_6.id_role, 1, 4, 0, 1),
    (droit_6.id_role, 2, 4, 0, 1),
    (droit_6.id_role, 3, 4, 0, 1),
    (droit_6.id_role, 4, 4, 0, 1),
    (droit_6.id_role, 5, 3, 0, 1),
    (droit_6.id_role, 6, 4, 0, 1),
    -- droit 6 acces à l'admin
    (droit_6.id_role, 1, 4, 1, 0),
    (droit_6.id_role, 2, 4, 1, 0),
    (droit_6.id_role, 3, 4, 1, 0),
    (droit_6.id_role, 4, 4, 1, 0),
    (droit_6.id_role, 5, 4, 1, 0),
    (droit_6.id_role, 6, 4, 1, 0),
    -- droit 6 peut acceder aux permissions
    (droit_6.id_role, 1, 4, 1, 2),
    (droit_6.id_role, 2, 4, 1, 2),
    (droit_6.id_role, 3, 4, 1, 2),
    (droit_6.id_role, 4, 4, 1, 2),
    (droit_6.id_role, 5, 4, 1, 2),
    (droit_6.id_role, 6, 4, 1, 2),
    -- droit 6 peut gérer les nomenclatures depuis le backoffice
    (droit_6.id_role, 1, 4, 1, 3),
    (droit_6.id_role, 2, 4, 1, 3),
    (droit_6.id_role, 3, 4, 1, 3),
    (droit_6.id_role, 4, 4, 1, 3),
    (droit_6.id_role, 5, 4, 1, 3),
    (droit_6.id_role, 6, 4, 1, 3)
   -- droit 2 pour tout GeoNature
    (droit_2.id_role, 1, 4, 0, 1),
    (droit_2.id_role, 2, 4, 0, 1),
    (droit_2.id_role, 3, 2, 0, 1),
    (droit_2.id_role, 4, 2, 0, 1),
    (droit_2.id_role, 5, 3, 0, 1),
    (droit_2.id_role, 6, 2, 0, 1),
  -- droit 2 pas accès à METADATA
    (droit_2.id_role, 1, 0, mod_metadata.id_module, 1),
    (droit_2.id_role, 2, 0, mod_metadata.id_module, 1),
    (droit_2.id_role, 3, 0, mod_metadata.id_module, 1),
    (droit_2.id_role, 4, 0, mod_metadata.id_module, 1),
    (droit_2.id_role, 5, 0, mod_metadata.id_module, 1),
    (droit_2.id_role, 6, 0, mod_metadata.id_module, 1),
-- equivalent droit 2 pas accès ADMIN
    (droit_2.id_role, 1, 0, mod_admin.id_module, 1),
    (droit_2.id_role, 2, 0, mod_admin.id_module, 1),
    (droit_2.id_role, 3, 0, mod_admin.id_module, 1),
    (droit_2.id_role, 4, 0, mod_admin.id_module, 1),
    (droit_2.id_role, 5, 0, mod_admin.id_module, 1),
    (droit_2.id_role, 6, 0, mod_admin.id_module, 1),
   -- groupe retraite GeoNature
    (droit_1.id_role, 1, 4, 0, 1),
    (droit_1.id_role, 2, 4, 0, 1),
    (droit_1.id_role, 3, 2, 0, 1),
    (droit_1.id_role, 4, 2, 0, 1),
    (droit_1.id_role, 5, 2, 0, 1),
    (droit_1.id_role, 6, 2, 0, 1),
  -- droit 1 pas accès à METADATA
    (droit_1.id_role, 1, 0, mod_metadata.id_module, 1),
    (droit_1.id_role, 2, 0, mod_metadata.id_module, 1),
    (droit_1.id_role, 3, 0, mod_metadata.id_module, 1),
    (droit_1.id_role, 4, 0, mod_metadata.id_module, 1),
    (droit_1.id_role, 5, 0, mod_metadata.id_module, 1),
    (droit_1.id_role, 6, 0, mod_metadata.id_module, 1),
-- droit 1 pas accès ADMIN
    (droit_1.id_role, 1, 0, mod_admin.id_module, 1),
    (droit_1.id_role, 2, 0, mod_admin.id_module, 1),
    (droit_1.id_role, 3, 0, mod_admin.id_module, 1),
    (droit_1.id_role, 4, 0, mod_admin.id_module, 1),
    (droit_1.id_role, 5, 0, mod_admin.id_module, 1),
    (droit_1.id_role, 6, 0, mod_admin.id_module, 1),



