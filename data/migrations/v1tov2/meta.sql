---------------
--SCHEMA META--
---------------
IMPORT FOREIGN SCHEMA meta FROM SERVER geonature1server INTO v1_compat;

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
  0 AS is_parent,
  '1000-01-01'::date AS acquisition_framework_start_date
FROM v1_compat.bib_programmes p
JOIN v1_compat.bib_lots l ON l.id_programme = p.id_programme;
--AND l.id_lot IN (SELECT DISTINCT id_lot FROM v1_compat.vm_syntheseff);

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



----------------------------------------------------
--ROLE DES ACTEURS POUR LES CADRES D'ACQUISITION PNE
----------------------------------------------------
--PNE "Contact principal" : Adapter le id_organism ci-dessous
INSERT INTO gn_meta.cor_acquisition_framework_actor (id_acquisition_framework, id_role, id_organism, id_nomenclature_actor_role)
SELECT id_acquisition_framework, null AS id_role, 2 as id_organisme, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','1') AS id_nomenclature_actor_role
FROM gn_meta.t_acquisition_frameworks;
--PNE : "Point de contact base de données de production" : Adapter le id_organism ci-dessous
INSERT INTO gn_meta.cor_acquisition_framework_actor (id_acquisition_framework, id_role, id_organism, id_nomenclature_actor_role)
SELECT id_acquisition_framework, null AS id_role, 2 as id_organisme, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7') AS id_nomenclature_actor_role
FROM gn_meta.t_acquisition_frameworks;
--PNE : "Point de contact pour les métadonnées"
INSERT INTO gn_meta.cor_acquisition_framework_actor (id_acquisition_framework, id_role, id_organism, id_nomenclature_actor_role)
SELECT id_acquisition_framework, null AS id_role, 2 as id_organisme, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','8') AS id_nomenclature_actor_role
FROM gn_meta.t_acquisition_frameworks;
--PNE "Fournisseur du jeu de données"
INSERT INTO gn_meta.cor_acquisition_framework_actor (id_acquisition_framework, id_role, id_organism, id_nomenclature_actor_role) VALUES
(107, NULL, 1, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','5'))
,(14, NULL, -1, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','5'))
,(16, NULL, -1, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','5'))
,(12, NULL, -1, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','5'));

--PNE OBECTIFS SCIENTIFIQUES DES CADRES D'ACQUISITION : id_nomenclature_objectif
--"Inventaire logique espace"
INSERT INTO gn_meta.cor_acquisition_framework_objectif (id_acquisition_framework, id_nomenclature_objectif)
SELECT id_acquisition_framework, ref_nomenclatures.get_id_nomenclature('CA_OBJECTIFS','3') AS id_nomenclature_actor_role
FROM gn_meta.t_acquisition_frameworks
WHERE id_acquisition_framework IN(1,2,3,9,11,13,14,15,16,104,105,106,107,108,109,110,111,200);
--"Inventaire espèce"
INSERT INTO gn_meta.cor_acquisition_framework_objectif (id_acquisition_framework, id_nomenclature_objectif)
SELECT id_acquisition_framework, ref_nomenclatures.get_id_nomenclature('CA_OBJECTIFS','1') AS id_nomenclature_actor_role
FROM gn_meta.t_acquisition_frameworks
WHERE id_acquisition_framework IN(3,4,5,9,10,105);
--"Evolution temporelle"
INSERT INTO gn_meta.cor_acquisition_framework_objectif (id_acquisition_framework, id_nomenclature_objectif)
SELECT id_acquisition_framework, ref_nomenclatures.get_id_nomenclature('CA_OBJECTIFS','5') AS id_nomenclature_actor_role
FROM gn_meta.t_acquisition_frameworks
WHERE id_acquisition_framework IN(4,5,6,7,8,10,104);
--"Regroupements et autres études"
INSERT INTO gn_meta.cor_acquisition_framework_objectif (id_acquisition_framework, id_nomenclature_objectif)
SELECT id_acquisition_framework, ref_nomenclatures.get_id_nomenclature('CA_OBJECTIFS','7') AS id_nomenclature_actor_role
FROM gn_meta.t_acquisition_frameworks
WHERE id_acquisition_framework IN(12,14,16,107,111);

--PNE VOLET SINP : = Terre, mer, paysage ; terre pour tous les CA du PNE
DELETE FROM gn_meta.cor_acquisition_framework_voletsinp;
INSERT INTO gn_meta.cor_acquisition_framework_voletsinp (id_acquisition_framework, id_nomenclature_voletsinp)
SELECT id_acquisition_framework, ref_nomenclatures.get_id_nomenclature('VOLET_SINP','1') AS id_nomenclature_voletsinp
FROM gn_meta.t_acquisition_frameworks;

--ROLE DES ACTEURS POUR LES JEUX DE DONNEES ; 
--PNE "Contact principal" : Adapter le id_organism ci-dessous
INSERT INTO gn_meta.cor_dataset_actor (id_dataset, id_role, id_organism, id_nomenclature_actor_role)
SELECT id_dataset, null AS id_role, 2 as id_organisme, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','1') AS id_nomenclature_actor_role
FROM gn_meta.t_datasets;

--PNE "Producteur du jeu de données = PNE"
INSERT INTO gn_meta.cor_dataset_actor (id_dataset, id_role, id_organism, id_nomenclature_actor_role)
SELECT id_dataset, null AS id_role, 2 as id_organisme, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6') AS id_nomenclature_actor_role
FROM gn_meta.t_datasets
WHERE id_dataset NOT IN (13,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,107,111);
INSERT INTO gn_meta.cor_dataset_actor (id_dataset, id_role, id_organism, id_nomenclature_actor_role) VALUES
(13,507,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(24,null,1002,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(25,1140,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(26,1140,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(27,null,110,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(28,1168,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(29,1205,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(30,1206,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(31,1167,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(32,1207,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(33,1209,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(34,1207,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(35,1208,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(36,1210,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(37,1239,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(38,1241,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(39,1243,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(40,null,110,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(41,1244,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(42,1268,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(44,1269,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(45,1270,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(46,1272,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(47,null,1001,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(48,1324,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(49,null,2,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(50,null,110,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(51,1319,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(52,null,2,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(53,null,2,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(54,null,110,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(107,null,1,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(111,null,101,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
;

--PNE "Point de contact base de données de production"
INSERT INTO gn_meta.cor_dataset_actor (id_dataset, id_role, id_organism, id_nomenclature_actor_role)
SELECT id_dataset, null AS id_role, 2 as id_organisme, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7') AS id_nomenclature_actor_role
FROM gn_meta.t_datasets
WHERE id_dataset NOT IN (24,27,40,47,50,54,107,111);
INSERT INTO gn_meta.cor_dataset_actor (id_dataset, id_role, id_organism, id_nomenclature_actor_role) VALUES
(107,null,1,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
,(111,null,101,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
,(54,null,110,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
,(50,null,110,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
,(40,null,110,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
,(27,null,110,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
,(47,null,1001,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
,(24,null,1002,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
;

--PNE : "Point de contact pour les métadonnées"
INSERT INTO gn_meta.cor_dataset_actor (id_dataset, id_role, id_organism, id_nomenclature_actor_role)
SELECT id_dataset, null AS id_role, 2 as id_organisme, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','8') AS id_nomenclature_actor_role
FROM gn_meta.t_datasets;

--PNE LIEN ENTRE TERRITOIRE ET LE JEU DE DONNEES ; = Métropole
INSERT INTO gn_meta.cor_dataset_territory (id_dataset,id_nomenclature_territory, territory_desc)
SELECT id_dataset, ref_nomenclatures.get_id_nomenclature('TERRITOIRE','METROP') AS id_nomenclature_territory, 'Territoire du parc national des Ecrins et des communes environnantes' AS territory_desc
FROM gn_meta.t_datasets;

--PNE LIEN ENTRE PROCOLE ET JEU DE DONNEES : TODO, COMPLEXE ATTENTE Campanule ???
--INSERT INTO gn_meta.cor_dataset_protocol (id_dataset, id_protocol) VALUES
--(1, 140)

--PNE les publications ne sont pas traitées (notion absente dans GN1)
--gn_meta.sinp_datatype_publications & gn_meta.cor_acquisition_framework_publication
