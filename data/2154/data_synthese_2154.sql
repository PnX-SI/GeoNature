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

SET search_path = public, pg_catalog;

INSERT INTO cor_boolean VALUES('oui',true);
INSERT INTO cor_boolean VALUES('non',false);


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

INSERT INTO bib_typeszones (id_type, typezone) VALUES (1, 'Coeurs des Parcs nationaux');
INSERT INTO bib_typeszones (id_type, typezone) VALUES (2, 'znieff2');
INSERT INTO bib_typeszones (id_type, typezone) VALUES (3, 'znieff1');
INSERT INTO bib_typeszones (id_type, typezone) VALUES (4, 'Aires de protection de biotope');
INSERT INTO bib_typeszones (id_type, typezone) VALUES (5, 'Réserves naturelles nationales');
INSERT INTO bib_typeszones (id_type, typezone) VALUES (6, 'Réserves naturelles regionales');
INSERT INTO bib_typeszones (id_type, typezone) VALUES (7, 'Natura 2000 - Zones de protection spéciales');
INSERT INTO bib_typeszones (id_type, typezone) VALUES (8, 'Natura 2000 - Sites d''importance communautaire');
INSERT INTO bib_typeszones (id_type, typezone) VALUES (9, 'Zone d''importance pour la conservation des oiseaux');
INSERT INTO bib_typeszones (id_type, typezone) VALUES (10, 'Réserves nationales de chasse et faune sauvage');
INSERT INTO bib_typeszones (id_type, typezone) VALUES (11, 'Réserves intégrales de parc national');
INSERT INTO bib_typeszones (id_type, typezone) VALUES (12, 'Sites acquis des Conservatoires d''espaces naturels');
INSERT INTO bib_typeszones (id_type, typezone) VALUES (13, 'Sites du Conservatoire du Littoral');
INSERT INTO bib_typeszones (id_type, typezone) VALUES (14, 'Parcs naturels marins');
INSERT INTO bib_typeszones (id_type, typezone) VALUES (15, 'Parcs naturels régionaux');
INSERT INTO bib_typeszones (id_type, typezone) VALUES (16, 'Réserves biologiques');
INSERT INTO bib_typeszones (id_type, typezone) VALUES (17, 'Réserves de biosphère');
INSERT INTO bib_typeszones (id_type, typezone) VALUES (18, 'Réserves naturelles de Corse');
INSERT INTO bib_typeszones (id_type, typezone) VALUES (19, 'Sites Ramsar');
INSERT INTO bib_typeszones (id_type, typezone) VALUES (20, 'Aire d''adhésion des Parcs nationaux');

UPDATE layers.l_communes SET saisie = true WHERE inseedep IN ('05', '38');


SET search_path = public, pg_catalog;

--
-- TOC entry 3249 (class 0 OID 16746)
-- Dependencies: 171
-- Data for Name: geometry_columns; Type: TABLE DATA; Schema: public; Owner: geonatuser
--
--faune
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'synthese', 'syntheseff', 'the_geom_2154', 2, 2154, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'synthese', 'syntheseff', 'the_geom_point', 2, 3857, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'synthese', 'syntheseff', 'the_geom_3857', 2, 3857, 'POINT');
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
--flore
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'bryophytes', 't_stations_bryo', 'the_geom_2154', 2, 2154, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'bryophytes', 't_stations_bryo', 'the_geom_3857', 2, 3857, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florepatri', 't_apresence', 'the_geom_2154', 2, 2154, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florepatri', 't_apresence', 'the_geom_3857', 2, 3857, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florepatri', 't_zprospection', 'the_geom_2154', 2, 2154, 'POLYGON');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florepatri', 't_zprospection', 'geom_point_3857', 2, 3857, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florepatri', 't_zprospection', 'geom_mixte_3857', 2, 3857, 'POLYGON');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florepatri', 't_zprospection', 'the_geom_3857', 2, 3857, 'POLYGON');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florestation', 't_stations_fs', 'the_geom_2154', 2, 2154, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'layers', 'l_territoires', 'the_geom', 2, 2154, 'MULTIPOLYGON');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florepatri', 'v_mobile_visu_zp', 'the_geom_2154', 2, 2154, 'POLYGON');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florestation', 'v_florestation_all', 'the_geom', 2, 2154, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florestation', 'v_florestation_patrimoniale', 'the_geom', 2, 27572, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florepatri', 'v_ap_poly', 'the_geom_2154', 2, 2154, 'POLYGON');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florepatri', 'v_ap_point', 'the_geom_2154', 2, 2154, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florepatri', 'v_ap_line', 'the_geom_2154', 2, 2154, 'LINESTRING');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florepatri', 'v_touteslesap_2154_point', 'the_geom_2154', 2, 2154, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florepatri', 'v_touteslesap_2154_line', 'the_geom_2154', 2, 2154, 'LINESTRING');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florepatri', 'v_touteslesap_2154_polygon', 'the_geom_2154', 2, 2154, 'POLYGON');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florepatri', 'v_toutesleszp_2154', 'the_geom_2154', 2, 2154, 'POLYGON');

SET search_path = synthese, pg_catalog;

--
-- TOC entry 3263 (class 0 OID 17698)
-- Dependencies: 229
-- Data for Name: bib_sources; Type: TABLE DATA; Schema: synthese; Owner: geonatuser
--

INSERT INTO bib_sources (id_source, nom_source, desc_source, host, port, username, pass, db_name, db_schema, db_table, db_field, url, target, picto, groupe, actif) VALUES (1, 'Contact faune', 'contenu des tables t_fiche_cf et t_releves_cf de la base faune postgres', 'localhost', 22, NULL, NULL, 'geonaturedb', 'contactfaune', 't_releves_cf', 'id_releve_cf', 'cf', NULL, 'images/pictos/amphibien.gif', 'FAUNE', true);
INSERT INTO bib_sources (id_source, nom_source, desc_source, host, port, username, pass, db_name, db_schema, db_table, db_field, url, target, picto, groupe, actif) VALUES (2, 'Mortalité', 'contenu des tables t_fiche_cf et t_releves_cf de la base faune postgres', 'localhost', 22, NULL, NULL, 'geonaturedb', 'contactfaune', 't_releves_cf', 'id_releve_cf', 'mortalite', NULL, 'images/pictos/squelette.png', 'FAUNE', true);
INSERT INTO bib_sources (id_source, nom_source, desc_source, host, port, username, pass, db_name, db_schema, db_table, db_field, url, target, picto, groupe, actif) VALUES (3, 'Contact invertébrés', 'contenu des tables t_fiches_inv et t_releves_inv de la base faune postgres', 'localhost', 22, NULL, NULL, 'geonaturedb', 'contactinv', 't_releves_inv', 'id_releve_inv', 'invertebre', NULL, 'images/pictos/insecte.gif', 'FAUNE', true);
INSERT INTO bib_sources (id_source, nom_source, desc_source, host, port, username, pass, db_name, db_schema, db_table, db_field, url, target, picto, groupe, actif) VALUES (4, 'Flore prioritaire', 'Relevés en présence-absence de la flore prioritaire', 'localhost', 22, NULL, NULL, 'geonaturedb', 'florepatri', 't_apresence', 'indexap', 'pda', NULL, 'images/pictos/plante.gif', 'FLORE', false);
INSERT INTO bib_sources (id_source, nom_source, desc_source, host, port, username, pass, db_name, db_schema, db_table, db_field, url, target, picto, groupe, actif) VALUES (5, 'Flore station', 'Données de relevés floristique stationnels complets ou partiel', 'localhost', 22, NULL, NULL, 'geonaturedb', 'florestation', 'cor_fs_taxon', 'gid', 'fs', NULL, 'images/pictos/plante.gif', 'FLORE', true);
INSERT INTO bib_sources (id_source, nom_source, desc_source, host, port, username, pass, db_name, db_schema, db_table, db_field, url, target, picto, groupe, actif) VALUES (6, 'Bryophytes', 'Données de contact bryologique', 'localhost', 22, NULL, NULL, 'geonaturedb', 'bryophytes', 'cor_bryo_taxon', 'gid', 'bryo', NULL, 'images/pictos/mousse.gif', 'FLORE', true);

SET search_path = taxonomie, pg_catalog;

--
-- TOC entry 3122 (class 0 OID 126729)
-- Dependencies: 194
-- Data for Name: bib_filtres; Type: TABLE DATA; Schema: taxonomie; Owner: -
--

INSERT INTO taxonomie.bib_filtres VALUES (2, 'patrimonial', 'Patrimoniale', NULL, NULL, 'Défini si le taxon est patrimonial pour le territoire', NULL, 'oui;non', true);
INSERT INTO taxonomie.bib_filtres VALUES (4, 'reproducteur', 'Reproducteur', NULL, NULL, 'Indique si le taxon est reproducteur sur le territoire', NULL, 'oui;non', false);
INSERT INTO taxonomie.bib_filtres VALUES (1, 'saisie', NULL, NULL, NULL, 'Permet d''exclure des taxons des menus déroulants de saisie', NULL, 'oui;non', true);
INSERT INTO taxonomie.bib_filtres VALUES (5, 'responsabilite_pne', 'Responsabilité', 'Responsabilité du PN Ecrins', NULL, 'Indique le niveau de responsabilité du PNE vis à vis de la conservation de ce taxon', NULL, 'nulle;faible;moyenne;forte;indéterminée', true);
INSERT INTO taxonomie.bib_filtres VALUES (6, 'statut_migration', 'Migrateur', 'Statut de migrateur', NULL, 'Indique le comportement de migrateur du taxon', NULL, 'sédentaire;migrateur-erratique-hivernant;estivant;disparu;absent;inconnu', true);
INSERT INTO taxonomie.bib_filtres VALUES (7, 'importance_population', 'Population', 'Importance de la population', NULL, 'Indique l''importance de la population pour le territoire', NULL, 'inexistante;anecdoctique;localisée;faible;moyenne;significative;inconnue', false);
INSERT INTO taxonomie.bib_filtres VALUES (3, 'protection_stricte', 'Protection stricte', 'Taxon protégé', NULL, 'Indique si le taxon est bénéficie d''un statut de protection sur le territoire (en excluant les statuts de réglementation)', NULL, 'oui;non', true);
INSERT INTO taxonomie.bib_filtres VALUES (8, 'règlementé', 'Règlementation', 'Taxon règlementé', NULL, 'Indique que le taxon fait l''objet d''une réglementation sur le territoire', NULL, 'oui;non', false);


--
-- TOC entry 3122 (class 0 OID 126729)
-- Dependencies: 194
-- Data for Name: bib_taxons; Type: TABLE DATA; Schema: taxonomie; Owner: -
--

INSERT INTO bib_taxons (id_taxon, cd_nom, nom_latin, nom_francais, auteur, filtre1, filtre2, filtre3) VALUES (704, 67111, 'Alburnus alburnus', 'Ablette', '(Linnaeus, 1758)', 'oui', 'non', 'non');
INSERT INTO bib_taxons (id_taxon, cd_nom, nom_latin, nom_francais, auteur, filtre1, filtre2, filtre3) VALUES (64, 60612, 'Lynx lynx', 'Lynx boréal', '(Linnaeus, 1758)', 'oui', 'oui', 'oui');
INSERT INTO bib_taxons (id_taxon, cd_nom, nom_latin, nom_francais, auteur, filtre1, filtre2, filtre3) VALUES (23, 351, 'Rana temporaria', 'Grenouille rousse', 'Linnaeus, 1758', 'oui', 'non', 'oui');
INSERT INTO bib_taxons (id_taxon, cd_nom, nom_latin, nom_francais, auteur, filtre1, filtre2, filtre3) VALUES (1950, 8326, 'Cicindela hybrida', 'Cicindela hybrida', 'Linné, 1758', 'oui', 'non', 'non');
INSERT INTO bib_taxons (id_taxon, cd_nom, nom_latin, nom_francais, auteur, filtre1, filtre2, filtre3) VALUES (2804, 11165, 'Coccinella septempunctata', 'Coccinella septempunctata', 'Linnaeus, 1758', 'oui', 'non', 'non');
INSERT INTO bib_taxons (id_taxon, cd_nom, nom_latin, nom_francais, auteur, filtre1, filtre2, filtre3) VALUES (816, 18437, 'Austropotamobius pallipes', 'Ecrevisse à pieds blancs', '(Lereboullet, 1858)', 'oui', 'oui', 'oui');
INSERT INTO bib_taxons (id_taxon, cd_nom, nom_latin, nom_francais, auteur, filtre1, filtre2, filtre3) VALUES (100001, 81065, 'Alchemilla decumbens', 'Alchémille rampante', 'Buser, 1894 ', 'oui', 'non', 'non');
INSERT INTO bib_taxons (id_taxon, cd_nom, nom_latin, nom_francais, auteur, filtre1, filtre2, filtre3) VALUES (100002, 95186, 'Dittrichia graveolens', 'Inule fétide', '(L.) Greuter, 1973', 'oui', 'non', 'non');


--
-- 
-- Data for Name: bib_attributs; Type: TABLE DATA; Schema: taxonomie; Owner: -
--

INSERT INTO bib_attributs (id_attribut ,nom_attribut, label_attribut, liste_valeur_attribut, obligatoire, desc_attribut) VALUES (1, 'patrimonial', 'Patrimonial', 'oui;non',true,'Défini si le taxon est patrimonial pour le territoire');
INSERT INTO bib_attributs (id_attribut ,nom_attribut, label_attribut, liste_valeur_attribut, obligatoire, desc_attribut) VALUES (2, 'protection_stricte', 'Protégé', 'oui;non',true,'Défini si le taxon bénéficie d''une protection juridique stricte pour le territoire');


--
-- 
-- Data for Name: cor_taxon_attribut; Type: TABLE DATA; Schema: taxonomie; Owner: -
--

INSERT INTO cor_taxon_attribut (id_taxon ,id_attribut, valeur_attribut) VALUES (704, 1, 'non');
INSERT INTO cor_taxon_attribut (id_taxon ,id_attribut, valeur_attribut) VALUES (704, 2, 'non');
INSERT INTO cor_taxon_attribut (id_taxon ,id_attribut, valeur_attribut) VALUES (64, 1, 'oui');
INSERT INTO cor_taxon_attribut (id_taxon ,id_attribut, valeur_attribut) VALUES (64, 2, 'oui');
INSERT INTO cor_taxon_attribut (id_taxon ,id_attribut, valeur_attribut) VALUES (23, 1, 'non');
INSERT INTO cor_taxon_attribut (id_taxon ,id_attribut, valeur_attribut) VALUES (23, 2, 'oui');
INSERT INTO cor_taxon_attribut (id_taxon ,id_attribut, valeur_attribut) VALUES (1950, 1, 'non');
INSERT INTO cor_taxon_attribut (id_taxon ,id_attribut, valeur_attribut) VALUES (1950, 2, 'non');
INSERT INTO cor_taxon_attribut (id_taxon ,id_attribut, valeur_attribut) VALUES (2804, 1, 'non');
INSERT INTO cor_taxon_attribut (id_taxon ,id_attribut, valeur_attribut) VALUES (2804, 2, 'non');
INSERT INTO cor_taxon_attribut (id_taxon ,id_attribut, valeur_attribut) VALUES (816, 1, 'non');
INSERT INTO cor_taxon_attribut (id_taxon ,id_attribut, valeur_attribut) VALUES (816, 2, 'oui');
INSERT INTO cor_taxon_attribut (id_taxon ,id_attribut, valeur_attribut) VALUES (100001, 1, 'non');
INSERT INTO cor_taxon_attribut (id_taxon ,id_attribut, valeur_attribut) VALUES (100001, 2, 'non');
INSERT INTO cor_taxon_attribut (id_taxon ,id_attribut, valeur_attribut) VALUES (100002, 1, 'non');
INSERT INTO cor_taxon_attribut (id_taxon ,id_attribut, valeur_attribut) VALUES (100002, 2, 'non');

--
-- 
-- Data for Name: bib_listes; Type: TABLE DATA; Schema: taxonomie; Owner: -
--

INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto) VALUES (1, 'liste faune vertébré', 'Liste de test servant à l''affichage des taxons de la faune vertébré pouvant être saisis', 'images/pictos/nopicto.gif');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto) VALUES (2, 'liste faune invertébré', 'Liste de test servant à l''affichage des taxons de la faune invertébré pouvant être saisis', 'images/pictos/nopicto.gif');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto) VALUES (3, 'liste flore', 'Liste de test servant à l''affichage des taxons de la flore pouvant être saisis', 'images/pictos/nopicto.gif');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto) VALUES (101, 'Amphibiens',null, 'images/pictos/amphibien.gif');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto) VALUES (102, 'Pycnogonides',null, 'images/pictos/nopicto.gif');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto) VALUES (103, 'Entognathes',null, 'images/pictos/nopicto.gif');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto) VALUES (104, 'Echinodermes',null, 'images/pictos/nopicto.gif');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto) VALUES (105, 'Ecrevisses',null, 'images/pictos/ecrevisse.gif');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto) VALUES (106, 'Insectes',null, 'images/pictos/insecte.gif');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto) VALUES (107, 'Mammifères',null, 'images/pictos/mammifere.gif');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto) VALUES (108, 'Oiseaux',null, 'images/pictos/oiseau.gif');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto) VALUES (109, 'Poissons',null, 'images/pictos/poisson.gif');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto) VALUES (110, 'Reptiles',null, 'images/pictos/reptile.gif');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto) VALUES (111, 'Myriapodes',null, 'images/pictos/nopicto.gif');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto) VALUES (112, 'Arachnides',null, 'images/pictos/araignee.gif');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto) VALUES (113, 'Mollusques',null, 'images/pictos/mollusque.gif');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto) VALUES (114, 'Vers',null, 'images/pictos/nopicto.gif');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto) VALUES (115, 'Rotifères',null, 'images/pictos/nopicto.gif');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto) VALUES (116, 'Tardigrades',null, 'images/pictos/nopicto.gif');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto) VALUES (666, 'Nuisibles',null, 'images/pictos/nopicto.gif');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto) VALUES (1000, 'Plantes vasculaires',null, 'images/pictos/plante.gif');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto) VALUES (1001, 'Bryophytes',null, 'images/pictos/mousse.gif');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto) VALUES (1002, 'Lichens',null, 'images/pictos/nopicto.gif');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto) VALUES (1003, 'Algues',null, 'images/pictos/nopicto.gif');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto) VALUES (1004, 'Champignons',null, 'images/pictos/champignon.gif');


--
-- 
-- Data for Name: cor_taxon_liste; Type: TABLE DATA; Schema: taxonomie; Owner: -
--

INSERT INTO cor_taxon_liste (id_taxon ,id_liste) VALUES (704, 1);
INSERT INTO cor_taxon_liste (id_taxon ,id_liste) VALUES (64, 1);
INSERT INTO cor_taxon_liste (id_taxon ,id_liste) VALUES (23, 1);
INSERT INTO cor_taxon_liste (id_taxon ,id_liste) VALUES (1950, 2);
INSERT INTO cor_taxon_liste (id_taxon ,id_liste) VALUES (2804, 2);
INSERT INTO cor_taxon_liste (id_taxon ,id_liste) VALUES (816, 2);
INSERT INTO cor_taxon_liste (id_taxon ,id_liste) VALUES (23, 101);
INSERT INTO cor_taxon_liste (id_taxon ,id_liste) VALUES (64, 107);
INSERT INTO cor_taxon_liste (id_taxon ,id_liste) VALUES (704, 109);
INSERT INTO cor_taxon_liste (id_taxon ,id_liste) VALUES (816, 105);
INSERT INTO cor_taxon_liste (id_taxon ,id_liste) VALUES (1950, 106);
INSERT INTO cor_taxon_liste (id_taxon ,id_liste) VALUES (2804,106);
INSERT INTO cor_taxon_liste (id_taxon ,id_liste) VALUES (100001,3);
INSERT INTO cor_taxon_liste (id_taxon ,id_liste) VALUES (100002,3);
INSERT INTO cor_taxon_liste (id_taxon ,id_liste) VALUES (100001,1000);
INSERT INTO cor_taxon_liste (id_taxon ,id_liste) VALUES (100002,1000);

SET search_path = contactfaune, pg_catalog;

--
-- TOC entry 3121 (class 0 OID 126644)
-- Dependencies: 175
-- Data for Name: cor_critere_groupe; Type: TABLE DATA; Schema: contactfaune; Owner: -
--
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (31, 101);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (32, 101);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (33, 101);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (34, 101);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (21, 107);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (22, 107);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (23, 107);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (24, 107);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (25, 107);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (26, 107);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (6, 108);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (7, 108);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (8, 108);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (9, 108);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (10, 108);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (11, 108);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (12, 108);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (13, 108);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (14, 108);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (15, 108);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (16, 108);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (17, 108);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (18, 108);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (19, 108);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (20, 108);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (35, 109);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (36, 109);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (37, 109);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (38, 109);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (27, 110);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (28, 110);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (29, 110);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (30, 110);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (5, 101);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (5, 107);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (5, 108);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (5, 109);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (5, 110);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (4, 101);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (4, 107);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (4, 108);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (3, 108);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (3, 107);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (3, 110);

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
INSERT INTO bib_unites (nom_unite, adresse_unite, cp_unite, ville_unite, tel_unite, fax_unite, email_unite, id_unite) VALUES ('Partenaire fournisseur', NULL, NULL, NULL, NULL, NULL, NULL, 10);
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
--faune
INSERT INTO bib_programmes (id_programme, nom_programme, desc_programme, actif, programme_public, desc_programme_public) VALUES (3, 'Contact invertébrés', 'Contact aléatoire de la faune invertébrée.', true, true, 'Contact aléatoire de la faune invertébrée.');
INSERT INTO bib_programmes (id_programme, nom_programme, desc_programme, actif, programme_public, desc_programme_public) VALUES (1, 'Contact vertébrés', 'Contact aléatoire de la faune vertébrée.', true, true, 'Contact aléatoire de la faune vertébrée.');
INSERT INTO bib_programmes (id_programme, nom_programme, desc_programme, actif, programme_public, desc_programme_public) VALUES (2, 'Mortalité', 'Données issue du protocole mortalité.', true, true, 'Données issue du protocole mortalité.');
--flore
INSERT INTO bib_programmes (id_programme, nom_programme, desc_programme, actif, programme_public, desc_programme_public) VALUES (4, 'Flore prioritaire', 'Inventaire et suivi en présence absence de la Flore prioritaire.', true, true, 'Inventaire et suivi en présence absence de la Flore prioritaire.');
INSERT INTO bib_programmes (id_programme, nom_programme, desc_programme, actif, programme_public, desc_programme_public) VALUES (5, 'Flore station', 'Relevés stationnels et stratifiés de la flore.', true, true, 'Relevés stationnels et stratifiés de la flore.');
INSERT INTO bib_programmes (id_programme, nom_programme, desc_programme, actif, programme_public, desc_programme_public) VALUES (6, 'Bryophytes', 'Relevés stationnels et non stratifiés de la flore bryophyte.', true, true, 'Relevés stationnels et non stratifiés de la flore bryophyte.');

--
-- TOC entry 3370 (class 0 OID 55751)
-- Dependencies: 248
-- Data for Name: bib_supports; Type: TABLE DATA; Schema: meta; Owner: cartopne
--

INSERT INTO bib_supports (id_support, nom_support) VALUES (1, 'Carte IGN 1:25 000');
INSERT INTO bib_supports (id_support, nom_support) VALUES (2, 'Photo aérienne');
INSERT INTO bib_supports (id_support, nom_support) VALUES (3, 'GPS');
INSERT INTO bib_supports (id_support, nom_support) VALUES (4, 'Milligrade');
INSERT INTO bib_supports (id_support, nom_support) VALUES (5, 'Quart centigrade');
INSERT INTO bib_supports (id_support, nom_support) VALUES (6, 'Demi centigrade');
INSERT INTO bib_supports (id_support, nom_support) VALUES (7, 'Centigrade');
INSERT INTO bib_supports (id_support, nom_support) VALUES (8, 'Centroïde de commune');
INSERT INTO bib_supports (id_support, nom_support) VALUES (9, 'Toponyme');
INSERT INTO bib_supports (id_support, nom_support) VALUES (10, 'LPO pointage GMap');
INSERT INTO bib_supports (id_support, nom_support) VALUES (999, 'Non renseigné');
INSERT INTO bib_supports (id_support, nom_support) VALUES (11, 'LPO lieu-dît');
INSERT INTO bib_supports (id_support, nom_support) VALUES (12, 'Grade sans info');

--
-- TOC entry 3138 (class 0 OID 126890)
-- Dependencies: 223
-- Data for Name: bib_lots; Type: TABLE DATA; Schema: meta; Owner: -
--

INSERT INTO bib_lots (id_lot, nom_lot, desc_lot, menu_cf, pn, menu_inv, id_programme) VALUES (1, 'Contact vertébrés', 'Contact vertébrés', true, true, false, 1);
INSERT INTO bib_lots (id_lot, nom_lot, desc_lot, menu_cf, pn, menu_inv, id_programme) VALUES (2, 'Mortalité', 'Mortalité', true, true, false, 2);
INSERT INTO bib_lots (id_lot, nom_lot, desc_lot, menu_cf, pn, menu_inv, id_programme) VALUES (3, 'Contact invertébrés', 'Contact invertébrés', true, true, false, 3);
--flore
INSERT INTO bib_lots (id_lot, nom_lot, desc_lot, menu_cf, pn, menu_inv, id_programme) VALUES (4, 'flore prioritaire', 'Inventaire et suivi en présence absence de la Flore prioritaire', true, true, false, 4);
INSERT INTO bib_lots (id_lot, nom_lot, desc_lot, menu_cf, pn, menu_inv, id_programme) VALUES (5, 'flore station', 'Relevés stationnels et stratifiés de la flore', true, true, false, 5);
INSERT INTO bib_lots (id_lot, nom_lot, desc_lot, menu_cf, pn, menu_inv, id_programme) VALUES (6, 'bryophytes', 'Relevés stationnels et non stratifiés de la flore bryophyte', true, true, false, 6);

--
-- TOC entry 3140 (class 0 OID 126911)
-- Dependencies: 226
-- Data for Name: t_protocoles; Type: TABLE DATA; Schema: meta; Owner: -
--

INSERT INTO t_protocoles VALUES (1, 'contact faune', 'à compléter', 'à compléter', 'à compléter', 'non', NULL, NULL);
INSERT INTO t_protocoles VALUES (2, 'contact invertébrés', 'à compléter', 'à compléter', 'à compléter', 'non', NULL, NULL);
INSERT INTO t_protocoles VALUES (3, 'mortalité', 'à compléter', 'à compléter', 'à compléter', 'non', NULL, NULL);
INSERT INTO t_protocoles VALUES (4, 'Flore prioritaire', 'à compléter', 'à compléter', 'à compléter', 'non', NULL, NULL);
INSERT INTO t_protocoles VALUES (5, 'Flore station', 'à compléter', 'à compléter', 'à compléter', 'non', NULL, NULL);
INSERT INTO t_protocoles VALUES (6, 'Bryophytes', 'à compléter', 'à compléter', 'à compléter', 'non', NULL, NULL);

SET search_path = bryophytes, pg_catalog;

--
-- TOC entry 3404 (class 0 OID 55310)
-- Dependencies: 179
-- Data for Name: bib_abondances; Type: TABLE DATA; Schema: bryophytes; Owner: cartopne
--

INSERT INTO bib_abondances (id_abondance, nom_abondance) VALUES ('+', 'Moins de 1 %');
INSERT INTO bib_abondances (id_abondance, nom_abondance) VALUES ('1', 'Moins de 5 %');
INSERT INTO bib_abondances (id_abondance, nom_abondance) VALUES ('2', 'De 5 à 25 %');
INSERT INTO bib_abondances (id_abondance, nom_abondance) VALUES ('3', 'De 25 à 50 %');
INSERT INTO bib_abondances (id_abondance, nom_abondance) VALUES ('4', 'De 50 à 75 %');
INSERT INTO bib_abondances (id_abondance, nom_abondance) VALUES ('5', 'Plus de 75 %');
INSERT INTO bib_abondances (id_abondance, nom_abondance) VALUES ('9', 'Aucune');


--
-- TOC entry 3405 (class 0 OID 55313)
-- Dependencies: 180
-- Data for Name: bib_expositions; Type: TABLE DATA; Schema: bryophytes; Owner: cartopne
--

INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('N ', 'Nord', 1);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('NE', 'Nord Est', 2);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('E ', 'Est', 3);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('SE', 'Sud Est', 4);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('S ', 'Sud', 5);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('SO', 'Sud Ouest', 6);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('O ', 'Ouest', 7);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('NO', 'Nord Ouest', 8);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('I ', 'Indéfinie', 9);


SET search_path = florepatri, pg_catalog;

--
-- TOC entry 3406 (class 0 OID 55397)
-- Dependencies: 187
-- Data for Name: bib_comptages_methodo; Type: TABLE DATA; Schema: florepatri; Owner: cartopne
--

INSERT INTO bib_comptages_methodo (id_comptage_methodo, nom_comptage_methodo) VALUES (1, 'Recensement exhaustif');
INSERT INTO bib_comptages_methodo (id_comptage_methodo, nom_comptage_methodo) VALUES (2, 'Echantillonage');
INSERT INTO bib_comptages_methodo (id_comptage_methodo, nom_comptage_methodo) VALUES (9, 'Aucun comptage');


--
-- TOC entry 3407 (class 0 OID 55400)
-- Dependencies: 188
-- Data for Name: bib_frequences_methodo_new; Type: TABLE DATA; Schema: florepatri; Owner: cartopne
--

INSERT INTO bib_frequences_methodo_new (id_frequence_methodo_new, nom_frequence_methodo_new) VALUES ('N', 'Nouveau transect');
INSERT INTO bib_frequences_methodo_new (id_frequence_methodo_new, nom_frequence_methodo_new) VALUES ('S', 'Estimation');


--
-- TOC entry 3408 (class 0 OID 55403)
-- Dependencies: 189
-- Data for Name: bib_pentes; Type: TABLE DATA; Schema: florepatri; Owner: cartopne
--

INSERT INTO bib_pentes (id_pente, val_pente, nom_pente) VALUES (1, 2.5, 'Labourable (0-5)');
INSERT INTO bib_pentes (id_pente, val_pente, nom_pente) VALUES (2, 7.5, 'Fauchable (5-10)');
INSERT INTO bib_pentes (id_pente, val_pente, nom_pente) VALUES (3, 12.5, 'Haut d''un cône de déjection torrentiel (10-15)');
INSERT INTO bib_pentes (id_pente, val_pente, nom_pente) VALUES (4, 17.5, 'Haut d''un cône d''avalanche (15-20)');
INSERT INTO bib_pentes (id_pente, val_pente, nom_pente) VALUES (5, 22.5, 'Pied d''éboulis (20-25)');
INSERT INTO bib_pentes (id_pente, val_pente, nom_pente) VALUES (6, 30, 'Tablier d''éboulis (25-35)');
INSERT INTO bib_pentes (id_pente, val_pente, nom_pente) VALUES (7, 37.5, 'Sommet d''éboulis (35-40)');
INSERT INTO bib_pentes (id_pente, val_pente, nom_pente) VALUES (8, 45, 'Rochillon (sans les mains) (40-50)');
INSERT INTO bib_pentes (id_pente, val_pente, nom_pente) VALUES (9, 55, 'Rochillon (avec les mains) (50-60)');
INSERT INTO bib_pentes (id_pente, val_pente, nom_pente) VALUES (10, 90, 'Vires et barres (>60)');
INSERT INTO bib_pentes (id_pente, val_pente, nom_pente) VALUES (0, 0, 'Aucune pente');


--
-- TOC entry 3409 (class 0 OID 55406)
-- Dependencies: 190
-- Data for Name: bib_perturbations; Type: TABLE DATA; Schema: florepatri; Owner: cartopne
--

INSERT INTO bib_perturbations (codeper, classification, description) VALUES (73, 'Processus naturels d''érosion', 'Engravement (laves torrentielles et divagation d''une rivière)');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (11, 'Gestion par le feu', 'Brûlage contrôlé');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (78, 'Processus naturels d''érosion', 'Eboulement récent');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (24, 'Activités de loisirs', 'Véhicules à moteur (écrasement)');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (54, 'Activités forestières', 'Elagage (haie et bord de route)');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (76, 'Processus naturels d''érosion', 'Sapement de la berge d''un cours d''eau');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (43, 'Activités agricoles', 'Produits phytosanitaires (épandage)');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (75, 'Processus naturels d''érosion', 'Erosion s''exerçant sur de vastes surfaces (gélifluxion)');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (12, 'Gestion par le feu', 'Incendie (naturel ou incontrôlé)');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (21, 'Activités de loisirs', 'Récolte des fleurs');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (22, 'Activités de loisirs', 'Arrachage des pieds');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (23, 'Activités de loisirs', 'Piétinement pédestre');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (25, 'Activités de loisirs', 'Plongée dans un lac');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (31, 'Gestion de l''eau', 'Pompage');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (32, 'Gestion de l''eau', 'Drainage');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (33, 'Gestion de l''eau', 'Irrigation par gravité');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (34, 'Gestion de l''eau', 'Irrigation par aspersion');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (35, 'Gestion de l''eau', 'Curage (fossé, mare, serve)');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (36, 'Gestion de l''eau', 'Extraction de granulats');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (41, 'Activités agricoles', 'Labour');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (42, 'Activités agricoles', 'Fertilisation');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (44, 'Activités agricoles', 'Fauchaison');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (45, 'Activités agricoles', 'Apport de blocs (déterrés par le labour)');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (46, 'Activités agricoles', 'Gyrobroyage');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (47, 'Activités agricoles', 'Revégétalisation (sur semis)');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (51, 'Activités forestières', 'Jeune plantation de feuillus');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (52, 'Activités forestières', 'Jeune plantation mixte (feuillus et résineux)');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (53, 'Activités forestières', 'Jeune plantation de résineux');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (55, 'Activités forestières', 'Coupe d''éclaircie');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (56, 'Activités forestières', 'Coupe à blanc');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (57, 'Activités forestières', 'Bois coupé et laissé sur place');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (58, 'Activités forestières', 'Ouverture de piste forestière');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (61, 'Comportement des animaux', 'Jas (couchades nocturnes des animaux domestiques)');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (62, 'Comportement des animaux', 'Chaume (couchades aux heures chaudes des animaux domestiques)');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (63, 'Comportement des animaux', 'Faune sauvage (reposoir)');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (64, 'Comportement des animaux', 'Piétinement, sans apports de déjection');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (65, 'Comportement des animaux', 'Pâturage (sur herbacées exclusivement)');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (66, 'Comportement des animaux', 'Abroutissement et écorçage (sur ligneux)');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (71, 'Processus naturels d''érosion', 'Submersion temporaire');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (72, 'Processus naturels d''érosion', 'Envasement');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (74, 'Processus naturels d''érosion', 'Avalanche : apport de matériaux non triés');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (77, 'Processus naturels d''érosion', 'Avalanche : ramonage du terrain');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (81, 'Aménagements lourds', 'Carrière en roche dure');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (82, 'Aménagements lourds', 'Fossé pare-blocs');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (83, 'Aménagements lourds', 'Endiguement');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (84, 'Aménagements lourds', 'Terrassement pour aménagements lourds');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (85, 'Aménagements lourds', 'Déboisement avec désouchage');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (86, 'Aménagements lourds', 'Béton, goudron : revêtement abiotique');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (67, 'Comportement des animaux', 'Sangliers : labours et grattis');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (68, 'Comportement des animaux', 'Marmottes : terriers');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (69, 'Comportement des animaux', 'Chenilles : défoliation');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (91, 'Gestion des invasives', 'Arrachage');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (92, 'Gestion des invasives', 'Fauchage');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (93, 'Gestion des invasives', 'Débroussaillage');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (94, 'Gestion des invasives', 'Recouvrement avec bâches');


--
-- TOC entry 3410 (class 0 OID 55409)
-- Dependencies: 191
-- Data for Name: bib_phenologies; Type: TABLE DATA; Schema: florepatri; Owner: cartopne
--

INSERT INTO bib_phenologies (codepheno, pheno) VALUES (1, 'Stade végétatif');
INSERT INTO bib_phenologies (codepheno, pheno) VALUES (2, 'Stade boutons floraux');
INSERT INTO bib_phenologies (codepheno, pheno) VALUES (3, 'Début de floraison');
INSERT INTO bib_phenologies (codepheno, pheno) VALUES (4, 'Pleine floraison');
INSERT INTO bib_phenologies (codepheno, pheno) VALUES (5, 'Fin de floraison et maturation des fruits');
INSERT INTO bib_phenologies (codepheno, pheno) VALUES (6, 'Dissémination');
INSERT INTO bib_phenologies (codepheno, pheno) VALUES (7, 'Stade de décrépitude');
INSERT INTO bib_phenologies (codepheno, pheno) VALUES (8, 'Stage végétatif permanent ');


--
-- TOC entry 3411 (class 0 OID 55412)
-- Dependencies: 192
-- Data for Name: bib_physionomies; Type: TABLE DATA; Schema: florepatri; Owner: cartopne
--

INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (1, 'Herbacée', 'Alluvions (Végétation herbacée pionnière des)', 'Formation très ouverte pionnière des alluvions actifs, régulièrement perturbés et alimentés, des torrents, des rivières et des fleuves à régime nival (bilan hydrique largement déficient sur un substrat très drainant), riches en galets mêlés ou non de terre fine.', 'AL');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (2, 'Herbacée', 'Végétation aquatique', 'Ensemble vaste de formations végétales strictement aquatiques (non hélophytiques), des eaux stagnantes et courantes, enracinées ou libres, immergées ou submergées. Comprend les herbiers à Sparganium angustifolium des étages subalpin et alpin.', 'AQ');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (3, 'Herbacée', 'Autre formation herbacée artificielle', 'à garder ?', 'AR');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (4, 'Herbacée', 'Bas-marais et marais de transition', 'Formation basse dominée par des cypéracées de petites et moyennes taille à nappe d''eau proche ou juste au dessus de la surface. Comprend aussi les formations amphibies franchement aquatiques (ceinture à Eriophorum scheuchzeri) des étages subalpin et alpin.', 'BM');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (5, 'Herbacée', 'Combe à neige (Végétation des)', 'Formation à degré d''ouverture variable des zones longuement enneigées de l''étage alpin (rare au subalpin) souvent dominée par des nanophanérophytes du genre Salix. Substrat variable, formes minérales  caractérisées le tassement des éléments du substrat (fins à moyens)', 'CN');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (6, 'Herbacée', 'Cultures  (Végétation des)', 'Formation basse et très ouverte dominée par des plantes annuelles (à bisannuelles) des terrains agricoles exploités et les cultures arboricoles à terre retournée.', 'CU');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (7, 'Herbacée', 'Dalles rocheuses (Végétation pionnière des)', 'Formation herbacée ouverte pionnière des affleurements rocheux (souvent tabulaires avec pente peu marqué), riche en plantes grasses et à composition mixte vivaces et annuelles. Elle comprend la végétation pionnière des lapiaz vifs', 'DA');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (8, 'Herbacée', 'Éboulis (Végétation des)', 'Formation très ouverte pionnière des éboulis et chaos rocheux, actifs ou stabilisés, comprenant la végétation colonisant les moraines. Formation caractérisée par la (quasi) absence de sol. Ne comprend pas les formations pionnières à saules nains des chaos rocheux longuement enneigés qui sont à coder sous CN (combes à neige)', 'EB');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (9, 'Herbacée', 'Bordure d''eaux courantes  (Végétation amphibie des)', 'Formation amphibie vivace dense (petits hélophytes souvent) et entremêlée occupant les petits cours d''eau et leurs berges ainsi que les lones et bras-mort à courant faible (comprend les herbiers à Glyceria, Berula, Apium, Nasturtium et Leersia).', 'EC');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (10, 'Herbacée', 'Grèves exondées  (Végétation pionnière des)', 'Formation pionnière annuelle et vivace de petite taille (Eleocharis acicularis, Littorella uniflora, Ludwigia palustris, Juncus bulbosus…) ou plus haute (Polygonum lapathifolium, Bidens pl.sp. etc.). des  zones périodiquement exondées des eaux stagnantes et courantes, végétation à caractère amphibie souvent marqué.', 'EX');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (11, 'Herbacée', 'Végétation fontinale', 'Formation en majorité dominée par les bryophytes, avec végétation vasculaire peu diversifiée mais parfois assez recouvrante (Epilobium alsinifolium, Saxifraga aizoides, Carex frigida), colonisant les sources, les bords de ruisselets et les rochers suintants, milieux imbibé en permanence', 'FO');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (12, 'Herbacée', 'Grands hélophytes  (Communauté de)', 'Formation souvent dense de grands hélophytes graminoïdes (roselières au sens large à Phragmites, Phalaris, Typha, Schoenoplectus, Cladium...) comprenant à la fois les communautés franchement aquatique et les communautés terrestres (atterries).', 'GH');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (13, 'Herbacée', 'Haut-marais', 'Formation mixte bryophytique (sphaignes), herbacée (cypéracée) et sous-arbustive (éricacées) formant un paysage lâchement moutonné de buttes de sphaignes et de creux plus ou moins inondés ', 'HM');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (14, 'Herbacée', 'Végétation rase hyperpiétinée', 'Formation dominée par des plantes annuelles prostrées supportant le piétinement régulier de toute nature', 'HY');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (15, 'Herbacée', 'Magnocariçaie', 'Formation haute dominée par des hélophytes de la famille des cypéracées comprenant à la fois les communautés franchement aquatiques et des communautés terrestres à sol mouillé une partie de l''année.', 'MC');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (16, 'Herbacée', 'Mégaphorbiaie', 'Formation dense et haute dominée par des dicotylédones à feuillage très recouvrant des milieux frais à humides, riches en éléments minéraux. Comprend aussi les formations montagnardes à subalpines mésophiles composition mixte entre graminées et dicotylédones (Calamagrostis sp. souvent), d’origine naturelle (praires de couloirs d’avalanche). Plaine, montagnard et subalpin. Urtica, Anthriscus, Convolvulus, lisière nitrophiles ?', 'MG');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (17, 'Herbacée', 'Murs  (Végétation anthropique des)', 'Formation colonisant les murs', 'MU');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (18, 'Herbacée', 'Coupes et ourlets forestiers', 'Formation intraforestière, constituée de grandes dicotylédones vivaces colonisant les coupes forestières récentes et les clairières à sol riches, ou de dicotylédones moins grande en situation de lisière et de clairière (Aegopodium, … ). Comprend également les formations de lisière intraforestièresd dominées par des graminées (Festuca gigantea, Bromus ramosus / benekenii, Calamagrostis varia, Elytrigia / Roegneria ou encore à Hordelymus europaeus ). A préciser JCV. Comprend les ronciers forestiers. Les formations riveraines à Petasites albus (souvent intraforestières) sont codées sous MG – Mégaphorbiaie. Les formations de lisère humides à Petasites albus sont quant à elles traités ici. ', 'OF');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (19, 'Herbacée', 'Ourlet maigre', 'Formation mésophile à méso-xérophile, peu élevée, développées sur des terrains maigres en bordure externe de végétations arbustives et forestières (conditions héliophiles à hémi-héliophiles) ou colonisant d’ancien espaces agro-pastoraux, dominée par des espèces à développement tardif, parmi lesquels les graminées sont (co-)dominantes. Les formations à Rubus sont codés OU ou OF en fonction de leur situation. Les manteaux arbustifs sont traités dans les fourré quand le recouvrement arbustif > 25 %, < 25 %, ils sont traités ici', 'OU');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (20, 'Herbacée', 'Pelouse alpine et pâturage d''altitude', 'Formation basse diversifiée à dominante de graminées et de cypéracées peu élevées des étages supérieurs (subalpin et alpin). Recouvrement minéral souvent important, comprend aussi les pelouses rocailleuses de colonisation d''éboulis et des roches altérées. L''altitude est le critère déterminant.', 'PA');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (21, 'Herbacée', 'Prairie humide', 'Formation herbacée d''origine anthropique diversifiée, dense et haute à dominante graminéenne, fauchée et/ou pâturée, humide à mouillée (nappe affleurante) une partie de l''année, périodiquement inondée. Les prairies alluviales à Arrhenatherum elatius à tendance mésohygrophile des niveaux topo supérieurs sont traitées sous PM. Les formations basses méditerranéennes à Deschampsia media sont comprises dans PH.', 'PH');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (22, 'Herbacée', 'Prairie mésophile', 'Formation diversifiée d''origine anthropique, dense et haute à dominante graminéenne de hauteur supérieure à 50 cm, fauchée et/ou pâturée, temporairement humide, exceptionnellement inondée et mouillée. Les formations semi hautes pâturées d''altitude ne sont pas comprises. La hauteur de certaines formations (ex. formation dense à Brome érigé) doit examinées attentivement pour distinguer la pelouse de la prairie. Les formations naturelles montagnardes à hautes herbes mixte (graminées et dicotylédones) sont à coder sous MG Mégaphorbiaie.', 'PM');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (23, 'Herbacée', 'Pelouse (de basse et moyenne altitude)', 'Formation basse diversifiée, de hauteur moyenne inférieure à 50 cm à dominante graminéenne, des sols maigres des étages planitiaire, collinéen et montagnard. Recouvrement minéral variable, comprend aussi les pelouses rocailleuses de colonisation d''éboulis et des roches altérées. La hauteur de certaines formations (ex. formation dense à Brome érigé) doit examinées attentivement pour distinguer la pelouse de la prairie.', 'PS');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (24, 'Herbacée', 'Petits hélophytes (Communauté de)', 'Formation souvent clairsemée de petits hélophytes non graminoïdes des eaux stagnantes peu profondes à niveau variable (Sparganium sppl., Alisma sppl., Equisetum fluviatile, Oenanthe aquatica, Rorippa amphibia, Butomus umbellatus, Sagitaria sagitifolia), également appelé roselière basse.', 'RB');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (25, 'Herbacée', 'Parois et façades rocheuses (Végétation des)', 'Formation clairsemée des anfractuosités rocheuses, végétation saxicole au sens strict, incluant la végétation des rochers frais méridionaux mais pas les suintement quasi permanents', 'RO');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (26, 'Herbacée', 'Friche herbacée et végétation rudérale', 'Formation dominée par des espèces annuelles et/ou bisannuelles des terrains agricoles, urbains, industriels irrégulièrement perturbé, souvent nitrophile. Comprend aussi la végétation rudérale vivace  des reposoirs à bestiaux et des friches à graminées (chiendent) sur anciens terrains agricoles. Comprend également les formations vivaces de substitution de xénopytes (Reynoutria japonica/ bohemica ou Impatiens glandulifera. lisières nitrophiles ?', 'RU');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (27, 'Herbacée', 'Pelouse pionnière annuelle', 'Formation très ouverte primaire dominée par espèces annuelles de petite taille à cycle court, fréquemment sur substrats fins et mobiles', 'TH');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (101, 'Sous-arbustive', 'Lande  (et landine)', 'Formation végétale dominée par des petits chaméphytes (landines) ou des grands chaméphytes (landes). Les seuils de recouvrement de la strate sous-arbustive sont donnés dans « Physionomies complexes ».', 'LA');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (102, 'Sous-arbustive', 'Garrigue  (incluant les ourlets herbacés méditerranéens)', 'Formation végétale dominée par des chaméphytes des secteurs supra- et oro-méditerranéens', 'GA');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (201, 'Arbustive', 'Fourré mésophile (mésophile à sec)', 'Formation dominée des espèces caducifoliées des autres situations (Coryllaie, coudraie, accru à …, fourré à Amelanchier, …). ', 'FM');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (202, 'Arbustive', 'Fourré artificiel', 'ex. : haie bocagère', 'FR');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (203, 'Arbustive', 'Fourré sempervirent', 'Formation dominée par des espèces à feuillage persistant, épineuses ou non', 'FS');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (204, 'Arbustive', 'Fourré humide', 'Formation dominée des des espèces caducifoliées des sols engorgés, des bordures d''eaux calmes et courantes (saulaie arbustive, fourré à bourdaine, …). Les aulnaies vertes sont traitées sous FM', 'FU');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (301, 'Arborescente', 'Boisement artificiel', NULL, 'BA');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (302, 'Arborescente', 'Boisement de conifères humide', 'Formation dominée par les conifères ( > 75 %  recouvrement) des sols humides ou engorgés. Les pré-bois de Pin à crochet sur tourbe sont considérés comme des formations arborescentes dès 15 % de recouvrement (au lieu de 30 % pour les autres essences).', 'BCH');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (303, 'Arborescente', 'Boisement de conifère  (mésophile à sec)', 'Formation dominée par les conifères (> 75 %  recouvrement) des situations  sèches ou mésophiles. Les pré-bois de Mélèze, Arolle, Pin à crochet et de Thurifère sont considérés comme des formations arborescentes dès 15 % de recouvrement (au lieu de 30 % pour les autres essences).', 'BCM');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (304, 'Arborescente', 'Boisement feuillu humide', 'Formation dominée par des espèces feuillues  (> 75 % de recouvrement) caducifoliées des sols engorgés (nappe affleurante ou peu profonde) et des situations alluviales et riveraines (nappe  circulante à niveau variable et crues). Les boisements à sous bois de mégaphorbiaie non riverain ou alluviaux sont traités sous BFM.', 'BFH');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (305, 'Arborescente', 'Boisement feuillu  (mésophile à sec)', 'Formation dominée par des espèces feuillues  (> 75 % de recouvrement) caducifoliées des autres situations, sèches ou mésophiles', 'BFM');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (306, 'Arborescente', 'Boisement feuillu sempervirent', 'Formation dominée par des espèces feuillues  (> 75 % de recouvrement) sempervirentes', 'BFS');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (307, 'Arborescente', 'Boisement mixte  (conifères/feuillus, sempervirent/caduc.)', 'Formation mixte conifères/feuillus ou feuillus sempervirents/feuillus caducifolié dans laquelle aucune des essences atteint individuellement 75 % de la surface. Les combinaisons mixte d’essences sont retenues dans la liste de peuplements.', 'BMI');


--
-- TOC entry 3412 (class 0 OID 55418)
-- Dependencies: 193
-- Data for Name: bib_rezo_ecrins; Type: TABLE DATA; Schema: florepatri; Owner: cartopne
--

INSERT INTO bib_rezo_ecrins (id_rezo_ecrins, nom_rezo_ecrins) VALUES (1, 'La synchronisation de la base Ecrins vers la base Rezo a été faite avec succès');
INSERT INTO bib_rezo_ecrins (id_rezo_ecrins, nom_rezo_ecrins) VALUES (2, 'La synchronisation de la base Rézo vers la base Ecrins a été faite avec succès');
INSERT INTO bib_rezo_ecrins (id_rezo_ecrins, nom_rezo_ecrins) VALUES (0, 'Erreur de synchronisation entre les 2 bases');
INSERT INTO bib_rezo_ecrins (id_rezo_ecrins, nom_rezo_ecrins) VALUES (9, 'Pas de synchronisation entre les 2 bases (données existantes avant mise en place synchronisations)');


--
-- TOC entry 3413 (class 0 OID 55421)
-- Dependencies: 194
-- Data for Name: bib_statuts; Type: TABLE DATA; Schema: florepatri; Owner: cartopne
--

INSERT INTO bib_statuts (id_statut, nom_statut, desc_statut) VALUES (1, 'UICN Vu', 'Liste rouge UICN - Vulnérable');
INSERT INTO bib_statuts (id_statut, nom_statut, desc_statut) VALUES (2, 'UICN En', 'Liste rouge UICN - En danger');
INSERT INTO bib_statuts (id_statut, nom_statut, desc_statut) VALUES (3, 'UICN Cr', 'Liste rouge UICN - En danger critique d''extinction');
INSERT INTO bib_statuts (id_statut, nom_statut, desc_statut) VALUES (10, 'PR PACA', 'Protection régionale Provence Alpes Caôte d''Azur');
INSERT INTO bib_statuts (id_statut, nom_statut, desc_statut) VALUES (11, 'PR RA', 'Protection régionale Rhône-Alpes');
INSERT INTO bib_statuts (id_statut, nom_statut, desc_statut) VALUES (12, 'PD 05', 'Protection départementale Hautes-Alpes');
INSERT INTO bib_statuts (id_statut, nom_statut, desc_statut) VALUES (13, 'PD 38', 'Protection départementale Isère');
INSERT INTO bib_statuts (id_statut, nom_statut, desc_statut) VALUES (14, 'PD 01', 'Protection départementale Ain');
INSERT INTO bib_statuts (id_statut, nom_statut, desc_statut) VALUES (15, 'PD 04', 'Protection départementale Alpes de Haute Provence');
INSERT INTO bib_statuts (id_statut, nom_statut, desc_statut) VALUES (16, 'PD 73', 'Protection départementale Savoie');
INSERT INTO bib_statuts (id_statut, nom_statut, desc_statut) VALUES (17, 'PD 74', 'Protection départementale Haute Savoie');
INSERT INTO bib_statuts (id_statut, nom_statut, desc_statut) VALUES (18, 'PD 26', 'Protection départementale Drôme');
INSERT INTO bib_statuts (id_statut, nom_statut, desc_statut) VALUES (30, 'PNat', 'Protection national');
INSERT INTO bib_statuts (id_statut, nom_statut, desc_statut) VALUES (40, 'EEE', 'Espèce exotique invasive');


--
-- TOC entry 3414 (class 0 OID 55427)
-- Dependencies: 195
-- Data for Name: bib_taxons_fp; Type: TABLE DATA; Schema: florepatri; Owner: cartopne
--

INSERT INTO bib_taxons_fp (num_nomenclatural, francais, latin, echelle, cd_nom, nomade_ecrins) VALUES (102232, 'Herbe aux cosaques', 'Litwinowia tenuissima', 4000, 611131, true);
INSERT INTO bib_taxons_fp (num_nomenclatural, francais, latin, echelle, cd_nom, nomade_ecrins) VALUES (35676, 'Houx', 'Ilex aquifolium', 8000, 103514, false);
INSERT INTO bib_taxons_fp (num_nomenclatural, francais, latin, echelle, cd_nom, nomade_ecrins) VALUES (43424, 'Cerfeuil musqué', 'Myrrhis odorata', 4000, 109161, false);
INSERT INTO bib_taxons_fp (num_nomenclatural, francais, latin, echelle, cd_nom, nomade_ecrins) VALUES (1071, 'Aethionéma des rochers', 'Aethionema saxatile', 8000, 130869, false);
INSERT INTO bib_taxons_fp (num_nomenclatural, francais, latin, echelle, cd_nom, nomade_ecrins) VALUES (14752, 'Châtaigner', 'Castanea sativa', 8000, 89304, false);
INSERT INTO bib_taxons_fp (num_nomenclatural, francais, latin, echelle, cd_nom, nomade_ecrins) VALUES (19204, 'Cotonéaster intermédiaire', 'Cotoneaster intermedius', 8000, 92715, false);
INSERT INTO bib_taxons_fp (num_nomenclatural, francais, latin, echelle, cd_nom, nomade_ecrins) VALUES (19226, 'Cotonéaster de Rabou', 'Cotoneaster raboutensis', 8000, 92700, false);
INSERT INTO bib_taxons_fp (num_nomenclatural, francais, latin, echelle, cd_nom, nomade_ecrins) VALUES (26575, 'Fétuque alpine', 'Festuca alpina', 8000, 98054, false);
INSERT INTO bib_taxons_fp (num_nomenclatural, francais, latin, echelle, cd_nom, nomade_ecrins) VALUES (29235, 'Gaillet des rochers', 'Galium saxosum', 8000, 99530, false);
INSERT INTO bib_taxons_fp (num_nomenclatural, francais, latin, echelle, cd_nom, nomade_ecrins) VALUES (39494, 'Liparis de loesel', 'Liparis loeselii', 4000, 106353, false);


SET search_path = florestation, pg_catalog;

--
-- TOC entry 3415 (class 0 OID 55555)
-- Dependencies: 212
-- Data for Name: bib_abondances; Type: TABLE DATA; Schema: florestation; Owner: cartopne
--

INSERT INTO bib_abondances (id_abondance, nom_abondance) VALUES ('+', 'Moins de 1 %');
INSERT INTO bib_abondances (id_abondance, nom_abondance) VALUES ('1', 'Moins de 5 %');
INSERT INTO bib_abondances (id_abondance, nom_abondance) VALUES ('2', 'De 5 à 25 %');
INSERT INTO bib_abondances (id_abondance, nom_abondance) VALUES ('3', 'De 25 à 50 %');
INSERT INTO bib_abondances (id_abondance, nom_abondance) VALUES ('4', 'De 50 à 75 %');
INSERT INTO bib_abondances (id_abondance, nom_abondance) VALUES ('5', 'Plus de 75 %');
INSERT INTO bib_abondances (id_abondance, nom_abondance) VALUES ('9', 'Aucune');


--
-- TOC entry 3416 (class 0 OID 55558)
-- Dependencies: 213
-- Data for Name: bib_expositions; Type: TABLE DATA; Schema: florestation; Owner: cartopne
--

INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('N ', 'Nord', 1);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('NE', 'Nord Est', 2);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('E ', 'Est', 3);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('SE', 'Sud Est', 4);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('S ', 'Sud', 5);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('SO', 'Sud Ouest', 6);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('O ', 'Ouest', 7);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('NO', 'Nord Ouest', 8);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('I ', 'Indéfinie', 9);


--
-- TOC entry 3417 (class 0 OID 55561)
-- Dependencies: 214
-- Data for Name: bib_homogenes; Type: TABLE DATA; Schema: florestation; Owner: cartopne
--

INSERT INTO bib_homogenes (id_homogene, nom_homogene) VALUES (1, 'Oui');
INSERT INTO bib_homogenes (id_homogene, nom_homogene) VALUES (2, 'Non');
INSERT INTO bib_homogenes (id_homogene, nom_homogene) VALUES (9, 'Ne sait pas');


--
-- TOC entry 3418 (class 0 OID 55564)
-- Dependencies: 215
-- Data for Name: bib_microreliefs; Type: TABLE DATA; Schema: florestation; Owner: cartopne
--

INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (1, 'Roche en place : rocher compact');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (2, 'Roche en place : rocher brisé, jamais surplombant');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (3, 'Formations détritiques : matériel grossier dominant');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (35, 'cône ou tablier d''éboulis (partie médiane à éléments moyens)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (36, 'cône d''avalanche (aucun tri des matériaux entre le haut et le bas)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (37, 'blocs épars dans une pelouse');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (4, 'Formations détritiques : matériel fin dominant (graviers, sables limons, argiles)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (41, 'moraines frontales, latérales ou de fond');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (42, 'creux et bosses (cas général)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (43, 'sommet déboulis (éléments les plus fins)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (44, 'guirlandes de solifluxion');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (45, 'laves torrentielles');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (46, 'alluvions : chenaux, méandres, tresses (le tout privé d''eau)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (47, 'talus naturel (cicatrice d''arrachement ou sapement à la base)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (48, 'berge de lac, de rivière ou de torrent');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (49, 'zone de limon à proximité des glaciers');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (5, 'Microformes liées aux activités humaines présentes (si non, voir 8)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (51, 'talus articficiel (en particulier de piste)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (52, 'piste non goudronnée');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (53, 'sillons de labour');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (54, 'canaux (d''irrigation ou de draînage) / fossé');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (55, 'bordure de sentier et sentier');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (56, 'bourrelet de bulldozer ');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (57, 'ornières');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (58, 'toile en plastique (pour éviter les mauvaises herbes autour des jeunes arbres)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (59, 'petite construction en ciment');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (6, 'Microformes liées aux animaux');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (61, 'draille des ovins, des bovins ou des chamois');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (62, 'labour de sanglier / boutis / gouille / grattis');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (63, 'galeries d''Arvicola terrestris');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (64, 'galeries de campagnols');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (65, 'déblais (devant un terrier de marmotte)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (66, 'autres terriers sans déblais');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (67, 'nids de fourmis');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (7, 'Microformes de nature végétale');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (71, 'bombements à sphaignes');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (72, 'touradons (de grand carex)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (73, 'chablis (racines mise à l''''air)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (74, 'arbres cassés et souches');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (8, 'Microformes liées aux activités humaines passées sauf murets (3.2) et clapier d''épierrement (3.3)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (81, 'brou, talus limitant une terrasse de culture');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (82, 'bombement entre chemin et champs');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (83, 'canal d''irrigation abandonné');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (9, 'Microformes liées à un pergélisol');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (91, 'buttes gazonnées (Emparis)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (92, 'langues gazonnées');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (93, 'sols polygonaux');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (94, 'glaciers rocheux');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (11, 'Poli glaciaire, roches moutonnées, dalles rocheuses lisses,"lauze"');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (12, 'Lapiaz (forme de dissolution du calcaire)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (13, 'Portion de falaise avec surplombs');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (14, 'Pied de falaise surplombante : balme " chemin de pluie" blocs écroulés');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (21, 'Eperons rocheux, rochers brisés, rochillons, petites vires, gradins rocheux');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (22, '"Fesses d''éléphant" (roubines)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (24, 'Ravines (entre les fesses d''éléphant), rigoles et autres talwegs');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (25, 'Petites barres (1 à 5 mètres)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (26, 'Débris rocheux en place ; pente très faible');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (27, 'Fond d''oukane  (crevasse rocheuse)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (28, 'Fond de doline');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (31, 'Falaise délabrée, disloquée  (fissures ouvertes)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (23, 'Couloir (entre les éprerons rocheux)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (32, 'Muret de pierres sèches, ruine   (si non voir 5.9)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (33, 'Clapier d''épierrement');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (34, 'Casse, éboulis (partie inférieure à éléments les plus grossiers)');


--
-- TOC entry 3419 (class 0 OID 55567)
-- Dependencies: 216
-- Data for Name: bib_programmes_fs; Type: TABLE DATA; Schema: florestation; Owner: cartopne
--

INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (3, 'IPA');
INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (4, 'STERF');
INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (5, 'Phytomasse');
INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (2, 'Natura 2000');
INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (1, 'Complément flore patrimoniale');
INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (6, 'Relevé sur un sommet');
INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (7, 'Milieux');
INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (8, 'Messicoles');
INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (9, 'M.A.E et C.A.D');
INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (10, 'Programme Bocage');
INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (101, 'Sophie');
INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (102, 'Autre');
INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (999, 'Aucun programme complémentaire');
INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (11, 'Ecologie verticale');
INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (12, 'Combes à neige');
INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (13, 'E.N.S');


--
-- TOC entry 3420 (class 0 OID 55570)
-- Dependencies: 217
-- Data for Name: bib_surfaces; Type: TABLE DATA; Schema: florestation; Owner: cartopne
--

INSERT INTO bib_surfaces (id_surface, nom_surface) VALUES (1, '100 m2');
INSERT INTO bib_surfaces (id_surface, nom_surface) VALUES (2, '10 m2');
INSERT INTO bib_surfaces (id_surface, nom_surface) VALUES (4, 'de 11 à 100 m2');
INSERT INTO bib_surfaces (id_surface, nom_surface) VALUES (5, 'de 101 à 1000 m2');
INSERT INTO bib_surfaces (id_surface, nom_surface) VALUES (3, 'Inf à 10 m2');
INSERT INTO bib_surfaces (id_surface, nom_surface) VALUES (999, 'Pas d''info');

-- Completed on 2014-09-04 15:12:51

--
-- PostgreSQL database dump complete
--

