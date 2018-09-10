SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

---------
--DATAS--
---------

-- Insérer un cadre d'acquisition d'exemple

INSERT INTO gn_meta.t_acquisition_frameworks (
    id_acquisition_framework, 
    unique_acquisition_framework_id, 
    acquisition_framework_name, 
    acquisition_framework_desc, 
    id_nomenclature_territorial_level, 
    territory_desc, 
    keywords, 
    id_nomenclature_financing_type, 
    target_description, 
    ecologic_or_geologic_target, 
    acquisition_framework_parent_id, 
    is_parent, 
    acquisition_framework_start_date, 
    acquisition_framework_end_date, 
    meta_create_date, 
    meta_update_date
    ) VALUES (
    1, 
    '57b7d0f2-4183-4b7b-8f08-6e105d476dc5', 
    'Données d''observation de la faune, de la Flore et de la fonge du Parc national des Ecrins',
    'Données d''observation de la faune, de la Flore et de la fonge du Parc national des Ecrins',
    ref_nomenclatures.get_id_nomenclature('NIVEAU_TERRITORIAL', '4'),
    'Territoire du Parc national des Ecrins correspondant au massif alpin des Ecrins',
    'Ecrins, parc national, faune, flore, fonge',
    ref_nomenclatures.get_id_nomenclature('TYPE_FINANCEMENT', '1'),
    'Tous les taxons',
    null,
    null,
    0,
    '1973-03-27',
    null,
    '2018-09-01 10:35:08',
    null
    )
;
SELECT pg_catalog.setval('gn_meta.t_acquisition_frameworks_id_acquisition_framework_seq', (SELECT max(id_acquisition_framework)+1 FROM gn_meta.t_acquisition_frameworks), true);

-- Insérer 2 jeux de données d'exemple

INSERT INTO gn_meta.t_datasets (
    id_dataset,
    unique_dataset_id,
    id_acquisition_framework,
    dataset_name,
    dataset_shortname,
    dataset_desc,
    id_nomenclature_data_type,
    keywords,
    marine_domain,
    terrestrial_domain,
    id_nomenclature_dataset_objectif,
    bbox_west,
    bbox_east,
    bbox_south,
    bbox_north,
    id_nomenclature_collecting_method,
    id_nomenclature_data_origin,
    id_nomenclature_source_status,
    id_nomenclature_resource_type,
    default_validity,
    meta_create_date,
    meta_update_date
    )
    VALUES
    (
    1,
    '4d331cae-65e4-4948-b0b2-a11bc5bb46c2',
     1,
    'Contact aléatoire tous règnes confondus',
    'Contact aléatoire',
    'Observations aléatoires de la faune, de la flore ou de la fonge',
    ref_nomenclatures.get_id_nomenclature('DATA_TYP', '1'),
    'Aléatoire, hors protocole, faune, flore, fonge',
    false,
    true,
    ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS', '1.1'),
    '4.85695',
    '6.85654',
    '44.5020',
    '45.25',
    ref_nomenclatures.get_id_nomenclature('METHO_RECUEIL', '1'),
    ref_nomenclatures.get_id_nomenclature('DS_PUBLIQUE', 'Pu'),
    ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE', 'Te'),
    ref_nomenclatures.get_id_nomenclature('RESOURCE_TYP', '1'),
    true,
    '2018-09-01 16:57:44.45879',
    null
    ),
    (
    2,
    'dadab32d-5f9e-4dba-aa1f-c06487d536e8',
    1,
    'ATBI de la réserve intégrale du Lauvitel dans le Parc national des Ecrins',
    'ATBI Lauvitel',
    'Inventaire biologique généralisé sur la réserve du Lauvitel',
    ref_nomenclatures.get_id_nomenclature('DATA_TYP', '1'),
    'Aléatoire, ATBI, biodiversité, faune, flore, fonge',
    false,
    true,
    ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS', '1.1'),
    '4.85695',
    '6.85654',
    '44.5020',
    '45.25',
    ref_nomenclatures.get_id_nomenclature('METHO_RECUEIL', '1'),
    ref_nomenclatures.get_id_nomenclature('DS_PUBLIQUE', 'Pu'),
    ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE', 'Te'),
    ref_nomenclatures.get_id_nomenclature('RESOURCE_TYP', '1'),
    true,
    '2018-09-01 16:59:03.25687',
    null
    )
;
SELECT pg_catalog.setval('gn_meta.t_datasets_id_dataset_seq', (SELECT max(id_dataset)+1 FROM gn_meta.t_datasets), true);

-- Renseigner les tables de correspondance

INSERT INTO gn_meta.cor_acquisition_framework_voletsinp (id_acquisition_framework, id_nomenclature_voletsinp) VALUES
(1, ref_nomenclatures.get_id_nomenclature('VOLET_SINP', '1'))
;

INSERT INTO gn_meta.cor_acquisition_framework_objectif (id_acquisition_framework, id_nomenclature_objectif) VALUES
(1, ref_nomenclatures.get_id_nomenclature('CA_OBJECTIFS', '1'))
;

INSERT INTO gn_meta.cor_acquisition_framework_actor (id_cafa, id_acquisition_framework, id_role, id_organism, id_nomenclature_actor_role) VALUES
(1, 1, NULL, 2, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '1'))
,(2, 1, NULL, 2, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '6'))
,(3, 1, NULL, 2, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '8'))
;
SELECT pg_catalog.setval('gn_meta.cor_acquisition_framework_actor_id_cafa_seq', (SELECT max(id_cafa)+1 FROM gn_meta.cor_acquisition_framework_actor), true);

INSERT INTO gn_meta.cor_dataset_actor (id_cda, id_dataset, id_role, id_organism, id_nomenclature_actor_role) VALUES
(1, 1, NULL, 2, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '1'))
,(2, 1, NULL, 2, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '6'))
,(3, 1, 3, NULL, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '8'))
,(4, 2, NULL, 2, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '1'))
,(5, 2, NULL, 2, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '6'))
,(6, 2, 3, NULL, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '8'))
,(7, 2, 2, NULL, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '5'))
,(8, 1, NULL, -1, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '6'))
,(9, 2, NULL, -1, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '6'))
;
SELECT pg_catalog.setval('gn_meta.cor_dataset_actor_id_cda_seq', (SELECT max(id_cda)+1 FROM gn_meta.cor_dataset_actor), true);

INSERT INTO gn_meta.cor_dataset_territory (id_dataset, id_nomenclature_territory, territory_desc) VALUES
(1, ref_nomenclatures.get_id_nomenclature('TERRITOIRE', 'METROP'),'Territoire du parc national des Ecrins et de ses environs immédiats')
,(2,ref_nomenclatures.get_id_nomenclature('TERRITOIRE', 'METROP'),'Réserve intégrale de lauvitel')
;

INSERT INTO gn_meta.cor_dataset_protocol (id_dataset, id_protocol) VALUES
(1,0)
,(2,0)
;
SELECT pg_catalog.setval('gn_meta.sinp_datatype_protocols_id_protocol_seq', (SELECT max(id_protocol)+1 FROM gn_meta.cor_dataset_protocol), true);

-- Insérer une source exemple

INSERT INTO gn_synthese.t_sources (name_source, desc_source, entity_source_pk_field, url_source, target, picto_source, groupe_source, active) VALUES
('occtax', 'Données issues du module Occtax', 'pr_occtax.cor_counting_occtax.id_counting_occtax', '/occtax', NULL, NULL, 'CONTACT', true);

-- Insérer 2 relevés d'exemple dans Occtax

INSERT INTO pr_occtax.t_releves_occtax (id_releve_occtax,id_dataset,id_digitiser,observers_txt,id_nomenclature_obs_technique,id_nomenclature_grp_typ,date_min,date_max,hour_min,hour_max,altitude_min,altitude_max,meta_device_entry,comment,geom_local,geom_4326,precision) VALUES
(1,1,1,'Obervateur test insert',ref_nomenclatures.get_id_nomenclature('TECHNIQUE_OBS', '133'),ref_nomenclatures.get_id_nomenclature('TYP_GRP', 'OBS'),'2017-01-01','2017-01-01','12:05:02','12:05:02',1500,1565,'web','Exemple test','01010000206A0800002E988D737BCC2D41ECFA38A659805841','0101000020E61000000000000000001A40CDCCCCCCCC6C4640',10)
,(2,1,1,'Obervateur test insert',ref_nomenclatures.get_id_nomenclature('TECHNIQUE_OBS', '133'),ref_nomenclatures.get_id_nomenclature('TYP_GRP', 'OBS'),'2017-01-08','2017-01-08','20:00:00','23:00:00',1600,1600,'web','Autre exemple test','01010000206A0800002E988D737BCC2D41ECFA38A659805841','0101000020E61000000000000000001A40CDCCCCCCCC6C4640',100);
SELECT pg_catalog.setval('pr_occtax.t_releves_occtax_id_releve_occtax_seq', (SELECT max(id_releve_occtax)+1 FROM pr_occtax.t_releves_occtax), true);

-- Insérer 3 occurrences dans les 2 relevés Occtax

INSERT INTO pr_occtax.t_occurrences_occtax  (
    id_occurrence_occtax,
    id_releve_occtax,
    id_nomenclature_obs_meth,
    id_nomenclature_bio_condition,
    id_nomenclature_bio_status,
    id_nomenclature_naturalness,
    id_nomenclature_exist_proof,
    id_nomenclature_diffusion_level,
    id_nomenclature_observation_status,
    id_nomenclature_blurring,
    determiner,
    id_nomenclature_determination_method,
    cd_nom,
    nom_cite,
    meta_v_taxref,
    sample_number_proof,
    digital_proof,
    non_digital_proof,
    comment
  )
VALUES
  (
    1,
    1,
    ref_nomenclatures.get_id_nomenclature('METH_OBS', '23'),
    ref_nomenclatures.get_id_nomenclature('ETA_BIO', '1'),
    ref_nomenclatures.get_id_nomenclature('STATUT_BIO', '1'),
    ref_nomenclatures.get_id_nomenclature('NATURALITE', '1'),
    ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST', '0'),
    ref_nomenclatures.get_id_nomenclature('NIV_PRECIS', '0'),
    ref_nomenclatures.get_id_nomenclature('STATUT_OBS', 'Pr'),
    ref_nomenclatures.get_id_nomenclature('DEE_FLOU', 'NON'),
    'Gil',
    ref_nomenclatures.get_id_nomenclature('METH_DETERMIN', '2'),
    60612,
    'Lynx Boréal',
    'Taxref V11.0',
    '',
    '',
    'Poil',
    'Test'
  ),
  (
    2,
    1,
    ref_nomenclatures.get_id_nomenclature('METH_OBS', '23'),
    ref_nomenclatures.get_id_nomenclature('ETA_BIO', '1'),
    ref_nomenclatures.get_id_nomenclature('STATUT_BIO', '1') ,
    ref_nomenclatures.get_id_nomenclature('NATURALITE', '1'),
    ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST', '0'),
    ref_nomenclatures.get_id_nomenclature('NIV_PRECIS', '0'),
    ref_nomenclatures.get_id_nomenclature('STATUT_OBS', 'Pr'),
    ref_nomenclatures.get_id_nomenclature('DEE_FLOU', 'NON'),
    'Gil D',
    ref_nomenclatures.get_id_nomenclature('METH_DETERMIN', '2'),
    351,
    'Grenouille rousse',
    'Taxref V11.0',
    '',
    '',
    'Poils de plumes',
    'Autre test'
  ),
  (
    3,
    2,
    ref_nomenclatures.get_id_nomenclature('METH_OBS', '23'),
    ref_nomenclatures.get_id_nomenclature('ETA_BIO', '1'),
    ref_nomenclatures.get_id_nomenclature('STATUT_BIO', '1'),
    ref_nomenclatures.get_id_nomenclature('NATURALITE', '1'),
    ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST', '0'),
    ref_nomenclatures.get_id_nomenclature('NIV_PRECIS', '0'),
    ref_nomenclatures.get_id_nomenclature('STATUT_OBS', 'Pr'),
    ref_nomenclatures.get_id_nomenclature('DEE_FLOU', 'NON'),
  'Donovan M',
  ref_nomenclatures.get_id_nomenclature('METH_DETERMIN', '2'),
  67111,
  'Ablette',
  'Taxref V11.0',
  '',
  '',
  'Poils de plumes',
  'Troisieme test'
  );

SELECT pg_catalog.setval('pr_occtax.t_occurrences_occtax_id_occurrence_occtax_seq', (SELECT max(id_occurrence_occtax)+1 FROM pr_occtax.t_occurrences_occtax), true);

-- Insérer 1 observateur pour chacun des 2 relevés Occtax

INSERT INTO pr_occtax.cor_role_releves_occtax (id_releve_occtax, id_role) VALUES
(1,1)
,(2,1);

-- Insérer 3 dénombrements dans les 3 occurrences

INSERT INTO  pr_occtax.cor_counting_occtax (
  id_counting_occtax,
  id_occurrence_occtax,
  id_nomenclature_life_stage,
  id_nomenclature_sex,
  id_nomenclature_obj_count,
  id_nomenclature_type_count,
  count_min,
  count_max
  )
  VALUES
  (
    1,
    1,
    ref_nomenclatures.get_id_nomenclature('STADE_VIE', '2') ,
    ref_nomenclatures.get_id_nomenclature('SEXE', '2') ,
    ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', 'IND'),
    ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'Co'),
    5,
    5
  ),
  (
    2,
    1,
    ref_nomenclatures.get_id_nomenclature('STADE_VIE', '4') ,
    ref_nomenclatures.get_id_nomenclature('SEXE', '2'),
    ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', 'IND'),
    ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'Co'),
    1,
    1
  ),
  (
    3,
    2,
    ref_nomenclatures.get_id_nomenclature('STADE_VIE', '3') ,
    ref_nomenclatures.get_id_nomenclature('SEXE', '2'),
    ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', 'IND'),
    ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'Co'),
    1,
    1
  )
;
SELECT pg_catalog.setval('pr_occtax.cor_counting_occtax_id_counting_occtax_seq', (SELECT max(id_counting_occtax)+1 FROM pr_occtax.cor_counting_occtax), true);
