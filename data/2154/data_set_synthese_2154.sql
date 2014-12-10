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


--
-- Data for Name: cor_role_fiche_cf; Type: TABLE DATA; Schema: contactfaune; Owner: cartopnx
--

INSERT INTO contactfaune.cor_role_fiche_cf VALUES (1, 1);


--
-- Data for Name: t_releves_cf; Type: TABLE DATA; Schema: contactfaune; Owner: cartopnx
--

INSERT INTO contactfaune.t_releves_cf VALUES (1, 1, 704, 35, 1, 0, 0, 0, 0, 0, 0, 67111, 'Ablette', 'test', false, false, 1);


--
-- Name: t_releves_cf_gid_seq; Type: SEQUENCE SET; Schema: contactfaune; Owner: cartopnx
--

SELECT pg_catalog.setval('contactfaune.t_releves_cf_gid_seq', 1, true);


--
-- PostgreSQL database dump complete
--

