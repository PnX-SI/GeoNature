

DELETE FROM pr_occtax.t_releves_occtax CASCADE;

DELETE FROM gn_synthese.synthese CASCADE;

DELETE FROM gn_commons.cor_module_dataset CASCADE;
DELETE FROM gn_meta.cor_dataset_actor CASCADE;
DELETE FROM gn_meta.cor_dataset_territory CASCADE;
DELETE FROM gn_meta.cor_dataset_protocol CASCADE;
DELETE FROM gn_meta.t_datasets CASCADE;

DELETE FROM gn_meta.cor_acquisition_framework_voletsinp CASCADE;
DELETE FROM gn_meta.cor_acquisition_framework_actor CASCADE;
DELETE FROM gn_meta.cor_acquisition_framework_objectif CASCADE;
DELETE FROM gn_meta.cor_acquisition_framework_publication CASCADE;
DELETE FROM gn_meta.cor_acquisition_framework_territory CASCADE;
DELETE FROM gn_meta.t_acquisition_frameworks CASCADE;

DELETE FROM gn_permissions.cor_role_action_filter_module_object CASCADE;

DELETE FROM utilisateurs.cor_role_app_profil CASCADE;

DELETE FROM taxonomie.cor_taxon_attribut;

-- set the serial of synthese to 0
SELECT pg_catalog.setval('gn_synthese.synthese_id_synthese_seq', 1, true);

-- remove custom filters from gn_permissions.t_filters
DELETE FROM gn_permissions.t_filters WHERE id_filter = 500;

-- test register 
DELETE FROM utilisateurs.t_roles WHERE identifiant = 'hello_test';
DELETE FROM utilisateurs.temp_users WHERE identifiant = 'hello_test';

-- test reports
DELETE FROM gn_synthese.t_reports WHERE id_report IN (100002, 100001, 100000);
----------------
-- GN_COMMONS --
----------------

DELETE FROM gn_commons.t_mobile_apps;
