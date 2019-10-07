-- on enleve les droits au module admin aux chargés de missions
DELETE FROM gn_permissions.cor_role_action_filter_module_object
WHERE id_role NOT IN (1004) AND id_module = 1;
-- On modifie les droits des chargés de mission au module metadata
DELETE FROM gn_permissions.cor_role_action_filter_module_object
WHERE id_role NOT IN (1004) AND id_module = 2; 
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 1, 1, 2, 1 FROM utilisateurs.t_roles WHERE id_role NOT IN (1004);
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 2, 4, 2, 1 FROM utilisateurs.t_roles WHERE id_role NOT IN (1004) AND id_role IN(1001);
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 3, 1, 2, 1 FROM utilisateurs.t_roles WHERE id_role NOT IN (1004);
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 4, 1, 2, 1 FROM utilisateurs.t_roles WHERE id_role NOT IN (1004);
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 5, 1, 2, 1 FROM utilisateurs.t_roles WHERE id_role NOT IN (1004);
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object) SELECT id_role, 6, 1, 2, 1 FROM utilisateurs.t_roles WHERE id_role NOT IN (1004);
