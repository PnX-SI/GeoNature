SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

---------
--DATAS--
---------

INSERT INTO gn_meta.t_datasets  VALUES (1, 'contact', 'Observation aléatoire de la faune, de la flore ou de la fonge', 1, 2, 2, 2, 2, true, NULL, '2017-06-01 00:00:00', '2017-06-01 00:00:00');

INSERT INTO gn_synthese.bib_modules (id_module, name_module, desc_module, entity_module_pk_field, url_module, target, picto_module, groupe_module, active) VALUES (1, 'contact', 'Données issues du contact aléatoire', 'pr_contact.t_occurrences_contact.id_occurrence_contact', '/contact', NULL, NULL, 'CONTACT', true);

INSERT INTO pr_contact.t_releves_contact VALUES(1,1,343,1,'2017-01-01','2017-01-01',1500,1565,'web',FALSE,NULL,NULL,'exemple test',NULL,NULL);
SELECT pg_catalog.setval('t_releves_contact_id_releve_contact_seq', 2, true);

INSERT INTO pr_contact.t_occurrences_contact VALUES(1,1,65,177,30,182,91,347,163,1,'gil','gees',60612,'Lynx Boréal','Taxref V9.0','','','poil',FALSE, now(),now(),'test');
INSERT INTO pr_contact.cor_role_releves_contact VALUES(1,1);
INSERT INTO pr_contact.cor_municipality_releves_contact VALUES(1,'05004');
INSERT INTO  pr_contact.cor_counting_contact VALUES
(1,4,190,166,107,5,5)
,(1,4,191,166,107,1,1);