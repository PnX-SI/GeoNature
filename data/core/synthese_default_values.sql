SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = gn_synthese, public, pg_catalog;

INSERT INTO defaults_nomenclatures_value (mnemonique_type, id_organism, regne, group2_inpn, id_nomenclature) VALUES
('TYP_INF_GEO',0,0,0,ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO','1'))
,('NAT_OBJ_GEO',0,0,0,ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO','NSP'))
,('METH_OBS',0,0,0,ref_nomenclatures.get_id_nomenclature('METH_OBS','21'))
,('ETA_BIO',0,0,0,ref_nomenclatures.get_id_nomenclature('ETA_BIO','1'))
,('STATUT_BIO',0,0,0,ref_nomenclatures.get_id_nomenclature('STATUT_BIO','1'))
,('NATURALITE',0,0,0,ref_nomenclatures.get_id_nomenclature('NATURALITE','0'))
,('PREUVE_EXIST',0,0,0,ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST','0'))
,('STATUT_VALID',0,0,0,ref_nomenclatures.get_id_nomenclature('STATUT_VALID','2'))
,('STADE_VIE',0,0,0,ref_nomenclatures.get_id_nomenclature('STADE_VIE','0'))
,('SEXE',0,0,0,ref_nomenclatures.get_id_nomenclature('SEXE','6'))
,('OBJ_DENBR',0,0,0,ref_nomenclatures.get_id_nomenclature('OBJ_DENBR','NSP'))
,('TYP_DENBR',0,0,0,ref_nomenclatures.get_id_nomenclature('TYP_DENBR','NSP'))
,('STATUT_OBS',0,0,0,ref_nomenclatures.get_id_nomenclature('STATUT_OBS','NSP'))
,('DEE_FLOU',0,0,0,ref_nomenclatures.get_id_nomenclature('DEE_FLOU','NON'))
,('TYP_GRP',0,0,0,ref_nomenclatures.get_id_nomenclature('TYP_GRP','NSP'))
,('TECHNIQUE_OBS',0,0,0,ref_nomenclatures.get_id_nomenclature('TECHNIQUE_OBS','133'))
,('SENSIBILITE',0,0,0,ref_nomenclatures.get_id_nomenclature('SENSIBILITE','0'))
,('STATUT_SOURCE',0,0,0,ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE','NSP'))
,('METH_DETERMIN',0,0,0,ref_nomenclatures.get_id_nomenclature('METH_DETERMIN','1'))
;
