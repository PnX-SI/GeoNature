SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

---------
--DATAS--
---------
INSERT INTO gn_meta.t_acquisition_frameworks (id_acquisition_framework, unique_acquisition_framework_id, acquisition_framework_name, acquisition_framework_desc, id_nomenclature_territorial_level, territory_desc, keywords, id_nomenclature_financing_type, target_description, ecologic_or_geologic_target, acquisition_framework_parent_id, is_parent, acquisition_framework_start_date, acquisition_framework_end_date, meta_create_date, meta_update_date) VALUES
(1, '57b7d0f2-4183-4b7b-8f08-6e105d476dc5','Données d''observation de la faune, de la Flore et de la fonge du parc nationl des Ecrins','Données d''observation de la faune, de la Flore et de la fonge du parc nationl des Ecrins',383,'Territoire du parc national des Ecrins correspondant au massif alpin des Ecrins','Ecrins, parc national, faune, flore, fonge',417,'Tous les taxons',null,null,0,'1973-03-27', null,'2017-05-01 10:35:08', null)
;

INSERT INTO gn_meta.t_datasets (id_dataset, unique_dataset_id, id_acquisition_framework, unique_acquisition_framework_id, dataset_name, dataset_shortname, dataset_desc, id_nomenclature_data_type, keywords, marine_domain, terrestrial_domain, id_nomenclature_dataset_objectif, bbox_west, bbox_east, bbox_south, bbox_north, id_nomenclature_collecting_method, id_nomenclature_data_origin, id_nomenclature_source_status, id_nomenclature_resource_type, id_program, default_validity, meta_create_date, meta_update_date) VALUES
(1, '4d331cae-65e4-4948-b0b2-a11bc5bb46c2', 1, '57b7d0f2-4183-4b7b-8f08-6e105d476dc5','Conctat aléatoire tous règnes confondus', 'Contact aléatoire', 'Observations aléatoires de la faune, de la flore ou de la fonge', 353,'Aléatoire, hors protocole, faune, flore, fonge',false,true, 442, '4.85695', '6.85654','44.5020','45.25', 430, 80, 76, 351, 1, true,  '2017-06-01 16:57:44.45879', null)
,(2, 'dadab32d-5f9e-4dba-aa1f-c06487d536e8', 1, '57b7d0f2-4183-4b7b-8f08-6e105d476dc5','ATBI de la réserve intégrale de Lauvitel dans le Parc national des Ecrins', 'ATBI Lauvitel', 'Inventaire biologique généralisé sur la réserve du Lauvitel', 353,'Aléatoire, ATBI, biodiversité, faune, flore, fonge',false,true, 456, '4.85695', '6.85654','44.5020','45.25', 430, 80, 76, 351, 1, true,  '2017-06-01 16:59:03.25687', null)
;

INSERT INTO gn_meta.cor_acquisition_framework_voletsinp (id_acquisition_framework, id_nomenclature_voletsinp) VALUES
(1,426)
;

INSERT INTO gn_meta.cor_acquisition_framework_objectif (id_acquisition_framework, id_nomenclature_objectif) VALUES
(1,387)
;

INSERT INTO gn_meta.cor_acquisition_framework_territory (id_acquisition_framework, id_nomenclature_territory, territory_desc) VALUES
(1,400,'Territoire du parc national des Ecrins et de ses environs immédiats')
;

INSERT INTO gn_meta.cor_acquisition_framework_actor (id_acquisition_framework, id_actor, id_nomenclature_actor_role) VALUES
(1,2,393)
,(1,2,398)
,(1,3,429)
;

INSERT INTO gn_meta.cor_acquisition_framework_protocol (id_acquisition_framework, id_protocol) VALUES
(1,0)
;

INSERT INTO gn_meta.cor_dataset_actor (id_dataset, id_actor, id_nomenclature_actor_role) VALUES
(1,2,393)
,(1,2,398)
,(1,3,429)
,(2,2,393)
,(2,2,398)
,(2,3,429)
,(2,4,397)
;

INSERT INTO gn_meta.cor_dataset_territory (id_dataset, id_nomenclature_territory, territory_desc) VALUES
(1,400,'Territoire du parc national des Ecrins et de ses environs immédiats')
,(2,400,'Réserve intégrale de lauvitel')
;

INSERT INTO gn_meta.cor_dataset_protocol (id_dataset, id_protocol) VALUES
(1,0)
,(2,0)
;

INSERT INTO gn_synthese.t_sources (id_source, name_source, desc_source, entity_source_pk_field, url_source, target, picto_source, groupe_source, active) VALUES
(1, 'Contact faune flore', 'Données issues du contact aléatoire', 'pr_contact.t_occurrences_contact.id_occurrence_contact', '/contact', NULL, NULL, 'CONTACT', true);

INSERT INTO pr_contact.defaults_nomenclatures_value (id_type, id_organism, id_nomenclature) VALUES
(14,0,42)
,(7,0,178)
,(13,0,30)
,(8,0,182)
,(15,0,91)
,(101,0,347)
,(5,0,163)
,(106,0,370)
,(10,0,2)
,(9,0,194)
,(6,0,166)
,(21,0,109)
,(18,0,101)
,(4,0,200)
;

INSERT INTO pr_contact.t_releves_contact VALUES
(1,1,1,'Obervateur test insert','2017-01-01','2017-01-01','12:05:02','12:05:02',1500,1565,FALSE,'web',now(),now(),'Exemple test','01010000206A0800002E988D737BCC2D41ECFA38A659805841','0101000020E61000000000000000001A40CDCCCCCCCC6C4640',10)
,(2,1,1,'Obervateur test insert','2017-01-08','2017-01-08','20:00:00','23:00:00',1600,1600,FALSE,'web',now(),now(),'Autre exemple test','01010000206A0800002E988D737BCC2D41ECFA38A659805841','0101000020E61000000000000000001A40CDCCCCCCCC6C4640',100);
SELECT pg_catalog.setval('pr_contact.t_releves_contact_id_releve_contact_seq', 2, true);

INSERT INTO pr_contact.t_occurrences_contact VALUES
(1,1,343,65,177,30,182,91,347,163,101,200,1,'Gil',379,'Gees',60612,'Lynx Boréal','Taxref V9.0','','','Poil',FALSE, now(),now(),'Test')
,(2,1,343,65,177,30,182,91,347,163,101,200,1,'Gil D',370,NULL,351,'Grenouille rousse','Taxref V9.0','','','Poils de plumes',FALSE, now(),now(),'Autre test')
,(3,2,343,65,177,30,182,91,347,163,101,200,1,'Donovan M',370,NULL,67111,'Ablette','Taxref V9.0','','','Poils de plumes',FALSE, now(),now(),'Troisieme test');


SELECT pg_catalog.setval('pr_contact.t_occurrences_contact_id_occurrence_contact_seq', 4, true);

INSERT INTO pr_contact.cor_role_releves_contact VALUES
(1,1)
,(2,1);

INSERT INTO  pr_contact.cor_counting_contact (id_counting_contact, id_occurrence_contact, id_nomenclature_life_stage, id_nomenclature_sex, id_nomenclature_obj_count, id_nomenclature_type_count, count_min, count_max) VALUES
(1,1,4,190,166,107,5,5)
,(2,1,4,191,166,107,1,1),
(3,2,4,191,166,107,1,1),
(4,3,4,191,166,107,1,1);
SELECT pg_catalog.setval('pr_contact.cor_counting_contact_id_counting_contact_seq', 4, true);
