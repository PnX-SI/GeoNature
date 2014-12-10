--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Data for Name: t_fiches_cf; Type: TABLE DATA; Schema: contactfaune; Owner: cartopnx
--

INSERT INTO contactfaune.t_fiches_cf VALUES (1, NULL, '2014-12-08', 967, 0, 967, '2014-12-09 18:23:41.009101', '2014-12-09 18:26:50.41963', false, -1, 'web', 2, 3857, 1, 1, '0101000020110F0000327AEA00FEB4184186BA592FFC105541', '01010000206A0800005A2BBC33F0E826418E2218932C465841');
INSERT INTO contactfaune.t_fiches_cf VALUES (2, NULL, '2014-12-10', 409, 0, 409, '2014-12-10 16:52:19.323035', '2014-12-10 17:15:40.195743', false, -1, 'web', 2, 3857, 2, 2, '0101000020110F000052C7B622B3AB1A41D1F5B32AE70A5541', '01010000206A0800007C3DB396459D274140D397690E425841');
INSERT INTO contactfaune.t_fiches_cf VALUES (3, NULL, '2014-12-10', 2772, 0, 2772, '2014-12-10 16:50:51.534199', '2014-12-10 17:15:57.502648', false, -1, 'web', 2, 3857, 1, 1, '0101000020110F00008E467880980E254132FD37DF3C495541', '01010000206A0800008F2C3BA375162D41F6C357AEFB725841');

--
-- Data for Name: cor_role_fiche_cf; Type: TABLE DATA; Schema: contactfaune; Owner: cartopnx
--

INSERT INTO contactfaune.cor_role_fiche_cf VALUES (1, 1);
INSERT INTO contactfaune.cor_role_fiche_cf VALUES (2, 1);
INSERT INTO contactfaune.cor_role_fiche_cf VALUES (3, 1);


--
-- Data for Name: t_releves_cf; Type: TABLE DATA; Schema: contactfaune; Owner: cartopnx
--

INSERT INTO contactfaune.t_releves_cf VALUES (1, 1, 704, 35, 1, 0, 0, 0, 0, 0, 0, 67111, 'Ablette', 'test', false, false, 1);
INSERT INTO contactfaune.t_releves_cf VALUES (2, 2, 704, 2, 0, 0, 0, 0, 1, 0, 0, 67111, 'Ablette', 'very bad ablette cévenole', false, true, 7);
INSERT INTO contactfaune.t_releves_cf VALUES (3, 3, 704, 35, 1, 0, 0, 0, 0, 0, 0, 67111, 'Ablette', 'la plus haute ablette du monde c''est dans les écrins', false, false, 6);


--
-- Name: t_releves_cf_gid_seq; Type: SEQUENCE SET; Schema: contactfaune; Owner: cartopnx
--

SELECT pg_catalog.setval('contactfaune.t_releves_cf_gid_seq', 3, true);


--
-- PostgreSQL database dump complete
--

