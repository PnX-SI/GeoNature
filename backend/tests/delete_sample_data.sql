

TRUNCATE pr_occtax.t_releves_occtax CASCADE;

TRUNCATE gn_meta.t_datasets CASCADE;

TRUNCATE gn_meta.t_acquisition_frameworks CASCADE;

TRUNCATE gn_permissions.cor_role_action_filter_module_object CASCADE;

TRUNCATE gn_synthese.synthese CASCADE;

TRUNCATE utilisateurs.cor_role_app_profil CASCADE;

TRUNCATE taxonomie.cor_taxon_attribut;

-- set the serial of synthese to 0
SELECT pg_catalog.setval('gn_synthese.synthese_id_synthese_seq', 1, true);

-- remove custom filters from gn_permissions.t_filters
DELETE FROM gn_permissions.t_filters WHERE id_filter = 500;

-- test register 
DELETE FROM utilisateurs.t_roles WHERE identifiant = 'hello_test';
DELETE FROM utilisateurs.temp_users WHERE identifiant = 'hello_test';