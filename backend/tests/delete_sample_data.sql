
DELETE FROM pr_occtax.cor_counting_occtax;
DELETE FROM pr_occtax.cor_role_releves_occtax;
DELETE FROM pr_occtax.t_occurrences_occtax;
DELETE FROM pr_occtax.t_releves_occtax;

DELETE FROM gn_meta.cor_dataset_protocol;
DELETE FROM gn_meta.cor_dataset_territory;
DELETE FROM gn_meta.cor_dataset_actor;
DELETE FROM gn_meta.t_datasets;

DELETE FROM gn_meta.cor_acquisition_framework_objectif;
DELETE FROM gn_meta.cor_acquisition_framework_publication;
DELETE FROM gn_meta.cor_acquisition_framework_voletsinp;
DELETE FROM gn_meta.cor_acquisition_framework_actor;
DELETE FROM gn_meta.t_acquisition_frameworks;

DELETE FROM utilisateurs.cor_app_privileges WHERE id_role = 3;