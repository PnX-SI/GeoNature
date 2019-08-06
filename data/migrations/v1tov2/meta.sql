---------------
--SCHEMA META--
---------------

--le schema "meta" est importé dans le script create_v1_compat

------------
--PROTOCOLES
------------
DELETE FROM gn_meta.sinp_datatype_protocols WHERE id_protocol > 0;
INSERT INTO gn_meta.sinp_datatype_protocols (
  id_protocol,
  protocol_name,
  protocol_desc,
  id_nomenclature_protocol_type
)
SELECT 
  id_protocole,
  nom_protocole,
  'Question : ' || COALESCE(question,'none') || ' - ' || 
    'Objectifs : ' || COALESCE(objectifs,'none') || ' - ' || 
    'Méthode : ' || COALESCE(methode,'none') || ' - ' ||  
    'Avancement : ' || COALESCE(avancement,'none') || ' - ' ||  
    'Date_debut : ' || COALESCE(date_debut,'1000-01-01') || ' - ' ||  
    'Date_fin : ' || COALESCE(date_fin, '3000-01-01')
    AS protocol_desc,
  ref_nomenclatures.get_id_nomenclature('TYPE_PROTOCOLE','1') AS id_nomenclature_protocol_type
FROM v1_compat.t_protocoles p
WHERE nom_protocole IS NOT NULL
AND id_protocole <> 0;
--AND id_protocole IN (SELECT DISTINCT id_protocole FROM v1_compat.vm_syntheseff);
SELECT setval('gn_meta.sinp_datatype_protocols_id_protocol_seq', (SELECT max(id_protocol)+1 FROM gn_meta.sinp_datatype_protocols), true);


--------------------------------------------
--CADRE D'ACQUISITION (V2) = PROGRAMMES (V1)
--------------------------------------------
TRUNCATE gn_meta.t_acquisition_frameworks CASCADE;
INSERT INTO gn_meta.t_acquisition_frameworks (
  id_acquisition_framework,
  acquisition_framework_name,
  acquisition_framework_desc,
  id_nomenclature_territorial_level,
  territory_desc,
  id_nomenclature_financing_type,
  is_parent,
  acquisition_framework_start_date
)
SELECT DISTINCT
  p.id_programme,
  nom_programme,
  desc_programme,
  ref_nomenclatures.get_id_nomenclature('NIVEAU_TERRITORIAL','4') AS id_nomenclature_territorial_level,
  'Territoire du parc national des Ecrins' AS territory_desc,
  ref_nomenclatures.get_id_nomenclature('TYPE_FINANCEMENT','1') AS id_nomenclature_financing_type,
  false AS is_parent,
  '1000-01-01'::date AS acquisition_framework_start_date
FROM v1_compat.bib_programmes p
JOIN v1_compat.bib_lots l ON l.id_programme = p.id_programme;
--AND l.id_lot IN (SELECT DISTINCT id_lot FROM v1_compat.vm_syntheseff);

SELECT setval('gn_meta.t_acquisition_frameworks_id_acquisition_framework_seq', (SELECT max(id_acquisition_framework)+1 FROM gn_meta.t_acquisition_frameworks), true);

--recréation du cadre d'acquisition tous règnes confondus
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
    'Données d''observation de la faune, de la Flore et de la fonge du Parc national des Ecrins',
    'Données d''observation de la faune, de la Flore et de la fonge du Parc national des Ecrins',
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
    )
;

---------------------------
--DATASETS (v2) - LOTS (V1)
---------------------------
TRUNCATE gn_meta.t_datasets CASCADE;
INSERT INTO gn_meta.t_datasets (
  id_dataset,
  id_acquisition_framework,
  dataset_name,
  dataset_shortname,
  dataset_desc,
  id_nomenclature_data_type,
  marine_domain,
  terrestrial_domain,
  id_nomenclature_dataset_objectif,
  id_nomenclature_collecting_method,
  id_nomenclature_data_origin,
  id_nomenclature_source_status,
  id_nomenclature_resource_type
)
SELECT DISTINCT
  id_lot,
  id_programme,
  nom_lot,
  nom_lot,
  desc_lot,
  ref_nomenclatures.get_id_nomenclature('DATA_TYP','1') AS id_nomenclature_data_type, --nomenclature 103 = "donnée source"
  false AS marine_domain,
  true AS terrestrial_domain,
  ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS','1.1') AS id_nomenclature_dataset_objectif, --nomenclature 114 à reprendre lot par lot
  ref_nomenclatures.get_id_nomenclature('METHO_RECUEIL','1') AS id_nomenclature_collecting_method, --nomenclature 115 = "Observation directe : Vue, écoute, olfactive, tactile"
  ref_nomenclatures.get_id_nomenclature('DS_PUBLIQUE','Pu') AS id_nomenclature_data_origin, --nomenclature 2 à reprendre lot par lot
  ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE','Te') AS id_nomenclature_source_status, --nomenclature 19 à reprendre lot par lot
  ref_nomenclatures.get_id_nomenclature('RESOURCE_TYP','1') AS id_nomenclature_resource_type --nomenclature 102 = "jeu de données"
FROM v1_compat.bib_lots;
--WHERE id_lot NOT IN (SELECT DISTINCT id_lot FROM v1_compat.vm_syntheseff);
SELECT setval('gn_meta.t_datasets_id_dataset_seq', (SELECT max(id_dataset)+1 FROM gn_meta.t_datasets), true);

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
    validable,
    meta_create_date,
    meta_update_date
    )
    VALUES
    (
    uuid_generate_v4(),
     (SELECT id_acquisition_framework FROM gn_meta.t_acquisition_frameworks WHERE unique_acquisition_framework_id='57b7d0f2-4183-4b7b-8f08-6e105d476dc5'),
    'Mobile V1 vers occtax - contacts aléatoires tous règnes confondus',
    'Mobile V1 vers occtax',
    'Observations aléatoires de la faune, de la flore ou de la fonge issues des applications mobile V1 et transrites par la webapi dans occtax',
    ref_nomenclatures.get_id_nomenclature('DATA_TYP', '1'),
    'Aléatoire, hors protocole, faune, flore, fonge, V1, mobile',
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
    now(),
    null
    ),
    (
    uuid_generate_v4(),
     (SELECT id_acquisition_framework FROM gn_meta.t_acquisition_frameworks WHERE unique_acquisition_framework_id='57b7d0f2-4183-4b7b-8f08-6e105d476dc5'),
    'Occtax - contacts aléatoires tous règnes confondus',
    'Occtax',
    'Observations aléatoires de la faune, de la flore ou de la fonge issues des saisies web occtax ou mobile V2',
    ref_nomenclatures.get_id_nomenclature('DATA_TYP', '1'),
    'Aléatoire, hors protocole, faune, flore, fonge, V2, occtax',
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
    now(),
    null
    )
;


UPDATE gn_meta.t_datasets SET active = false;
UPDATE gn_meta.t_datasets SET active = true WHERE id_dataset IN(4,14,15);
UPDATE gn_meta.t_datasets SET active = true WHERE dataset_shortname IN('Occtax','Mobile V1 vers occtax');
