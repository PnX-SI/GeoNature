-------------------------
--CADRE D'ACQUISITION PNE
-------------------------
--Mise à jour du niveau territorial
UPDATE gn_meta.t_acquisition_frameworks SET id_nomenclature_territorial_level = ref_nomenclatures.get_id_nomenclature('NIVEAU_TERRITORIAL','1') WHERE id_acquisition_framework IN (3,19);
UPDATE gn_meta.t_acquisition_frameworks SET id_nomenclature_territorial_level = ref_nomenclatures.get_id_nomenclature('NIVEAU_TERRITORIAL','2') WHERE id_acquisition_framework = 8;
UPDATE gn_meta.t_acquisition_frameworks SET id_nomenclature_territorial_level = ref_nomenclatures.get_id_nomenclature('NIVEAU_TERRITORIAL','3') WHERE id_acquisition_framework IN (13,17,9,10) ;
UPDATE gn_meta.t_acquisition_frameworks SET id_nomenclature_territorial_level = ref_nomenclatures.get_id_nomenclature('NIVEAU_TERRITORIAL','6') WHERE id_acquisition_framework = 111;

--mise à jour du type de financement
UPDATE gn_meta.t_acquisition_frameworks SET id_nomenclature_financing_type = ref_nomenclatures.get_id_nomenclature('TYPE_FINANCEMENT','2') WHERE id_acquisition_framework = 111;
UPDATE gn_meta.t_acquisition_frameworks SET id_nomenclature_financing_type = ref_nomenclatures.get_id_nomenclature('TYPE_FINANCEMENT','4') WHERE id_acquisition_framework = 16;
SELECT setval('gn_meta.t_acquisition_frameworks_id_acquisition_framework_seq', (SELECT max(id_acquisition_framework)+1 FROM gn_meta.t_acquisition_frameworks), true);


-------------
--DATASET PNE
-------------

--PNE : id_nomenclature_dataset_objectif
UPDATE gn_meta.t_datasets SET id_nomenclature_dataset_objectif = ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS','1.2') WHERE id_dataset IN (104,108); --"Inventaire pour étude d’espèces ou de communautés"
UPDATE gn_meta.t_datasets SET id_nomenclature_dataset_objectif = ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS','1.3') WHERE id_dataset IN (5,6,21,105); --"Inventaire pour étude d’espèces ou de communautés"
UPDATE gn_meta.t_datasets SET id_nomenclature_dataset_objectif = ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS','1.5') WHERE id_dataset IN (8,43); --"Numérisation de bibliographie"
UPDATE gn_meta.t_datasets SET id_nomenclature_dataset_objectif = ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS','5.2') WHERE id_dataset IN (9,10,11,16,18,19,20); --"Surveillance temporelle d'espèces"
UPDATE gn_meta.t_datasets SET id_nomenclature_dataset_objectif = ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS','5.3') WHERE id_dataset IN (17); --"Surveillance temporelle d'espèces"
UPDATE gn_meta.t_datasets SET id_nomenclature_dataset_objectif = ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS','7.1') WHERE id_dataset IN (47,107,111); --"Inventaires généralisés & exploration""
UPDATE gn_meta.t_datasets SET id_nomenclature_dataset_objectif = ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS','3.1') WHERE id_dataset IN (200,63,69,72,74,77,78,79,82,83,84); --"Inventaires généralisés & exploration""
UPDATE gn_meta.t_datasets SET id_nomenclature_dataset_objectif = ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS','3.2') WHERE id_dataset IN (76, 86); --"Inventaires dans site natura 200 ou zone à interet""
UPDATE gn_meta.t_datasets SET id_nomenclature_dataset_objectif = ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS','3.5') WHERE id_dataset IN (44); --"Inventaires généralisés & exploration""
UPDATE gn_meta.t_datasets SET id_nomenclature_dataset_objectif = ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS','3.5') WHERE id_dataset >= 25 AND id_dataset <= 42; --"Inventaires généralisés & exploration""
UPDATE gn_meta.t_datasets SET id_nomenclature_dataset_objectif = ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS','3.5') WHERE id_dataset >= 48 AND id_dataset <= 58; --"Inventaires généralisés & exploration""
UPDATE gn_meta.t_datasets SET id_nomenclature_dataset_objectif = ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS','3.5') WHERE id_dataset IN (60,61,62,64,65,80,88,89); --"Inventaires généralisés & exploration""
--PNE : id_nomenclature_collecting_method ; Même si les jeux de données peuvent comporter des méthodes de collectes mixtes, tous les lots sont considérés comme "Observation directe : Vue, écoute, olfactive, tactile"
--PNE : id_nomenclature_data_origin (données privées, publiques)
UPDATE gn_meta.t_datasets SET id_nomenclature_data_origin = ref_nomenclatures.get_id_nomenclature('DS_PUBLIQUE','Pr') WHERE id_dataset IN (13,23,24,47,73,111); --"Privés"
UPDATE gn_meta.t_datasets SET id_nomenclature_data_origin = ref_nomenclatures.get_id_nomenclature('DS_PUBLIQUE','NSP') WHERE id_dataset IN (43,85); --"Ne sait pas"

--PNE : id_nomenclature_source_status
UPDATE gn_meta.t_datasets SET id_nomenclature_source_status = ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE','Li') WHERE id_dataset IN (8,43); --"Littérature : l'observation a été extraite d'un article ou un ouvrage scientifique."


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
,(14, NULL, 99, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','5'))
,(16, NULL, 99, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','5'))
,(12, NULL, 99, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','5'));

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
