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
-- Data for Name: t_fiches_cf; Type: TABLE DATA; Schema: contactfaune; Owner: cartopnx
--

INSERT INTO t_fiches_cf VALUES (2, NULL, '2014-12-10', 409, 0, 409, '2014-12-11 18:00:33.561278', '2014-12-11 18:00:33.561278', false, -1, 'web', 2, 3857, 2, 2, '0101000020110F000052C7B622B3AB1A41D1F5B32AE70A5541', '01010000206A0800007C3DB396459D274140D397690E425841');
INSERT INTO t_fiches_cf VALUES (3, NULL, '2014-12-10', 2772, 0, 2772, '2014-12-11 18:00:33.569997', '2014-12-11 18:00:33.569997', false, -1, 'web', 2, 3857, 1, 1, '0101000020110F00008E467880980E254132FD37DF3C495541', '01010000206A0800008F2C3BA375162D41F6C357AEFB725841');
INSERT INTO t_fiches_cf VALUES (1, NULL, '2014-12-08', 967, 0, 967, '2014-12-11 18:00:33.570695', '2014-12-11 18:00:33.570695', false, -1, 'web', 2, 3857, 1, 1, '0101000020110F0000327AEA00FEB4184186BA592FFC105541', '01010000206A0800005A2BBC33F0E826418E2218932C465841');
INSERT INTO t_fiches_cf VALUES (4, NULL, '2014-12-11', 133, 0, 133, '2014-12-11 18:00:33.571303', '2014-12-11 18:00:33.571303', false, -1, 'web', 2, 3857, 1, 1, '0101000020110F000039575AC72A8403417EACE095539D5441', '01010000206A0800004DB1A3201282214198AFE5A021F45741');
INSERT INTO t_fiches_cf VALUES (5, NULL, '2014-12-11', 690, 0, 690, '2014-12-11 18:00:33.571909', '2014-12-11 18:00:33.571909', false, -1, 'web', 2, 3857, 1, 1, '0101000020110F0000E237C7B1493218415E58C82FAE0E5541', '01010000206A080000DD8032F13FBA264190CF4B447C445841');


--
-- Data for Name: cor_role_fiche_cf; Type: TABLE DATA; Schema: contactfaune; Owner: cartopnx
--

INSERT INTO cor_role_fiche_cf VALUES (2, 1);
INSERT INTO cor_role_fiche_cf VALUES (3, 1);
INSERT INTO cor_role_fiche_cf VALUES (1, 1);
INSERT INTO cor_role_fiche_cf VALUES (4, 1);
INSERT INTO cor_role_fiche_cf VALUES (5, 1);


--
-- Data for Name: t_releves_cf; Type: TABLE DATA; Schema: contactfaune; Owner: cartopnx
--

INSERT INTO t_releves_cf VALUES (1, 1, 704, 35, 1, 0, 0, 0, 0, 0, 0, 67111, 'Ablette', 'test', false, false, 1);
INSERT INTO t_releves_cf VALUES (2, 2, 704, 2, 0, 0, 0, 0, 1, 0, 0, 67111, 'Ablette', 'very bad ablette cévenole', false, true, 7);
INSERT INTO t_releves_cf VALUES (3, 3, 704, 35, 1, 0, 0, 0, 0, 0, 0, 67111, 'Ablette', 'la plus haute ablette du monde c''est dans les écrins', false, false, 6);
INSERT INTO t_releves_cf VALUES (4, 1, 704, 36, 0, 0, 2, 0, 0, 0, 0, 67111, 'Ablette', '', false, false, 4);
INSERT INTO t_releves_cf VALUES (5, 4, 704, 37, 0, 1, 0, 0, 0, 0, 0, 67111, 'Ablette', '', false, false, 5);
INSERT INTO t_releves_cf VALUES (6, 5, 64, 21, 1, 3, 0, 0, 0, 0, 0, 60612, 'Lynx boréal', '', false, false, 6);


--
-- Name: t_releves_cf_gid_seq; Type: SEQUENCE SET; Schema: contactfaune; Owner: cartopnx
--

SELECT pg_catalog.setval('t_releves_cf_gid_seq', 6, true);


SET search_path = contactinv,public, pg_catalog;

--
-- Data for Name: t_fiches_inv; Type: TABLE DATA; Schema: contactinv; Owner: cartopnx
--

INSERT INTO t_fiches_inv VALUES (1, NULL, '2014-12-11', 11, 1525, 0, 1525, '2014-12-11 18:03:46.288976', '2014-12-11 18:03:46.303834', false, -1, 'web', 2, 3857, 3, 3, '0101000020110F00002B227945A00C19412828452BB11B5541', 0, '01010000206A0800003642BEE8C5072741DD5BFD24D74D5841');
INSERT INTO t_fiches_inv VALUES (2, NULL, '2014-12-11', 10, 1047, 0, 1047, '2014-12-11 18:04:54.159624', '2014-12-11 18:04:54.172636', false, -1, 'web', 2, 3857, 3, 3, '0101000020110F0000F2B4DBC6113F18413955881BB4035541', 0, '01010000206A08000022D826FF46BF26411D8067D4A63C5841');


--
-- Data for Name: cor_role_fiche_inv; Type: TABLE DATA; Schema: contactinv; Owner: cartopnx
--

INSERT INTO cor_role_fiche_inv VALUES (1, 1);
INSERT INTO cor_role_fiche_inv VALUES (2, 1);


--
-- Data for Name: t_releves_inv; Type: TABLE DATA; Schema: contactinv; Owner: cartopnx
--

INSERT INTO t_releves_inv VALUES (1, 1, 2804, 3, 0, 0, 1, 0, 11165, 'Coccinella septempunctata', 'test', false, false, 1, NULL);
INSERT INTO t_releves_inv VALUES (2, 2, 816, 8, 100, 0, 0, 0, 18437, 'Ecrevisse à pieds blancs', 'test', false, false, 2, NULL);


--
-- Name: t_releves_inv_gid_seq; Type: SEQUENCE SET; Schema: contactinv; Owner: cartopnx
--

SELECT pg_catalog.setval('t_releves_inv_gid_seq', 2, true);


--
-- PostgreSQL database dump complete
--

