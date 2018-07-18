SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = gn_synthese, public, pg_catalog;


---------
--DATAS--
---------
INSERT INTO defaults_nomenclatures_value (mnemonique_type, id_organism, regne, group2_inpn, cd_nomenclature) VALUES
('TYP_INF_GEO',0,0,0,'1')
,('NAT_OBJ_GEO',0,0,0,'NSP')
,('METH_OBS',0,0,0,'21')
,('ETA_BIO',0,0,0,'1')
,('STATUT_BIO',0,0,0,'1')
,('NATURALITE',0,0,0,'0')
,('PREUVE_EXIST',0,0,0,'0')
,('STATUT_VALID',0,0,0,'2')
,('NIV_PRECIS',0,0,0,'5')
,('STADE_VIE',0,0,0,'0')
,('SEXE',0,0,0,'6')
,('OBJ_DENBR',0,0,0,'NSP')
,('TYP_DENBR',0,0,0,'NSP')
,('STATUT_OBS',0,0,0,'NSP')
,('DEE_FLOU',0,0,0,'NON')
,('TYP_GRP',0,0,0,'NSP')
,('TECHNIQUE_OBS',0,0,0,'133')
,('SENSIBILITE',0,0,0,'0')
,('STATUT_SOURCE',0,0,0,'NSP')
,('METH_DETERMIN',0,0,0,'1') 
;
