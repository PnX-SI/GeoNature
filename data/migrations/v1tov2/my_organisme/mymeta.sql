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
--nommenclature id_type = 109
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
--PNE : "Producteurs"
INSERT INTO gn_meta.cor_acquisition_framework_actor (id_acquisition_framework, id_role, id_organism, id_nomenclature_actor_role)
SELECT id_acquisition_framework, null AS id_role, 2 as id_organisme, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6') AS id_nomenclature_actor_role
FROM gn_meta.t_acquisition_frameworks
WHERE id_acquisition_framework IN(1,2,3,4,5,6,7,8,9,10,11,15,104,105,106,108,109);
--PNE : "Maître d'ouvrage"
INSERT INTO gn_meta.cor_acquisition_framework_actor (id_acquisition_framework, id_role, id_organism, id_nomenclature_actor_role)
SELECT id_acquisition_framework, null AS id_role, 2 as id_organisme, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','3') AS id_nomenclature_actor_role
FROM gn_meta.t_acquisition_frameworks
WHERE id_acquisition_framework IN(13,18,200);
--PNE : "Maître d'oeuvre"
INSERT INTO gn_meta.cor_acquisition_framework_actor (id_acquisition_framework, id_role, id_organism, id_nomenclature_actor_role)
SELECT id_acquisition_framework, null AS id_role, 2 as id_organisme, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','4') AS id_nomenclature_actor_role
FROM gn_meta.t_acquisition_frameworks
WHERE id_acquisition_framework IN(17,9,10,8,3);
--PNE "Fournisseur du jeu de données"
INSERT INTO gn_meta.cor_acquisition_framework_actor (id_acquisition_framework, id_role, id_organism, id_nomenclature_actor_role) VALUES
(107, NULL, 1, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','5'))
,(107, NULL, 1, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(111, NULL, 101, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','5'))
,(111, NULL, 101, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
;
--TODO : ce travail n'a été fait que pour les organismes. Il reste à faire pour les individus.


-----------------------------------------------------
--PNE OBECTIFS SCIENTIFIQUES DES CADRES D'ACQUISITION
-----------------------------------------------------
-- id_nomenclature_objectif id_type = 108
--"Inventaire logique espace"
INSERT INTO gn_meta.cor_acquisition_framework_objectif (id_acquisition_framework, id_nomenclature_objectif)
SELECT id_acquisition_framework, ref_nomenclatures.get_id_nomenclature('CA_OBJECTIFS','3') AS id_nomenclature_actor_role
FROM gn_meta.t_acquisition_frameworks
WHERE id_acquisition_framework IN(1,2,3,9,11,13,14,15,16,17,18,104,105,106,107,108,109,110,111,200);
--"Inventaire espèce"
INSERT INTO gn_meta.cor_acquisition_framework_objectif (id_acquisition_framework, id_nomenclature_objectif)
SELECT id_acquisition_framework, ref_nomenclatures.get_id_nomenclature('CA_OBJECTIFS','1') AS id_nomenclature_actor_role
FROM gn_meta.t_acquisition_frameworks
WHERE id_acquisition_framework IN(3,4,5,9,10,19,105);
--"Evolution temporelle"
INSERT INTO gn_meta.cor_acquisition_framework_objectif (id_acquisition_framework, id_nomenclature_objectif)
SELECT id_acquisition_framework, ref_nomenclatures.get_id_nomenclature('CA_OBJECTIFS','5') AS id_nomenclature_actor_role
FROM gn_meta.t_acquisition_frameworks
WHERE id_acquisition_framework IN(4,5,6,7,8,10,104);
--"Regroupements et autres études"
INSERT INTO gn_meta.cor_acquisition_framework_objectif (id_acquisition_framework, id_nomenclature_objectif)
SELECT id_acquisition_framework, ref_nomenclatures.get_id_nomenclature('CA_OBJECTIFS','7') AS id_nomenclature_actor_role
FROM gn_meta.t_acquisition_frameworks
WHERE id_acquisition_framework IN(12,14,16,19,107,111);

-----------------------------------------
--PNE VOLET SINP DES CADRES D'ACQUISITION
-----------------------------------------
--Terre, mer, paysage ; terre pour tous les CA du PNE
DELETE FROM gn_meta.cor_acquisition_framework_voletsinp;
INSERT INTO gn_meta.cor_acquisition_framework_voletsinp (id_acquisition_framework, id_nomenclature_voletsinp)
SELECT id_acquisition_framework, ref_nomenclatures.get_id_nomenclature('VOLET_SINP','1') AS id_nomenclature_voletsinp
FROM gn_meta.t_acquisition_frameworks;


-------------------------------------------
--ROLE DES ACTEURS POUR LES JEUX DE DONNEES
-------------------------------------------
--PNE "Contact principal" : Adapter le id_organism ci-dessous
INSERT INTO gn_meta.cor_dataset_actor (id_dataset, id_role, id_organism, id_nomenclature_actor_role)
SELECT id_dataset, null AS id_role, 2 as id_organisme, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','1') AS id_nomenclature_actor_role
FROM gn_meta.t_datasets;
--PNE "Point de contact base de données de production" : Adapter le id_organism ci-dessous
INSERT INTO gn_meta.cor_dataset_actor (id_dataset, id_role, id_organism, id_nomenclature_actor_role)
SELECT id_dataset, null AS id_role, 2 as id_organisme, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7') AS id_nomenclature_actor_role
FROM gn_meta.t_datasets;
--PNE "Point de contact pour les métadonnées" : Adapter le id_organism ci-dessous
INSERT INTO gn_meta.cor_dataset_actor (id_dataset, id_role, id_organism, id_nomenclature_actor_role)
SELECT id_dataset, null AS id_role, 2 as id_organisme, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','8') AS id_nomenclature_actor_role
FROM gn_meta.t_datasets;

--PNE "Producteur du jeu de données = PNE"
INSERT INTO gn_meta.cor_dataset_actor (id_dataset, id_role, id_organism, id_nomenclature_actor_role)
SELECT id_dataset, null AS id_role, 2 as id_organisme, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6') AS id_nomenclature_actor_role
FROM gn_meta.t_datasets
WHERE id_dataset IN(1,2,3,4,5,6,7,8,9,10,11,12,14,15,16,17,18,19,20,21,22,59,65,66,76,77,78,79,84,86,88,89,104,105,106,108,109,110,112,200)
--PNE "autres producteurs"
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
,(56,1269,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(57,1360,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(58,1352,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(60,1319,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(61,1241,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(62,1352,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(63,1371,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(63,1306,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(64,1269,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(64,1272,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(65,1354,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','4'))
,(66,null,1003,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','4'))
,(67,1374,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(67,1374,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','4'))
,(68,1354,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','4'))
,(69,1374,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(69,1376,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(69,1374,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','4'))
,(70,1270,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(71,1270,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(72,1272,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(73,1278,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(75,1272,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(87,1272,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(76,1208,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(77,1296,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','5'))
,(78,null,1004,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','5'))
,(79,1168,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(80,1239,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(81,1371,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(82,1204,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(82,1374,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(83,1391,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','5'))
,(84,1391,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(85,1394,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(85,1386,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(85,1393,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(85,1396,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(85,1395,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(85,1241,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(85,1399,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(85,1397,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(85,1398,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(85,1392,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(86,1208,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(88,1239,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(89,1167,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','4'))
,(107,null,1,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
,(111,null,101,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','6'))
;

--PNE "Point de contact base de données de production"
INSERT INTO gn_meta.cor_dataset_actor (id_dataset, id_role, id_organism, id_nomenclature_actor_role)
SELECT id_dataset, null AS id_role, 2 as id_organisme, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7') AS id_nomenclature_actor_role
FROM gn_meta.t_datasets
WHERE id_dataset NOT IN (24,27,40,45,46,47,50,54,107,111);
INSERT INTO gn_meta.cor_dataset_actor (id_dataset, id_role, id_organism, id_nomenclature_actor_role) VALUES
(107,null,1,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
,(111,null,101,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
,(54,null,110,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
,(50,null,110,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
,(40,null,110,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
,(27,null,110,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
,(47,null,1001,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
,(24,null,1002,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
,(45,1270,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
,(46,1272,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
,(70,1270,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
,(71,1270,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
,(72,1272,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
,(75,1272,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
,(87,1272,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
,(73,1378,null,ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','7'))
;

--PNE : "Point de contact pour les métadonnées"
INSERT INTO gn_meta.cor_dataset_actor (id_dataset, id_role, id_organism, id_nomenclature_actor_role)
SELECT id_dataset, null AS id_role, 2 as id_organisme, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR','8') AS id_nomenclature_actor_role
FROM gn_meta.t_datasets;

--PNE LIEN ENTRE TERRITOIRE ET LE JEU DE DONNEES ; = Métropole
INSERT INTO gn_meta.cor_dataset_territory (id_dataset,id_nomenclature_territory, territory_desc)
SELECT id_dataset, ref_nomenclatures.get_id_nomenclature('TERRITOIRE','METROP') AS id_nomenclature_territory, 'Territoire du parc national des Ecrins et des communes environnantes' AS territory_desc
FROM gn_meta.t_datasets;

--PNE LIEN ENTRE PROCOLE ET JEU DE DONNEES : TODO, COMPLEXE ATTENTE Campanule ou à faire en interface par les thématiciens???
--INSERT INTO gn_meta.cor_dataset_protocol (id_dataset, id_protocol) VALUES
--(1, 140)

--PNE les publications ne sont pas traitées (notion absente dans GN1)
--gn_meta.sinp_datatype_publications & gn_meta.cor_acquisition_framework_publication
