-- on met tous les JDD comme appartenant Occtax par défaut pour assurer la rétrocompatibilité
SELECT id_module, t.id_dataset
gn_commons.get_id_module_bycode('OCCTAX'), gn_meta.t_datasets t
WHERE t.active = true
;
