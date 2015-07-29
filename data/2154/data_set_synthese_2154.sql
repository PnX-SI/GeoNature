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

--
-- Data for Name: t_fiches_cf; Type: TABLE DATA; Schema: contactfaune; Owner: geonatuser
--

INSERT INTO t_fiches_cf VALUES (2, NULL, '2014-12-10', 409, 0, 409, '2014-12-11 18:00:33.561278', '2014-12-11 18:00:33.561278', false, -1, 'web', 99, 3857, 2, 2, '0101000020110F000052C7B622B3AB1A41D1F5B32AE70A5541', '01010000206A0800007C3DB396459D274140D397690E425841');
INSERT INTO t_fiches_cf VALUES (3, NULL, '2014-12-10', 2772, 0, 2772, '2014-12-11 18:00:33.569997', '2014-12-11 18:00:33.569997', false, -1, 'web', 99, 3857, 1, 1, '0101000020110F00008E467880980E254132FD37DF3C495541', '01010000206A0800008F2C3BA375162D41F6C357AEFB725841');
INSERT INTO t_fiches_cf VALUES (1, NULL, '2014-12-08', 967, 0, 967, '2014-12-11 18:00:33.570695', '2014-12-11 18:00:33.570695', false, -1, 'web', 99, 3857, 1, 1, '0101000020110F0000327AEA00FEB4184186BA592FFC105541', '01010000206A0800005A2BBC33F0E826418E2218932C465841');
INSERT INTO t_fiches_cf VALUES (4, NULL, '2014-12-11', 133, 0, 133, '2014-12-11 18:00:33.571303', '2014-12-11 18:00:33.571303', false, -1, 'web', 99, 3857, 1, 1, '0101000020110F000039575AC72A8403417EACE095539D5441', '01010000206A0800004DB1A3201282214198AFE5A021F45741');
INSERT INTO t_fiches_cf VALUES (5, NULL, '2014-12-11', 690, 0, 690, '2014-12-11 18:00:33.571909', '2014-12-11 18:00:33.571909', false, -1, 'web', 99, 3857, 1, 1, '0101000020110F0000E237C7B1493218415E58C82FAE0E5541', '01010000206A080000DD8032F13FBA264190CF4B447C445841');


--
-- Data for Name: cor_role_fiche_cf; Type: TABLE DATA; Schema: contactfaune; Owner: geonatuser
--

INSERT INTO cor_role_fiche_cf VALUES (2, 1);
INSERT INTO cor_role_fiche_cf VALUES (3, 1);
INSERT INTO cor_role_fiche_cf VALUES (1, 1);
INSERT INTO cor_role_fiche_cf VALUES (4, 1);
INSERT INTO cor_role_fiche_cf VALUES (5, 1);


--
-- Data for Name: t_releves_cf; Type: TABLE DATA; Schema: contactfaune; Owner: geonatuser
--

INSERT INTO t_releves_cf VALUES (1, 1, 704, 35, 1, 0, 0, 0, 0, 0, 0, 67111, 'Ablette', 'test','qq''un', false, false, 1);
INSERT INTO t_releves_cf VALUES (2, 2, 704, 2, 0, 0, 0, 0, 1, 0, 0, 67111, 'Ablette', 'very bad ablette cévenole','Amandine', false, true, 7);
INSERT INTO t_releves_cf VALUES (3, 3, 704, 35, 1, 0, 0, 0, 0, 0, 0, 67111, 'Ablette', 'la plus haute ablette du monde c''est dans les écrins','Gil', false, false, 6);
INSERT INTO t_releves_cf VALUES (4, 1, 704, 36, 0, 0, 2, 0, 0, 0, 0, 67111, 'Ablette', '','déterminateur test', false, false, 4);
INSERT INTO t_releves_cf VALUES (5, 4, 704, 37, 0, 1, 0, 0, 0, 0, 0, 67111, 'Ablette', '','déterminateur test', false, false, 5);
INSERT INTO t_releves_cf VALUES (6, 5, 64, 21, 1, 3, 0, 0, 0, 0, 0, 60612, 'Lynx boréal', '','Amandine', false, false, 6);


--
-- Name: t_releves_cf_gid_seq; Type: SEQUENCE SET; Schema: contactfaune; Owner: geonatuser
--

SELECT pg_catalog.setval('t_releves_cf_gid_seq', 6, true);


SET search_path = contactinv,public, pg_catalog;

--
-- Data for Name: t_fiches_inv; Type: TABLE DATA; Schema: contactinv; Owner: geonatuser
--

INSERT INTO t_fiches_inv VALUES (1, NULL, '2014-12-11', 11, 1525, 0, 1525, '2014-12-11 18:03:46.288976', '2014-12-11 18:03:46.303834', false, -1, 'web', 99, 3857, 3, 3, '0101000020110F00002B227945A00C19412828452BB11B5541', 0, '01010000206A0800003642BEE8C5072741DD5BFD24D74D5841');
INSERT INTO t_fiches_inv VALUES (2, NULL, '2014-12-11', 10, 1047, 0, 1047, '2014-12-11 18:04:54.159624', '2014-12-11 18:04:54.172636', false, -1, 'web', 99, 3857, 3, 3, '0101000020110F0000F2B4DBC6113F18413955881BB4035541', 0, '01010000206A08000022D826FF46BF26411D8067D4A63C5841');


--
-- Data for Name: cor_role_fiche_inv; Type: TABLE DATA; Schema: contactinv; Owner: geonatuser
--

INSERT INTO cor_role_fiche_inv VALUES (1, 1);
INSERT INTO cor_role_fiche_inv VALUES (2, 1);


--
-- Data for Name: t_releves_inv; Type: TABLE DATA; Schema: contactinv; Owner: geonatuser
--

INSERT INTO t_releves_inv VALUES (1, 1, 2804, 3, 0, 0, 1, 0, 11165, 'Coccinella septempunctata', 'test','Gil', false, false, 1);
INSERT INTO t_releves_inv VALUES (2, 2, 816, 8, 100, 0, 0, 0, 18437, 'Ecrevisse à pieds blancs', 'test','Amandine', false, false, 2);


--
-- Name: t_releves_inv_gid_seq; Type: SEQUENCE SET; Schema: contactinv; Owner: geonatuser
--

SELECT pg_catalog.setval('t_releves_inv_gid_seq', 2, true);


SET search_path = florestation, public, pg_catalog;

--
-- TOC entry 3781 (class 0 OID 382074)
-- Dependencies: 240
-- Data for Name: t_stations_fs; Type: TABLE DATA; Schema: florestation; Owner: geonatuser
--

INSERT INTO t_stations_fs (id_station, id_exposition, id_sophie, id_programme_fs, id_support, id_protocole, id_lot, id_organisme, id_homogene, dateobs, info_acces, id_surface, complet_partiel, meso_longitudinal, meso_lateral, canopee, ligneux_hauts, ligneux_bas, ligneux_tbas, herbaces, mousses, litiere, altitude_saisie, altitude_sig, altitude_retenue, remarques, pdop, supprime, date_insert, date_update, srid_dessin, insee, gid, validation) VALUES (1, 'I ', '0', 999, 1, 5, 5, 99, 1, '2015-02-17', 'test', 2, 'P', 1, 2, 0, 1, 2, 3, 4, 5, 6, 0, 0, 0, 'testage', -1, false, '2015-02-17 10:47:27.427575', '2015-02-17 10:48:40.892845', 3857, '38375', 1, true);
UPDATE t_stations_fs SET the_geom_3857 = '0101000020110F0000F2B4DBC6113F18413955881BB4035541';

--
-- TOC entry 3776 (class 0 OID 382056)
-- Dependencies: 234
-- Data for Name: cor_fs_delphine; Type: TABLE DATA; Schema: florestation; Owner: geonatuser
--

INSERT INTO cor_fs_delphine (id_station, id_delphine) VALUES (1, 'ghj45');


--
-- TOC entry 3777 (class 0 OID 382059)
-- Dependencies: 235
-- Data for Name: cor_fs_microrelief; Type: TABLE DATA; Schema: florestation; Owner: geonatuser
--

INSERT INTO cor_fs_microrelief (id_station, id_microrelief) VALUES (1, 1);
INSERT INTO cor_fs_microrelief (id_station, id_microrelief) VALUES (1, 2);
INSERT INTO cor_fs_microrelief (id_station, id_microrelief) VALUES (1, 3);


--
-- TOC entry 3778 (class 0 OID 382062)
-- Dependencies: 236
-- Data for Name: cor_fs_observateur; Type: TABLE DATA; Schema: florestation; Owner: geonatuser
--

INSERT INTO cor_fs_observateur (id_role, id_station) VALUES (1, 1);


--
-- TOC entry 3779 (class 0 OID 382067)
-- Dependencies: 238
-- Data for Name: cor_fs_taxon; Type: TABLE DATA; Schema: florestation; Owner: geonatuser
--
--ALTER TABLE synthese.syntheseff DISABLE TRIGGER tri_maj_cor_unite_synthese;
INSERT INTO cor_fs_taxon (id_station, cd_nom, herb, inf_1m, de_1_4m, sup_4m, taxon_saisi, supprime, id_station_cd_nom, gid) VALUES (1, 81065, '+', '1', '2', '2', 'Alchemilla decumbens Buser, 1894', false, 1, 1);
INSERT INTO cor_fs_taxon (id_station, cd_nom, herb, inf_1m, de_1_4m, sup_4m, taxon_saisi, supprime, id_station_cd_nom, gid) VALUES (1, 95186, NULL, '+', NULL, NULL, 'Dittrichia graveolens (L.) Greuter, 1973', false, 2, 2);
--ALTER TABLE synthese.syntheseff ENABLE TRIGGER tri_maj_cor_unite_synthese;

--
-- TOC entry 3787 (class 0 OID 0)
-- Dependencies: 239
-- Name: cor_fs_taxon_id_station_cd_nom_seq; Type: SEQUENCE SET; Schema: florestation; Owner: geonatuser
--

SELECT pg_catalog.setval('cor_fs_taxon_id_station_cd_nom_seq', 2, true);


--
-- TOC entry 3788 (class 0 OID 0)
-- Dependencies: 241
-- Name: t_stations_fs_gid_seq; Type: SEQUENCE SET; Schema: florestation; Owner: geonatuser
--

SELECT pg_catalog.setval('t_stations_fs_gid_seq', 1, true);

--
-- PostgreSQL database dump complete
--

