

TRUNCATE pr_occtax.t_releves_occtax CASCADE;

TRUNCATE gn_meta.t_datasets CASCADE;

TRUNCATE gn_meta.t_acquisition_frameworks CASCADE;


DELETE FROM utilisateurs.cor_app_privileges WHERE id_role = 3;
