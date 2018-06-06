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
(1, '57b7d0f2-4183-4b7b-8f08-6e105d476dc5', 'Données d''observation de la faune, de la Flore et de la fonge du parc nationl des Ecrins','Données d''observation de la faune, de la Flore et de la fonge du parc nationl des Ecrins',383,'Territoire du parc national des Ecrins correspondant au massif alpin des Ecrins','Ecrins, parc national, faune, flore, fonge',417,'Tous les taxons',null,null,0,'1973-03-27', null,'2017-05-01 10:35:08', null)
;
SELECT pg_catalog.setval('gn_meta.t_datasets_id_dataset_seq', 2, true);

INSERT INTO gn_meta.t_datasets (id_dataset, unique_dataset_id, id_acquisition_framework, dataset_name, dataset_shortname, dataset_desc, id_nomenclature_data_type, keywords, marine_domain, terrestrial_domain, id_nomenclature_dataset_objectif, bbox_west, bbox_east, bbox_south, bbox_north, id_nomenclature_collecting_method, id_nomenclature_data_origin, id_nomenclature_source_status, id_nomenclature_resource_type, default_validity, meta_create_date, meta_update_date) VALUES
(1, '4d331cae-65e4-4948-b0b2-a11bc5bb46c2', 1, 'Conctat aléatoire tous règnes confondus', 'Contact aléatoire', 'Observations aléatoires de la faune, de la flore ou de la fonge', 353,'Aléatoire, hors protocole, faune, flore, fonge',false,true, 442, '4.85695', '6.85654','44.5020','45.25', 430, 80, 76, 351, true,  '2017-06-01 16:57:44.45879', null)
,(2, 'dadab32d-5f9e-4dba-aa1f-c06487d536e8', 1, 'ATBI de la réserve intégrale de Lauvitel dans le Parc national des Ecrins', 'ATBI Lauvitel', 'Inventaire biologique généralisé sur la réserve du Lauvitel', 353,'Aléatoire, ATBI, biodiversité, faune, flore, fonge',false,true, 456, '4.85695', '6.85654','44.5020','45.25', 430, 80, 76, 351, true,  '2017-06-01 16:59:03.25687', null)
;
SELECT pg_catalog.setval('gn_meta.t_acquisition_frameworks_id_acquisition_framework_seq', 2, true);

-- INSERT INTO gn_meta.cor_acquisition_framework_voletsinp (id_acquisition_framework, id_nomenclature_voletsinp) VALUES
-- (1,426)
-- ;

-- INSERT INTO gn_meta.cor_acquisition_framework_objectif (id_acquisition_framework, id_nomenclature_objectif) VALUES
-- (1,387)
-- ;

INSERT INTO gn_meta.cor_acquisition_framework_actor (id_cafa, id_acquisition_framework, id_role, id_organism, id_nomenclature_actor_role) VALUES
(1, 1, NULL, 2, 393)
,(2, 1, NULL, 2, 398)
,(3, 1, NULL, 2, 429)
;
SELECT pg_catalog.setval('gn_meta.cor_acquisition_framework_actor_id_cafa_seq', 4, true);

INSERT INTO gn_meta.cor_dataset_actor (id_cda, id_dataset, id_role, id_organism, id_nomenclature_actor_role) VALUES
(1, 1, NULL, 2, 393)
,(2, 1, NULL, 2, 398)
,(3, 1, 3, NULL, 429)
,(4, 2, NULL, 2, 393)
,(5, 2, NULL, 2, 398)
,(7, 2, NULL, -1, 397)
;
SELECT pg_catalog.setval('gn_meta.cor_dataset_actor_id_cda_seq', 8, true);


-- Utilisateurs
UPDATE utilisateurs.t_roles SET pass_plus = '$2y$13$TMuRXgvIg6/aAez0lXLLFu0lyPk4m8N55NDhvLoUHh/Ar3rFzjFT.' WHERE id_role=3;
-- Ajout d'un utilisateurs partenaire avec comme cruved R=1
INSERT INTO utilisateurs.cor_app_privileges(id_tag_action, id_tag_object, id_application, id_role) VALUES
(12,21,14,3);

-- INSERT INTO gn_meta.cor_dataset_territory (id_dataset, id_nomenclature_territory, territory_desc) VALUES
-- (1,400,'Territoire du parc national des Ecrins et de ses environs immédiats')
-- ,(2,400,'Réserve intégrale de lauvitel')
-- ;

-- INSERT INTO gn_meta.cor_dataset_protocol (id_dataset, id_protocol) VALUES
-- (1,0)
-- ,(2,0)
-- ;
-- SELECT pg_catalog.setval('gn_meta.sinp_datatype_protocols_id_protocol_seq', 2, true);

-- INSERT INTO gn_synthese.t_sources (id_source, name_source, desc_source, entity_source_pk_field, url_source, target, picto_source, groupe_source, active) VALUES
-- (1, 'Contact faune flore', 'Données issues du occtax aléatoire', 'pr_occtax.cor_counting_occtax.id_counting_occtax', '/occtax', NULL, NULL, 'CONTACT', true);


INSERT INTO pr_occtax.t_releves_occtax (id_releve_occtax,id_dataset,id_digitiser,observers_txt,id_nomenclature_obs_technique,id_nomenclature_grp_typ,date_min,date_max,hour_min,hour_max,altitude_min,altitude_max,meta_device_entry,comment,geom_local,geom_4326,precision) VALUES 
(1,1,1,'Obervateur test insert',343,151,'2017-01-01','2017-01-01','12:05:02','12:05:02',1500,1565,'web','Exemple test','01010000206A0800002E988D737BCC2D41ECFA38A659805841','0101000020E61000000000000000001A40CDCCCCCCCC6C4640',10)
,(2,1,1,'Obervateur test insert',343,151,'2017-01-08','2017-01-08','20:00:00','23:00:00',1600,1600,'web','Autre exemple test','01010000206A0800002E988D737BCC2D41ECFA38A659805841','0101000020E61000000000000000001A40CDCCCCCCCC6C4640',100);
SELECT pg_catalog.setval('pr_occtax.t_releves_occtax_id_releve_occtax_seq', 3, true);

INSERT INTO pr_occtax.t_occurrences_occtax  (id_occurrence_occtax, id_releve_occtax, id_nomenclature_obs_meth, id_nomenclature_bio_condition, id_nomenclature_bio_status, id_nomenclature_naturalness, id_nomenclature_exist_proof, id_nomenclature_diffusion_level, id_nomenclature_observation_status, id_nomenclature_blurring, determiner, id_nomenclature_determination_method, cd_nom, nom_cite, meta_v_taxref, sample_number_proof, digital_proof, non_digital_proof, comment) VALUES
(1,1,65,177,30,182,91,163,101,200,'Gil',379,60612,'Lynx Boréal','Taxref V9.0','','','Poil','Test')
,(2,1,65,177,30,182,91,163,101,200,'Gil D',370,351,'Grenouille rousse','Taxref V9.0','','','Poils de plumes','Autre test')
,(3,2,65,177,30,182,91,163,101,200,'Donovan M',370,67111,'Ablette','Taxref V9.0','','','Poils de plumes','Troisieme test');
SELECT pg_catalog.setval('pr_occtax.t_occurrences_occtax_id_occurrence_occtax_seq', 4, true);


INSERT INTO pr_occtax.cor_role_releves_occtax (id_releve_occtax, id_role) VALUES
(1,1)
,(2,1);

INSERT INTO  pr_occtax.cor_counting_occtax (id_counting_occtax, id_occurrence_occtax, id_nomenclature_life_stage, id_nomenclature_sex, id_nomenclature_obj_count, id_nomenclature_type_count, count_min, count_max) VALUES
(1,1,4,190,166,107,5,5)
,(2,1,4,191,166,107,1,1),
(3,2,4,191,166,107,1,1),
(4,3,4,191,166,107,1,1);
SELECT pg_catalog.setval('pr_occtax.cor_counting_occtax_id_counting_occtax_seq', 5, true);
