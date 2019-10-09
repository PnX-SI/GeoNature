-- on met tous les JDD comme appartenant Occtax par défaut pour assurer la rétrocompatibilité
SELECT id_module, t.id_dataset
FROM gn_commons.t_modules, gn_meta.t_datasets t
WHERE module_code = 'OCCTAX'