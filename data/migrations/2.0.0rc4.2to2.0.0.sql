-- Migration du metadata comme un module à part

INSERT INTO gn_commons.t_modules(module_code, module_label, module_picto, module_desc, module_path, module_target, active_frontend, active_backend) VALUES
('METADATA', 'Metadonnées', 'fa-book', 'Module de gestion des métadonnées', 'metadata', '_self', TRUE, TRUE)
;

-- migration des permission dans le nouveau module
INSERT INTO gn_permissions.cor_role_action_filter_module_object(
  id_role,
  id_action,
  id_filter,
  id_module
)
WITH mod_admin AS (
    SELECT id_module
    FROM gn_commons.t_modules
    WHERE module_code ILIKE 'ADMIN'
),
obj AS (
    SELECT id_object
    FROM gn_permissions.t_objects
    WHERE code_object ILIKE 'METADATA'
),
mod_metadata AS (
    SELECT id_module
    FROM gn_commons.t_modules
    WHERE module_code ILIKE 'METADATA' 
)
SELECT id_role, id_action, id_filter, mod_metadata.id_module
FROM gn_permissions.cor_role_action_filter_module_object cor, mod_admin, obj, mod_metadata
WHERE cor.id_module = mod_admin.id_module AND cor.id_object = obj.id_object;

-- suppression relation cor_object_module 
DELETE FROM gn_permissions.cor_object_module WHERE id_object = (
    SELECT id_object FROM gn_permissions.t_objects WHERE code_object = 'METADATA'
);

-- suppression des permissions de l'objet metadata inutiles
DELETE 
FROM gn_permissions.cor_role_action_filter_module_object
WHERE id_object = (
    SELECT id_object FROM gn_permissions.t_objects WHERE code_object = 'METADATA'
) AND id_module = (
    SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'ADMIN'
);
