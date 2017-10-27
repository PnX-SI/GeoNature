SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

---------
--DATAS--
---------

INSERT INTO gn_meta.t_datasets (
            id_dataset, dataset_name, dataset_desc, id_program, id_organism_owner,
            id_organism_producer, id_organism_administrator, id_organism_funder,
            public_data, default_validity, id_nomenclature_resource_type,
            id_nomenclature_data_type, ecologic_group, id_nomenclature_sampling_plan_type,
            id_nomenclature_sampling_units_type, meta_create_date, meta_update_date
)VALUES
(1, 'Contact aléatoire', 'Observation aléatoire de la faune, de la flore ou de la fonge', 1, 2, 2, 2, 2, true, NULL, 351, 353, NULL, 356, 369,  '2017-06-01 00:00:00', '2017-06-01 00:00:00')
,(2, 'ATBI Lauvitel', 'Inventaire biologique généralisé sur la réserve du Lauvitel', 1, 2, 2, 2, 2, true, NULL, 351, 353, NULL, 356, 369, '2017-06-01 00:00:00', '2017-06-01 00:00:00');

INSERT INTO gn_synthese.t_modules (id_module, name_module, desc_module, entity_module_pk_field, url_module, target, picto_module, groupe_module, active) VALUES
(1, 'Contact faune flore', 'Données issues du contact aléatoire', 'pr_contact.t_occurrences_contact.id_occurrence_contact', '/contact', NULL, NULL, 'CONTACT', true);

INSERT INTO pr_contact.t_releves_contact (
            id_releve_contact, id_dataset, id_digitiser, observers_txt, date_min,
            date_max, hour_min, hour_max, altitude_min, altitude_max, deleted,
            meta_device_entry, meta_create_date, meta_update_date, comment,
            geom_local, geom_4326, "precision"
)  VALUES
(1,1,1,NULL, '2017-01-01','2017-01-01','12:30', '12:30', 1500,1565,FALSE,'web',now(),now(),'Exemple test','01010000206A0800002E988D737BCC2D41ECFA38A659805841','0101000020E61000000000000000001A40CDCCCCCCCC6C4640', 10)
,(2,1,1,NULL, '2017-01-08','2017-01-08',NULL, NULL, 1600,1600,FALSE,'web',now(),now(),'Autre exemple test','01010000206A0800002E988D737BCC2D41ECFA38A659805841','0101000020E61000000000000000001A40CDCCCCCCCC6C4640',10);
SELECT pg_catalog.setval('pr_contact.t_releves_contact_id_releve_contact_seq', 2, true);

INSERT INTO pr_contact.t_occurrences_contact (
            id_occurrence_contact, id_releve_contact,
            id_nomenclature_obs_technique, id_nomenclature_obs_meth, id_nomenclature_bio_condition,
            id_nomenclature_bio_status, id_nomenclature_naturalness, id_nomenclature_exist_proof,
            id_nomenclature_valid_status, id_nomenclature_diffusion_level,
            id_validator, determiner, id_nomenclature_determination_method,
            determination_method_as_text, cd_nom, nom_cite, meta_v_taxref,
            sample_number_proof, digital_proof, non_digital_proof, deleted,
            meta_create_date, meta_update_date, comment
)VALUES
(1,1,343,65,177,30,182,91,347,163,1,'Gil',370, 'Gees',60612,'Lynx Boréal','Taxref V9.0','','','Poil',FALSE, now(),now(),'Test')
,(2,1,343,65,177,30,182,91,347,163,1,'Gil D',370,'Gees',351,'Grenouille rousse','Taxref V9.0','','','Poils de plumes',FALSE, now(),now(),'Autre test')
,(3,2,343,65,177,30,182,91,347,163,1,'Donovan M',370,'Gees',67111,'Ablette','Taxref V9.0','','','Poils de plumes',FALSE, now(),now(),'Troisieme test');
SELECT pg_catalog.setval('pr_contact.t_occurrences_contact_id_occurrence_contact_seq', 3, true);

INSERT INTO pr_contact.cor_role_releves_contact VALUES
(1,1)
,(2,1);


INSERT INTO  pr_contact.cor_counting_contact (id_counting_contact, id_occurrence_contact, id_nomenclature_life_stage, id_nomenclature_sex, id_nomenclature_obj_count, id_nomenclature_type_count, count_min, count_max) VALUES
(1,1,4,190,166,107,5,5)
,(2,1,4,191,166,107,1,1),
(3,2,4,191,166,107,1,1),
(4,3,4,191,166,107,1,1);
SELECT pg_catalog.setval('pr_contact.cor_counting_contact_id_counting_contact_seq', 4, true);
