--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = contactfaune, public, pg_catalog;

INSERT INTO t_fiches_cf VALUES (2, NULL, '2014-12-10', 409, 0, 409, '2014-12-11 18:00:33.561278', '2014-12-11 18:00:33.561278', false, -1, 'web', 2, 3857, 2, 2, '0101000020110F000052C7B622B3AB1A41D1F5B32AE70A5541', '01010000206A0800007C3DB396459D274140D397690E425841');
INSERT INTO t_fiches_cf VALUES (3, NULL, '2014-12-10', 2772, 0, 2772, '2014-12-11 18:00:33.569997', '2014-12-11 18:00:33.569997', false, -1, 'web', 2, 3857, 1, 1, '0101000020110F00008E467880980E254132FD37DF3C495541', '01010000206A0800008F2C3BA375162D41F6C357AEFB725841');
INSERT INTO t_fiches_cf VALUES (1, NULL, '2014-12-08', 967, 0, 967, '2014-12-11 18:00:33.570695', '2014-12-11 18:00:33.570695', false, -1, 'web', 2, 3857, 1, 1, '0101000020110F0000327AEA00FEB4184186BA592FFC105541', '01010000206A0800005A2BBC33F0E826418E2218932C465841');
INSERT INTO t_fiches_cf VALUES (4, NULL, '2014-12-11', 133, 0, 133, '2014-12-11 18:00:33.571303', '2014-12-11 18:00:33.571303', false, -1, 'web', 2, 3857, 1, 1, '0101000020110F000039575AC72A8403417EACE095539D5441', '01010000206A0800004DB1A3201282214198AFE5A021F45741');

INSERT INTO cor_role_fiche_cf VALUES (2, 1);
INSERT INTO cor_role_fiche_cf VALUES (3, 1);
INSERT INTO cor_role_fiche_cf VALUES (1, 1);
INSERT INTO cor_role_fiche_cf VALUES (4, 1);

INSERT INTO t_releves_cf VALUES (1, 1, 704, 35, 1, 0, 0, 0, 0, 0, 0, 67111, 'Ablette', 'test','qq''un', false, false, true, 1);
INSERT INTO t_releves_cf VALUES (2, 2, 704, 2, 0, 0, 0, 0, 1, 0, 0, 67111, 'Ablette', 'very bad ablette cévenole','Amandine', false, true, true, 7);
INSERT INTO t_releves_cf VALUES (3, 3, 704, 35, 1, 0, 0, 0, 0, 0, 0, 67111, 'Ablette', 'la plus haute ablette du monde c''est dans les écrins','Gil', false, false, true, 6);
INSERT INTO t_releves_cf VALUES (4, 1, 704, 36, 0, 0, 2, 0, 0, 0, 0, 67111, 'Ablette', '','déterminateur test', false, false, true, 4);
INSERT INTO t_releves_cf VALUES (5, 4, 704, 37, 0, 1, 0, 0, 0, 0, 0, 67111, 'Ablette', '','déterminateur test', false, false, true, 5);

SELECT pg_catalog.setval('t_releves_cf_gid_seq', 6, true);


SET search_path = contactinv,public, pg_catalog;

INSERT INTO t_fiches_inv VALUES (1, NULL, '2014-12-11', 11, 1525, 0, 1525, '2014-12-11 18:03:46.288976', '2014-12-11 18:03:46.303834', false, -1, 'web', 2, 3857, 3, 3, '0101000020110F00002B227945A00C19412828452BB11B5541', 0, '01010000206A0800003642BEE8C5072741DD5BFD24D74D5841');
INSERT INTO t_fiches_inv VALUES (2, NULL, '2014-12-11', 10, 1047, 0, 1047, '2014-12-11 18:04:54.159624', '2014-12-11 18:04:54.172636', false, -1, 'web', 2, 3857, 3, 3, '0101000020110F0000F2B4DBC6113F18413955881BB4035541', 0, '01010000206A08000022D826FF46BF26411D8067D4A63C5841');

INSERT INTO cor_role_fiche_inv VALUES (1, 1);
INSERT INTO cor_role_fiche_inv VALUES (2, 1);

INSERT INTO t_releves_inv VALUES (1, 1, 2804, 3, 0, 0, 1, 0, 11165, 'Coccinella septempunctata', 'test','Gil', false, false, true, 1);
INSERT INTO t_releves_inv VALUES (2, 2, 816, 8, 100, 0, 0, 0, 18437, 'Ecrevisse à pieds blancs', 'test','Amandine', false, false, true, 2);

SELECT pg_catalog.setval('t_releves_inv_gid_seq', 3, true);


SET search_path = contactflore,public, pg_catalog;

INSERT INTO t_fiches_cflore (id_cflore, insee, dateobs, altitude_saisie, altitude_sig, altitude_retenue, date_insert, date_update, supprime, pdop, saisie_initiale, id_organisme, srid_dessin, id_protocole, id_lot, the_geom_3857, the_geom_local) VALUES (1, '05181', '2016-03-10', 3627, 0, 3627, '2016-03-10 17:34:09.160291', '2016-03-10 17:34:09.319749', false, -1, 'web', 2, 3857, 7, 7, '0101000020110F00003DFA78D1CE79254161CCCC4D13725541', '01010000206A0800007B4143E5ED582D41481F86793A905841');
INSERT INTO t_fiches_cflore (id_cflore, insee, dateobs, altitude_saisie, altitude_sig, altitude_retenue, date_insert, date_update, supprime, pdop, saisie_initiale, id_organisme, srid_dessin, id_protocole, id_lot, the_geom_3857, the_geom_local) VALUES (2, '05063', '2016-03-10', 2295, 0, 2295, '2016-03-10 17:47:42.100277', '2016-03-10 17:47:42.257232', false, -1, 'web', 2, 3857, 7, 7, '0101000020110F000026A524147A502541FD0BA9995B805541', '01010000206A0800009C3CFA465C382D41F7844B6F229A5841');

INSERT INTO t_releves_cflore (id_releve_cflore, id_cflore, id_nom, id_abondance_cflore, id_phenologie_cflore, cd_ref_origine, nom_taxon_saisi, commentaire, determinateur, supprime, herbier, gid, validite_cflore) VALUES (1, 1, 100001, 1, 2, 81065, 'Alchémille rampante', 'test comment', 'Gil det', false, true, 4, NULL);
INSERT INTO t_releves_cflore (id_releve_cflore, id_cflore, id_nom, id_abondance_cflore, id_phenologie_cflore, cd_ref_origine, nom_taxon_saisi, commentaire, determinateur, supprime, herbier, gid, validite_cflore) VALUES (2, 1, 100002, 4, 8, 95186, 'Inule fétide', 'test sans prélevemnt', 'Gil test det2', false, true, 5, NULL);
INSERT INTO t_releves_cflore (id_releve_cflore, id_cflore, id_nom, id_abondance_cflore, id_phenologie_cflore, cd_ref_origine, nom_taxon_saisi, commentaire, determinateur, supprime, herbier, gid, validite_cflore) VALUES (3, 2, 100001, 2, 4, 81065, 'Alchémille rampante', '', '', false, false, 6, NULL);

INSERT INTO cor_role_fiche_cflore (id_cflore, id_role) VALUES (1, 1);
INSERT INTO cor_role_fiche_cflore (id_cflore, id_role) VALUES (2, 1);

SELECT pg_catalog.setval('t_releves_cflore_gid_seq', 3, true);


SET search_path = florestation, public, pg_catalog;

INSERT INTO t_stations_fs (id_station, id_exposition, id_sophie, id_programme_fs, id_support, id_protocole, id_lot, id_organisme, id_homogene, dateobs, info_acces, id_surface, complet_partiel, meso_longitudinal, meso_lateral, canopee, ligneux_hauts, ligneux_bas, ligneux_tbas, herbaces, mousses, litiere, altitude_saisie, altitude_sig, altitude_retenue, remarques, pdop, supprime, date_insert, date_update, srid_dessin, insee, gid, validation) VALUES (1, 'I ', '0', 999, 1, 5, 5, 2, 1, '2015-02-17', 'test', 2, 'P', 1, 2, 0, 1, 2, 3, 4, 5, 6, 0, 0, 0, 'testage', -1, false, '2015-02-17 10:47:27.427575', '2015-02-17 10:48:40.892845', 3857, '38375', 1, true);
UPDATE t_stations_fs SET the_geom_3857 = '0101000020110F0000F2B4DBC6113F18413955881BB4035541';

INSERT INTO cor_fs_delphine (id_station, id_delphine) VALUES (1, 'ghj45');

INSERT INTO cor_fs_microrelief (id_station, id_microrelief) VALUES (1, 1);
INSERT INTO cor_fs_microrelief (id_station, id_microrelief) VALUES (1, 2);
INSERT INTO cor_fs_microrelief (id_station, id_microrelief) VALUES (1, 3);

INSERT INTO cor_fs_observateur (id_role, id_station) VALUES (1, 1);

--ALTER TABLE synthese.syntheseff DISABLE TRIGGER tri_maj_cor_unite_synthese;
INSERT INTO cor_fs_taxon (id_station, cd_nom, herb, inf_1m, de_1_4m, sup_4m, taxon_saisi, supprime, id_station_cd_nom, gid) VALUES (1, 81065, '+', '1', '2', '2', 'Alchemilla decumbens Buser, 1894', false, 1, 1);
INSERT INTO cor_fs_taxon (id_station, cd_nom, herb, inf_1m, de_1_4m, sup_4m, taxon_saisi, supprime, id_station_cd_nom, gid) VALUES (1, 95186, NULL, '+', NULL, NULL, 'Dittrichia graveolens (L.) Greuter, 1973', false, 2, 2);
--ALTER TABLE synthese.syntheseff ENABLE TRIGGER tri_maj_cor_unite_synthese;

SELECT pg_catalog.setval('cor_fs_taxon_id_station_cd_nom_seq', 3, true);

SELECT pg_catalog.setval('t_stations_fs_gid_seq', 2, true);
