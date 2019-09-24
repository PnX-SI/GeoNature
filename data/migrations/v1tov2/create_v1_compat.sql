INSERT INTO gn_synthese.defaults_nomenclatures_value(mnemonique_type, id_organism,regne, group2_inpn, id_nomenclature)
VALUES ('SENSIBILITE', 0, 0, 0, ref_nomenclatures.get_id_nomenclature('SENSIBILITE', '0'));

DROP SCHEMA IF EXISTS v1_compat CASCADE ;

CREATE SCHEMA v1_compat;
COMMENT ON SCHEMA v1_compat IS 'schéma contenant des objets permettant une compatibilité temporaire avec les outils mobiles de la V1';

--On importe ici les schémas V1 meta et synthese pour faire les correspondances nécessaires
IMPORT FOREIGN SCHEMA synthese FROM SERVER geonature1server INTO v1_compat;
IMPORT FOREIGN SCHEMA meta FROM SERVER geonature1server INTO v1_compat;

--SET search_path = v1_compat, public, pg_catalog;

CREATE TABLE v1_compat.cor_boolean
(
  expression character varying(25) NOT NULL,
  bool boolean NOT NULL
);

INSERT INTO v1_compat.cor_boolean VALUES('oui',true);
INSERT INTO v1_compat.cor_boolean VALUES('non',false);

CREATE TABLE v1_compat.cor_synthese_v1_to_v2 (
	pk_source integer,
	entity_source character varying(100),
	field_source character varying(50),
	entity_target character varying(100),
	field_target character varying(50),
	id_type_nomenclature_cible integer,
	id_nomenclature_cible integer,
	commentaire text,
	CONSTRAINT pk_cor_synthese_v1_to_v2 PRIMARY KEY (pk_source, entity_source, entity_target, field_target)
);
COMMENT ON TABLE v1_compat.cor_synthese_v1_to_v2 IS 'Permet de définir des correspondances entre le MCD de la V1 et celui de la V2';
COMMENT ON COLUMN v1_compat.cor_synthese_v1_to_v2.pk_source IS 'Valeur de la PK du champ de la table source pour laquelle une correspondance doit être établie';
COMMENT ON COLUMN v1_compat.cor_synthese_v1_to_v2.entity_source IS 'Table source (schema.table) utilisé pour la correspondance';
COMMENT ON COLUMN v1_compat.cor_synthese_v1_to_v2.entity_target IS 'Table cible (schema.table) utilisé pour la correspondance';
COMMENT ON COLUMN v1_compat.cor_synthese_v1_to_v2.field_source IS 'Nom du champ de la table source (schema.table) utilisé pour la correspondance';
COMMENT ON COLUMN v1_compat.cor_synthese_v1_to_v2.field_target IS 'Nom du champ de la table cible (schema.table) utilisé pour la correspondance';
COMMENT ON COLUMN v1_compat.cor_synthese_v1_to_v2.id_type_nomenclature_cible IS 'Id_type de la nomenclature sur laquelle la correspondance en V2 est établie';
COMMENT ON COLUMN v1_compat.cor_synthese_v1_to_v2.id_nomenclature_cible IS 'id de la nomenclature sur laquelle la correspondance en V2 est établie';
ALTER TABLE ONLY v1_compat.cor_synthese_v1_to_v2
    ADD CONSTRAINT fk_cor_synthese_v1_to_v2_id_type_nomenclature FOREIGN KEY (id_type_nomenclature_cible) REFERENCES ref_nomenclatures.bib_nomenclatures_types(id_type) ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE ONLY v1_compat.cor_synthese_v1_to_v2
    ADD CONSTRAINT fk_cor_synthese_v1_to_v2_t_nomenclatures FOREIGN KEY (id_nomenclature_cible) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE ON DELETE NO ACTION;

CREATE INDEX i_cor_synthese_v1_to_v2_pk_source
  ON v1_compat.cor_synthese_v1_to_v2
  USING btree
  (pk_source);
 
CREATE INDEX i_cor_synthese_v1_to_v2_id_nomenclature_cible
  ON v1_compat.cor_synthese_v1_to_v2
  USING btree
  (id_nomenclature_cible);

--On déplace l'id de la source occtax
UPDATE gn_synthese.t_sources 
SET id_source = (SELECT max(id_source)+1 FROM v1_compat.bib_sources) 
WHERE name_source = 'Occtax';
--on insert ensuite les sources de la V1
INSERT INTO gn_synthese.t_sources (
	id_source,
  name_source,
  desc_source,
  entity_source_pk_field
)
SELECT 
  id_source, 
  nom_source, 
  desc_source, 
  'historique.' || db_schema || '_' || db_table || '.' || db_field AS entity_source_pk_field
FROM v1_compat.bib_sources;
SELECT setval('gn_synthese.t_sources_id_source_seq', (SELECT max(id_source)+1 FROM gn_synthese.t_sources), true);

-----------------------------------------------
--ETABLIR LES CORESPONDANCES DE NOMENCLATURES--
-----------------------------------------------

--NATURE DE L'OBJET GEOGRAPHIQUE NAT_OBJ_GEO
--ne sait pas
INSERT INTO v1_compat.cor_synthese_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT 
    id_precision, 
    'v1_compat.t_precisions' AS entity_source, 
    'id_precision' as entity_source, 
    'gn_synthese.synthese' AS entity_target, 
    'id_nomenclature_geo_object_nature' AS field_target, 
    3 AS id_type_nomenclature_cible, 
    ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO','NSP') AS id_nomenclature_cible 
FROM v1_compat.t_precisions;
--stationnel
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO','St')
WHERE pk_source IN(1,2,3,4,10)
AND entity_source = 'v1_compat.t_precisions'
AND field_source = 'id_precision'
AND entity_target = 'gn_synthese.synthese'
AND field_target = 'id_nomenclature_geo_object_nature';
--inventoriel
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO','In')
WHERE pk_source IN(5,6,7,8,9,11,13,14)
AND entity_source = 'v1_compat.t_precisions'
AND field_source = 'id_precision'
AND entity_target = 'gn_synthese.synthese'
AND field_target = 'id_nomenclature_geo_object_nature';


--TYPE DE REGROUPEMENT TYP_GRP
--observation
INSERT INTO v1_compat.cor_synthese_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_lot, 'v1_compat.bib_lots' AS entity_source, 'id_lot' as entity_source, 'gn_synthese.synthese' AS entity_target, 'id_nomenclature_grp_typ' AS field_target, 24 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('TYP_GRP','OBS') AS id_nomenclature_cible 
FROM v1_compat.bib_lots;
--Inventaire stationnel
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('TYP_GRP','INVSTA')
WHERE pk_source IN(105)
AND entity_source = 'v1_compat.bib_lots' AND field_source = 'id_lot' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_grp_typ';
--Ne sait pas
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('TYP_GRP','NSP')
WHERE pk_source IN(111,107,47,8,24,43)
AND entity_source = 'v1_compat.bib_lots' AND field_source = 'id_lot' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_grp_typ';
--Point de prélèvement ou point d'observation.
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('TYP_GRP','POINT')
WHERE pk_source IN(9,10,17)
AND entity_source = 'v1_compat.bib_lots' AND field_source = 'id_lot' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_grp_typ';
--Passage (pour les comptages).
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('TYP_GRP','PASS')
WHERE pk_source IN(18,19,20)
AND entity_source = 'v1_compat.bib_lots' AND field_source = 'id_lot' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_grp_typ';


--METHODE d'OBSERVATION METH_OBS 
INSERT INTO v1_compat.cor_synthese_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_critere_synthese, 'v1_compat.bib_criteres_synthese' AS entity_source, 'id_critere_synthese' as entity_source, 'gn_synthese.synthese' AS entity_target, 'id_nomenclature_obs_meth' AS field_target, 14 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('METH_OBS','21') AS id_nomenclature_cible 
FROM v1_compat.bib_criteres_synthese;
--vu
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('METH_OBS','0')
WHERE pk_source IN(2,5,6,8,9,10,11,12,14,16,18,21,22,23,26,27,29,30,31,33,34,35,37,38,101,102,103,201,204,208,209,214,215,217,221,222,224,226)
AND entity_source = 'v1_compat.bib_criteres_synthese' AND field_source = 'id_critere_synthese' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_obs_meth';
--Entendu
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('METH_OBS','1')
WHERE pk_source IN(4,7,207)
AND entity_source = 'v1_compat.bib_criteres_synthese' AND field_source = 'id_critere_synthese' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_obs_meth';
--Empreintes
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('METH_OBS','4')
WHERE pk_source IN(3,219)
AND entity_source = 'v1_compat.bib_criteres_synthese' AND field_source = 'id_critere_synthese' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_obs_meth';
--"Fèces/Guano/Epreintes"
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('METH_OBS','6')
WHERE pk_source IN(205)
AND entity_source = 'v1_compat.bib_criteres_synthese' AND field_source = 'id_critere_synthese' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_obs_meth';
--Nid/Gîte
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('METH_OBS','8')
WHERE pk_source IN(13,15,17,19,20,216)
AND entity_source = 'v1_compat.bib_criteres_synthese' AND field_source = 'id_critere_synthese' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_obs_meth';
--Restes de repas
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('METH_OBS','12')
WHERE pk_source IN(211)
AND entity_source = 'v1_compat.bib_criteres_synthese' AND field_source = 'id_critere_synthese' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_obs_meth';
--Autres
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('METH_OBS','20')
WHERE pk_source IN(105,203,220)
AND entity_source = 'v1_compat.bib_criteres_synthese' AND field_source = 'id_critere_synthese' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_obs_meth';
--Galerie/terrier
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('METH_OBS','23')
WHERE pk_source IN(24,25)
AND entity_source = 'v1_compat.bib_criteres_synthese' AND field_source = 'id_critere_synthese' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_obs_meth';


--STATUT BIOLOGIQUE STATUT_BIO 
--non détermminé
INSERT INTO v1_compat.cor_synthese_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_critere_synthese, 'v1_compat.bib_criteres_synthese' AS entity_source, 'id_critere_synthese' as entity_source, 'gn_synthese.synthese' AS entity_target, 'id_nomenclature_bio_status' AS field_target, 13 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('STATUT_BIO','0') AS id_nomenclature_cible 
FROM v1_compat.bib_criteres_synthese;
--Reproduction
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('STATUT_BIO','3')
WHERE pk_source IN(10,11,12,13,14,15,16,17,18,19,20,21,22,23,27,28,29,31,32,33,35,36,37,101,102,204,209,215,216,221,224,226)
AND entity_source = 'v1_compat.bib_criteres_synthese' AND field_source = 'id_critere_synthese' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_bio_status';
--Hibernation
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('STATUT_BIO','4')
WHERE pk_source IN(26)
AND entity_source = 'v1_compat.bib_criteres_synthese' AND field_source = 'id_critere_synthese' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_bio_status';


--ETAT BIOLOGIQUE ETA_BIO
--vivant
INSERT INTO v1_compat.cor_synthese_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_critere_synthese, 'v1_compat.bib_criteres_synthese' AS entity_source, 'id_critere_synthese' as entity_source, 'gn_synthese.synthese' AS entity_target, 'id_nomenclature_bio_condition' AS field_target, 7 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('ETA_BIO','2') AS id_nomenclature_cible 
FROM v1_compat.bib_criteres_synthese;
--trouvé mort
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('ETA_BIO','3')
WHERE pk_source IN(2)
AND entity_source = 'v1_compat.bib_criteres_synthese' AND field_source = 'id_critere_synthese' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_bio_condition';
INSERT INTO v1_compat.cor_synthese_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_lot, 'v1_compat.bib_lots' AS entity_source, 'id_lot' as entity_source, 'gn_synthese.synthese' AS entity_target, 'id_nomenclature_bio_condition' AS field_target, 7 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('ETA_BIO','3') AS id_nomenclature_cible 
FROM v1_compat.bib_lots
WHERE id_lot IN(12,15);


--NATURALITE NATURALITE 
--sauvage
INSERT INTO v1_compat.cor_synthese_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_lot, 'v1_compat.bib_lots' AS entity_source, 'id_lot' as entity_source, 'gn_synthese.synthese' AS entity_target, 'id_nomenclature_naturalness' AS field_target, 8 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('NATURALITE','1') AS id_nomenclature_cible 
FROM v1_compat.bib_lots;
--inconnu (lot des partenaires, notamment de la LP0 PACA qui comporte des espèces férales)
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('NATURALITE','0')
WHERE pk_source IN(107,111,47,24)
AND entity_source = 'v1_compat.bib_lots' AND field_source = 'id_lot' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_naturalness';


--PREUVE D'EXISTANCE PREUVE_EXIST 
--DELETE FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 15
--non
INSERT INTO v1_compat.cor_synthese_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_source, 'v1_compat.bib_sources' AS entity_source, 'id_source' as entity_source, 'gn_synthese.synthese' AS entity_target, 'id_nomenclature_exist_proof' AS field_target, 15 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST','2') AS id_nomenclature_cible 
FROM v1_compat.bib_sources;
--inconnu (sources des partenaires)
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST','NSP')
WHERE pk_source IN(11,12,13,17,99,107,111,201,202)
AND entity_source = 'v1_compat.bib_sources' AND field_source = 'id_source' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_exist_proof';


--STATUT DE VALIDATION STATUT_VALID
--DELETE FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 101
--probable (données PNE)
INSERT INTO v1_compat.cor_synthese_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_source, 'v1_compat.bib_sources' AS entity_source, 'id_source' as entity_source, 'gn_synthese.synthese' AS entity_target, 'id_nomenclature_valid_status' AS field_target, 101 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('STATUT_VALID','2') AS id_nomenclature_cible 
FROM v1_compat.bib_sources;
--Certain - très probable (données PNE)
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('STATUT_VALID','1')
WHERE pk_source IN(11,13,16,201,202)
AND entity_source = 'v1_compat.bib_sources' AND field_source = 'id_source' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_valid_status';
--inconnu (sources des partenaires)
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('STATUT_VALID','6')
WHERE pk_source IN(12,17,111)
AND entity_source = 'v1_compat.bib_sources' AND field_source = 'id_source' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_valid_status';


--NIVEAU DE DIFFUSION NIV_PRECIS 
--DELETE FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 5
--Précises (données PNE). a affiner données par données une fois la sensibilité définie.
INSERT INTO v1_compat.cor_synthese_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_source, 'v1_compat.bib_sources' AS entity_source, 'id_source' as entity_source, 'gn_synthese.synthese' AS entity_target, 'id_nomenclature_diffusion_level' AS field_target, 5 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('NIV_PRECIS','5') AS id_nomenclature_cible 
FROM v1_compat.bib_sources;
--aucune (sources des partenaires)
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('NIV_PRECIS','4')
WHERE pk_source IN(11,12,17,111,107,201,202)
AND entity_source = 'v1_compat.bib_sources' AND field_source = 'id_source' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_diffusion_level';


--STADE DE VIE - AGE - PHENOLOGIE STADE_VIE 
--DELETE FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 10
--Non renseigné. A affiner données par données en fonction de la structuration dans les tables sources.
INSERT INTO v1_compat.cor_synthese_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_source, 'v1_compat.bib_sources' AS entity_source, 'id_source' as entity_source, 'gn_synthese.synthese' AS entity_target, 'id_nomenclature_life_stage' AS field_target, 10 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('STADE_VIE','0') AS id_nomenclature_cible 
FROM v1_compat.bib_sources;


--SEXE SEXE 
--DELETE FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 9
--Non renseigné. A affiner données par données en fonction de la scturturation dans les tables sources.
INSERT INTO v1_compat.cor_synthese_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_source, 'v1_compat.bib_sources' AS entity_source, 'id_source' as entity_source, 'gn_synthese.synthese' AS entity_target, 'id_nomenclature_sex' AS field_target, 9 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('SEXE','6') AS id_nomenclature_cible 
FROM v1_compat.bib_sources;


--OBJET DU DENOMBREMENT OBJ_DENBR 
--DELETE FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 6
--Ne sait pas. A affiner données par données en fonction de la structuration dans les tables sources.
INSERT INTO v1_compat.cor_synthese_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_source, 'v1_compat.bib_sources' AS entity_source, 'id_source' as entity_source, 'gn_synthese.synthese' AS entity_target, 'id_nomenclature_obj_count' AS field_target, 6 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('OBJ_DENBR','NSP') AS id_nomenclature_cible 
FROM v1_compat.bib_sources;
--individu (sources faune PNE)
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('OBJ_DENBR','IND')
WHERE pk_source IN(1,2,3,4,5,6,7,8,9,10,13,14,99,200)
AND entity_source = 'v1_compat.bib_sources' AND field_source = 'id_source' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_obj_count';


--TYPE DE DENOMBREMENT TYP_DENBR 
--DELETE FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 21
--Ne sait pas. Pour toutes les sources. A voir si possibilité d'affiner
INSERT INTO v1_compat.cor_synthese_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_source, 'v1_compat.bib_sources' AS entity_source, 'id_source' as entity_source, 'gn_synthese.synthese' AS entity_target, 'id_nomenclature_type_count' AS field_target, 21 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('TYP_DENBR','NSP') AS id_nomenclature_cible 
FROM v1_compat.bib_sources;


--SENSIBILITE
--A calculer ou définir au caspar cas. Mise à "NULL" en attendant


--STATUT DE L'OBSERVATION
--On n'a que des observations correspondant à de la présence dans la base PNE : id_nomenclature = 101


--FLOUTAGE
--PNE : A ma connaissance aucune donnée PNE ou partenaire n'a été dégradée : id_nomenclature_blurring = 200


--TYPE D'INFORMATION GEOGRAPHIQUE (géoréférencement ou rattachement) TYP_INF_GEO
--DELETE FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 23
--Géoréférencement.  
INSERT INTO v1_compat.cor_synthese_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_precision, 'v1_compat.t_precisions' AS entity_source, 'id_precision' as entity_source, 'gn_synthese.synthese' AS entity_target, 'id_nomenclature_info_geo_type' AS field_target, 23 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO','1') AS id_nomenclature_cible 
FROM v1_compat.t_precisions;
--rattachement
UPDATE v1_compat.cor_synthese_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO','2')
WHERE pk_source IN(5,6,7,8,9,11,13,14)
AND entity_source = 'v1_compat.t_precisions' AND field_source = 'id_precision' AND entity_target = 'gn_synthese.synthese' AND field_target = 'id_nomenclature_info_geo_type';
