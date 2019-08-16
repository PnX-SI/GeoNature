CREATE TABLE temp_droit_6 AS (
    SELECT cor.id_role
    FROM v1_compat.cor_role_droit_application cor 
    JOIN v1_compat.t_applications app ON app.id_application = cor.id_application
    WHERE app.code_application = 'GN' AND id_droit = 6
);
CREATE TABLE temp_droit_2 AS (
    SELECT cor.id_role
    FROM v1_compat.cor_role_droit_application cor
    JOIN v1_compat.t_applications app ON app.id_application = cor.id_application
    WHERE app.code_application = 'GN' AND cor.id_droit = 2
);
CREATE TABLE temp_droit_1 AS (
    SELECT cor.id_role
    FROM v1_compat.cor_role_droit_application cor
    JOIN v1_compat.t_applications app ON app.id_application = cor.id_application
    WHERE app.code_application = 'GN' AND cor.id_droit = 1
);

DELETE FROM gn_permissions.cor_role_action_filter_module_object;


-- droit 6 pour tout GeoNature
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role , 1, 4, 0, 1 FROM temp_droit_6;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 2, 4, 0, 1 FROM temp_droit_6;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role,  3, 4, 0, 1 FROM temp_droit_6;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 4, 4, 0, 1 FROM temp_droit_6;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 5, 3, 0, 1 FROM temp_droit_6;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 6, 4, 0, 1 FROM temp_droit_6;
-- droit 6 acces à l'admin
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 1, 4, 1, 1 FROM temp_droit_6;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 2, 4, 1, 1 FROM temp_droit_6;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 3, 4, 1, 1 FROM temp_droit_6;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 4, 4, 1, 1 FROM temp_droit_6;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 5, 4, 1, 1 FROM temp_droit_6;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 6, 4, 1, 1 FROM temp_droit_6;
-- droit 6 peut acceder aux permissions
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 1, 4, 1, 2 FROM temp_droit_6;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 2, 4, 1, 2 FROM temp_droit_6;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 3, 4, 1, 2 FROM temp_droit_6;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 4, 4, 1, 2 FROM temp_droit_6;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 5, 4, 1, 2 FROM temp_droit_6;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 6, 4, 1, 2 FROM temp_droit_6;
-- droit 6 peut gérer les nomenclatures depuis le backoffice
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 1, 4, 1, 3 FROM temp_droit_6;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 2, 4, 1, 3 FROM temp_droit_6;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 3, 4, 1, 3 FROM temp_droit_6;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 4, 4, 1, 3 FROM temp_droit_6;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 5, 4, 1, 3 FROM temp_droit_6;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 6, 4, 1, 3 FROM temp_droit_6;
-- droit 2 pour tout GeoNature
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 1, 4, 0, 1 FROM temp_droit_2;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 2, 4, 0, 1 FROM temp_droit_2;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 3, 2, 0, 1 FROM temp_droit_2;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 4, 2, 0, 1 FROM temp_droit_2;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 5, 3, 0, 1 FROM temp_droit_2;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 6, 2, 0, 1 FROM temp_droit_2;
-- droit 2 pas accès à METADATA
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 1, 1, 2, 1 FROM temp_droit_2;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 2, 1, 2, 1 FROM temp_droit_2;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 3, 1, 2, 1 FROM temp_droit_2;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 4, 1, 2, 1 FROM temp_droit_2;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 5, 1, 2, 1 FROM temp_droit_2;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 6, 1, 2, 1 FROM temp_droit_2;
-- equivalent droit 2 pas accès ADMIN
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 1, 1, 1, 1 FROM temp_droit_2;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 2, 1, 1, 1 FROM temp_droit_2;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 3, 1, 1, 1 FROM temp_droit_2;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 4, 1, 1, 1 FROM temp_droit_2;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 5, 1, 1, 1 FROM temp_droit_2;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 6, 1, 1, 1 FROM temp_droit_2;
-- droit 1 GeoNature
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 1, 4, 0, 1 FROM temp_droit_1;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 2, 4, 0, 1 FROM temp_droit_1;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 3, 2, 0, 1 FROM temp_droit_1;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 4, 2, 0, 1 FROM temp_droit_1;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 5, 2, 0, 1 FROM temp_droit_1;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 6, 2, 0, 1 FROM temp_droit_1;
-- droit 1 pas accès à METADATA
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 1, 1, 2, 1 FROM temp_droit_1;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 2, 2, 2, 1 FROM temp_droit_1;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 3, 1, 2, 1 FROM temp_droit_1;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 4, 1, 2, 1 FROM temp_droit_1;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 5, 1, 2, 1 FROM temp_droit_1;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 6, 1, 2, 1 FROM temp_droit_1;
-- droit 1 pas accès ADMIN
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 1, 1, 1, 1 FROM temp_droit_1;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 2, 1, 1, 1 FROM temp_droit_1;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 3, 1, 1, 1 FROM temp_droit_1;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 4, 1, 1, 1 FROM temp_droit_1;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 5, 1, 1, 1 FROM temp_droit_1;
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 6, 1, 1, 1 FROM  temp_droit_1;
;


DROP TABLE temp_droit_1;
DROP TABLE temp_droit_2;
DROP TABLE temp_droit_6;
