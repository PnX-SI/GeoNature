--
-- PostgreSQL database dump
--

-- Dumped from database version 9.1.13
-- Dumped by pg_dump version 9.2.0
-- Started on 2014-09-04 15:12:21

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = utilisateurs, pg_catalog;

--
-- TOC entry 3284 (class 0 OID 0)
-- Dependencies: 262
-- Name: t_applications_id_application_seq; Type: SEQUENCE SET; Schema: utilisateurs; Owner: geonatuser
--

SELECT pg_catalog.setval('t_applications_id_application_seq', 15, true);


--
-- TOC entry 3285 (class 0 OID 0)
-- Dependencies: 264
-- Name: t_menus_id_menu_seq; Type: SEQUENCE SET; Schema: utilisateurs; Owner: geonatuser
--

SELECT pg_catalog.setval('t_menus_id_menu_seq', 10, true);


SET search_path = synthese, pg_catalog;

--
-- TOC entry 3262 (class 0 OID 17695)
-- Dependencies: 228
-- Data for Name: bib_criteres_synthese; Type: TABLE DATA; Schema: synthese; Owner: geonatuser
--

INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (15, 'o10', 'Nid utilisé récemment ou coquille vide', 15);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (16, 'o11', 'Jeunes fraîchement envolés ou poussins', 16);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (17, 'o12', 'Nid occupé', 17);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (18, 'o13', 'Adulte transportant des sacs fécaux ou de la nourriture pour les jeunes', 18);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (19, 'o14', 'Nid avec oeuf(s)', 19);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (20, 'o15', 'Nid avec jeune(s)', 20);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (31, 'a1', 'Accouplement', 31);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (32, 'a2', 'Ponte', 32);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (33, 'a3', 'Têtards ou larves', 33);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (34, 'a4', 'Léthargie hivernale', 34);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (21, 'm1', 'Accouplement ', 21);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (22, 'm2', 'Femelle gestante', 22);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (23, 'm3', 'Femelle allaitante, suitée', 23);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (24, 'm4', 'Terrier occupé', 24);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (25, 'm5', 'Terrier non occupé', 25);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (26, 'm6', 'Hibernation', 26);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (6, 'o1', 'Immature', 6);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (7, 'o2', 'Mâle chanteur', 7);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (8, 'o3', 'Couple', 8);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (9, 'o4', 'Comportements territoriaux ou observations à 8 jours d''intervalle au moins au même endroit', 9);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (10, 'o5', 'Parades nuptiales', 10);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (11, 'o6', 'Signes ou cris d''inquiétude d''un individu adulte', 11);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (12, 'o7', 'Plaque incubaid_critere_cfce ', 12);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (13, 'o8', 'Construction d''un nid', 13);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (14, 'o9', 'Adulte feignant une blessure ou cherchant à détourner l''attention', 14);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (35, 'p1', 'Activité de frai', 35);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (36, 'p2', 'Ponte ou nids de ponte', 36);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (30, 'r4', 'Léthargie hivernale', 30);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (29, 'r3', 'Jeune éclos', 29);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (28, 'r2', 'Ponte', 28);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (27, 'r1', 'Accouplement', 27);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (38, 'p4', 'Remontées migratoires', 38);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (37, 'p3', 'Alevins ou larves', 37);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (2, 'c', 'Cadavre', NULL);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (1, 'x', 'Absence de critère d’observation', 999);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (4, 'e', 'Entendu', 51);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (5, 'v', 'Vu', 50);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (3, 't', 'Traces ou indices de présence', 52);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (101, '1', 'larve, oeuf, chenille, nymphe...', 101);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (102, '2', 'adultes en parade nuptiale...', 102);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (105, '5', 'autres indices', 105);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (103, '3', 'adulte observé de corps', 103);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (201, '1', 'animaux malades, blessés', NULL);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (203, '3', 'autres indices', NULL);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (204, '4', 'comportements et cris d’alarme', NULL);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (207, '7', 'entendu après repasse', NULL);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (205, '5', 'crottes', NULL);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (208, '8', 'hivernant', NULL);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (209, '9', 'juvéniles non volants', NULL);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (211, '11', 'loge hivernale', NULL);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (214, '14', 'nicheurs possibles', NULL);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (215, '15', 'nicheurs probables', NULL);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (216, '16', 'nid', NULL);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (217, '17', 'oiseau vu en période de nidification dans un milieu favorable', NULL);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (219, '19', 'place pouillage', NULL);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (220, '20', 'plumée', NULL);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (221, '21', 'reproducteur', NULL);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (222, '22', 'sites de nids fréquentés', NULL);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (224, '24', 'territorial', NULL);
INSERT INTO bib_criteres_synthese (id_critere_synthese, code_critere_synthese, nom_critere_synthese, tri) VALUES (226, '26', 'adulte transportant des sacs fécaux ou de la nourriture pour les jeunes', NULL);


SET search_path = contactfaune, pg_catalog;

--
-- TOC entry 3250 (class 0 OID 17370)
-- Dependencies: 173
-- Data for Name: bib_criteres_cf; Type: TABLE DATA; Schema: contactfaune; Owner: geonatuser
--

INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (15, 'o10', 'Nid utilisé récemment ou coquille vide', 15, '10', 15);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (16, 'o11', 'Jeunes fraîchement envolés ou poussins', 16, '11', 16);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (17, 'o12', 'Nid occupé', 17, '12', 17);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (18, 'o13', 'Adulte transportant des sacs fécaux ou de la nourriture pour les jeunes', 18, '13', 18);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (19, 'o14', 'Nid avec oeuf(s)', 19, '14', 19);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (20, 'o15', 'Nid avec jeune(s)', 20, '15', 20);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (31, 'a1 ', 'Accouplement', 31, '1 ', 31);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (32, 'a2 ', 'Ponte', 32, '2 ', 32);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (33, 'a3 ', 'Têtards ou larves', 33, '3 ', 33);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (34, 'a4 ', 'Léthargie hivernale', 34, '4 ', 34);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (21, 'm1 ', 'Accouplement ', 21, '1 ', 21);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (22, 'm2 ', 'Femelle gestante', 22, '2 ', 22);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (23, 'm3 ', 'Femelle allaitante, suitée', 23, '3 ', 23);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (24, 'm4 ', 'Terrier occupé', 24, '4 ', 24);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (25, 'm5 ', 'Terrier non occupé', 25, '5 ', 25);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (26, 'm6 ', 'Hibernation', 26, '6 ', 26);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (6, 'o1 ', 'Immature', 6, '1 ', 6);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (7, 'o2 ', 'Mâle chanteur', 7, '2 ', 7);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (8, 'o3 ', 'Couple', 8, '3 ', 8);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (10, 'o5 ', 'Parades nuptiales', 10, '5 ', 10);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (11, 'o6 ', 'Signes ou cris d''inquiétude d''un individu adulte', 11, '6 ', 11);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (13, 'o8 ', 'Construction d''un nid', 13, '8 ', 13);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (14, 'o9 ', 'Adulte feignant une blessure ou cherchant à détourner l''attention', 14, '9 ', 14);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (35, 'p1 ', 'Activité de frai', 35, '1 ', 35);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (36, 'p2 ', 'Ponte ou nids de ponte', 36, '2 ', 36);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (30, 'r4 ', 'Léthargie hivernale', 30, '4 ', 30);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (29, 'r3 ', 'Jeune éclos', 29, '3 ', 29);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (28, 'r2 ', 'Ponte', 28, '2 ', 28);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (27, 'r1 ', 'Accouplement', 27, '1 ', 27);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (38, 'p4 ', 'Remontées migratoires', 38, '4 ', 38);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (37, 'p3 ', 'Alevins ou larves', 37, '3 ', 37);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (2, 'C  ', 'Cadavre', NULL, 'C ', 2);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (1, 'X  ', 'Absence de critère d’observation', 999, 'X ', 1);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (4, 'E  ', 'Entendu', 101, 'E ', 4);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (5, 'V  ', 'Vu', 100, 'V ', 5);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (3, 'T  ', 'Traces ou indices de présence', 102, 'T ', 3);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (12, 'o7 ', 'Plaque incubatrice ', 12, '7 ', 12);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (9, 'o4 ', 'Comportements territoriaux', 9, '4 ', 9);


--
-- TOC entry 3251 (class 0 OID 17373)
-- Dependencies: 174
-- Data for Name: bib_messages_cf; Type: TABLE DATA; Schema: contactfaune; Owner: geonatuser
--

INSERT INTO bib_messages_cf (id_message_cf, texte_message_cf) VALUES (1, 'Exemple de message : l''élephant rose est extrèmement rare ; merci de fournir une photo pour confirmer l''observation');


SET search_path = contactinv, pg_catalog;

--
-- TOC entry 3258 (class 0 OID 17495)
-- Dependencies: 195
-- Data for Name: bib_criteres_inv; Type: TABLE DATA; Schema: contactinv; Owner: geonatuser
--

INSERT INTO bib_criteres_inv (id_critere_inv, code_critere_inv, nom_critere_inv, tri_inv, id_critere_synthese) VALUES (1, '1', 'larve, oeuf, chenille, nymphe...', 1, 101);
INSERT INTO bib_criteres_inv (id_critere_inv, code_critere_inv, nom_critere_inv, tri_inv, id_critere_synthese) VALUES (2, '2', 'adultes en parade nuptiale...', 2, 102);
INSERT INTO bib_criteres_inv (id_critere_inv, code_critere_inv, nom_critere_inv, tri_inv, id_critere_synthese) VALUES (5, '5', 'autres indices', 5, 105);
INSERT INTO bib_criteres_inv (id_critere_inv, code_critere_inv, nom_critere_inv, tri_inv, id_critere_synthese) VALUES (3, '3', 'adulte observé de corps', 3, 103);
INSERT INTO bib_criteres_inv (id_critere_inv, code_critere_inv, nom_critere_inv, tri_inv, id_critere_synthese) VALUES (8, '8', 'animal mort', 8, 2);


--
-- TOC entry 3259 (class 0 OID 17498)
-- Dependencies: 196
-- Data for Name: bib_messages_inv; Type: TABLE DATA; Schema: contactinv; Owner: geonatuser
--



--
-- TOC entry 3260 (class 0 OID 17501)
-- Dependencies: 197
-- Data for Name: bib_milieux_inv; Type: TABLE DATA; Schema: contactinv; Owner: geonatuser
--

INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (0, 'Indéterminé');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (11, 'Friche');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (12, 'Prairie');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (13, 'Culture');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (14, 'Jardin');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (15, 'Vigne');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (16, 'Verger');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (17, 'Haie');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (18, 'Reposoir');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (19, 'Habitat, ruine, route');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (20, 'Combe à neige');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (21, 'Pelouse');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (22, 'Lande');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (23, 'Fourré');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (24, 'Bois, Futaie');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (25, 'Ripisylve');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (26, 'Clairière');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (27, 'Reboisement (jeune)');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (28, 'Taillis');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (31, 'Arête');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (32, 'Barre');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (33, 'Falaise, grotte');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (34, 'Moraine');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (35, 'Eboulis');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (36, 'Roc, bloc');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (37, 'Gravière');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (41, 'Tourbière');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (42, 'Mare');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (43, 'Marais');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (44, 'Etang');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (45, 'Lac');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (46, 'Ruisseau');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (47, 'Torrent');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (48, 'Rivière');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (49, 'Neige, glace (permanente)');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (88, 'Atmosphère');


SET search_path = layers, pg_catalog;

--
-- TOC entry 3261 (class 0 OID 17577)
-- Dependencies: 210
-- Data for Name: bib_typeszones; Type: TABLE DATA; Schema: layers; Owner: geonatuser
--

INSERT INTO bib_typeszones (id_type, typezone) VALUES (2, 'znieff2');
INSERT INTO bib_typeszones (id_type, typezone) VALUES (3, 'znieff1');
INSERT INTO bib_typeszones (id_type, typezone) VALUES (4, 'Coeur du parc national');
INSERT INTO bib_typeszones (id_type, typezone) VALUES (5, 'Natura 2000');
INSERT INTO bib_typeszones (id_type, typezone) VALUES (6, 'Réserves de chasses');
INSERT INTO bib_typeszones (id_type, typezone) VALUES (8, 'Sites classés');
INSERT INTO bib_typeszones (id_type, typezone) VALUES (11, 'Réserves naturelles');
INSERT INTO bib_typeszones (id_type, typezone) VALUES (9, 'Sites inscrits');
INSERT INTO bib_typeszones (id_type, typezone) VALUES (13, 'Réserve intégrale');
INSERT INTO bib_typeszones (id_type, typezone) VALUES (12, 'zone de libre adhésion');
INSERT INTO bib_typeszones (id_type, typezone) VALUES (14, 'Arretés de biotope');


SET search_path = public, pg_catalog;

--
-- TOC entry 3249 (class 0 OID 16746)
-- Dependencies: 171
-- Data for Name: geometry_columns; Type: TABLE DATA; Schema: public; Owner: geonatuser
--

INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'synthese', 'synthesefaune', 'the_geom_2154', 2, 2154, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'synthese', 'synthesefaune', 'the_geom_point', 2, 3857, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'synthese', 'synthesefaune', 'the_geom_3857', 2, 3857, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'contactinv', 't_fiches_inv', 'the_geom_2154', 2, 2154, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'contactinv', 't_fiches_inv', 'the_geom_3857', 2, 3857, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'contactfaune', 't_fiches_cf', 'the_geom_3857', 2, 3857, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'contactfaune', 't_fiches_cf', 'the_geom_2154', 2, 2154, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'layers', 'l_zonesstatut', 'the_geom', 2, 2154, 'MULTIPOLYGON');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'layers', 'l_communes', 'the_geom', 2, 2154, 'MULTIPOLYGON');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'layers', 'l_secteurs', 'the_geom', 2, 2154, 'MULTIPOLYGON');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'layers', 'l_aireadhesion', 'the_geom', 2, 2154, 'MULTIPOLYGON');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'layers', 'l_unites_geo', 'the_geom', 2, 2154, 'MULTIPOLYGON');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'layers', 'l_isolines20', 'the_geom', 2, 2154, 'MULTILINESTRING');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'contactinv', 'v_nomade_unites_geo_inv', 'the_geom', 2, 2154, 'MULTIPOLYGON');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'contactfaune', 'v_nomade_unites_geo_cf', 'the_geom', 2, 2154, 'MULTIPOLYGON');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'public', 'v_datas_nomade_cf', 'the_geom_2154', 2, 2154, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'public', 'v_datas_nomade_cf', 'the_geom_point', 2, 3857, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'public', 'v_datas_nomade_cf', 'the_geom_3857', 2, 3857, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'public', 'v_datas_nomade_inv', 'the_geom_2154', 2, 2154, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'public', 'v_datas_nomade_inv', 'the_geom_point', 2, 3857, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'public', 'v_datas_nomade_inv', 'the_geom_3857', 2, 3857, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'public', 'v_datas_web_cf', 'the_geom_2154', 2, 2154, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'public', 'v_datas_web_cf', 'the_geom_point', 2, 3857, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'public', 'v_datas_web_cf', 'the_geom_3857', 2, 3857, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'public', 'v_datas_web_inv', 'the_geom_2154', 2, 2154, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'public', 'v_datas_web_inv', 'the_geom_point', 2, 3857, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'public', 'v_datas_web_inv', 'the_geom_3857', 2, 3857, 'POINT');

SET search_path = synthese, pg_catalog;

--
-- TOC entry 3263 (class 0 OID 17698)
-- Dependencies: 229
-- Data for Name: bib_sources; Type: TABLE DATA; Schema: synthese; Owner: geonatuser
--

INSERT INTO bib_sources (id_source, nom_source, desc_source, host, port, username, pass, db_name, db_schema, db_table, db_field) VALUES (1, 'Contact faune', 'contenu des tables t_fiche_cf et t_releves_cf de la base faune postgres', 'localhost', 22, NULL, NULL, 'synthese', 'contactfaune', 't_releves_cf', 'id_releve_cf');
INSERT INTO bib_sources (id_source, nom_source, desc_source, host, port, username, pass, db_name, db_schema, db_table, db_field) VALUES (3, 'Contact invertébrés', 'contenu des tables t_fiches_inv et t_releves_inv de la base faune postgres', 'localhost', 22, NULL, NULL, 'synthese', 'contactinv', 't_releves_inv', 'id_releve_inv');

SET search_path = taxonomie, pg_catalog;

--
-- TOC entry 3134 (class 0 OID 126691)
-- Dependencies: 184
-- Data for Name: bib_groupes; Type: TABLE DATA; Schema: taxonomie; Owner: -
--

INSERT INTO taxonomie.bib_groupes (id_groupe, nom_groupe) VALUES(1,'Amphibiens');
INSERT INTO taxonomie.bib_groupes (id_groupe, nom_groupe) VALUES(11,'Mammifères');
INSERT INTO taxonomie.bib_groupes (id_groupe, nom_groupe) VALUES(12,'Oiseaux');
INSERT INTO taxonomie.bib_groupes (id_groupe, nom_groupe) VALUES(13,'Poissons');
INSERT INTO taxonomie.bib_groupes (id_groupe, nom_groupe) VALUES(14,'Reptiles');

INSERT INTO taxonomie.bib_groupes (id_groupe, nom_groupe) VALUES(5,'Ecrevisses');
INSERT INTO taxonomie.bib_groupes (id_groupe, nom_groupe) VALUES(9,'Insectes');
INSERT INTO taxonomie.bib_groupes (id_groupe, nom_groupe) VALUES(15,'Myriapodes');
INSERT INTO taxonomie.bib_groupes (id_groupe, nom_groupe) VALUES(16,'Arachnides');


--
-- TOC entry 3122 (class 0 OID 126729)
-- Dependencies: 194
-- Data for Name: bib_taxons; Type: TABLE DATA; Schema: taxonomie; Owner: -
--

INSERT INTO bib_taxons (id_taxon, cd_nom, nom_latin, nom_francais, auteur, saisie_autorisee, id_groupe, patrimonial, protection_stricte) VALUES (704, 67111, 'Alburnus alburnus', 'Ablette', '(Linnaeus, 1758)', 1, 13, false, false);
INSERT INTO bib_taxons (id_taxon, cd_nom, nom_latin, nom_francais, auteur, saisie_autorisee, id_groupe, patrimonial, protection_stricte) VALUES (64, 60612, 'Lynx lynx', 'Lynx boréal', '(Linnaeus, 1758)',  0, 11, true, true);
INSERT INTO bib_taxons (id_taxon, cd_nom, nom_latin, nom_francais, auteur, saisie_autorisee, id_groupe, patrimonial, protection_stricte) VALUES (23, 351, 'Rana temporaria', 'Grenouille rousse', 'Linnaeus, 1758', 1, 1, false, true);
INSERT INTO bib_taxons (id_taxon, cd_nom, nom_latin, nom_francais, auteur, saisie_autorisee, id_groupe, patrimonial, protection_stricte) VALUES (1950, 8326, 'Cicindela hybrida', 'Cicindela hybrida', 'Linné, 1758', 0, 9, false, false);
INSERT INTO bib_taxons (id_taxon, cd_nom, nom_latin, nom_francais, auteur, saisie_autorisee, id_groupe, patrimonial, protection_stricte) VALUES (2804, 11165, 'Coccinella septempunctata', 'Coccinella septempunctata', 'Linnaeus, 1758', 0, 9, false, false);
INSERT INTO bib_taxons (id_taxon, cd_nom, nom_latin, nom_francais, auteur, saisie_autorisee, id_groupe, patrimonial, protection_stricte) VALUES (816, 18437, 'Austropotamobius pallipes', 'Ecrevisse à pieds blancs', '(Lereboullet, 1858)', 0, 5, false, true);


SET search_path = contactfaune, pg_catalog;

--
-- TOC entry 3121 (class 0 OID 126644)
-- Dependencies: 175
-- Data for Name: cor_critere_groupe; Type: TABLE DATA; Schema: contactfaune; Owner: -
--

INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (31, 1);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (32, 1);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (33, 1);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (34, 1);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (21, 11);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (22, 11);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (23, 11);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (24, 11);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (25, 11);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (26, 11);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (6, 12);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (7, 12);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (8, 12);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (9, 12);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (10, 12);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (11, 12);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (12, 12);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (13, 12);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (14, 12);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (15, 12);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (16, 12);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (17, 12);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (18, 12);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (19, 12);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (20, 12);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (35, 13);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (36, 13);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (37, 13);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (38, 13);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (27, 14);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (28, 14);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (29, 14);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (30, 14);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (5, 1);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (5, 11);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (5, 12);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (5, 13);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (5, 14);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (4, 1);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (4, 11);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (4, 12);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (3, 12);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (3, 11);
INSERT INTO cor_critere_groupe (id_critere_cf, id_groupe) VALUES (3, 14);


SET search_path = utilisateurs, pg_catalog;

INSERT INTO bib_droits (id_droit, nom_droit, desc_droit) VALUES (5, 'validateur', 'Il valide bien sur');
INSERT INTO bib_droits (id_droit, nom_droit, desc_droit) VALUES (4, 'modérateur', 'Peu utilisé');
INSERT INTO bib_droits (id_droit, nom_droit, desc_droit) VALUES (0, 'aucun', 'aucun droit.');
INSERT INTO bib_droits (id_droit, nom_droit, desc_droit) VALUES (1, 'utilisateur', 'Ne peut que consulter');
INSERT INTO bib_droits (id_droit, nom_droit, desc_droit) VALUES (2, 'rédacteur', 'Il possède des droit d''écriture pour créer des enregistrements');
INSERT INTO bib_droits (id_droit, nom_droit, desc_droit) VALUES (6, 'administrateur', 'Il a tous les droits');
INSERT INTO bib_droits (id_droit, nom_droit, desc_droit) VALUES (3, 'référent', 'utilisateur ayant des droits complémentaires au rédacteur (par exemple exporter des données ou autre)');
-- 
-- TOC entry 3275 (class 0 OID 17821)
-- Dependencies: 256
-- Data for Name: bib_organismes; Type: TABLE DATA; Schema: utilisateurs; Owner: geonatuser
-- 
INSERT INTO bib_organismes (nom_organisme, adresse_organisme, cp_organisme, ville_organisme, tel_organisme, fax_organisme, email_organisme, id_organisme) VALUES ('PNF', NULL, NULL, 'Montpellier', NULL, NULL, NULL, 1);
INSERT INTO bib_organismes (nom_organisme, adresse_organisme, cp_organisme, ville_organisme, tel_organisme, fax_organisme, email_organisme, id_organisme) VALUES ('Parc National des Ecrins', 'Domaine de Charance', '05000', 'GAP', '04 92 40 20 10', '', '', 2);
INSERT INTO bib_organismes (nom_organisme, adresse_organisme, cp_organisme, ville_organisme, tel_organisme, fax_organisme, email_organisme, id_organisme) VALUES ('Autre', '', '', '', '', '', '', 99);
-- 
-- TOC entry 3276 (class 0 OID 17827)
-- Dependencies: 258
-- Data for Name: bib_unites; Type: TABLE DATA; Schema: utilisateurs; Owner: geonatuser
-- 

INSERT INTO bib_unites (nom_unite, adresse_unite, cp_unite, ville_unite, tel_unite, fax_unite, email_unite, id_unite) VALUES ('Virtuel', NULL, NULL, NULL, NULL, NULL, NULL, 1);
INSERT INTO bib_unites (nom_unite, adresse_unite, cp_unite, ville_unite, tel_unite, fax_unite, email_unite, id_unite) VALUES ('personnels partis', NULL, NULL, NULL, NULL, NULL, NULL, 2);
INSERT INTO bib_unites (nom_unite, adresse_unite, cp_unite, ville_unite, tel_unite, fax_unite, email_unite, id_unite) VALUES ('Stagiaires', NULL, NULL, '', '', NULL, NULL, 3);
INSERT INTO bib_unites (nom_unite, adresse_unite, cp_unite, ville_unite, tel_unite, fax_unite, email_unite, id_unite) VALUES ('Secretariat général', '', '', '', '', NULL, NULL, 4);
INSERT INTO bib_unites (nom_unite, adresse_unite, cp_unite, ville_unite, tel_unite, fax_unite, email_unite, id_unite) VALUES ('Service scientifique', '', '', '', '', NULL, NULL, 5);
INSERT INTO bib_unites (nom_unite, adresse_unite, cp_unite, ville_unite, tel_unite, fax_unite, email_unite, id_unite) VALUES ('Service SI', '', '', '', '', NULL, NULL, 6);
INSERT INTO bib_unites (nom_unite, adresse_unite, cp_unite, ville_unite, tel_unite, fax_unite, email_unite, id_unite) VALUES ('Service Communication', '', '', '', '', NULL, NULL, 7);
INSERT INTO bib_unites (nom_unite, adresse_unite, cp_unite, ville_unite, tel_unite, fax_unite, email_unite, id_unite) VALUES ('Conseil scientifique', '', '', '', NULL, NULL, NULL, 8);
INSERT INTO bib_unites (nom_unite, adresse_unite, cp_unite, ville_unite, tel_unite, fax_unite, email_unite, id_unite) VALUES ('Conseil d''administration', '', '', '', NULL, NULL, NULL, 9);
INSERT INTO bib_unites (nom_unite, adresse_unite, cp_unite, ville_unite, tel_unite, fax_unite, email_unite, id_unite) VALUES ('Autres', NULL, NULL, NULL, NULL, NULL, NULL, 99);
-- 
-- TOC entry 3278 (class 0 OID 17837)
-- Dependencies: 261
-- Data for Name: t_applications; Type: TABLE DATA; Schema: utilisateurs; Owner: geonatuser
-- 
INSERT INTO t_applications (id_application, nom_application, desc_application) VALUES (1, 'application utilisateurs', 'application permettant d''administrer la présente base de données.');
INSERT INTO t_applications (id_application, nom_application, desc_application) VALUES (14, 'application geonature', 'Application permettant la consultation et la gestion des relevés faune et flore.');

-- 
-- TOC entry 3255 (class 0 OID 17445)
-- Dependencies: 189
-- Data for Name: t_roles; Type: TABLE DATA; Schema: utilisateurs; Owner: geonatuser
-- 
INSERT INTO t_roles (groupe, id_role, identifiant, nom_role, prenom_role, desc_role, pass, email, organisme, id_unite, pn, session_appli, date_insert, date_update, id_organisme, remarques) VALUES (true, 20002, NULL, 'grp_en_poste', NULL, 'Tous les agents en poste au PN', NULL, NULL, 'monpn', 99, true, NULL, NULL, NULL, NULL,'groupe test');
INSERT INTO t_roles (groupe, id_role, identifiant, nom_role, prenom_role, desc_role, pass, email, organisme, id_unite, pn, session_appli, date_insert, date_update, id_organisme, remarques) VALUES (false, 1, 'admin', 'Administrateur', 'test', NULL, '21232f297a57a5a743894a0e4a801fc3', '', 'Parc national des Ecrins', 1, true, NULL, NULL, NULL, 99,'utilisateur test à modifier');
-- 
-- TOC entry 3277 (class 0 OID 17831)
-- Dependencies: 259
-- Data for Name: cor_role_droit_application; Type: TABLE DATA; Schema: utilisateurs; Owner: geonatuser
-- 
INSERT INTO cor_role_droit_application (id_role, id_droit, id_application) VALUES (1, 6, 1);
INSERT INTO cor_role_droit_application (id_role, id_droit, id_application) VALUES (20002, 3, 14);
INSERT INTO cor_role_droit_application (id_role, id_droit, id_application) VALUES (1, 6, 14);
-- 
-- TOC entry 3279 (class 0 OID 17845)
-- Dependencies: 263
-- Data for Name: t_menus; Type: TABLE DATA; Schema: utilisateurs; Owner: geonatuser
-- 
INSERT INTO t_menus (id_menu, nom_menu, desc_menu, id_application) VALUES (9, 'faune - Observateurs', 'listes des observateurs faune', 14);
INSERT INTO t_menus (id_menu, nom_menu, desc_menu, id_application) VALUES (10, 'flore - Observateurs', 'Liste des observateurs flore', 14);
-- 
-- TOC entry 3253 (class 0 OID 17437)
-- Dependencies: 186
-- Data for Name: cor_role_menu; Type: TABLE DATA; Schema: utilisateurs; Owner: geonatuser
-- 
INSERT INTO cor_role_menu (id_role, id_menu) VALUES (1, 10);
INSERT INTO cor_role_menu (id_role, id_menu) VALUES (1, 9);
-- 
-- TOC entry 3254 (class 0 OID 17440)
-- Dependencies: 187
-- Data for Name: cor_roles; Type: TABLE DATA; Schema: utilisateurs; Owner: geonatuser
-- 
INSERT INTO cor_roles (id_role_groupe, id_role_utilisateur) VALUES (20002, 1);


SET search_path = meta, pg_catalog;

--
-- TOC entry 3450 (class 0 OID 18828)
-- Dependencies: 294
-- Data for Name: t_precisions; Type: TABLE DATA; Schema: meta; Owner: -
--

INSERT INTO t_precisions (id_precision, nom_precision, desc_precision) VALUES (4, 'Saisie au GPS', NULL);
INSERT INTO t_precisions (id_precision, nom_precision, desc_precision) VALUES (5, 'Maille quart centigrade', NULL);
INSERT INTO t_precisions (id_precision, nom_precision, desc_precision) VALUES (6, 'Maille demi centigrade', NULL);
INSERT INTO t_precisions (id_precision, nom_precision, desc_precision) VALUES (7, 'Maille centigrade', NULL);
INSERT INTO t_precisions (id_precision, nom_precision, desc_precision) VALUES (8, 'Centroide de commune', NULL);
INSERT INTO t_precisions (id_precision, nom_precision, desc_precision) VALUES (9, 'Toponyme cartes IGN', NULL);
INSERT INTO t_precisions (id_precision, nom_precision, desc_precision) VALUES (10, 'MultiPoints', NULL);
INSERT INTO t_precisions (id_precision, nom_precision, desc_precision) VALUES (11, 'Maille non précisée', NULL);
INSERT INTO t_precisions (id_precision, nom_precision, desc_precision) VALUES (12, 'Non précisée', NULL);
INSERT INTO t_precisions (id_precision, nom_precision, desc_precision) VALUES (13, 'lieu-dit LPO', 'Liste de localisation se basant sur un toponyme du scan25 + précison nord, sud,est, ouest, aval, amont...');
INSERT INTO t_precisions (id_precision, nom_precision, desc_precision) VALUES (1, 'Point', NULL);
INSERT INTO t_precisions (id_precision, nom_precision, desc_precision) VALUES (2, 'Ligne', NULL);
INSERT INTO t_precisions (id_precision, nom_precision, desc_precision) VALUES (3, 'Polygone', NULL);


--
-- TOC entry 3139 (class 0 OID 126899)
-- Dependencies: 224
-- Data for Name: bib_programmes; Type: TABLE DATA; Schema: meta; Owner: -
--

INSERT INTO bib_programmes (id_programme, nom_programme, desc_programme, sitpn, desc_programme_sitpn) VALUES (3, 'Contact invertébrés', 'Contact aléatoire de la faune invertébrée.', true, 'Contact aléatoire de la faune invertébrée.');
INSERT INTO bib_programmes (id_programme, nom_programme, desc_programme, sitpn, desc_programme_sitpn) VALUES (1, 'Contact vertébrés', 'Contact aléatoire de la faune vertébrée.', true, 'Contact aléatoire de la faune vertébrée.');
INSERT INTO bib_programmes (id_programme, nom_programme, desc_programme, sitpn, desc_programme_sitpn) VALUES (2, 'Mortalité', 'Données issue du protocole mortalité.', true, 'Données issue du protocole mortalité.');
--
-- TOC entry 3138 (class 0 OID 126890)
-- Dependencies: 223
-- Data for Name: bib_lots; Type: TABLE DATA; Schema: meta; Owner: -
--

INSERT INTO bib_lots (id_lot, nom_lot, desc_lot, menu_cf, pn, menu_inv, id_programme) VALUES (1, 'Contact vertébrés', 'Contact vertébrés', true, true, false, 1);
INSERT INTO bib_lots (id_lot, nom_lot, desc_lot, menu_cf, pn, menu_inv, id_programme) VALUES (2, 'Mortalité', 'Mortalité', true, true, false, 2);
INSERT INTO bib_lots (id_lot, nom_lot, desc_lot, menu_cf, pn, menu_inv, id_programme) VALUES (3, 'Contact invertébrés', 'Contact invertébrés', true, true, false, 3);

--
-- TOC entry 3140 (class 0 OID 126911)
-- Dependencies: 226
-- Data for Name: t_protocoles; Type: TABLE DATA; Schema: meta; Owner: -
--

INSERT INTO t_protocoles VALUES (1, 'contact faune', 'à compléter', 'à compléter', 'à compléter', 'non', NULL, NULL);
INSERT INTO t_protocoles VALUES (2, 'contact invertébrés', 'à compléter', 'à compléter', 'à compléter', 'non', NULL, NULL);
INSERT INTO t_protocoles VALUES (3, 'mortalité', 'à compléter', 'à compléter', 'à compléter', 'non', NULL, NULL);


-- Completed on 2014-09-04 15:12:51

--
-- PostgreSQL database dump complete
--

