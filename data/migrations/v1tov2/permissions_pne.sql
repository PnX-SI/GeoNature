-- on enleve les droits au module admin aux chargés de missions
DELETE FROM gn_permissions.cor_role_action_filter_module_object
WHERE id_role IN (232, 332, 1131) AND id_module = 1;