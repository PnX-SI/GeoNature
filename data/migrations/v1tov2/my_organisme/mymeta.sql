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
UPDATE gn_meta.t_datasets SET id_nomenclature_dataset_objectif = ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS','3.5') WHERE IN (60,61,62,64,65,80,88,89); --"Inventaires généralisés & exploration""
--PNE : id_nomenclature_collecting_method ; Même si les jeux de données peuvent comporter des méthodes de collectes mixtes, tous les lots sont considérés comme "Observation directe : Vue, écoute, olfactive, tactile"
--PNE : id_nomenclature_data_origin (données privées, publiques)
UPDATE gn_meta.t_datasets SET id_nomenclature_data_origin = ref_nomenclatures.get_id_nomenclature('DS_PUBLIQUE','Pr') WHERE id_dataset IN (13,23,24,47,73,111); --"Privés"
UPDATE gn_meta.t_datasets SET id_nomenclature_data_origin = ref_nomenclatures.get_id_nomenclature('DS_PUBLIQUE','NSP') WHERE id_dataset IN (43,85); --"Ne sait pas"

--PNE : id_nomenclature_source_status
UPDATE gn_meta.t_datasets SET id_nomenclature_source_status = ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE','Li') WHERE id_dataset IN (8,43); --"Littérature : l'observation a été extraite d'un article ou un ouvrage scientifique."
