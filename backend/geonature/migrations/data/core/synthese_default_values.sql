-- Compléments du schéma "gn_synthese" en version 2.7.5
-- A partir de la version 2.8.0, les évolutions de la BDD sont gérées dans des migrations Alembic

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = gn_synthese, public, pg_catalog;

INSERT INTO defaults_nomenclatures_value (mnemonique_type, id_organism, regne, group2_inpn, id_nomenclature) VALUES
('TYP_INF_GEO',(SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'ALL'),0,0,ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO','1'))
,('NAT_OBJ_GEO',(SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'ALL'),0,0,ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO','NSP'))
,('METH_OBS',(SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'ALL'),0,0,ref_nomenclatures.get_id_nomenclature('METH_OBS','21'))
,('ETA_BIO',(SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'ALL'),0,0,ref_nomenclatures.get_id_nomenclature('ETA_BIO','1'))
,('STATUT_BIO',(SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'ALL'),0,0,ref_nomenclatures.get_id_nomenclature('STATUT_BIO','1'))
,('NATURALITE',(SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'ALL'),0,0,ref_nomenclatures.get_id_nomenclature('NATURALITE','0'))
,('PREUVE_EXIST',(SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'ALL'),0,0,ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST','0'))
,('STATUT_VALID',(SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'ALL'),0,0,ref_nomenclatures.get_id_nomenclature('STATUT_VALID','0'))
,('STADE_VIE',(SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'ALL'),0,0,ref_nomenclatures.get_id_nomenclature('STADE_VIE','0'))
,('SEXE',(SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'ALL'),0,0,ref_nomenclatures.get_id_nomenclature('SEXE','6'))
,('OBJ_DENBR',(SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'ALL'),0,0,ref_nomenclatures.get_id_nomenclature('OBJ_DENBR','NSP'))
,('TYP_DENBR',(SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'ALL'),0,0,ref_nomenclatures.get_id_nomenclature('TYP_DENBR','NSP'))
,('STATUT_OBS',(SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'ALL'),0,0,ref_nomenclatures.get_id_nomenclature('STATUT_OBS','Pr'))
,('DEE_FLOU',(SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'ALL'),0,0,ref_nomenclatures.get_id_nomenclature('DEE_FLOU','NON'))
,('TYP_GRP',(SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'ALL'),0,0,ref_nomenclatures.get_id_nomenclature('TYP_GRP','NSP'))
,('TECHNIQUE_OBS',(SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'ALL'),0,0,ref_nomenclatures.get_id_nomenclature('TECHNIQUE_OBS','133'))
,('STATUT_SOURCE',(SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'ALL'),0,0,ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE','NSP'))
,('METH_DETERMIN',(SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'ALL'),0,0,ref_nomenclatures.get_id_nomenclature('METH_DETERMIN','1'))
,('OCC_COMPORTEMENT',(SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'ALL'),0,0, ref_nomenclatures.get_id_nomenclature('OCC_COMPORTEMENT', '0'))
,('STAT_BIOGEO',(SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'ALL'),0,0, ref_nomenclatures.get_id_nomenclature('STAT_BIOGEO', '1'))
;
