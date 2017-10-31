SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

---------
--DATAS--
---------

INSERT INTO gn_meta.t_datasets (id_dataset, dataset_name, dataset_desc, id_program, id_organism_owner, id_organism_producer, id_organism_administrator, id_organism_funder, public_data, default_validity, id_nomenclature_resource_type, id_nomenclature_data_type, ecologic_group, id_nomenclature_sampling_plan_type, id_nomenclature_sampling_units_type, meta_create_date, meta_update_date) VALUES
(1, 'Contact aléatoire', 'Observation aléatoire de la faune, de la flore ou de la fonge', 1, 2, 2, 2, 2, true, true, 351, 353, 'all', 356, 369, '2017-06-01 00:00:00', '2017-06-01 00:00:00')
,(2, 'ATBI Lauvitel', 'Inventaire biologique généralisé sur la réserve du Lauvitel', 1, 2, 2, 2, 2, true, true, 351, 353, 'all', 356, 369, '2017-06-01 00:00:00', '2017-06-01 00:00:00');

INSERT INTO gn_synthese.t_sources (id_source, name_source, desc_source, entity_source_pk_field, url_source, target, picto_source, groupe_source, active) VALUES
(1, 'Contact faune flore', 'Données issues du contact aléatoire', 'pr_contact.t_occurrences_contact.id_occurrence_contact', '/contact', NULL, NULL, 'CONTACT', true);

INSERT INTO ref_nomenclatures.defaults_nomenclatures_value (id_type, id_organism, entity_module, id_nomenclature) VALUES
(14,1,'pr_contact',42)
,(7,1,'pr_contact',178)
,(13,1,'pr_contact',30)
,(8,1,'pr_contact',182)
,(15,1,'pr_contact',91)
,(101,1,'pr_contact',347)
,(5,1,'pr_contact',163)
,(106,1,'pr_contact',370)
,(10,1,'pr_contact',2)
,(9,1,'pr_contact',194)
,(6,1,'pr_contact',166)
,(21,1,'pr_contact',109)
,(18,1,'pr_contact',101)
;

INSERT INTO pr_contact.t_releves_contact VALUES
(1,1,1,'Obervateur test insert','2017-01-01','2017-01-01','12:05:02','12:05:02',1500,1565,FALSE,'web',now(),now(),'Exemple test','01010000206A0800002E988D737BCC2D41ECFA38A659805841','0101000020E61000000000000000001A40CDCCCCCCCC6C4640',10)
,(2,1,1,'Obervateur test insert','2017-01-08','2017-01-08','20:00:00','23:00:00',1600,1600,FALSE,'web',now(),now(),'Autre exemple test','01010000206A0800002E988D737BCC2D41ECFA38A659805841','0101000020E61000000000000000001A40CDCCCCCCCC6C4640',100);
SELECT pg_catalog.setval('pr_contact.t_releves_contact_id_releve_contact_seq', 2, true);

INSERT INTO pr_contact.t_occurrences_contact VALUES
(1,1,343,65,177,30,182,91,347,163,101,1,'Gil',379,'Gees',60612,'Lynx Boréal','Taxref V9.0','','','Poil',FALSE, now(),now(),'Test')
,(2,1,343,65,177,30,182,91,347,163,101,1,'Gil D',370,NULL,351,'Grenouille rousse','Taxref V9.0','','','Poils de plumes',FALSE, now(),now(),'Autre test')
,(3,2,343,65,177,30,182,91,347,163,101,1,'Donovan M',370,NULL,67111,'Ablette','Taxref V9.0','','','Poils de plumes',FALSE, now(),now(),'Troisieme test');


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
