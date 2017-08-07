<--></-->
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.7
-- Dumped by pg_dump version 9.5.7

-- Started on 2017-06-15 17:26:11 CEST

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
--SET row_security = off;

SET search_path = meta, pg_catalog;

DELETE FROM t_nomenclatures;
DELETE FROM bib_types_nomenclatures;
DELETE FROM t_programmes;
DELETE FROM t_lots;
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (2, 'DS_PUBLIQUE', 'Code d''origine de la donnée', 'Nomenclature des codes d''origine de la donnée : publique, privée, mixte...', 'Validé', '2013-12-05 00:00:00', '2013-12-05 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (3, 'NAT_OBJ_GEO', 'Nature d''objet géographique', 'Nomenclature des natures d''objets géographiques', 'Validé', '2014-01-22 00:00:00', '2015-10-15 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (4, 'DEE_FLOU', 'Existence d''un floutage sur la donnée', 'Nomenclature indiquant l''existence d''un floutage sur la donnée lors de sa création en tant que DEE.', 'Validé', '2015-09-18 00:00:00', '2015-10-15 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (5, 'NIV_PRECIS', 'Niveaux de précision de diffusion souhaités', 'Nomenclature des niveaux de précision de diffusion souhaités par le producteur.', 'Validé', '2015-07-29 00:00:00', '2015-10-15 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (6, 'OBJ_DENBR', 'Objet du dénombrement', 'Nomenclature des objets qui peuvent être dénombrés', 'Validé', '2014-01-22 00:00:00', '2015-10-15 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (7, 'ETA_BIO', 'Etat biologique de l''observation', 'Nomenclature des états biologiques de l''observation.', 'Validé', '2015-07-29 00:00:00', '2015-10-19 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (8, 'NATURALITE', 'Niveau de naturalité', 'Nomenclature des niveaux de naturalité', 'Validé', '2015-07-29 00:00:00', '2015-10-19 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (9, 'SEXE', 'Sexe', 'Nomenclature des sexes', 'Validé', '2015-07-29 00:00:00', '2015-10-19 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (10, 'STADE_VIE', 'Stade de vie : stade de développement du sujet', 'Nomenclature des stades de vie : stades de développement du sujet de l''observation.', 'Validé', '2015-07-29 00:00:00', '2016-03-24 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (11, 'STAT_BIOGEO', 'Statut biogéographique', 'Nomenclature des statuts biogéographiques.', 'Validé', '2015-07-29 00:00:00', '2015-10-15 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (12, 'REF_HAB', 'Référentiels d''habitats et typologies', 'Nomenclature des référentiels d''habitats et typologies utilisés pour rapporter un habitat au sein du standard. La référence à paraître prochainement est HABREF. http://inpn.mnhn.fr/telechargement/referentiels/habitats Les typologies sont disponibles à la même adresse, mais seront prochainement à l''adresse suivante : http://inpn.mnhn.fr/telechargement/referentiels/habitats/typologies', 'Validé', '2013-03-13 00:00:00', '2016-06-23 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (13, 'STATUT_BIO', 'Statut biologique', 'Nomenclature des statuts biologiques.', 'Validé', '2015-07-29 00:00:00', '2015-12-16 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (14, 'METH_OBS', 'Méthodes d''observation', 'Nomenclature des méthodes d''observation, indiquant de quelle manière ou avec quel indice on a pu observer le sujet.', 'Validé', '2015-07-29 00:00:00', '2015-12-16 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (15, 'PREUVE_EXIST', 'Preuve existante', 'Nomenclature de l''existence des preuves.', 'Validé', '2015-07-29 00:00:00', '2015-12-16 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (16, 'SENSIBILITE', 'Niveaux de sensibilité', 'Nomenclature des niveaux de sensibilité possibles', 'Validé', '2015-06-10 00:00:00', '2016-06-23 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (17, 'SENSIBLE', 'Valeurs de sensibilité qualitative', 'Nomenclature des valeurs de sensibilité qualitative (oui/non)', 'Validé', '2015-07-29 00:00:00', '2016-04-07 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (18, 'STATUT_OBS', 'Statut d''observation', 'Nomenclature des statuts d''observation.', 'Validé', '2013-12-05 00:00:00', '2016-03-24 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (19, 'STATUT_SOURCE', 'Statut de la source', 'Nomenclature des statuts possibles de la source.', 'Validé', '2013-12-04 00:00:00', '2013-12-04 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (20, 'TYP_ATTR', 'Type de l''attribut', 'Nomenclature des types d''attributs additionnels.', 'Validé', '2015-09-16 00:00:00', '2015-12-07 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (21, 'TYP_DENBR', 'Type de dénombrement', 'Nomenclature des types de dénombrement possibles (comptage, estimation...)', 'Validé', '2014-01-22 00:00:00', '2015-12-16 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (22, 'TYP_EN', 'Type d''espace naturel', 'Nomenclature des types d''espaces naturels.', 'Validé', '2014-01-22 00:00:00', '2016-06-15 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (23, 'TYP_INF_GEO', 'Type d''information géographique', 'Nomenclature des types d''information géographique dans le cas de l''utilisation d''un rattachement à un objet géographique (commune, département, espace naturel, masse d''eau...).', 'Validé', '2015-09-18 00:00:00', '2015-12-16 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (24, 'TYP_GRP', 'Type de regroupement', 'Nomenclature listant les valeurs possibles pour le type de regroupement.', 'Validé', '2015-06-09 00:00:00', '2015-12-07 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (25, 'VERS_ME', 'Version des masses d''eau', 'Nomenclature des versions du référentiel SANDRE utilisé pour les masses d''eau.', 'Validé', '2015-09-18 00:00:00', '2015-12-16 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (26, 'ACC2', 'Raison de niveau d''accessibilité', 'Nomenclature des raisons d''un niveau d''accessibilité', 'Validé', '2016-04-07 00:00:00', '2016-04-08 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (27, 'ACC', 'Niveau d''accessibilité', 'Nomenclature des niveaux d''accessibilité à un site géologique', 'Validé', '2016-04-07 00:00:00', '2016-04-08 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (28, 'AUTPREAL', 'Autorisation préalable pour accès', 'Nomenclature des valeurs concernant l''éventuelle délivrance d''une autorisation préalable pour accéder à un site', 'Validé', '2016-04-07 00:00:00', '2016-04-08 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (29, 'GILGES', 'Code Gilges', 'Nomenclature des codes Gilges', 'Validé', '2016-04-07 00:00:00', '2016-04-08 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (30, 'REGION', 'Code région', 'Nomenclature des codes région', 'Validé', '2016-04-07 00:00:00', '2016-04-08 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (31, 'CONFID', 'Valeur de confidentialité', 'Nomenclatures des valeurs de confidentialité', 'Validé', '2016-04-07 00:00:00', '2016-04-08 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (32, 'COUPGEOL', 'Présence/absence de coupe géologique', 'Nomenclature de présence/absence de coupe géologique', 'Validé', '2016-04-07 00:00:00', '2016-04-08 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (33, 'ETAT1', 'Niveau d''état d''un site géologique', 'Nomenclature des niveaux d''état potentiels d''un site', 'Validé', '2016-04-07 00:00:00', '2016-04-08 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (34, 'ETAT2', 'Raison du niveau d''état d''un site géologique', 'Nomenclature indiquant les raisons du niveau d''état du site', 'Validé', '2016-04-07 00:00:00', '2016-04-08 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (35, 'EXISTPROT', 'Existence d''une protection pour un site géologique', 'Nomenclature indiquant si une protection existe ou non', 'Validé', '2016-04-07 00:00:00', '2016-04-08 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (36, 'INTGEOL', 'Intérêt géologique du site géologique', 'Nomenclature des intérêts géologiques que peut avoir un site', 'Validé', '2016-04-07 00:00:00', '2016-04-08 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (37, 'INTSECTYP', 'Type d''intérêt secondaire du site géologique', 'Nomenclature des types d''intérêt secondaire potentiels d''un site géologique', 'Validé', '2016-04-07 00:00:00', '2016-04-08 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (38, 'INTSEC', 'Intérêt secondaire du site géologique', 'Nomenclature des intérêts secondaires potentiels, fonction des types d''intérêts secondaires.', 'Validé', '2016-04-07 00:00:00', '2016-04-08 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (39, 'MODIF', 'Statut de modification de fiche de site géologique', 'Nomenclature des statuts de modification de fiche de site', 'Validé', '2016-04-07 00:00:00', '2016-04-08 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (40, 'PAY', 'Paiement spécifique à l''accès du site géologique', 'Nomenclature qui indique si un site nécessite un paiement spécifique pour y accéder', 'Validé', '2016-04-07 00:00:00', '2016-04-08 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (41, 'PEROUV', 'Périodes d''ouverture du site géologique', 'Nomenclature des périodes d''ouverture d''un site', 'Validé', '2016-04-07 00:00:00', '2016-04-08 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (42, 'PHENGEOL', 'Phénomène géologique', 'Nomenclature des phénomènes géologiques', 'Validé', '2016-04-07 00:00:00', '2016-04-08 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (43, 'RARETE', 'Niveau de rareté du site géologique', 'Nomenclature des niveaux de rareté pour les sites géologiques', 'Validé', '2016-04-07 00:00:00', '2016-04-08 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (44, 'JUR1', 'Statut de protection, éléments primaires, pour un site géologique', 'Nomenclature des statuts de protection, éléments primaires', 'Validé', '2016-04-07 00:00:00', '2016-04-08 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (45, 'JUR2', 'Statut de protection, éléments secondaires, pour un site géologique', 'Nomenclature des statuts de protection, éléments secondaires', 'Validé', '2016-04-07 00:00:00', '2016-04-08 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (46, 'PROT1', 'Type générique de statut de protection pour un site géologique', 'Nomenclature des types génériques (ou primaires) de statuts de protection et/ou de gestion', 'Validé', '2016-04-07 00:00:00', '2016-04-08 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (47, 'PROT2', 'Type spécifique de statut de protection pour un site  géologique', 'Nomenclature des types spécifiques (ou secondaires) de statuts de protection et/ou gestion d''un site géologique', 'Validé', '2016-04-07 00:00:00', '2016-04-08 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (48, 'VALNAT', 'Statut de validation nationale pour un site géologique', 'Nomenclature des statuts de validation nationaux pour un site géologique', 'Validé', '2016-04-07 00:00:00', '2016-04-08 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (49, 'VALREG', 'Statut de validation régionale pour un site géologique', 'Nomenclature des statuts de validation régionaux pour le site considéré.', 'Validé', '2016-04-07 00:00:00', '2016-04-08 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (50, 'DOC', 'Type de document', 'Nomenclature des types de documents', 'Validé', '2016-04-07 00:00:00', '2016-04-08 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (51, 'INVGEOL', 'Type d''inventaire géologique', 'Nomenclature des types d''inventaires géologiques pouvant être réalisés sur un site', 'Validé', '2016-04-07 00:00:00', '2016-09-01 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (52, 'TYPPERS', 'Intervenant fiche (type de personne)', 'Nomenclature des types de personnes ayant pu intervenir sur une fiche de site géologique, de quelque manière que ce soit, ou types de personnes.', 'Validé', '2016-04-07 00:00:00', '2016-04-08 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (53, 'TYPO1', 'Typologie primaire d''un site géologique', 'Nomenclature des éléments de typologie primaire d''un site géologique', 'Validé', '2016-04-07 00:00:00', '2016-04-08 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (54, 'TYPO2', 'Typologie secondaire d''un site géologique', 'Nomenclature des éléments secondaires de typologie du site géologique. Certains éléments de cette liste sont restreints à certains éléments primaires uniquement (cf. nomenclature 53).', 'Validé', '2016-04-07 00:00:00', '2016-04-08 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (55, 'TYPO3', 'Typologie tertiaire d''un site géologique', 'Nomenclature des éléments tertiaires de typologie du site géologique', 'Validé', '2016-04-07 00:00:00', '2016-04-08 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (56, 'UNITSURF', 'Unité de superficie pour un site géologique', 'Nomenclature des unités de superficie pouvant être utilisées pour indiquer la surface d''un site géologique', 'Validé', '2016-04-07 00:00:00', '2016-04-08 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (57, 'USEACTU', 'Usage d''un site géologique', 'Nomenclature des usages qui peuvent être faits d''un site géologique', 'Validé', '2016-04-07 00:00:00', '2016-04-08 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (58, 'AIRECONNUE', 'Aire connue', 'Nomenclature des valeurs indiquant si la surface d''un relevé est connue ou non', 'Validé', '2016-06-21 00:00:00', '2016-06-21 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (59, 'BRANCHEMETH', 'Méthodes phytosociologiques, branches', 'Nomenclature des branches de méthodes phytosociologiques', 'Validé', '2016-06-21 00:00:00', '2016-06-21 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (60, 'BRAUNBLANQABDOM', 'Braun Blanquet Pavillard, abondance-dominance', 'Nomenclature des valeurs pour l''échelle d''abondance-dominance de Braun-Blanquet Pavillard (1928)', 'Validé', '2016-06-21 00:00:00', '2016-06-21 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (61, 'BRAUNBARK', 'Braun Blanquet Barkman, abondance-dominance', 'Nomenclature des valeurs de l''échelle de Braun-Blanquet Barkman complétée telle que dans le dictionnaire de sociologie et synécologie végétales (Géhu, 2006)', 'Validé', '2016-06-21 00:00:00', '2016-06-21 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (62, 'BRAUNPAV', 'Braun Blanquet Pavillard, abondance', 'Nomenclature des valeurs de l''échelle d''abondance de Braun-Blanquet Pavillard (1928)', 'Validé', '2016-06-21 00:00:00', '2016-06-21 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (63, 'COMPLETREL', 'Complétude des relevés', 'Nomenclature des valeurs de complétude des relevés phytosociologiques détaillés', 'Validé', '2016-06-21 00:00:00', '2016-06-21 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (64, 'RATTACH', 'Rattachement au syntaxon, confère', 'Nomenclature des indicateurs de doute dans le rattachement au syntaxon (confère).', 'Validé', '2016-06-21 00:00:00', '2016-06-21 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (65, 'DOMIN', 'Echelle de Domin', 'Nomenclature des valeurs de l''échelle de Domin (Source : Evans & Dahl, 1955)', 'Validé', '2016-06-21 00:00:00', '2016-06-21 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (66, 'EXPOSITION', 'Exposition d''un terrain', 'Nomenclature des points cardinaux et intercardinaux permettant d''indiquer l''exposition d''un terrain.', 'Validé', '2016-06-21 00:00:00', '2016-06-21 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (67, 'FORMES', 'Formes du relevé', 'Nomenclature des formes possibles pour un relevé phytosociologique', 'Validé', '2016-06-21 00:00:00', '2016-06-21 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (68, 'LONDO', 'Echelle de Londo', 'Nomenclature des valeurs de l''échelle d''abondance-dominnance de Londo suivant Londo, 1976 (The decimal scale for releves of permanent quadrats)', 'Validé', '2016-06-21 00:00:00', '2016-06-21 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (69, 'NIVORGA', 'Niveaux d''organisation des relevés', 'Nomenclature des niveaux d''organisation auxquels peuvent se trouver des relevés phytosociologiques détaillés', 'Validé', '2016-06-21 00:00:00', '2016-06-21 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (70, 'ORDIN', 'Echelle ordinale', 'Nomenclature des valeurs de l''échelle ordinale d''abondance-dominance, suivant Barkman (1964)', 'Validé', '2016-06-21 00:00:00', '2016-06-21 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (71, 'PRES', 'Présence', 'Nomenclature des cas de présence d''un taxon', 'Validé', '2016-06-21 00:00:00', '2016-06-21 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (72, 'SOCIAB', 'Sociabilité', 'Nomenclature des valeurs de sociabilité des taxons végétaux suivant Braun Blanquet (1964)', 'Validé', '2016-06-21 00:00:00', '2016-06-21 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (73, 'TYPEAIRE', 'Types de surface', 'Nomenclature des types de surfaces utilisées pour les relevés phytosociologiques', 'Validé', '2016-06-21 00:00:00', '2016-06-21 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (74, 'TYPCORR', 'Type de correspondance avec le syntaxon', 'Nomenclature des types de correspondance entre relevés synusiaux et syntaxons sigmatistes', 'Validé', '2016-06-21 00:00:00', '2016-06-21 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (75, 'TYPECH', 'Type d''échelle', 'Nomenclature des types d''échelles utilisées pour l''évaluation d''un paramètre de taxon en phytosociologie', 'Validé', '2016-06-21 00:00:00', '2016-06-21 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (76, 'TYPEPARM', 'Paramètres suivis pour un taxon, phytosociologie', 'Nomenclature des types de paramètres potentiellement suivis pour un taxon en phytosociologie', 'Validé', '2016-06-21 00:00:00', '2016-06-21 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (77, 'UNITOP', 'Unités opérationnelles', 'Liste des modifications morphologiques végétales particulières, génétiquement non fixées (unités morphologiques opérationnelles, unités biologiques opérationnelles, et/ou accommodats), imposées par le milieu', 'Validé', '2016-06-21 00:00:00', '2016-06-21 00:00:00');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (0, 'ROOT', 'Racine des nomenclatures', 'Racine. Parent de toutes les nomenclatures', 'GeoNature', '2017-06-15 12:51:30.197042', '2017-06-15 12:51:30.197042');
INSERT INTO bib_types_nomenclatures (id_type_nomenclature, mnemonique, libelle_type_nomenclature, definition_type_nomenclature, statut_type_nomenclature, date_create, date_update) VALUES (100, 'TECHNIQUE_OBS', 'Techniques d''observation', 'Une technique désigne l’ensemble des savoirs-faire, procédés et outils spécifiques, mobilisés de manière logique (règles, étapes et principes) pour collecter des données associées à un paramètre à observer ou à un facteur écologique à prendre en compte.
Ce sont les moyens mis en oeuvre sur le terrain pour l''observation d''espèces ou d''habitats.
Une technique est définie par rapport à une cible. Dans le cadre d’un protocole, elle doit être reproductible dans le temps et dans l’espace.', 'Campanule validation', '2017-06-19 15:03:31.135525', '2017-06-19 15:03:31.135525');

INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (0, 0, '0', 'Root', 'Racine des nomenclatures', 'Racine = Parent de toutes les nomenclatures', 'GeoNature', 0, '000', '2017-06-15 12:53:01.201955', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (1, 10, 'STADE_VIE', 'Stade de vie', 'Stade de vie', 'Stade de vie', 'GeoNature', 0, '010', '2017-06-15 12:33:04.435521', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (86, 2, 'DS_PUBLIQUE', 'DS_PUBLIQUE', 'Code d''origine de la donnée', 'Nomenclature des codes d''origine de la donnée : publique, privée, mixte...', 'GeoNature', 0, '002', '2017-06-15 14:01:10.46415', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (85, 19, 'STATUT_SOURCE', 'STATUT_SOURCE', 'Statut de la source', 'Nomenclature des statuts possibles de la source.', 'GeoNature', 0, '019', '2017-06-15 14:00:39.493901', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (84, 16, 'SENSIBILITE', 'SENSIBILITE', 'Niveaux de sensibilité', 'Nomenclature des niveaux de sensibilité possibles', 'GeoNature', 0, '016', '2017-06-15 13:59:32.543721', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (82, 13, 'STATUT_BIO', 'STATUT_BIO', 'Statut biologique', 'Nomenclature des statuts biologiques.', 'GeoNature', 0, '013', '2017-06-15 12:58:43.51278', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (83, 14, 'METH_OBS', 'METH_OBS', 'Méthodes d''observation', 'Nomenclature des méthodes d''observation, indiquant de quelle manière ou avec quel indice on a pu observer le sujet.', 'GeoNature', 0, '014', '2017-06-15 13:55:01.757403', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (98, 18, 'STATUT_OBS', 'STATUT_OBS', 'Statut d''observation', 'Nomenclature des statuts d''observation.', 'GeoNature', 0, '018', '2017-06-15 15:44:29.136533', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (102, 20, 'TYP_ATTR', 'TYP_ATTR', 'Type de l''attribut', 'Nomenclature des types d''attributs additionnels.', 'GeoNature', 0, '020', '2017-06-15 15:47:46.088312', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (105, 21, 'TYP_DENBR', 'TYP_DENBR', 'Type de dénombrement', 'Nomenclature des types de dénombrement possibles (comptage, estimation...)', 'GeoNature', 0, '021', '2017-06-15 15:50:10.679957', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (175, 7, 'ETA_BIO', 'ETA_BIO', 'Etat biologique de l''observation', 'Nomenclature des états biologiques de l''observation.', 'GeoNature', 0, '007', '2017-06-15 16:40:08.476652', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (164, 6, 'OBJ_DENBR', 'OBJ_DENBR', 'Objet du dénombrement', 'Nomenclature des objets qui peuvent être dénombrés', 'GeoNature', 0, '006', '2017-06-15 16:34:14.436954', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (157, 5, 'NIV_PRECIS', 'NIV_PRECIS', 'Niveaux de précision de diffusion souhaités', 'Nomenclature des niveaux de précision de diffusion souhaités par le producteur.', 'GeoNature', 0, '005', '2017-06-15 16:32:42.005049', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (145, 24, 'TYP_GRP', 'TYP_GRP', 'Type de regroupement', 'Nomenclature listant les valeurs possibles pour le type de regroupement.', 'GeoNature', 0, '024', '2017-06-15 16:28:33.444783', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (195, 3, 'NAT_OBJ_GEO', 'NAT_OBJ_GEO', 'Nature d''objet géographique', 'Nomenclature des natures d''objets géographiques', 'GeoNature', 0, '003', '2017-06-15 17:06:36.786688', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (187, 9, 'SEXE', 'SEXE', 'Sexe', 'Nomenclature des sexes', 'GeoNature', 0, '009', '2017-06-15 17:01:11.050998', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (180, 8, 'NATURALITE', 'NATURALITE', 'Niveau de naturalité', 'Nomenclature des niveaux de naturalité', 'GeoNature', 0, '008', '2017-06-15 16:59:05.859797', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (142, 23, 'TYP_INF_GEO', 'TYP_INF_GEO', 'Type d''information géographique', 'Nomenclature des types d''information géographique dans le cas de l''utilisation d''un rattachement à un objet géographique (commune, département, espace naturel, masse d''eau...).', 'GeoNature', 0, '023', '2017-06-15 16:03:59.511517', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (110, 22, 'TYP_EN', 'TYP_EN', 'Type d''espace naturel', 'Nomenclature des types d''espaces naturels.', 'GeoNature', 0, '022', '2017-06-15 15:58:57.805968', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (95, 17, 'SENSIBLE', 'SENSIBLE', 'Valeurs de sensibilité qualitative', 'Nomenclature des valeurs de sensibilité qualitative (oui/non)', 'GeoNature', 0, '017', '2017-06-15 15:39:36.514988', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (90, 15, 'PREUVE_EXIST', 'PREUVE_EXIST', 'Preuve existante', 'Nomenclature de l''existence des preuves.', 'GeoNature', 0, '015', '2017-06-15 14:22:21.68921', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (199, 4, 'DEE_FLOU', 'DEE_FLOU', 'Existence d''un floutage sur la donnée', 'Nomenclature indiquant l''existence d''un floutage sur la donnée lors de sa création en tant que DEE.', 'GeoNature', 0, '004', '2017-06-15 17:12:55.666177', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (202, 11, 'STAT_BIOGEO', 'STAT_BIOGEO', 'Statut biogéographique', 'Nomenclature des statuts biogéographiques.', 'GeoNature', 0, '011', '2017-06-15 17:15:50.315314', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (210, 100, 'TECHNIQUES_OBS', 'Techniques d''observation', 'Techniques d''observation', 'Une technique désigne l’ensemble des savoirs-faire, procédés et outils spécifiques, mobilisés de manière logique (règles, étapes et principes) pour collecter des données associées à un paramètre à observer ou à un facteur écologique à prendre en compte.
Ce sont les moyens mis en oeuvre sur le terrain pour l''observation d''espèces ou d''habitats.
Une technique est définie par rapport à une cible. Dans le cadre d’un protocole, elle doit être reproductible dans le temps et dans l’espace.', 'Campanule en cours d', 0, '100', '2017-06-19 15:04:20.845984', NULL, true);

INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (4, 10, '2', 'Adulte', 'Adulte', 'L''individu est au stade adulte.', 'Validé', 1, '010.002', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (5, 10, '3', 'Juvénile', 'Juvénile', 'L''individu n''a pas encore atteint le stade adulte. C''est un individu jeune.', 'Validé', 1, '010.003', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (66, 14, '24', 'Oothèque', 'Oothèque', 'Membrane-coque qui protège la ponte de certains insectes et certains mollusques.', 'Validé', 83, '014.024', '2015-12-07 00:00:00', '2015-12-07 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (67, 14, '25', 'Vu et entendu', 'Vu et entendu', 'Vu et entendu : l''occurrence a à la fois été vue et entendue.', 'Validé', 83, '014.025', '2015-12-07 00:00:00', '2015-12-07 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (78, 2, 'NSP', 'Ne sait pas', 'Ne sait pas', 'Ne sait pas : L’information indiquant si la Donnée Source est publique ou privée n’est pas connue.', 'Validé', 86, '002.000', '2013-12-05 00:00:00', '2013-12-05 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (29, 13, '0', 'Inconnu', 'Inconnu', 'Inconnu : Le statut biologique de l''individu n''est pas connu.', 'Validé', 82, '013.000', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (30, 13, '1', 'Non renseigné', 'Non renseigné', 'Non renseigné : Le statut biologique de l''individu n''a pas été renseigné.', 'Validé', 82, '013.001', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (31, 13, '2', 'Non Déterminé', 'Non Déterminé', 'Non déterminé : Le statut biologique de l''individu n''a pas pu être déterminé.', 'Validé', 82, '013.002', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (32, 13, '3', 'Reproduction', 'Reproduction', 'Reproduction : Le sujet d''observation en est au stade de reproduction (nicheur, gravide, carpophore, floraison, fructification…)', 'Validé', 82, '013.003', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (33, 13, '4', 'Hibernation', 'Hibernation', 'Hibernation : L’hibernation est un état d’hypothermie régulée, durant plusieurs jours ou semaines qui permet aux animaux de conserver leur énergie pendant l’hiver. ', 'Validé', 82, '013.004', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (34, 13, '5', 'Estivation', 'Estivation', 'Estivation : L''estivation est un phénomène analogue à celui de l''hibernation, au cours duquel les animaux tombent en léthargie. L''estivation se produit durant les périodes les plus chaudes et les plus sèches de l''été.', 'Validé', 82, '013.005', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (36, 13, '7', 'Swarming', 'Swarming', 'Swarming : Indique que l''individu a un comportement de swarming : il se regroupe avec d''autres individus de taille similaire, sur une zone spécifique, ou en mouvement.', 'Validé', 82, '013.007', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (37, 13, '8', 'Chasse / alimentation', 'Chasse / alimentation', 'Chasse / alimentation : Indique que l''individu est sur une zone qui lui permet de chasser ou de s''alimenter.', 'Validé', 82, '013.008', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (35, 13, '6', 'Halte migratoire', 'Halte migratoire', 'Halte migratoire : Indique que l''individu procède à une halte au cours de sa migration, et a été découvert sur sa zone de halte.', 'Validé', 82, '013.006', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (38, 13, '9', 'Pas de reproduction', 'Pas de reproduction', 'Pas de reproduction : Indique que l''individu n''a pas un comportement reproducteur. Chez les végétaux : absence de fleurs, de fruits…', 'Validé', 82, '013.009', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (40, 13, '11', 'Erratique', 'Erratique', 'Erratique : Individu d''une ou de populations d''un taxon qui ne se trouve, actuellement, que de manière occasionnelle dans les limites d’une région. Il a été retenu comme seuil, une absence de 80% d''un laps de temps donné (année, saisons...).', 'Validé', 82, '013.011', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (41, 13, '12', 'Sédentaire', 'Sédentaire', 'Sédentaire : Individu demeurant à un seul emplacement, ou restant toute l''année dans sa région d''origine, même s''il effectue des déplacements locaux.', 'Validé', 82, '013.012', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (39, 13, '10', 'Passage en vol', 'Passage en vol', 'Passage en vol : Indique que l''individu  est de passage et en vol.', 'Validé', 82, '013.010', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (74, 19, 'Li', 'Li', 'Littérature', 'Littérature : l''observation a été extraite d''un article ou un ouvrage scientifique.', 'Validé', 85, '019.002', '2013-12-04 00:00:00', '2013-12-04 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (76, 19, 'Te', 'Te', 'Terrain', 'Terrain : l''observation provient directement d''une base de données ou d''un document issu de la prospection sur le terrain.', 'Validé', 85, '019.001', '2013-12-04 00:00:00', '2013-12-04 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (75, 19, 'NSP', 'NSP', 'Ne Sait Pas', 'Ne Sait Pas : la source est inconnue.', 'Validé', 85, '019.000', '2013-12-04 00:00:00', '2013-12-04 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (77, 2, 'Ac', 'Publique acquise', 'Publique acquise', 'Publique Acquise : La donnée-source a été produite par un organisme privé (associations, bureaux d’étude…) ou une personne physique à titre personnel. Les droits patrimoniaux exclusifs ou non exclusifs, de copie, traitement et diffusion sans limitation ont été acquis à titre gracieux ou payant, sur marché ou par convention, par un organisme ayant autorité publique. La donnée-source est devenue publique.  ', 'Validé', 86, '002.001.002', '2013-12-05 00:00:00', '2013-12-05 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (52, 14, '10', 'Restes dans pelote de réjection', 'Restes dans pelote de réjection', 'Identifie l''espèce à laquelle appartiennent les restes retrouvés dans la pelote de réjection (os ou exosquelettes, par exemple).', 'Validé', 83, '014.010', '2015-07-29 00:00:00', '2015-12-07 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (42, 14, '0', 'Vu', 'Vu', 'Observation directe d''un individu vivant.', 'Validé', 83, '014.000', '2015-07-29 00:00:00', '2015-12-07 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (43, 14, '1', 'Entendu', 'Entendu', 'Observation acoustique d''un individu vivant.', 'Validé', 83, '014.001', '2015-07-29 00:00:00', '2015-12-07 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (44, 14, '2', 'Coquilles d''œuf', 'Coquilles d''œuf', 'Observation indirecte via coquilles d''œuf.', 'Validé', 83, '014.002', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (45, 14, '3', 'Ultrasons', 'Ultrasons', 'Observation acoustique indirecte d''un individu vivant avec matériel spécifique permettant de transduire des ultrasons en sons perceptibles par un humain.', 'Validé', 83, '014.003', '2015-07-29 00:00:00', '2015-12-07 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (46, 14, '4', 'Empreintes', 'Empreintes', 'Observation indirecte via empreintes.', 'Validé', 83, '014.004', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (47, 14, '5', 'Exuvie', 'Exuvie', 'Observation indirecte : une exuvie.', 'Validé', 83, '014.005', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (48, 14, '6', 'Fèces/Guano/Epreintes', 'Fèces/Guano/Epreintes', 'Observation indirecte par les excréments', 'Validé', 83, '014.006', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (49, 14, '7', 'Mues', 'Mues', 'Observation indirecte par des plumes, poils, phanères, peau, bois... issus d''une mue.', 'Validé', 83, '014.007', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (50, 14, '8', 'Nid/Gîte', 'Nid/Gîte', 'Observation indirecte par présence d''un nid ou d''un gîte non occupé au moment de l''observation.', 'Validé', 83, '014.008', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (51, 14, '9', 'Pelote de réjection', 'Pelote de réjection', 'Identifie l''espèce ayant produit la pelote de réjection.', 'Validé', 83, '014.009', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (68, 16, '0', '0', 'Maximale', 'Précision maximale telle que saisie (non sensible). Statut par défaut', 'Validé', 84, '016.000', '2015-06-10 00:00:00', '2015-06-10 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (69, 16, '1', '1', 'Département, maille, espace, commune, ZNIEFF', 'Département, maille, espace, commune, ZNIEFF.', 'Validé', 84, '016.001', '2015-06-10 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (70, 16, '2', '2', 'Département et maille 10 x 10 km', 'Département et maille 10 x 10 km.', 'Validé', 84, '016.002', '2015-06-10 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (71, 16, '3', '3', 'Département seulement', 'Département seulement.', 'Validé', 84, '016.003', '2015-06-10 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (72, 16, '4', '4', 'Aucune diffusion (cas exceptionnel)', 'Aucune diffusion (cas exceptionnel).', 'Validé', 84, '016.004', '2015-06-10 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (73, 19, 'Co', 'Co', 'Collection', 'Collection : l''observation concerne une base de données de collection.', 'Validé', 85, '019.003', '2013-12-04 00:00:00', '2013-12-04 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (2, 10, '0', 'Inconnu', 'Inconnu', 'Le stade de vie de l''individu n''est pas connu.', 'Validé', 1, '010.000', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (3, 10, '1', 'Indéterminé', 'Indéterminé', 'Le stade de vie de l''individu n''a pu être déterminé (observation insuffisante pour la détermination).', 'Validé', 1, '010.001', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (6, 10, '4', 'Immature', 'Immature', 'Individu n''ayant pas atteint sa maturité sexuelle.', 'Validé', 1, '010.004', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (7, 10, '5', 'Sub-adulte', 'Sub-adulte', 'Individu ayant presque atteint la taille adulte mais qui n''est pas considéré en tant que tel par ses congénères.', 'Validé', 1, '010.005', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (8, 10, '6', 'Larve', 'Larve', 'Individu dans l''état où il est en sortant de l''œuf, état dans lequel il passe un temps plus ou moins long avant métamorphose.', 'Validé', 1, '010.006', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (9, 10, '7', 'Chenille', 'Chenille', 'Larve éruciforme des lépidoptères ou papillons.', 'Validé', 1, '010.007', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (10, 10, '8', 'Têtard', 'Têtard', 'Larve de batracien.', 'Validé', 1, '010.008', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (11, 10, '9', 'Œuf', 'Œuf', 'L''individu se trouve dans un œuf, ou au sein d''un regroupement d''œufs (ponte)', 'Validé', 1, '010.009', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (12, 10, '10', 'Mue', 'Mue', 'L''individu est en cours de mue (pour les reptiles : renouvellement de la peau, pour les oiseaux/mammifères : renouvellement du plumage/pelage, pour les cervidés : chute des bois).', 'Validé', 1, '010.010', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (13, 10, '11', 'Exuvie', 'Exuvie', 'L''individu est en cours d''exuviation : l''exuvie est une enveloppe (cuticule chitineuse ou peau) que le corps de l''animal a quittée lors de la mue ou de la métamorphose.', 'Validé', 1, '010.011', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (14, 10, '12', 'Chrysalide', 'Chrysalide', 'Nymphe des lépidoptères ou papillons.', 'Validé', 1, '010.012', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (15, 10, '13', 'Nymphe', 'Nymphe', 'Stade de développement intermédiaire, entre larve et imago, pendant lequel l''individu ne se nourrit pas.', 'Validé', 1, '010.013', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (53, 14, '11', 'Poils/plumes/phanères', 'Poils/plumes/phanères', 'Observation indirecte de l''espèce par ses poils, plumes ou phanères, non nécessairement issus d''une mue.', 'Validé', 83, '014.011', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (54, 14, '12', 'Restes de repas', 'Restes de repas', 'Observation indirecte par le biais de restes de l''alimentation de l''individu.', 'Validé', 83, '014.012', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (55, 14, '13', 'Spore', 'Spore', 'Identification d''un individu ou groupe d''individus d''un taxon par l''observation de spores, corpuscules unicellulaires ou pluricellulaires pouvant donner naissance sans fécondation à un nouvel individu. Chez les végétaux, corpuscules reproducteurs donnant des prothalles rudimentaires mâles et femelles (correspondant respectivement aux grains de pollen et au sac embryonnaire), dont les produits sont les gamètes.', 'Validé', 83, '014.013', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (80, 2, 'Pu', 'Publique', 'Publique', 'Publique : La Donnée Source est publique qu’elle soit produite en « régie » ou « acquise ».', 'Validé', 86, '002.001', '2013-12-05 00:00:00', '2013-12-05 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (81, 2, 'Re', 'Publique Régie', 'Publique Régie', 'Publique Régie : La Donnée Source est publique et a été produite directement par un organisme ayant autorité publique avec ses moyens humains et techniques propres.', 'Validé', 86, '002.001.001', '2013-12-05 00:00:00', '2013-12-05 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (79, 2, 'Pr', 'Privée', 'Privée', 'Privée : La Donnée Source a été produite par un organisme privé ou un individu à titre personnel. Aucun organisme ayant autorité publique n''a acquis les droits patrimoniaux,  la Donnée Source reste la propriété de l’organisme ou de l’individu privé. Seul ce cas autorise un floutage géographique de la DEE.', 'Validé', 86, '002.002', '2013-12-05 00:00:00', '2013-12-05 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (56, 14, '14', 'Pollen', 'Pollen', 'Observation indirecte d''un individu ou groupe d''individus d''un taxon par l''observation de pollen, poussière très fine produite dans les loges des anthères et dont chaque grain microscopique est un utricule ou petit sac membraneux contenant le fluide fécondant (d''apr. Bouillet 1859).', 'Validé', 83, '014.014', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (57, 14, '15', 'Oosphère', 'Oosphère', 'Observation indirecte. Cellule sexuelle femelle chez les végétaux qui, après sa fécondation, devient l''oeuf.', 'Validé', 83, '014.015', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (58, 14, '16', 'Ovule', 'Ovule', 'Observation indirecte. Organe contenant le gamète femelle. Macrosporange des spermaphytes.', 'Validé', 83, '014.016', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (59, 14, '17', 'Fleur', 'Fleur', 'Identification d''un individu ou groupe d''individus d''un taxon par l''observation  de fleurs. La fleur correspond à un ensemble de feuilles modifiées, en enveloppe florale et en organe sexuel, disposées sur un réceptacle. Un pédoncule la relie à la tige. (ex : chaton).', 'Validé', 83, '014.017', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (60, 14, '18', 'Feuille', 'Feuille', 'Identification d''un individu ou groupe d''individus d''un taxon par l''observation  de feuilles. Organe aérien très important dans la nutrition de la plante, lieu de la photosynthèse qui aboutit à des composés organiques (sucres, protéines) formant la sève.', 'Validé', 83, '014.018', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (61, 14, '19', 'ADN environnemental', 'ADN environnemental', 'Séquence ADN trouvée dans un prélèvement environnemental (eau ou sol).', 'Validé', 83, '014.019', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (16, 10, '14', 'Pupe', 'Pupe', 'Nymphe des diptères.', 'Validé', 1, '010.014', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (17, 10, '15', 'Imago', 'Imago', 'Stade final d''un individu dont le développement se déroule en plusieurs phases (en général, œuf, larve, imago).', 'Validé', 1, '010.015', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (18, 10, '16', 'Sub-imago', 'Sub-imago', 'Stade de développement chez certains insectess : insecte mobile, incomplet et sexuellement immature, bien qu''évoquant assez fortement la forme définitive de l''adulte, l''imago.', 'Validé', 1, '010.016', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (19, 10, '17', 'Alevin', 'Alevin', 'L''individu, un poisson, est à un stade juvénile.', 'Validé', 1, '010.017', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (20, 10, '18', 'Germination', 'Germination', 'L''individu est en cours de germination.', 'Validé', 1, '010.018', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (21, 10, '19', 'Fané', 'Fané', 'L''individu est altéré dans ses couleurs et sa fraîcheur, par rapport à un individu normal.', 'Validé', 1, '010.019', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (22, 10, '20', 'Graine', 'Graine', 'La graine est la structure qui contient et protège l''embryon végétal.', 'Validé', 1, '010.020', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (23, 10, '21', 'Thalle, protothalle', 'Thalle, protothalle', 'Un thalle est un appareil végétatif ne possédant ni feuilles, ni tiges, ni racines, produit par certains organismes non mobiles.', 'Validé', 1, '010.021', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (24, 10, '22', 'Tubercule', 'Tubercule', 'Un tubercule est un organe de réserve, généralement souterrain, assurant la survie des plantes pendant la saison d''hiver ou en période de sécheresse, et souvent leur multiplication par voie végétative.', 'Validé', 1, '010.022', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (25, 10, '23', 'Bulbe', 'Bulbe', 'Un bulbe est une pousse souterraine verticale disposant de feuilles modifiées utilisées comme organe de stockage de nourriture par une plante à dormance.', 'Validé', 1, '010.023', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (26, 10, '24', 'Rhizome', 'Rhizome', 'Le rhizome est une tige souterraine et parfois subaquatique remplie de réserves alimentaires chez certaines plantes vivaces.', 'Validé', 1, '010.024', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (27, 10, '25', 'Emergent', 'Emergent', 'L''individu est au stade émergent : sortie de l''œuf.', 'Validé', 1, '010.025', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (28, 10, '26', 'Post-Larve', 'Post-Larve', 'Stade qui suit immédiatement celui de la larve et présente certains caractères du juvénile.', 'Validé', 1, '010.026', '2016-03-24 00:00:00', '2016-03-24 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (62, 14, '20', 'Autre', 'Autre', 'Pour tout cas qui ne rentrerait pas dans la présente liste. Le nombre d''apparitions permettra de faire évoluer la nomenclature.', 'Validé', 83, '014.020', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (63, 14, '21', 'Inconnu', 'Inconnu', 'Inconnu : La méthode n''est pas mentionnée dans les documents de l''observateur (bibliographie par exemple).', 'Validé', 83, '014.021', '2015-07-29 00:00:00', '2015-08-21 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (64, 14, '22', 'Mine', 'Mine', 'Galerie forée dans l''épaisseur d''une feuille, entre l''épiderme supérieur et l''épiderme inférieur par des larves', 'Validé', 83, '014.022', '2015-12-07 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (65, 14, '23', 'Galerie/terrier', 'Galerie/terrier', 'Galerie forée dans le bois, les racines ou les tiges, par des larves (Lépidoptères, Coléoptères, Diptères) ou creusée dans la terre (micro-mammifères, mammifères... ).', 'Validé', 83, '014.023', '2015-12-07 00:00:00', '2015-12-07 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (92, 15, '1', 'Oui', 'Oui', 'Indique qu''une preuve existe ou a existé pour la détermination, et est toujours accessible.', 'Validé', 90, '015.001', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (93, 15, '2', 'Non', 'Non', 'Indique l''absence de preuve.', 'Validé', 90, '015.002', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (94, 15, '3', 'NonAcquise', 'Non acquise', 'NonAcquise : La donnée de départ mentionne une preuve, ou non, mais n''est pas suffisamment standardisée pour qu''il soit possible de récupérer des informations. L''information n''est donc pas acquise lors du transfert.', 'Validé', 90, '015.003', '2015-07-29 00:00:00', '2015-12-12 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (91, 15, '0', 'NSP', 'Inconnu', 'Indique que la personne ayant fourni la donnée ignore s''il existe une preuve, ou qu''il est indiqué dans la donnée qu''il y a eu une preuve qui a pu servir pour la détermination, sans moyen de le vérifier.', 'Validé', 90, '015.000', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (96, 17, 'NON', 'Non', 'Non', '"Indique que la donnée n''est pas sensible (par défaut, équivalent au niveau ""0"" des niveaux de sensibilité)."', 'Validé', 95, '017.001', '2015-06-10 00:00:00', '2015-08-21 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (97, 17, 'OUI', 'Oui', 'Oui', 'Indique que la donnée est sensible.', 'Validé', 95, '017.002', '2015-06-10 00:00:00', '2015-08-21 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (99, 18, 'No', 'No', 'Non observé', 'Non Observé : L''observateur n''a pas détecté un taxon particulier, recherché suivant le protocole adéquat à la localisation et à la date de l''observation. Le taxon peut être présent et non vu, temporairement absent, ou réellement absent.', 'Validé', 98, '018.001', '2013-12-05 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (100, 18, 'NSP', 'NSP', 'Ne Sait Pas', 'Ne Sait Pas : l''information n''est pas connue', 'Validé', 98, '018.000', '2016-03-24 00:00:00', '2016-03-24 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (101, 18, 'Pr', 'Pr', 'Présent', 'Présent : Un ou plusieurs individus du taxon ont été effectivement observés et/ou des indices témoignant de la présence du taxon', 'Validé', 98, '018.002', '2013-12-05 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (103, 20, 'QTA', 'QTA', 'Quantitatif', 'Le paramètre est de type quantitatif : il peut être mesuré par une valeur numérique. Exemples : âge précis, taille, nombre de cercles ligneux...', 'Validé', 102, '020.001', '2015-09-16 00:00:00', '2015-09-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (104, 20, 'QUAL', 'QUAL', 'Qualitatif', 'Le paramètre est de type qualitatif : Il décrit une qualité qui ne peut être définie par une quantité numérique. Exemples : individu âgé / individu jeune, eau trouble, milieu clairsemé…', 'Validé', 102, '020.002', '2015-09-16 00:00:00', '2015-12-07 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (106, 21, 'Ca', 'Ca', 'Calculé', 'Calculé : Dénombrement par opération mathématique', 'Validé', 105, '021.002', '2014-01-22 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (107, 21, 'Co', 'Co', 'Compté', 'Compté : Dénombrement par énumération des individus', 'Validé', 105, '021.001', '2014-01-22 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (108, 21, 'Es', 'Es', 'Estimé', 'Estimé : Dénombrement qualifié d’estimé lorsque le produit concerné n''a fait l''objet d''aucune action de détermination de cette valeur du paramètre par le biais d''une technique de mesure.', 'Validé', 105, '021.003', '2014-01-22 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (109, 21, 'NSP', 'NSP', 'Ne sait pas', 'Ne sait Pas : La méthode de dénombrement n’est pas connue', 'Validé', 105, '021.000', '2014-01-22 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (111, 22, 'AAPN', 'AAPN', 'AAPN', 'Aire d’adhésion de parc national', 'Validé', 110, '022.001', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (112, 22, 'ANTAR', 'ANTAR', 'ANTAR', 'Zone protégée du Traité de l''Antarctique', 'Validé', 110, '022.002', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (113, 22, 'APB', 'APB', 'APB', 'Arrêté de protection de biotope', 'Validé', 110, '022.003', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (114, 22, 'APIA', 'APIA', 'APIA', 'Zone protégée de la convention d''Apia', 'Validé', 110, '022.004', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (115, 22, 'ASPIM', 'ASPIM', 'ASPIM', 'Aire spécialement protégée d’importance méditerranéenne', 'Validé', 110, '022.005', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (116, 22, 'BPM', 'BPM', 'BPM', 'Bien inscrit sur la liste du patrimoine mondial de l''UNESCO', 'Validé', 110, '022.006', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (117, 22, 'CARTH', 'CARTH', 'CARTH', 'Zone protégée de la convention de Carthagène', 'Validé', 110, '022.007', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (118, 22, 'CNP', 'CNP', 'CNP', '"Coeur de parc national. Valeur gelée le 15/06/2016 et remplacée par ""CPN"""', 'Gelé', 110, '022.008', '2014-01-22 00:00:00', '2016-06-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (119, 22, 'ENS', 'ENS', 'ENS', 'Espace naturel sensible', 'Validé', 110, '022.009', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (120, 22, 'MAB', 'MAB', 'MAB', 'Réserve de biosphère (Man and Biosphère)', 'Validé', 110, '022.010', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (121, 22, 'N2000', 'N2000', 'N2000', 'Natura 2000', 'Validé', 110, '022.011', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (122, 22, 'NAIRO', 'NAIRO', 'NAIRO', 'Zone spécialement protégée de la convention de Nairobi', 'Validé', 110, '022.012', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (123, 22, 'OSPAR', 'OSPAR', 'OSPAR', 'Zone marine protégée de la convention OSPAR', 'Validé', 110, '022.013', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (124, 22, 'PNM', 'PNM', 'PNM', 'Parc naturel marin', 'Validé', 110, '022.014', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (125, 22, 'PNR', 'PNR', 'PNR', 'Parc naturel régional', 'Validé', 110, '022.015', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (126, 22, 'PRN', 'PRN', 'PRN', 'Périmètre de protection de réserve naturelle', 'Validé', 110, '022.016', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (127, 22, 'RAMSAR', 'RAMSAR', 'RAMSAR', 'Site Ramsar : Zone humide d''importance internationale', 'Validé', 110, '022.017', '2014-01-22 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (128, 22, 'RBD', 'RBD', 'RBD', 'Réserve biologique', 'Validé', 110, '022.018', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (129, 22, 'RBI', 'RBI', 'RBI', 'Réserve biologique intégrale', 'Validé', 110, '022.019', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (130, 22, 'RCFS', 'RCFS', 'RCFS', 'Réserve de chasse et de faune sauvage', 'Validé', 110, '022.020', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (131, 22, 'RIPN', 'RIPN', 'RIPN', 'Réserve intégrale de parc national', 'Validé', 110, '022.021', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (132, 22, 'RNC', 'RNC', 'RNC', 'Réserve naturelle de Corse', 'Validé', 110, '022.022', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (133, 22, 'RNCFS', 'RNCFS', 'RNCFS', 'Réserve nationale de chasse et faune sauvage', 'Validé', 110, '022.023', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (134, 22, 'RNN', 'RNN', 'RNN', 'Réserve naturelle nationale', 'Validé', 110, '022.024', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (135, 22, 'RNR', 'RNR', 'RNR', 'Réserve naturelle régionale', 'Validé', 110, '022.025', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (136, 22, 'SCEN', 'SCEN', 'SCEN', 'Site de Conservatoire d’espaces naturels', 'Validé', 110, '022.026', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (137, 22, 'SCL', 'SCL', 'SCL', 'Site du Conservatoire du littoral', 'Validé', 110, '022.027', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (138, 22, 'ZHAE', 'ZHAE', 'ZHAE', 'Zone humide acquise par une Agence de l’eau', 'Validé', 110, '022.028', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (139, 22, 'ZNIEFF', 'ZNIEFF', 'ZNIEFF', 'Zone Naturelle d’Intérêt Ecologique Faunistique et Floristique (type non précisé)', 'Validé', 110, '022.029', '2015-09-15 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (140, 22, 'ZNIEFF1', 'ZNIEFF1', 'ZNIEFF1', 'Zone Naturelle d’Intérêt Ecologique Faunistique et Floristique de type I', 'Validé', 110, '022.029.001', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (141, 22, 'ZNIEFF2', 'ZNIEFF2', 'ZNIEFF2', 'Zone Naturelle d’Intérêt Ecologique Faunistique et Floristique de type II', 'Validé', 110, '022.029.002', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (143, 23, '1', '1', 'Géoréférencement', 'Géoréférencement de l''objet géographique. L''objet géographique est celui sur lequel on a effectué l''observation.', 'Validé', 142, '023.001', '2015-09-18 00:00:00', '2015-09-18 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (144, 23, '2', '2', 'Rattachement', 'Rattachement à l''objet géographique : l''objet géographique n''est pas la géoréférence d''origine, ou a été déduit d''informations autres.', 'Validé', 142, '023.002', '2015-09-18 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (146, 24, 'AUTR', 'AUTR', 'AUTR', 'La valeur n''est pas contenue dans la présente liste. Elle doit être complétée par d''autres informations.', 'Validé', 145, '024.001', '2015-06-09 00:00:00', '2015-12-07 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (147, 24, 'CAMP', 'CAMP', 'CAMP', 'Campagne de prélèvement', 'Validé', 145, '024.002', '2015-06-09 00:00:00', '2015-06-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (148, 24, 'INVSTA', 'INVSTA', 'INVSTA', 'Inventaire stationnel', 'Validé', 145, '024.003', '2015-06-09 00:00:00', '2015-06-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (149, 24, 'LIEN', 'LIEN', 'LIEN', 'Lien : Indique un lien fort entre 2 observations. (Une occurrence portée par l''autre, une symbiose, un parasitisme…)', 'Validé', 145, '024.004', '2015-06-09 00:00:00', '2015-12-16 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (150, 24, 'NSP', 'NSP', 'NSP', 'Ne sait pas : l''information n''est pas connue.', 'Validé', 145, '024.000', '2015-06-09 00:00:00', '2015-06-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (151, 24, 'OBS', 'OBS', 'OBS', 'Observations', 'Validé', 145, '024.005', '2015-06-09 00:00:00', '2015-06-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (152, 24, 'OP', 'OP', 'OP', 'Opération de prélèvement', 'Validé', 145, '024.006', '2015-06-09 00:00:00', '2015-06-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (153, 24, 'PASS', 'PASS', 'PASS', 'Passage', 'Validé', 145, '024.007', '2015-06-09 00:00:00', '2015-06-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (154, 24, 'POINT', 'POINT', 'POINT', 'Point de prélèvement ou point d''observation.', 'Validé', 145, '024.008', '2015-06-09 00:00:00', '2015-06-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (155, 24, 'REL', 'REL', 'REL', 'Relevé (qu''il soit phytosociologique, d''observation, ou autre...)', 'Validé', 145, '024.009', '2015-06-09 00:00:00', '2015-06-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (156, 24, 'STRAT', 'STRAT', 'STRAT', 'Strate', 'Validé', 145, '024.010', '2015-06-09 00:00:00', '2015-06-09 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (158, 5, '0', 'Standard', 'Standard', 'Diffusion standard : à la maille, à la ZNIEFF, à la commune, à l’espace protégé (statut par défaut).', 'Validé', 157, '005.000', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (159, 5, '1', 'Commune', 'Commune', 'Diffusion floutée de la DEE par rattachement à la commune.', 'Validé', 157, '005.001', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (160, 5, '2', 'Maille', 'Maille', 'Diffusion floutée par rattachement à la maille 10 x 10 km', 'Validé', 157, '005.002', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (161, 5, '3', 'Département', 'Département', 'Diffusion floutée par rattachement au département.', 'Validé', 157, '005.003', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (162, 5, '4', 'Aucune', 'Aucune', 'Aucune diffusion (cas exceptionnel), correspond à une donnée de sensibilité 4.', 'Validé', 157, '005.004', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (163, 5, '5', 'Précise', 'Précise', 'Diffusion telle quelle : si une donnée précise existe, elle doit être diffusée telle quelle.', 'Validé', 157, '005.005', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (165, 6, 'NSP', 'Ne Sait Pas', 'Ne Sait Pas', 'La méthode de dénombrement n''est pas connue.', 'Validé', 164, '006.000', '2014-01-22 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (166, 6, 'IND', 'Individu', 'Individu', 'Nombre d''individus observés.', 'Validé', 164, '006.001', '2014-01-22 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (167, 6, 'CPL', 'Couple', 'Couple', 'Nombre de couples observé.', 'Validé', 164, '006.002', '2015-07-21 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (168, 6, 'COL', 'Colonie', 'Colonie', 'Nombre de colonies observées.', 'Validé', 164, '006.003', '2015-07-21 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (169, 6, 'NID', 'Nid', 'Nid', 'Nombre de nids observés.', 'Validé', 164, '006.004', '2015-07-21 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (170, 6, 'PON', 'Ponte', 'Ponte', 'Nombre de pontes observées.', 'Validé', 164, '006.005', '2015-07-21 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (171, 6, 'HAM', 'Hampe florale', 'Hampe florale', 'Nombre de hampes florales observées.', 'Validé', 164, '006.006', '2015-07-21 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (172, 6, 'TIGE', 'Tige', 'Tige', 'Nombre de tiges observées.', 'Validé', 164, '006.007', '2015-07-21 00:00:00', '2015-10-20 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (173, 6, 'TOUF', 'Touffe', 'Touffe', 'Nombre de touffes observées.', 'Validé', 164, '006.008', '2015-07-21 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (174, 6, 'SURF', 'Surface', 'Surface', 'Zone aréale occupée par le taxon, en mètres carrés.', 'Validé', 164, '006.009', '2015-07-21 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (176, 7, '0', 'NSP', 'NSP', 'Inconnu (peut être utilisé pour les virus ou les végétaux fanés par exemple).', 'Validé', 175, '007.000', '2015-07-29 00:00:00', '2015-10-19 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (177, 7, '1', 'Non renseigné', 'Non renseigné', 'L''information n''a pas été renseignée.', 'Validé', 175, '007.001', '2015-07-29 00:00:00', '2015-10-19 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (178, 7, '2', 'Observé vivant', 'Observé vivant', 'L''individu a été observé vivant.', 'Validé', 175, '007.002', '2015-07-29 00:00:00', '2015-10-19 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (179, 7, '3', 'Trouvé mort', 'Trouvé mort', 'L''individu a été trouvé mort : Cadavre entier ou crâne par exemple. La mort est antérieure au processus d''observation.', 'Validé', 175, '007.003', '2015-07-29 00:00:00', '2015-10-19 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (181, 8, '0', 'Inconnu', 'Inconnu', 'Inconnu : la naturalité du sujet est inconnue', 'Validé', 180, '008.000', '2015-07-29 00:00:00', '2015-10-19 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (182, 8, '1', 'Sauvage', 'Sauvage', 'Sauvage : Qualifie un animal ou végétal à l''état sauvage, individu autochtone, se retrouvant dans son aire de répartition naturelle et dont les individus sont le résultat d''une reproduction naturelle, sans intervention humaine.', 'Validé', 180, '008.001', '2015-07-29 00:00:00', '2015-10-19 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (183, 8, '2', 'Cultivé/élevé', 'Cultivé/élevé', 'Cultivé/élevé : Qualifie un individu d''une population allochtone introduite volontairement dans des espaces non naturels dédiés à la culture, ou à l''élevage.', 'Validé', 180, '008.002', '2015-07-29 00:00:00', '2015-10-19 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (184, 8, '3', 'Planté', 'Planté', 'Planté : Qualifie un végétal d''une population allochtone introduite ponctuellement et  volontairement dans un espace naturel/semi naturel.', 'Validé', 180, '008.003', '2015-07-29 00:00:00', '2015-10-19 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (185, 8, '4', 'Féral', 'Féral', 'Féral : Qualifie un animal élevé retourné à l''état sauvage, individu d''une population allochtone.', 'Validé', 180, '008.004', '2015-07-29 00:00:00', '2015-10-19 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (186, 8, '5', 'Subspontané', 'Subspontané', '"Subspontané : Qualifie un végétal d''une population allochtone, introduite volontairement, qui persiste plus ou moins longtemps dans sa station d’origine et qui a une dynamique propre peu étendue et limitée aux alentours de son implantation initiale. ""Echappée des jardins""."', 'Validé', 180, '008.005', '2015-07-29 00:00:00', '2015-10-19 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (188, 9, '0', 'Inconnu', 'Inconnu', 'Inconnu : Il n''y a pas d''information disponible pour cet individu.', 'Validé', 188, '009.000', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (189, 9, '1', 'Indéterminé', 'Indéterminé', 'Indéterminé : Le sexe de l''individu n''a pu être déterminé', 'Validé', 188, '009.001', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (190, 9, '2', 'Femelle', 'Femelle', 'Féminin : L''individu est de sexe féminin.', 'Validé', 188, '009.002', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (191, 9, '3', 'Mâle', 'Mâle', 'Masculin : L''individu est de sexe masculin.', 'Validé', 188, '009.003', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (192, 9, '4', 'Hermaphrodite', 'Hermaphrodite', 'Hermaphrodite : L''individu est hermaphrodite.', 'Validé', 188, '009.004', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (193, 9, '5', 'Mixte', 'Mixte', 'Mixte : Sert lorsque l''on décrit plusieurs individus.', 'Validé', 188, '009.005', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (194, 9, '6', 'Non renseigné', 'Non renseigné', 'Non renseigné : l''information n''a pas été renseignée dans le document à l''origine de la donnée.', 'Validé', 188, '009.006', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (196, 3, 'In', 'Inventoriel', 'Inventoriel', 'Inventoriel : Le taxon observé est présent quelque part dans l’objet géographique', 'Validé', 195, '003.001', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (197, 3, 'NSP', 'Ne sait pas', 'Ne sait pas', 'Ne Sait Pas : L’information est inconnue', 'Validé', 195, '003.000', '2014-01-22 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (198, 3, 'St', 'Stationnel', 'Stationnel', 'Stationnel : Le taxon observé est présent sur l’ensemble de l’objet géographique', 'Validé', 195, '003.002', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (200, 4, 'NON', 'Non', 'Non', 'Non : indique qu''aucun floutage n''a eu lieu.', 'Validé', 199, '004.001', '2015-09-18 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (201, 4, 'OUI', 'Oui', 'Oui', 'Oui : indique qu''un floutage a eu lieu.', 'Validé', 199, '004.002', '2015-09-18 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (203, 11, '0', 'Inconnu/cryptogène', 'Inconnu/cryptogène', 'Individu dont le taxon a une aire d’origine inconnue qui fait qu''on ne peut donc pas dire s’il est indigène ou introduit.', 'Validé', 202, '011.000', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (204, 11, '1', 'Non renseigné', 'Non renseigné', 'Individu pour lequel l''information n''a pas été renseignée.', 'Validé', 202, '011.001', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (205, 11, '2', 'Présent (indigène ou indéterminé)', 'Présent (indigène ou indéterminé)', 'Individu d''un taxon présent au sens large dans la zone géographique considérée, c''est-à-dire taxon indigène ou taxon dont on ne sait pas s’il appartient à l''une des autres catégories. Le défaut de connaissance profite donc à l’indigénat.  Par indigène on entend : taxon qui est issu de la zone géographique considérée et qui s’y est naturellement développé sans contribution humaine, ou taxon qui est arrivé là sans intervention humaine (intentionnelle ou non) à partir d’une zone dans laquelle il est indigène6.  (NB : exclut les hybrides dont l’un des parents au moins est introduit dans la zone considérée)  Sont regroupés sous ce statut tous les taxons catégorisés « natif » ou « autochtone ».  Les taxons hivernant quelques mois de l’année entrent dans cette catégorie.', 'Validé', 202, '011.002', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (206, 11, '3', 'Introduit', 'Introduit', 'Taxon introduit (établi ou possiblement établi) au niveau local.  Par introduit on entend : taxon dont la présence locale est due à une intervention humaine, intentionnelle ou non, ou taxon qui est arrivé dans la zone sans intervention humaine mais à partir d’une zone dans laquelle il est introduit.  Par établi (terme pour la faune, naturalisé pour la flore) on entend : taxon introduit qui forme des populations viables (se reproduisant) et durables qui se maintiennent dans le milieu naturel sans besoin d’intervention humaine.  Sont regroupés sous ce statut tous les taxons catégorisés « non-indigène », « exotique », « exogène », « allogène », « allochtone », « non-natif », « naturalisé » dans une publication scientifique.', 'Validé', 202, '011.003', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (207, 11, '4', 'Introduit envahissant', 'Introduit envahissant', '"Individu d''un taxon introduit  localement, qui produit des descendants fertiles souvent en grand nombre, et qui a le potentiel pour s''étendre de façon exponentielle sur une grande aire, augmentant ainsi rapidement son aire de répartition. Cela induit souvent des conséquences écologiques, économiques ou sanitaires négatives. Sont regroupés sous ce statut tous les individus de taxons catégorisés ""introduits envahissants"", ""exotiques envahissants"", ou ""invasif""."', 'Validé', 202, '011.004', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (208, 11, '5', 'Introduit non établi (dont domestique)', 'Introduit non établi (dont domestique)', 'Individu dont le taxon est introduit, qui se reproduit occasionnellement hors de son aire de culture ou captivité, mais qui ne peut se maintenir à l''état sauvage.', 'Validé', 202, '011.005', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (209, 11, '6', 'Occasionnel', 'Occasionnel', 'Individu dont le taxon est occasionnel, non nicheur, accidentel ou exceptionnel dans la zone géographique considérée (par exemple migrateur de passage), qui est locale.', 'Validé', 202, '011.006', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (287, 100, '77', 'Pêche au filet troubleau (chasse au filet troubleau)', 'Pêche au filet troubleau (chasse au filet troubleau)', 'Pêche au filet troubleau (chasse au filet troubleau)', 'Validation en cours', 100, '100.077', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (288, 100, '78', 'Pêche électrique, électropêche', 'Pêche électrique, électropêche', 'Pêche électrique, électropêche', 'Validation en cours', 100, '100.078', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (289, 100, '79', 'Piégeage à appât type Plantrou (piège à Charaxes)', 'Piégeage à appât type Plantrou (piège à Charaxes)', 'Piégeage à appât type Plantrou (piège à Charaxes)', 'Validation en cours', 100, '100.079', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (290, 100, '80', 'Piégeage à cornet (capture par piège cornet unidirectionnel)', 'Piégeage à cornet (capture par piège cornet unidirectionnel)', 'Piégeage à cornet (capture par piège cornet unidirectionnel)', 'Validation en cours', 100, '100.080', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (291, 100, '81', 'Piégeage à fosse à coprophages', 'Piégeage à fosse à coprophages', 'Piégeage à fosse à coprophages', 'Validation en cours', 100, '100.081', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (292, 100, '82', 'Piégeage à fosse à nécrophages', 'Piégeage à fosse à nécrophages', 'Piégeage à fosse à nécrophages', 'Validation en cours', 100, '100.082', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (293, 100, '83', 'Piégeage à fosse appâté (capture par piège à fosse avec liquide conservateur, piège Barber, pot-piège)', 'Piégeage à fosse appâté (capture par piège à fosse avec liquide conservateur, piège Barber, pot-piège)', 'Piégeage à fosse appâté (capture par piège à fosse avec liquide conservateur, piège Barber, pot-piège)', 'Validation en cours', 100, '100.083', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (294, 100, '84', 'Piégeage à fosse non appâté (piège à fosse sans liquide conservateur)', 'Piégeage à fosse non appâté (piège à fosse sans liquide conservateur)', 'Piégeage à fosse non appâté (piège à fosse sans liquide conservateur)', 'Validation en cours', 100, '100.084', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (295, 100, '85', 'Piégeage adhésif (piège collant, piège gluant, bande collante)', 'Piégeage adhésif (piège collant, piège gluant, bande collante)', 'Piégeage adhésif (piège collant, piège gluant, bande collante)', 'Validation en cours', 100, '100.085', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (211, 100, '1', 'Analyse ADN environnemental (ADNe)', 'Analyse ADN environnemental (ADNe)', 'Analyse ADN environnemental (ADNe)', 'Validation en cours', 100, '100.001', '2017-06-19 15:11:40.590509', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (212, 100, '2', 'Analyse de restes de prédateurs - pelotes de réjection, restes de repas de carnivores, analyses stomacales', 'Analyse de restes de prédateurs - pelotes de réjection, restes de repas de carnivores, analyses stomacales', 'Analyse de restes de prédateurs - pelotes de réjection, restes de repas de carnivores, analyses stomacales', 'Validation en cours', 100, '100.002', '2017-06-19 15:11:40.590509', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (213, 100, '3', 'Aspirateur à air comprimé (marin)', 'Aspirateur à air comprimé (marin)', 'Aspirateur à air comprimé (marin)', 'Validation en cours', 100, '100.003', '2017-06-19 15:11:40.590509', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (214, 100, '4', 'Aspiration moteur type D-VAC (aspirateur à moteur)', 'Aspiration moteur type D-VAC (aspirateur à moteur)', 'Aspiration moteur type D-VAC (aspirateur à moteur)', 'Validation en cours', 100, '100.004', '2017-06-19 15:11:40.590509', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (215, 100, '5', 'Attraction pour observation (miellée, phéromones…)', 'Attraction pour observation (miellée, phéromones…)', 'Attraction pour observation (miellée, phéromones…)', 'Validation en cours', 100, '100.005', '2017-06-19 15:11:40.590509', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (216, 100, '6', 'Battage (battage de la végétation, parapluie japonais)', 'Battage (battage de la végétation, parapluie japonais)', 'Battage (battage de la végétation, parapluie japonais)', 'Validation en cours', 100, '100.006', '2017-06-19 15:11:40.590509', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (217, 100, '7', 'Battue avec rabatteurs', 'Battue avec rabatteurs', 'Battue avec rabatteurs', 'Validation en cours', 100, '100.007', '2017-06-19 15:11:40.590509', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (218, 100, '8', 'Brossage (terrestre : écorces…)', 'Brossage (terrestre : écorces…)', 'Brossage (terrestre : écorces…)', 'Validation en cours', 100, '100.008', '2017-06-19 15:11:40.590509', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (219, 100, '9', 'Capture au collet', 'Capture au collet', 'Capture au collet', 'Validation en cours', 100, '100.009', '2017-06-19 15:11:40.590509', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (220, 100, '10', 'Capture au filet Cryldé', 'Capture au filet Cryldé', 'Capture au filet Cryldé', 'Validation en cours', 100, '100.010', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (221, 100, '11', 'Capture au filet japonais', 'Capture au filet japonais', 'Capture au filet japonais', 'Validation en cours', 100, '100.011', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (222, 100, '12', 'Capture au filet stationnaire', 'Capture au filet stationnaire', 'Capture au filet stationnaire', 'Validation en cours', 100, '100.012', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (223, 100, '13', 'Capture directe (capture à vue, capture relâche)', 'Capture directe (capture à vue, capture relâche)', 'Capture directe (capture à vue, capture relâche)', 'Validation en cours', 100, '100.013', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (224, 100, '14', 'Chalutage terrestre (capture au filet de toit - voiture)', 'Chalutage terrestre (capture au filet de toit - voiture)', 'Chalutage terrestre (capture au filet de toit - voiture)', 'Validation en cours', 100, '100.014', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (225, 100, '15', 'Création d''habitat refuge : autres techniques', 'Création d''habitat refuge : autres techniques', 'Création d''habitat refuge : autres techniques', 'Validation en cours', 100, '100.015', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (226, 100, '16', 'Création d''habitat refuge : couverture du sol (plaques, bâches)', 'Création d''habitat refuge : couverture du sol (plaques, bâches)', 'Création d''habitat refuge : couverture du sol (plaques, bâches)', 'Validation en cours', 100, '100.016', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (227, 100, '17', 'Création d''habitat refuge : dévitalisation de plantes, mutilation', 'Création d''habitat refuge : dévitalisation de plantes, mutilation', 'Création d''habitat refuge : dévitalisation de plantes, mutilation', 'Validation en cours', 100, '100.017', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (228, 100, '18', 'Création d''habitat refuge : hôtels à insectes, nichoirs', 'Création d''habitat refuge : hôtels à insectes, nichoirs', 'Création d''habitat refuge : hôtels à insectes, nichoirs', 'Validation en cours', 100, '100.018', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (229, 100, '19', 'Création d''habitat refuge : substrat artificiel aquatique', 'Création d''habitat refuge : substrat artificiel aquatique', 'Création d''habitat refuge : substrat artificiel aquatique', 'Validation en cours', 100, '100.019', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (230, 100, '20', 'Détection au chien d''arrêt', 'Détection au chien d''arrêt', 'Détection au chien d''arrêt', 'Validation en cours', 100, '100.020', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (231, 100, '21', 'Détection des ultrasons (écoute indirecte, analyse sonore, détection ultrasonore)', 'Détection des ultrasons (écoute indirecte, analyse sonore, détection ultrasonore)', 'Détection des ultrasons (écoute indirecte, analyse sonore, détection ultrasonore)', 'Validation en cours', 100, '100.021', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (232, 100, '22', 'Détection nocturne à la lampe frontale (chasse de nuit à la lampe frontale)', 'Détection nocturne à la lampe frontale (chasse de nuit à la lampe frontale)', 'Détection nocturne à la lampe frontale (chasse de nuit à la lampe frontale)', 'Validation en cours', 100, '100.022', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (233, 100, '23', 'Ecorcage', 'Ecorcage', 'Ecorcage', 'Validation en cours', 100, '100.023', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (234, 100, '24', 'Ecoute directe (reconnaissance sonore directe, détection auditive)', 'Ecoute directe (reconnaissance sonore directe, détection auditive)', 'Ecoute directe (reconnaissance sonore directe, détection auditive)', 'Validation en cours', 100, '100.024', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (235, 100, '25', 'Ecoute directe avec hydrophone', 'Ecoute directe avec hydrophone', 'Ecoute directe avec hydrophone', 'Validation en cours', 100, '100.025', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (236, 100, '26', 'Ecoute directe avec repasse', 'Ecoute directe avec repasse', 'Ecoute directe avec repasse', 'Validation en cours', 100, '100.026', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (237, 100, '27', 'Enregistrement sonore avec hydrophone', 'Enregistrement sonore avec hydrophone', 'Enregistrement sonore avec hydrophone', 'Validation en cours', 100, '100.027', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (238, 100, '28', 'Enregistrement sonore simple', 'Enregistrement sonore simple', 'Enregistrement sonore simple', 'Validation en cours', 100, '100.028', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (239, 100, '29', 'Etude de la banque de graines du sol', 'Etude de la banque de graines du sol', 'Etude de la banque de graines du sol', 'Validation en cours', 100, '100.029', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (240, 100, '30', 'Examen des hôtes - écrevisses et poissons (sangsues piscicolidae et branchiobdellidae)', 'Examen des hôtes - écrevisses et poissons (sangsues piscicolidae et branchiobdellidae)', 'Examen des hôtes - écrevisses et poissons (sangsues piscicolidae et branchiobdellidae)', 'Validation en cours', 100, '100.030', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (241, 100, '31', 'Extraction de substrat : délitage de susbtrats durs (marin)', 'Extraction de substrat : délitage de susbtrats durs (marin)', 'Extraction de substrat : délitage de susbtrats durs (marin)', 'Validation en cours', 100, '100.031', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (242, 100, '32', 'Extraction de substrat par benne (Van Veen, Smith McIntyre, Hamon…)', 'Extraction de substrat par benne (Van Veen, Smith McIntyre, Hamon…)', 'Extraction de substrat par benne (Van Veen, Smith McIntyre, Hamon…)', 'Validation en cours', 100, '100.032', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (243, 100, '33', 'Extraction de substrat par carottier à main (en plongée)', 'Extraction de substrat par carottier à main (en plongée)', 'Extraction de substrat par carottier à main (en plongée)', 'Validation en cours', 100, '100.033', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (244, 100, '34', 'Extraction de substrat par carottier à main (sans plongée - continental ou supra/médiolittoral)', 'Extraction de substrat par carottier à main (sans plongée - continental ou supra/médiolittoral)', 'Extraction de substrat par carottier à main (sans plongée - continental ou supra/médiolittoral)', 'Validation en cours', 100, '100.034', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (245, 100, '35', 'Extraction de substrat par filet dragueur ou haveneau (drague Rallier du Baty, Charcot Picard…)', 'Extraction de substrat par filet dragueur ou haveneau (drague Rallier du Baty, Charcot Picard…)', 'Extraction de substrat par filet dragueur ou haveneau (drague Rallier du Baty, Charcot Picard…)', 'Validation en cours', 100, '100.035', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (246, 100, '36', 'Extraction de substrat terrestre : bloc de sol, récolte de litière…', 'Extraction de substrat terrestre : bloc de sol, récolte de litière…', 'Extraction de substrat terrestre : bloc de sol, récolte de litière…', 'Validation en cours', 100, '100.036', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (247, 100, '37', 'Fauchage marin au filet fauchoir (en plongée)', 'Fauchage marin au filet fauchoir (en plongée)', 'Fauchage marin au filet fauchoir (en plongée)', 'Validation en cours', 100, '100.037', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (248, 100, '38', 'Fauchage marin au filet fauchoir (sans plongée - supra/médiolittoral)', 'Fauchage marin au filet fauchoir (sans plongée - supra/médiolittoral)', 'Fauchage marin au filet fauchoir (sans plongée - supra/médiolittoral)', 'Validation en cours', 100, '100.038', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (249, 100, '39', 'Fauchage terrestre au filet fauchoir (fauchage de la végétation)', 'Fauchage terrestre au filet fauchoir (fauchage de la végétation)', 'Fauchage terrestre au filet fauchoir (fauchage de la végétation)', 'Validation en cours', 100, '100.039', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (250, 100, '40', 'Fumigation (fogging, thermonébulisation insecticide)', 'Fumigation (fogging, thermonébulisation insecticide)', 'Fumigation (fogging, thermonébulisation insecticide)', 'Validation en cours', 100, '100.040', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (251, 100, '41', 'Grattage, brossage du susbtrat (marin)', 'Grattage, brossage du susbtrat (marin)', 'Grattage, brossage du susbtrat (marin)', 'Validation en cours', 100, '100.041', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (252, 100, '42', 'Méthode de De Vries (méthode des prélèvements, méthode des poignées)', 'Méthode de De Vries (méthode des prélèvements, méthode des poignées)', 'Méthode de De Vries (méthode des prélèvements, méthode des poignées)', 'Validation en cours', 100, '100.042', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (253, 100, '43', 'Méthode de l''élastique (lézards arboricoles)', 'Méthode de l''élastique (lézards arboricoles)', 'Méthode de l''élastique (lézards arboricoles)', 'Validation en cours', 100, '100.043', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (254, 100, '44', 'Observation à la moutarde - vers de terre', 'Observation à la moutarde - vers de terre', 'Observation à la moutarde - vers de terre', 'Validation en cours', 100, '100.044', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (255, 100, '45', 'Observation aux jumelles (observation à la longue-vue)', 'Observation aux jumelles (observation à la longue-vue)', 'Observation aux jumelles (observation à la longue-vue)', 'Validation en cours', 100, '100.045', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (256, 100, '46', 'Observation aux lunettes polarisantes', 'Observation aux lunettes polarisantes', 'Observation aux lunettes polarisantes', 'Validation en cours', 100, '100.046', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (257, 100, '47', 'Observation de détritus d''inondation, débris et laisses de crues', 'Observation de détritus d''inondation, débris et laisses de crues', 'Observation de détritus d''inondation, débris et laisses de crues', 'Validation en cours', 100, '100.047', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (258, 100, '48', 'Observation de larves (recherche de larves)', 'Observation de larves (recherche de larves)', 'Observation de larves (recherche de larves)', 'Validation en cours', 100, '100.048', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (259, 100, '49', 'Observation de macro-restes (cadavres, élytres…)', 'Observation de macro-restes (cadavres, élytres…)', 'Observation de macro-restes (cadavres, élytres…)', 'Validation en cours', 100, '100.049', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (260, 100, '50', 'Observation de micro-habitats (recherche de gîtes, chandelles, polypores, dendrotelmes…) ', 'Observation de micro-habitats (recherche de gîtes, chandelles, polypores, dendrotelmes…) ', 'Observation de micro-habitats (recherche de gîtes, chandelles, polypores, dendrotelmes…) ', 'Validation en cours', 100, '100.050', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (261, 100, '51', 'Observation de pontes (observation des œufs, recherche des pontes)', 'Observation de pontes (observation des œufs, recherche des pontes)', 'Observation de pontes (observation des œufs, recherche des pontes)', 'Validation en cours', 100, '100.051', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (262, 100, '52', 'Observation de substrat et tamisage', 'Observation de substrat et tamisage', 'Observation de substrat et tamisage', 'Validation en cours', 100, '100.052', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (263, 100, '53', 'Observation de substrat par extraction : appareil de Berlèse-Tullgren, Winckler-Moczarski…', 'Observation de substrat par extraction : appareil de Berlèse-Tullgren, Winckler-Moczarski…', 'Observation de substrat par extraction : appareil de Berlèse-Tullgren, Winckler-Moczarski…', 'Validation en cours', 100, '100.053', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (264, 100, '54', 'Observation de substrat par extraction : par flottaison (par densité)', 'Observation de substrat par extraction : par flottaison (par densité)', 'Observation de substrat par extraction : par flottaison (par densité)', 'Validation en cours', 100, '100.054', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (265, 100, '55', 'Observation de trous de sortie, trous d''émergence', 'Observation de trous de sortie, trous d''émergence', 'Observation de trous de sortie, trous d''émergence', 'Validation en cours', 100, '100.055', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (266, 100, '56', 'Observation d''exuvies', 'Observation d''exuvies', 'Observation d''exuvies', 'Validation en cours', 100, '100.056', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (267, 100, '57', 'Observation d''indices de présence', 'Observation d''indices de présence', 'Observation d''indices de présence', 'Validation en cours', 100, '100.057', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (268, 100, '58', 'Observation directe marine (observation en plongée)', 'Observation directe marine (observation en plongée)', 'Observation directe marine (observation en plongée)', 'Validation en cours', 100, '100.058', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (269, 100, '59', 'Observation directe terrestre diurne (chasse à vue de jour)', 'Observation directe terrestre diurne (chasse à vue de jour)', 'Observation directe terrestre diurne (chasse à vue de jour)', 'Validation en cours', 100, '100.059', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (270, 100, '60', 'Observation directe terrestre nocturne (chasse à vue de nuit)', 'Observation directe terrestre nocturne (chasse à vue de nuit)', 'Observation directe terrestre nocturne (chasse à vue de nuit)', 'Validation en cours', 100, '100.060', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (271, 100, '61', 'Observation directe terrestre nocturne au phare', 'Observation directe terrestre nocturne au phare', 'Observation directe terrestre nocturne au phare', 'Validation en cours', 100, '100.061', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (272, 100, '62', 'Observation manuelle de substrat (litière, sol…)', 'Observation manuelle de substrat (litière, sol…)', 'Observation manuelle de substrat (litière, sol…)', 'Validation en cours', 100, '100.062', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (273, 100, '63', 'Observation marine par caméra suspendue', 'Observation marine par caméra suspendue', 'Observation marine par caméra suspendue', 'Validation en cours', 100, '100.063', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (274, 100, '64', 'Observation marine par traineau vidéo', 'Observation marine par traineau vidéo', 'Observation marine par traineau vidéo', 'Validation en cours', 100, '100.064', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (275, 100, '65', 'Observation marine par véhicule téléguidé (ROV)', 'Observation marine par véhicule téléguidé (ROV)', 'Observation marine par véhicule téléguidé (ROV)', 'Validation en cours', 100, '100.065', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (276, 100, '66', 'Observation marine photographique (observation photographique en plongée)', 'Observation marine photographique (observation photographique en plongée)', 'Observation marine photographique (observation photographique en plongée)', 'Validation en cours', 100, '100.066', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (277, 100, '67', 'Observation par piège photographique', 'Observation par piège photographique', 'Observation par piège photographique', 'Validation en cours', 100, '100.067', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (278, 100, '68', 'Observation photographique aérienne, prise de vue aérienne', 'Observation photographique aérienne, prise de vue aérienne', 'Observation photographique aérienne, prise de vue aérienne', 'Validation en cours', 100, '100.068', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (279, 100, '69', 'Observation photographique terrestre (affût photographique)', 'Observation photographique terrestre (affût photographique)', 'Observation photographique terrestre (affût photographique)', 'Validation en cours', 100, '100.069', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (280, 100, '70', 'Paniers à vers de terre', 'Paniers à vers de terre', 'Paniers à vers de terre', 'Validation en cours', 100, '100.070', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (281, 100, '71', 'Pêche à la palangre', 'Pêche à la palangre', 'Pêche à la palangre', 'Validation en cours', 100, '100.071', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (282, 100, '72', 'Pêche à l''épuisette (capture par épuisette, chasse à l''épuisette)', 'Pêche à l''épuisette (capture par épuisette, chasse à l''épuisette)', 'Pêche à l''épuisette (capture par épuisette, chasse à l''épuisette)', 'Validation en cours', 100, '100.072', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (283, 100, '73', 'Pêche au chalut, chalutage (chalut à perche...)', 'Pêche au chalut, chalutage (chalut à perche...)', 'Pêche au chalut, chalutage (chalut à perche...)', 'Validation en cours', 100, '100.073', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (284, 100, '74', 'Pêche au filet - à détailler', 'Pêche au filet - à détailler', 'Pêche au filet - à détailler', 'Validation en cours', 100, '100.074', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (285, 100, '75', 'Pêche au filet lesté (pêche à la senne)', 'Pêche au filet lesté (pêche à la senne)', 'Pêche au filet lesté (pêche à la senne)', 'Validation en cours', 100, '100.075', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (286, 100, '76', 'Pêche au filet Surber', 'Pêche au filet Surber', 'Pêche au filet Surber', 'Validation en cours', 100, '100.076', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (296, 100, '86', 'Piégeage aérien à succion (aspirateur échantillonneur, piège à moustiques)', 'Piégeage aérien à succion (aspirateur échantillonneur, piège à moustiques)', 'Piégeage aérien à succion (aspirateur échantillonneur, piège à moustiques)', 'Validation en cours', 100, '100.086', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (297, 100, '87', 'Piégeage aérien rotatif', 'Piégeage aérien rotatif', 'Piégeage aérien rotatif', 'Validation en cours', 100, '100.087', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (298, 100, '88', 'Piégeage au sol - à détailler', 'Piégeage au sol - à détailler', 'Piégeage au sol - à détailler', 'Validation en cours', 100, '100.088', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (299, 100, '89', 'Piégeage bouteille (piège à vin, piège à appât fermenté, piège à cétoines)', 'Piégeage bouteille (piège à vin, piège à appât fermenté, piège à cétoines)', 'Piégeage bouteille (piège à vin, piège à appât fermenté, piège à cétoines)', 'Validation en cours', 100, '100.089', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (300, 100, '90', 'Piégeage entomologique composite (PEC)', 'Piégeage entomologique composite (PEC)', 'Piégeage entomologique composite (PEC)', 'Validation en cours', 100, '100.090', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (301, 100, '91', 'Piégeage lumineux aquatique à fluorescence', 'Piégeage lumineux aquatique à fluorescence', 'Piégeage lumineux aquatique à fluorescence', 'Validation en cours', 100, '100.091', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (302, 100, '92', 'Piégeage lumineux aquatique à incandescence', 'Piégeage lumineux aquatique à incandescence', 'Piégeage lumineux aquatique à incandescence', 'Validation en cours', 100, '100.092', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (303, 100, '93', 'Piégeage lumineux aquatique à LED', 'Piégeage lumineux aquatique à LED', 'Piégeage lumineux aquatique à LED', 'Validation en cours', 100, '100.093', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (304, 100, '94', 'Piégeage lumineux automatique à fluorescence', 'Piégeage lumineux automatique à fluorescence', 'Piégeage lumineux automatique à fluorescence', 'Validation en cours', 100, '100.094', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (305, 100, '95', 'Piégeage lumineux automatique à incandescence', 'Piégeage lumineux automatique à incandescence', 'Piégeage lumineux automatique à incandescence', 'Validation en cours', 100, '100.095', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (306, 100, '96', 'Piégeage lumineux automatique à LED', 'Piégeage lumineux automatique à LED', 'Piégeage lumineux automatique à LED', 'Validation en cours', 100, '100.096', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (307, 100, '97', 'Piégeage lumineux manuel à fluorescence', 'Piégeage lumineux manuel à fluorescence', 'Piégeage lumineux manuel à fluorescence', 'Validation en cours', 100, '100.097', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (308, 100, '98', 'Piégeage lumineux manuel à incandescence', 'Piégeage lumineux manuel à incandescence', 'Piégeage lumineux manuel à incandescence', 'Validation en cours', 100, '100.098', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (309, 100, '99', 'Piégeage lumineux manuel à LED', 'Piégeage lumineux manuel à LED', 'Piégeage lumineux manuel à LED', 'Validation en cours', 100, '100.099', '2017-06-19 15:12:46.794127', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (310, 100, '100', 'Piégeage Malaise (capture par tente Malaise)', 'Piégeage Malaise (capture par tente Malaise)', 'Piégeage Malaise (capture par tente Malaise)', 'Validation en cours', 100, '100.100', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (311, 100, '101', 'Piégeage Marris House Net (capture par piège Malaise type Marris House Net)', 'Piégeage Marris House Net (capture par piège Malaise type Marris House Net)', 'Piégeage Marris House Net (capture par piège Malaise type Marris House Net)', 'Validation en cours', 100, '100.101', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (312, 100, '102', 'Piégeage microtube à fourmis', 'Piégeage microtube à fourmis', 'Piégeage microtube à fourmis', 'Validation en cours', 100, '100.102', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (313, 100, '103', 'Piégeage par assiettes colorées (piège coloré, plaque colorée adhésive)', 'Piégeage par assiettes colorées (piège coloré, plaque colorée adhésive)', 'Piégeage par assiettes colorées (piège coloré, plaque colorée adhésive)', 'Validation en cours', 100, '100.103', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (314, 100, '104', 'Piégeage par attraction sexuelle avec femelles', 'Piégeage par attraction sexuelle avec femelles', 'Piégeage par attraction sexuelle avec femelles', 'Validation en cours', 100, '100.104', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (315, 100, '105', 'Piégeage par attraction sexuelle avec phéromones', 'Piégeage par attraction sexuelle avec phéromones', 'Piégeage par attraction sexuelle avec phéromones', 'Validation en cours', 100, '100.105', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (316, 100, '106', 'Piégeage par enceinte à émergence aquatique (nasse à émergence aquatique)', 'Piégeage par enceinte à émergence aquatique (nasse à émergence aquatique)', 'Piégeage par enceinte à émergence aquatique (nasse à émergence aquatique)', 'Validation en cours', 100, '100.106', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (317, 100, '107', 'Piégeage par enceinte à émergence terrestre ex situ (nasse à émergence terrestre, éclosoir)', 'Piégeage par enceinte à émergence terrestre ex situ (nasse à émergence terrestre, éclosoir)', 'Piégeage par enceinte à émergence terrestre ex situ (nasse à émergence terrestre, éclosoir)', 'Validation en cours', 100, '100.107', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (318, 100, '108', 'Piégeage par enceinte à émergence terrestre in situ (nasse à émergence terrestre, éclosoir)', 'Piégeage par enceinte à émergence terrestre in situ (nasse à émergence terrestre, éclosoir)', 'Piégeage par enceinte à émergence terrestre in situ (nasse à émergence terrestre, éclosoir)', 'Validation en cours', 100, '100.108', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (319, 100, '109', 'Piégeage par enceinte type biocénomètre', 'Piégeage par enceinte type biocénomètre', 'Piégeage par enceinte type biocénomètre', 'Validation en cours', 100, '100.109', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (320, 100, '110', 'Piégeage par nasse à Coléoptères Hydrocanthares (piège appâté aquatique)', 'Piégeage par nasse à Coléoptères Hydrocanthares (piège appâté aquatique)', 'Piégeage par nasse à Coléoptères Hydrocanthares (piège appâté aquatique)', 'Validation en cours', 100, '100.110', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (321, 100, '111', 'Piégeage par nasses aquatiques ou filets verveux (appâtés)', 'Piégeage par nasses aquatiques ou filets verveux (appâtés)', 'Piégeage par nasses aquatiques ou filets verveux (appâtés)', 'Validation en cours', 100, '100.111', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (322, 100, '112', 'Piégeage par nasses aquatiques ou filets verveux (non appâtés)', 'Piégeage par nasses aquatiques ou filets verveux (non appâtés)', 'Piégeage par nasses aquatiques ou filets verveux (non appâtés)', 'Validation en cours', 100, '100.112', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (323, 100, '113', 'Piégeage par piège à entonnoir terrestre (funnel trap) (appâté)', 'Piégeage par piège à entonnoir terrestre (funnel trap) (appâté)', 'Piégeage par piège à entonnoir terrestre (funnel trap) (appâté)', 'Validation en cours', 100, '100.113', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (324, 100, '114', 'Piégeage par piège à entonnoir terrestre (funnel trap) (non appâté)', 'Piégeage par piège à entonnoir terrestre (funnel trap) (non appâté)', 'Piégeage par piège à entonnoir terrestre (funnel trap) (non appâté)', 'Validation en cours', 100, '100.114', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (325, 100, '115', 'Piégeage par piège-vitre bidirectionnel \"mimant une cavité\" (bande noire)', 'Piégeage par piège-vitre bidirectionnel \"mimant une cavité\" (bande noire)', 'Piégeage par piège-vitre bidirectionnel \"mimant une cavité\" (bande noire)', 'Validation en cours', 100, '100.115', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (326, 100, '116', 'Piégeage par piège-vitre bidirectionnel (piège fenêtre, piège-vitre plan)', 'Piégeage par piège-vitre bidirectionnel (piège fenêtre, piège-vitre plan)', 'Piégeage par piège-vitre bidirectionnel (piège fenêtre, piège-vitre plan)', 'Validation en cours', 100, '100.116', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (327, 100, '117', 'Piégeage par piège-vitre multidirectionnel avec alcool (piège Polytrap, PIMUL)', 'Piégeage par piège-vitre multidirectionnel avec alcool (piège Polytrap, PIMUL)', 'Piégeage par piège-vitre multidirectionnel avec alcool (piège Polytrap, PIMUL)', 'Validation en cours', 100, '100.117', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (328, 100, '118', 'Piégeage par piège-vitre multidirectionnel sans alcool (piège Polytrap, PIMUL)', 'Piégeage par piège-vitre multidirectionnel sans alcool (piège Polytrap, PIMUL)', 'Piégeage par piège-vitre multidirectionnel sans alcool (piège Polytrap, PIMUL)', 'Validation en cours', 100, '100.118', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (329, 100, '119', 'Piégeage par sac collecteur de feuillage et rameaux ligneux', 'Piégeage par sac collecteur de feuillage et rameaux ligneux', 'Piégeage par sac collecteur de feuillage et rameaux ligneux', 'Validation en cours', 100, '100.119', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (330, 100, '120', 'Piégeage par sélecteur de Chauvin', 'Piégeage par sélecteur de Chauvin', 'Piégeage par sélecteur de Chauvin', 'Validation en cours', 100, '100.120', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (331, 100, '121', 'Piégeage par tissu imbibé d''insecticide', 'Piégeage par tissu imbibé d''insecticide', 'Piégeage par tissu imbibé d''insecticide', 'Validation en cours', 100, '100.121', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (332, 100, '122', 'Piégeage SLAM (capture par piège Sand Land and Air Malaise)', 'Piégeage SLAM (capture par piège Sand Land and Air Malaise)', 'Piégeage SLAM (capture par piège Sand Land and Air Malaise)', 'Validation en cours', 100, '100.122', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (333, 100, '123', 'Piégeages par pièges barrières (pots-pièges associés à une barrière d''interception)', 'Piégeages par pièges barrières (pots-pièges associés à une barrière d''interception)', 'Piégeages par pièges barrières (pots-pièges associés à une barrière d''interception)', 'Validation en cours', 100, '100.123', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (334, 100, '124', 'Pièges à poils', 'Pièges à poils', 'Pièges à poils', 'Validation en cours', 100, '100.124', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (335, 100, '125', 'Pièges à traces (pièges à empreintes)', 'Pièges à traces (pièges à empreintes)', 'Pièges à traces (pièges à empreintes)', 'Validation en cours', 100, '100.125', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (336, 100, '126', 'Pièges aquatiques à sangsues (bouteilles percées, appâtées…)', 'Pièges aquatiques à sangsues (bouteilles percées, appâtées…)', 'Pièges aquatiques à sangsues (bouteilles percées, appâtées…)', 'Validation en cours', 100, '100.126', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (337, 100, '127', 'Pièges cache-tubes', 'Pièges cache-tubes', 'Pièges cache-tubes', 'Validation en cours', 100, '100.127', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (338, 100, '128', 'Pièges cache-tubes adhésifs (tubes capteurs de poils)', 'Pièges cache-tubes adhésifs (tubes capteurs de poils)', 'Pièges cache-tubes adhésifs (tubes capteurs de poils)', 'Validation en cours', 100, '100.128', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (339, 100, '129', 'Prélèvement par râteau ou grappin (macrophytes)', 'Prélèvement par râteau ou grappin (macrophytes)', 'Prélèvement par râteau ou grappin (macrophytes)', 'Validation en cours', 100, '100.129', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (340, 100, '130', 'Prospection à pied de cours d''eau (macrophytes)', 'Prospection à pied de cours d''eau (macrophytes)', 'Prospection à pied de cours d''eau (macrophytes)', 'Validation en cours', 100, '100.130', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (341, 100, '131', 'Prospection active dans l''habitat naturel (talus, souches, pierres…)', 'Prospection active dans l''habitat naturel (talus, souches, pierres…)', 'Prospection active dans l''habitat naturel (talus, souches, pierres…)', 'Validation en cours', 100, '100.131', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (342, 100, '132', 'Recherche dans filtres de piscines, skimmer', 'Recherche dans filtres de piscines, skimmer', 'Recherche dans filtres de piscines, skimmer', 'Validation en cours', 100, '100.132', '2017-06-19 15:13:18.161067', NULL, true);
INSERT INTO t_nomenclatures (id_nomenclature, id_type_nomenclature, cd_nomenclature, mnemonique, libelle_nomenclature, definition_nomenclature, statut_nomenclature, id_parent, hierarchie, date_create, date_update, actif) VALUES (343, 100, '133', 'Non renseigné', 'Non renseigné', 'La  technique d''observation n''est pas renseignée', 'non validé', 100, '100.133', '2017-06-19 15:13:18.161067', NULL, true);

SELECT pg_catalog.setval('t_nomenclatures_id_nomenclature_seq', 342, true);


SET search_path = taxonomie, pg_catalog;

TRUNCATE TABLE cor_taxref_nomenclature;
----------------------------
--TECHNIQUES D'OBSERVATION--
----------------------------
INSERT INTO cor_taxref_nomenclature VALUES (211, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (212, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (221, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (223, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (228, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (230, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (234, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (236, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (238, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (255, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (261, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (267, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (268, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (269, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (273, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (274, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (276, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (277, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (278, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (279, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (287, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (289, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (290, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (291, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (292, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (293, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (294, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (295, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (211, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (212, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (214, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (215, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (216, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (218, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (220, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (222, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (223, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (224, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (225, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (226, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (227, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (228, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (229, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (231, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (232, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (233, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (234, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (236, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (238, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (242, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (243, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (244, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (245, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (246, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (248, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (249, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (250, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (251, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (255, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (257, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (258, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (259, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (260, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (261, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (262, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (263, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (264, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (265, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (266, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (267, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (269, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (270, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (272, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (279, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (282, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (286, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (296, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (297, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (299, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (300, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (301, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (302, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (303, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (304, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (305, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (306, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (307, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (308, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (309, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (310, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (311, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (312, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (313, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (314, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (315, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (316, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (317, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (318, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (319, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (320, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (325, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (326, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (327, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (328, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (329, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (330, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (331, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (332, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (341, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (342, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (287, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (295, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (211, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (223, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (225, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (226, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (232, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (234, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (235, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (236, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (237, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (238, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (253, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (255, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (256, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (258, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (261, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (267, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (268, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (269, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (270, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (273, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (274, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (275, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (276, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (277, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (278, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (279, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (282, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (283, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (285, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (298, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (321, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (322, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (323, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (324, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (333, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (341, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (287, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (295, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (211, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (223, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (225, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (226, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (232, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (234, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (235, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (236, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (237, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (238, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (253, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (255, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (256, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (258, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (261, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (267, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (268, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (269, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (270, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (273, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (274, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (275, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (276, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (277, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (278, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (279, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (282, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (283, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (285, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (298, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (321, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (322, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (323, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (324, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (333, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (341, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (211, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (213, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (239, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (241, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (242, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (243, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (244, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (245, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (247, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (248, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (251, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (252, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (255, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (268, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (269, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (273, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (274, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (275, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (276, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (278, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (279, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (339, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (340, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (211, 'Fungi', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (218, 'Fungi', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (233, 'Fungi', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (246, 'Fungi', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (269, 'Fungi', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (279, 'Fungi', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (341, 'Fungi', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (211, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (212, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (217, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (219, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (221, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (223, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (231, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (234, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (236, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (238, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (255, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (267, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (268, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (269, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (270, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (271, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (273, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (274, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (275, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (276, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (277, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (278, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (279, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (283, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (298, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (334, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (335, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (337, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (338, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (341, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (287, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (288, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (211, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (223, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (232, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (240, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (247, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (248, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (255, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (258, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (261, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (268, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (273, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (274, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (275, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (276, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (277, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (278, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (279, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (281, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (282, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (283, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (284, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (285, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (286, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (321, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (322, 'Animalia', 'Poissons', now(), NULL);

-----------------
--STADES DE VIE--
-----------------
INSERT INTO cor_taxref_nomenclature VALUES (2, 'all', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (3, 'all', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (20, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (21, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (22, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (24, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (25, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (26, 'Plantae', 'all', now(), NULL);

--TODO : "Acanthocéphales"

INSERT INTO cor_taxref_nomenclature VALUES (11, 'Animalia', 'Bivalves', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (8, 'Animalia', 'Bivalves', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (5, 'Animalia', 'Bivalves', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (4, 'Animalia', 'Bivalves', now(), NULL);

--TODO : "Céphalopodes"

INSERT INTO cor_taxref_nomenclature VALUES (11, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (8, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (9, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (12, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (13, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (14, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (15, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (16, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (17, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (18, 'Animalia', 'Insectes', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (11, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (28, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (5, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (6, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (12, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (4, 'Animalia', 'Reptiles', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (11, 'Animalia', 'Crustacés', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (8, 'Animalia', 'Crustacés', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (28, 'Animalia', 'Crustacés', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (5, 'Animalia', 'Crustacés', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (7, 'Animalia', 'Crustacés', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (4, 'Animalia', 'Crustacés', now(), NULL);

--TODO : "Scléractiniaires"

--TODO : "Hydrozoaires"

INSERT INTO cor_taxref_nomenclature VALUES (11, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (27, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (5, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (6, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (7, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (4, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (12, 'Animalia', 'Oiseaux', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (11, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (27, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (19, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (6, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (7, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (4, 'Animalia', 'Poissons', now(), NULL);

--TODO : "Némertes"

INSERT INTO cor_taxref_nomenclature VALUES (11, 'Animalia', 'Arachnides', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (5, 'Animalia', 'Arachnides', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (12, 'Animalia', 'Arachnides', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (4, 'Animalia', 'Arachnides', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (11, 'Animalia', 'Gastéropodes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (5, 'Animalia', 'Gastéropodes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (4, 'Animalia', 'Gastéropodes', now(), NULL);
--A compléter : Gastéropodes

INSERT INTO cor_taxref_nomenclature VALUES (11, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (27, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (8, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (10, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (28, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (4, 'Animalia', 'Amphibiens', now(), NULL);

--TODO : "Octocoralliaires"
--TODO : "Entognathes"
--TODO : "Annélides"
--TODO : "Pycnogonides"
--TODO : "Nématodes"

INSERT INTO cor_taxref_nomenclature VALUES (5, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (6, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (7, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (4, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (12, 'Animalia', 'Mammifères', now(), NULL);

-- TODO : "Ascidies"
-- TODO : "Myriapodes"
-- TODO : "Plathelminthes"

-- TODO : "Bacteria"

-- TODO : "Chromista"

-- TODO : "Fungi"

-- TODO : "Protozoa"

--------
--SEXE--
--------
INSERT INTO cor_taxref_nomenclature VALUES (188, 'all', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (189, 'all', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (194, 'all', 'all', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (193, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (193, 'Animalia', 'all', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (190, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (191, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (192, 'Plantae', 'all', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (190, 'Animalia', 'Bivalves', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (191, 'Animalia', 'Bivalves', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (192, 'Animalia', 'Bivalves', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (190, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (191, 'Animalia', 'Insectes', now(), NULL);

--TODO : "Acanthocéphales"

INSERT INTO cor_taxref_nomenclature VALUES (190, 'Animalia', 'Céphalopodes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (191, 'Animalia', 'Céphalopodes', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (190, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (191, 'Animalia', 'Reptiles', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (190, 'Animalia', 'Crustacés', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (191, 'Animalia', 'Crustacés', now(), NULL);

--TODO : "Scléractiniaires"

--TODO : "Hydrozoaires"

INSERT INTO cor_taxref_nomenclature VALUES (190, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (191, 'Animalia', 'Oiseaux', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (190, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (191, 'Animalia', 'Poissons', now(), NULL);

--TODO : "Némertes"

INSERT INTO cor_taxref_nomenclature VALUES (190, 'Animalia', 'Arachnides', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (191, 'Animalia', 'Arachnides', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (190, 'Animalia', 'Gastéropodes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (191, 'Animalia', 'Gastéropodes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (192, 'Animalia', 'Gastéropodes', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (190, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (191, 'Animalia', 'Amphibiens', now(), NULL);

--TODO : "Octocoralliaires"
--TODO : "Entognathes"

INSERT INTO cor_taxref_nomenclature VALUES (190, 'Animalia', 'Annélides', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (191, 'Animalia', 'Annélides', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (192, 'Animalia', 'Annélides', now(), NULL);


--TODO : "Pycnogonides"
--TODO : "Nématodes"

INSERT INTO cor_taxref_nomenclature VALUES (190, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (191, 'Animalia', 'Mammifères', now(), NULL);

--TODO : "Ascidies"

INSERT INTO cor_taxref_nomenclature VALUES (190, 'Animalia', 'Myriapodes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (191, 'Animalia', 'Myriapodes', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (190, 'Animalia', 'Plathelminthes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (191, 'Animalia', 'Plathelminthes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (192, 'Animalia', 'Plathelminthes', now(), NULL);


--TODO : "Fungi" à priori il n'y a pas de notion de sexe chez les champignons. Au mieux de polarité + et -.

--TODO : "Bacteria"

-- TODO : "Chromista"

-- TODO : "Protozoa"


-------------------------
--METHODE D'OBSERVATION--
-------------------------
INSERT INTO cor_taxref_nomenclature VALUES (42, 'all', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (61, 'all', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (62, 'all', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (63, 'all', 'all', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (57, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (58, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (60, 'Plantae', 'all', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (56, 'Plantae', 'Angiospermes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (59, 'Plantae', 'Angiospermes', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (56, 'Plantae', 'Gymnospermes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (59, 'Plantae', 'Gymnospermes', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (55, 'Plantae', 'Fougères', now(), NULL);

--TODO : "Algues vertes"
--TODO : "Algues rouges"

INSERT INTO cor_taxref_nomenclature VALUES (55, 'Plantae', 'Mousses', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (55, 'Plantae', 'Hépatiques et Anthocérotes', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (55, 'Fungi', 'all', now(), NULL);

--TODO : "Bacteria"
--TODO : "Chromista"
--TODO : "Protozoa"

--Aucun critère spécifique identifié pour les bivalves

INSERT INTO cor_taxref_nomenclature VALUES (43, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (45, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (47, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (48, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (49, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (50, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (52, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (53, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (64, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (65, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (66, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (67, 'Animalia', 'Insectes', now(), NULL);

--Aucun critère spécifique identifié pour les acanthocéphales
--Aucun critère spécifique identifié pour les céphalopodes

INSERT INTO cor_taxref_nomenclature VALUES (44, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (46, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (49, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (52, 'Animalia', 'Reptiles', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (49, 'Animalia', 'Crustacés', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (52, 'Animalia', 'Crustacés', now(), NULL);

--TODO : "Scléractiniaires"
--TODO : "Hydrozoaires"

INSERT INTO cor_taxref_nomenclature VALUES (43, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (44, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (46, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (48, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (49, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (50, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (51, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (52, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (53, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (54, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (67, 'Animalia', 'Oiseaux', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (52, 'Animalia', 'Poissons', now(), NULL);

--TODO : "Némertes"

INSERT INTO cor_taxref_nomenclature VALUES (49, 'Animalia', 'Arachnides', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (53, 'Animalia', 'Arachnides', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (52, 'Animalia', 'Gastéropodes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (66, 'Animalia', 'Gastéropodes', now(), NULL);
--manque l'identificatino par la coquille. TODO : proposer l'ajout à l'INPN

INSERT INTO cor_taxref_nomenclature VALUES (43, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (46, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (48, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (52, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (67, 'Animalia', 'Amphibiens', now(), NULL);
--manque l'identificatino par la ponte. TODO : proposer l'ajout à l'INPN

--TODO : "Octocoralliaires"
--TODO : "Entognathes"
--Aucun critère spécifique identifié pour les annélides
--TODO : "Pycnogonides"
--TODO : "Nématodes"
--TODO : "Ascidies"
--TODO : "Plathelminthes"

INSERT INTO cor_taxref_nomenclature VALUES (43, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (45, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (46, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (48, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (49, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (50, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (52, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (53, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (54, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (65, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (67, 'Animalia', 'Mammifères', now(), NULL);

--TODO : "Ascidies"
--Aucun critère spécifique identifié pour les myriapodes
--TODO : "Plathelminthes"

---------------------
--Statut biologique--
---------------------
INSERT INTO cor_taxref_nomenclature VALUES (29, 'all', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (30, 'all', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (31, 'all', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (41, 'all', 'all', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (32, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (38, 'Plantae', 'all', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (32, 'Fungi', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (38, 'Fungi', 'all', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (32, 'Animalia', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (38, 'Animalia', 'all', now(), NULL);

--TODO : "Bacteria"
--TODO : "Chromista"
--TODO : "Protozoa"

--Aucun critère spécifique identifié pour les bivalves

INSERT INTO cor_taxref_nomenclature VALUES (35, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (37, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (39, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (40, 'Animalia', 'Insectes', now(), NULL);

--TODO : "Acanthocéphales"

INSERT INTO cor_taxref_nomenclature VALUES (37, 'Animalia', 'Céphalopodes', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (33, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (34, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (37, 'Animalia', 'Reptiles', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (37, 'Animalia', 'Crustacés', now(), NULL);

--TODO : "Scléractiniaires"
--TODO : "Hydrozoaires"

INSERT INTO cor_taxref_nomenclature VALUES (33, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (34, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (35, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (36, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (37, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (39, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (40, 'Animalia', 'Oiseaux', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (35, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (37, 'Animalia', 'Poissons', now(), NULL);

--TODO : "Némertes"

INSERT INTO cor_taxref_nomenclature VALUES (37, 'Animalia', 'Arachnides', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (37, 'Animalia', 'Gastéropodes', now(), NULL);


INSERT INTO cor_taxref_nomenclature VALUES (33, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (37, 'Animalia', 'Amphibiens', now(), NULL);

--TODO : "Octocoralliaires"
--TODO : "Entognathes"
--TODO : "Annélides"
--TODO : "Pycnogonides"
--TODO : "Nématodes"
--TODO : "Ascidies"
--TODO : "Plathelminthes"

INSERT INTO cor_taxref_nomenclature VALUES (33, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (34, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (35, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (37, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (39, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (40, 'Animalia', 'Mammifères', now(), NULL);

--TODO : "Ascidies"
--TODO : "Myriapodes
--TODO : "Plathelminthes"


------------------------
--Type de dénombrement--
------------------------
INSERT INTO cor_taxref_nomenclature VALUES (106, 'all', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (107, 'all', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (108, 'all', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (109, 'all', 'all', now(), NULL);


-------------------------
--Objet du dénombrement--
-------------------------
INSERT INTO cor_taxref_nomenclature VALUES (165, 'all', 'all', now(), NULL);


INSERT INTO cor_taxref_nomenclature VALUES (166, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (171, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (172, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (173, 'Plantae', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (174, 'Plantae', 'all', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (166, 'Fungi', 'all', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (174, 'Fungi', 'all', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (166, 'Animalia', 'all', now(), NULL);


--TODO : "Bacteria"
--TODO : "Chromista"
--TODO : "Protozoa"

INSERT INTO cor_taxref_nomenclature VALUES (168, 'Animalia', 'Bivalves', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (167, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (168, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (169, 'Animalia', 'Insectes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (170, 'Animalia', 'Insectes', now(), NULL);

--TODO : "Acanthocéphales"

INSERT INTO cor_taxref_nomenclature VALUES (167, 'Animalia', 'Céphalopodes', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (167, 'Animalia', 'Reptiles', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (170, 'Animalia', 'Reptiles', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (168, 'Animalia', 'Crustacés', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (170, 'Animalia', 'Crustacés', now(), NULL);

--TODO : "Scléractiniaires"
--TODO : "Hydrozoaires"

INSERT INTO cor_taxref_nomenclature VALUES (167, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (168, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (169, 'Animalia', 'Oiseaux', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (170, 'Animalia', 'Oiseaux', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (168, 'Animalia', 'Poissons', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (170, 'Animalia', 'Poissons', now(), NULL);

--TODO : "Némertes"

INSERT INTO cor_taxref_nomenclature VALUES (168, 'Animalia', 'Arachnides', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (170, 'Animalia', 'Arachnides', now(), NULL);

INSERT INTO cor_taxref_nomenclature VALUES (168, 'Animalia', 'Gastéropodes', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (170, 'Animalia', 'Gastéropodes', now(), NULL);


INSERT INTO cor_taxref_nomenclature VALUES (167, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (168, 'Animalia', 'Amphibiens', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (170, 'Animalia', 'Amphibiens', now(), NULL);

--TODO : "Octocoralliaires"
--TODO : "Entognathes"
--TODO : "Annélides"
--TODO : "Pycnogonides"
--TODO : "Nématodes"
--TODO : "Ascidies"
--TODO : "Plathelminthes"

INSERT INTO cor_taxref_nomenclature VALUES (167, 'Animalia', 'Mammifères', now(), NULL);
INSERT INTO cor_taxref_nomenclature VALUES (168, 'Animalia', 'Mammifères', now(), NULL);

--TODO : "Ascidies"
--TODO : "Myriapodes
--TODO : "Plathelminthes"
