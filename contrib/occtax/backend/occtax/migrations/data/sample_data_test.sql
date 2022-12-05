SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;


SET search_path = pr_occtax, pg_catalog, public;

---------
--DATAS--
---------

-- ajout d'un module occtax dupliqué
INSERT INTO gn_commons.t_modules
(module_code, module_label, module_path, active_frontend, active_backend, ng_module)
VALUES('OCCTAX_DS', 'Occtax ds',  'occtax_ds', true, false, 'occtax');

-- ajout d’une source pour le module occtax dupliqué
WITH s AS (
    SELECT s.*
    FROM gn_synthese.t_sources s
    JOIN gn_commons.t_modules USING (id_module)
    WHERE module_code = 'OCCTAX'
)
INSERT INTO
    gn_synthese.t_sources (name_source, desc_source, entity_source_pk_field, url_source, id_module)
SELECT
    s.name_source || ' DS',
    s.desc_source || ' DS',
    s.entity_source_pk_field,
    s.url_source,
    (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'OCCTAX_DS')
FROM s;


-- Insérer un cadre d'acquisition d'exemple

INSERT INTO gn_meta.t_acquisition_frameworks (
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
    '57b7d0f2-4183-4b7b-8f08-6e105d476dc5', 
    'CA-1',
    'CA-1',
    ref_nomenclatures.get_id_nomenclature('NIVEAU_TERRITORIAL', '4'),
    'Territoire du Parc national des Ecrins correspondant au massif alpin des Ecrins',
    'Ecrins, parc national, faune, flore, fonge',
    ref_nomenclatures.get_id_nomenclature('TYPE_FINANCEMENT', '1'),
    'Tous les taxons',
    null,
    null,
    false,
    '1973-03-27',
    null,
    '2018-09-01 10:35:08',
    null
    );
;

INSERT INTO gn_meta.t_acquisition_frameworks (
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
    '48b7d0f2-4183-4b7b-8f08-6e105d476dd8', 
    'CA-2-empty',
    'CA-1-empty',
    ref_nomenclatures.get_id_nomenclature('NIVEAU_TERRITORIAL', '4'),
    'Test',
    'flore, fonge',
    ref_nomenclatures.get_id_nomenclature('TYPE_FINANCEMENT', '1'),
    'Tous les taxons',
    null,
    null,
    false,
    '2002-03-27',
    null,
    '2022-09-01 10:35:08',
    null
    );

-- Insérer 2 jeux de données d'exemple
INSERT INTO gn_meta.t_datasets (
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
    active,
    validable,
    meta_create_date,
    meta_update_date
    )
    VALUES
    (
    '4d331cae-65e4-4948-b0b2-a11bc5bb46c2',
     (SELECT id_acquisition_framework FROM gn_meta.t_acquisition_frameworks WHERE unique_acquisition_framework_id='57b7d0f2-4183-4b7b-8f08-6e105d476dc5'),
    'JDD-1',
    'Contact aléatoire',
    'Observations aléatoires de la faune, de la flore ou de la fonge',
    ref_nomenclatures.get_id_nomenclature('DATA_TYP', '1'),
    'Aléatoire, hors protocole, faune, flore, fonge',
    false,
    true,
    ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS', '1.1'),
    4.85695,
    6.85654,
    44.5020,
    45.25,
    ref_nomenclatures.get_id_nomenclature('METHO_RECUEIL', '1'),
    ref_nomenclatures.get_id_nomenclature('DS_PUBLIQUE', 'Pu'),
    ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE', 'Te'),
    ref_nomenclatures.get_id_nomenclature('RESOURCE_TYP', '1'),
    true,
    true,
    '2018-09-01 16:57:44.45879',
    null
    ),
    (
    'dadab32d-5f9e-4dba-aa1f-c06487d536e8',
    (SELECT id_acquisition_framework FROM gn_meta.t_acquisition_frameworks WHERE unique_acquisition_framework_id='57b7d0f2-4183-4b7b-8f08-6e105d476dc5'),
    'JDD-2',
    'ATBI Lauvitel',
    'Inventaire biologique généralisé sur la réserve du Lauvitel',
    ref_nomenclatures.get_id_nomenclature('DATA_TYP', '1'),
    'Aléatoire, ATBI, biodiversité, faune, flore, fonge',
    false,
    true,
    ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS', '1.1'),
    4.85695,
    6.85654,
    44.5020,
    45.25,
    ref_nomenclatures.get_id_nomenclature('METHO_RECUEIL', '1'),
    ref_nomenclatures.get_id_nomenclature('DS_PUBLIQUE', 'Pu'),
    ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE', 'Te'),
    ref_nomenclatures.get_id_nomenclature('RESOURCE_TYP', '1'),
    true,
    true,
    '2018-09-01 16:59:03.25687',
    null
    ),
    (
    'ac55a073-222a-4acc-8ac7-2b1f622018b2',
     (SELECT id_acquisition_framework FROM gn_meta.t_acquisition_frameworks WHERE unique_acquisition_framework_id='57b7d0f2-4183-4b7b-8f08-6e105d476dc5'),
    'JDD-Occtax-ds',
    'JDD-Occtax-ds',
    'JDD-Occtax-ds',
    ref_nomenclatures.get_id_nomenclature('DATA_TYP', '1'),
    'Aléatoire, hors protocole, faune, flore, fonge',
    false,
    true,
    ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS', '1.1'),
    4.85695,
    6.85654,
    44.5020,
    45.25,
    ref_nomenclatures.get_id_nomenclature('METHO_RECUEIL', '1'),
    ref_nomenclatures.get_id_nomenclature('DS_PUBLIQUE', 'Pu'),
    ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE', 'Te'),
    ref_nomenclatures.get_id_nomenclature('RESOURCE_TYP', '1'),
    true,
    true,
    '2018-09-01 16:57:44.45879',
    null
    )
;

-- ajout des JDD dans les modules occtax et occtax dupliqué
INSERT INTO gn_commons.cor_module_dataset (id_module, id_dataset)
VALUES (
    (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'OCCTAX'),
    (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id='4d331cae-65e4-4948-b0b2-a11bc5bb46c2')
),
(
    (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'OCCTAX'),
    (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id='dadab32d-5f9e-4dba-aa1f-c06487d536e8')
),
(
    (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'OCCTAX_DS'),
    (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id='ac55a073-222a-4acc-8ac7-2b1f622018b2')
);
            

-- Renseigner les tables de correspondance
INSERT INTO gn_meta.cor_acquisition_framework_voletsinp (id_acquisition_framework, id_nomenclature_voletsinp) VALUES
((SELECT id_acquisition_framework FROM gn_meta.t_acquisition_frameworks WHERE unique_acquisition_framework_id='57b7d0f2-4183-4b7b-8f08-6e105d476dc5')
,ref_nomenclatures.get_id_nomenclature('VOLET_SINP', '1'))
;

INSERT INTO gn_meta.cor_acquisition_framework_objectif (id_acquisition_framework, id_nomenclature_objectif) VALUES
((SELECT id_acquisition_framework FROM gn_meta.t_acquisition_frameworks WHERE unique_acquisition_framework_id='57b7d0f2-4183-4b7b-8f08-6e105d476dc5')
, ref_nomenclatures.get_id_nomenclature('CA_OBJECTIFS', '8'))
;

INSERT INTO gn_meta.cor_acquisition_framework_actor (id_acquisition_framework, id_role, id_organism, id_nomenclature_actor_role) VALUES
(
    (SELECT id_acquisition_framework FROM gn_meta.t_acquisition_frameworks WHERE unique_acquisition_framework_id='57b7d0f2-4183-4b7b-8f08-6e105d476dc5'),
    NULL,
    (SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'ma structure test'),
    ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '1')
),(
    (SELECT id_acquisition_framework FROM gn_meta.t_acquisition_frameworks WHERE unique_acquisition_framework_id='57b7d0f2-4183-4b7b-8f08-6e105d476dc5'),
    NULL,
    (SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'ma structure test'),
    ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '6')
),(
    (SELECT id_acquisition_framework FROM gn_meta.t_acquisition_frameworks WHERE unique_acquisition_framework_id='57b7d0f2-4183-4b7b-8f08-6e105d476dc5'),
    NULL,
    (SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'ma structure test'),
    ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '8')
);

INSERT INTO gn_meta.cor_dataset_actor (id_dataset, id_role, id_organism, id_nomenclature_actor_role) VALUES
(
    (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id='4d331cae-65e4-4948-b0b2-a11bc5bb46c2'),
    NULL,
    (SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'ma structure test'),
    ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '1')
),(
    (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id='4d331cae-65e4-4948-b0b2-a11bc5bb46c2'),
    NULL,
    (SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'ma structure test'),
    ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '6')
),(
    (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id='4d331cae-65e4-4948-b0b2-a11bc5bb46c2'),
    (SELECT id_role FROM utilisateurs.t_roles WHERE identifiant='partenaire'),
    NULL,
    ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '8')
),(
    (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id='dadab32d-5f9e-4dba-aa1f-c06487d536e8'),
    NULL,
    (SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'ma structure test'),
    ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '1')
),(
    (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id='dadab32d-5f9e-4dba-aa1f-c06487d536e8'),
    NULL,
    (SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'ma structure test'),
    ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '6')
),(
    (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id='dadab32d-5f9e-4dba-aa1f-c06487d536e8'),
    (SELECT id_role FROM utilisateurs.t_roles WHERE identifiant='partenaire'),
    NULL,
    ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '8')
),(
    (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id='dadab32d-5f9e-4dba-aa1f-c06487d536e8'),
    (SELECT id_role FROM utilisateurs.t_roles WHERE identifiant='agent'),
    NULL,
    ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '5')
),(
    (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id='4d331cae-65e4-4948-b0b2-a11bc5bb46c2'),
    NULL,
    (SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'Autre'),
    ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '6')
),(
    (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id='dadab32d-5f9e-4dba-aa1f-c06487d536e8'),
    NULL,
    (SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'Autre'),
    ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '6')
),(    
    (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id='ac55a073-222a-4acc-8ac7-2b1f622018b2'),
    NULL,
    (SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'ma structure test'),
    ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '1'))
;

INSERT INTO gn_meta.cor_dataset_territory (id_dataset, id_nomenclature_territory, territory_desc) VALUES
(
    (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id='4d331cae-65e4-4948-b0b2-a11bc5bb46c2'),
    ref_nomenclatures.get_id_nomenclature('TERRITOIRE', 'METROP'),
    'Territoire du parc national des Ecrins et de ses environs immédiats'
),(
    (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id='dadab32d-5f9e-4dba-aa1f-c06487d536e8'),
    ref_nomenclatures.get_id_nomenclature('TERRITOIRE', 'METROP'),
    'Réserve intégrale de lauvitel'
);

INSERT INTO gn_meta.cor_dataset_protocol (id_dataset, id_protocol) VALUES
(
    (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id='4d331cae-65e4-4948-b0b2-a11bc5bb46c2'),
    (SELECT id_protocol FROM gn_meta.sinp_datatype_protocols WHERE protocol_name='hors protocole')
),(
    (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id='dadab32d-5f9e-4dba-aa1f-c06487d536e8'),
    (SELECT id_protocol FROM gn_meta.sinp_datatype_protocols WHERE protocol_name='hors protocole')
);

-- Insérer 3 relevés d'exemple dans Occtax

INSERT INTO pr_occtax.t_releves_occtax (
  unique_id_sinp_grp,
  id_module,
  id_dataset,
  id_digitiser,
  id_nomenclature_tech_collect_campanule,
  id_nomenclature_grp_typ,
  id_nomenclature_geo_object_nature,
  date_min,
  date_max,
  hour_min,
  hour_max,
  altitude_min,
  altitude_max,
  meta_device_entry,
  comment,
  geom_local,
  geom_4326,
  precision
  ) VALUES (
      '4f784326-2511-11ec-9fdd-23b0fb947058',
      (SELECT id_module FROM gn_commons.t_modules WHERE module_code='OCCTAX'),
      (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id='4d331cae-65e4-4948-b0b2-a11bc5bb46c2'),
      (SELECT id_role from utilisateurs.t_roles WHERE identifiant='admin'),
      ref_nomenclatures.get_id_nomenclature('TECHNIQUE_OBS', '133'),
      ref_nomenclatures.get_id_nomenclature('TYP_GRP','OBS'),
      ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO','In'), -- ?
      '2017-01-01',
      '2017-01-01',
      '12:05:02',
      '12:05:02',
      1500,
      1565,
      'web',
      'Exemple test',
      '01010000206A0800002E988D737BCC2D41ECFA38A659805841',
      '0101000020E61000000000000000001A40CDCCCCCCCC6C4640',
      10
),(
      '4fa06f7c-2511-11ec-93a1-eb4838107091',
       (SELECT id_module FROM gn_commons.t_modules WHERE module_code='OCCTAX'),
      (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id='4d331cae-65e4-4948-b0b2-a11bc5bb46c2'),
      1,
      ref_nomenclatures.get_id_nomenclature('TECHNIQUE_OBS', '133'),
      ref_nomenclatures.get_id_nomenclature('TYP_GRP', 'OBS'),
      ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO','In'), -- ?
      '2017-01-08',
      '2017-01-08',
      '20:00:00',
      '23:00:00',
      1600,
      1600,
      'web',
      'Autre exemple test',
      '01010000206A0800002E988D737BCC2D41ECFA38A659805841',
      '0101000020E61000000000000000001A40CDCCCCCCCC6C4640',
      100
  ),
  (
      '297106a0-4dad-4d44-ae59-2e44a419e11f',
       (SELECT id_module FROM gn_commons.t_modules WHERE module_code='OCCTAX_DS'),
      (SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id='ac55a073-222a-4acc-8ac7-2b1f622018b2'),
      1,
      ref_nomenclatures.get_id_nomenclature('TECHNIQUE_OBS', '133'),
      ref_nomenclatures.get_id_nomenclature('TYP_GRP', 'OBS'),
      ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO','In'), -- ?
      '2017-01-08',
      '2017-01-08',
      '20:00:00',
      '23:00:00',
      1600,
      1600,
      'web',
      'Autre exemple test',
      '01010000206A0800002E988D737BCC2D41ECFA38A659805841',
      '0101000020E61000000000000000001A40CDCCCCCCCC6C4640',
      100
  )
  ;

-- Insérer 4 occurrences dans les 3 relevés Occtax

INSERT INTO pr_occtax.t_occurrences_occtax  (
    unique_id_occurence_occtax,
    id_releve_occtax,
    id_nomenclature_obs_technique,
    id_nomenclature_bio_condition,
    id_nomenclature_bio_status,
    id_nomenclature_naturalness,
    id_nomenclature_exist_proof,
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
    'f303683c-2510-11ec-b93a-67b44043fe7d',
    (SELECT id_releve_occtax FROM pr_occtax.t_releves_occtax WHERE unique_id_sinp_grp='4f784326-2511-11ec-9fdd-23b0fb947058'),
    ref_nomenclatures.get_id_nomenclature('METH_OBS', '23'),
    ref_nomenclatures.get_id_nomenclature('ETA_BIO', '1'),
    ref_nomenclatures.get_id_nomenclature('STATUT_BIO', '1'),
    ref_nomenclatures.get_id_nomenclature('NATURALITE', '1'),
    ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST', '0'),
    --ref_nomenclatures.get_id_nomenclature('NIV_PRECIS', '0'),
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
    'fb106f34-2510-11ec-a3ff-6fb52354595c',
    (SELECT id_releve_occtax FROM pr_occtax.t_releves_occtax WHERE unique_id_sinp_grp='4f784326-2511-11ec-9fdd-23b0fb947058'),
    ref_nomenclatures.get_id_nomenclature('METH_OBS', '23'),
    ref_nomenclatures.get_id_nomenclature('ETA_BIO', '1'),
    ref_nomenclatures.get_id_nomenclature('STATUT_BIO', '1') ,
    ref_nomenclatures.get_id_nomenclature('NATURALITE', '1'),
    ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST', '0'),
    --ref_nomenclatures.get_id_nomenclature('NIV_PRECIS', '0'),
    ref_nomenclatures.get_id_nomenclature('STATUT_OBS', 'Pr'),
    ref_nomenclatures.get_id_nomenclature('DEE_FLOU', 'NON'),
    'Théo',
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
    'fcdf2c24-2510-11ec-9995-fb27008e2817',
    (SELECT id_releve_occtax FROM pr_occtax.t_releves_occtax WHERE unique_id_sinp_grp='4fa06f7c-2511-11ec-93a1-eb4838107091'),
    ref_nomenclatures.get_id_nomenclature('METH_OBS', '23'),
    ref_nomenclatures.get_id_nomenclature('ETA_BIO', '1'),
    ref_nomenclatures.get_id_nomenclature('STATUT_BIO', '1'),
    ref_nomenclatures.get_id_nomenclature('NATURALITE', '1'),
    ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST', '0'),
    --ref_nomenclatures.get_id_nomenclature('NIV_PRECIS', '0'),
    ref_nomenclatures.get_id_nomenclature('STATUT_OBS', 'Pr'),
    ref_nomenclatures.get_id_nomenclature('DEE_FLOU', 'NON'),
  'Donovan',
  ref_nomenclatures.get_id_nomenclature('METH_DETERMIN', '2'),
  67111,
  'Ablette',
  'Taxref V11.0',
  '',
  '',
  'Poils de plumes',
  'Troisieme test'
  ),
  (
    '8db83b16-3d88-4af3-85ca-44464daf32c0',
    (SELECT id_releve_occtax FROM pr_occtax.t_releves_occtax WHERE unique_id_sinp_grp='297106a0-4dad-4d44-ae59-2e44a419e11f'),
    ref_nomenclatures.get_id_nomenclature('METH_OBS', '23'),
    ref_nomenclatures.get_id_nomenclature('ETA_BIO', '1'),
    ref_nomenclatures.get_id_nomenclature('STATUT_BIO', '1'),
    ref_nomenclatures.get_id_nomenclature('NATURALITE', '1'),
    ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST', '0'),
    --ref_nomenclatures.get_id_nomenclature('NIV_PRECIS', '0'),
    ref_nomenclatures.get_id_nomenclature('STATUT_OBS', 'Pr'),
    ref_nomenclatures.get_id_nomenclature('DEE_FLOU', 'NON'),
  'Donovan',
  ref_nomenclatures.get_id_nomenclature('METH_DETERMIN', '2'),
  67111,
  'Ablette',
  'Taxref V11.0',
  '',
  '',
  'Poils de plumes',
  'Troisieme test'
  )
  ;

-- Insérer 1 observateur pour chacun des 3 relevés Occtax

INSERT INTO pr_occtax.cor_role_releves_occtax (id_releve_occtax, id_role) VALUES
(
    (SELECT id_releve_occtax FROM pr_occtax.t_releves_occtax WHERE unique_id_sinp_grp='4f784326-2511-11ec-9fdd-23b0fb947058'),
    (SELECT id_role from utilisateurs.t_roles WHERE identifiant='admin')
),(
    (SELECT id_releve_occtax FROM pr_occtax.t_releves_occtax WHERE unique_id_sinp_grp='4fa06f7c-2511-11ec-93a1-eb4838107091'),
    (SELECT id_role from utilisateurs.t_roles WHERE identifiant='admin')
),(
    (SELECT id_releve_occtax FROM pr_occtax.t_releves_occtax WHERE unique_id_sinp_grp='297106a0-4dad-4d44-ae59-2e44a419e11f'),
    (SELECT id_role from utilisateurs.t_roles WHERE identifiant='admin')
);

-- Insérer 4 dénombrements dans les 4 occurrences

INSERT INTO  pr_occtax.cor_counting_occtax (
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
    (SELECT id_occurrence_occtax FROM pr_occtax.t_occurrences_occtax WHERE unique_id_occurence_occtax='f303683c-2510-11ec-b93a-67b44043fe7d'),
    ref_nomenclatures.get_id_nomenclature('STADE_VIE', '2') ,
    ref_nomenclatures.get_id_nomenclature('SEXE', '2') ,
    ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', 'IND'),
    ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'Co'),
    5,
    5
  ),
  (
    (SELECT id_occurrence_occtax FROM pr_occtax.t_occurrences_occtax WHERE unique_id_occurence_occtax='fb106f34-2510-11ec-a3ff-6fb52354595c'),
    ref_nomenclatures.get_id_nomenclature('STADE_VIE', '4') ,
    ref_nomenclatures.get_id_nomenclature('SEXE', '2'),
    ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', 'IND'),
    ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'Co'),
    1,
    1
  ),
  (
    (SELECT id_occurrence_occtax FROM pr_occtax.t_occurrences_occtax WHERE unique_id_occurence_occtax='fcdf2c24-2510-11ec-9995-fb27008e2817'),
    ref_nomenclatures.get_id_nomenclature('STADE_VIE', '3') ,
    ref_nomenclatures.get_id_nomenclature('SEXE', '2'),
    ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', 'IND'),
    ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'Co'),
    1,
    1
  ),
    (
    (SELECT id_occurrence_occtax FROM pr_occtax.t_occurrences_occtax WHERE unique_id_occurence_occtax='8db83b16-3d88-4af3-85ca-44464daf32c0'),
    ref_nomenclatures.get_id_nomenclature('STADE_VIE', '2') ,
    ref_nomenclatures.get_id_nomenclature('SEXE', '2') ,
    ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', 'IND'),
    ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'Co'),
    5,
    5
  )
;
