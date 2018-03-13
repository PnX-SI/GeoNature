SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
--SET row_security = off;

SET search_path = ref_nomenclatures, pg_catalog;

DELETE FROM t_nomenclatures;
DELETE FROM bib_nomenclatures_types;

INSERT INTO bib_nomenclatures_types (id_type, mnemonique, label_fr, definition_fr, source, statut, meta_create_date, meta_update_date) VALUES
(2, 'DS_PUBLIQUE', 'Code d''origine de la donnée', 'Nomenclature des codes d''origine de la donnée : publique, privée, mixte...', 'SINP', 'Validé',  '2013-12-05 00:00:00', '2013-12-05 00:00:00')
,(3, 'NAT_OBJ_GEO', 'Nature d''objet géographique', 'Nomenclature des natures d''objets géographiques', 'SINP', 'Validé',  '2014-01-22 00:00:00', '2015-10-15 00:00:00')
,(4, 'DEE_FLOU', 'Existence d''un floutage sur la donnée', 'Nomenclature indiquant l''existence d''un floutage sur la donnée lors de sa création en tant que DEE.', 'SINP', 'Validé',  '2015-09-18 00:00:00', '2015-10-15 00:00:00')
,(5, 'NIV_PRECIS', 'Niveaux de précision de diffusion souhaités', 'Nomenclature des niveaux de précision de diffusion souhaités par le producteur.', 'SINP', 'Validé',  '2015-07-29 00:00:00', '2015-10-15 00:00:00')
,(6, 'OBJ_DENBR', 'Objet du dénombrement', 'Nomenclature des objets qui peuvent être dénombrés', 'SINP', 'Validé',  '2014-01-22 00:00:00', '2015-10-15 00:00:00')
,(7, 'ETA_BIO', 'Etat biologique de l''observation', 'Nomenclature des états biologiques de l''observation.', 'SINP', 'Validé',  '2015-07-29 00:00:00', '2015-10-19 00:00:00')
,(8, 'NATURALITE', 'Niveau de naturalité', 'Nomenclature des niveaux de naturalité', 'SINP', 'Validé',  '2015-07-29 00:00:00', '2015-10-19 00:00:00')
,(9, 'SEXE', 'Sexe', 'Nomenclature des sexes', 'SINP', 'Validé',  '2015-07-29 00:00:00', '2015-10-19 00:00:00')
,(10, 'STADE_VIE', 'Stade de vie : stade de développement du sujet', 'Nomenclature des stades de vie : stades de développement du sujet de l''observation.', 'SINP', 'Validé',  '2015-07-29 00:00:00', '2016-03-24 00:00:00')
,(11, 'STAT_BIOGEO', 'Statut biogéographique', 'Nomenclature des statuts biogéographiques.', 'SINP', 'Validé',  '2015-07-29 00:00:00', '2015-10-15 00:00:00')
,(12, 'REF_HAB', 'Référentiels d''habitats et typologies', 'Nomenclature des référentiels d''habitats et typologies utilisés pour rapporter un habitat au sein du standard. La référence à paraître prochainement est HABREF. http://inpn.mnhn.fr/telechargement/referentiels/habitats Les typologies sont disponibles à la même adresse, mais seront prochainement à l''adresse suivante : http://inpn.mnhn.fr/telechargement/referentiels/habitats/typologies', 'SINP', 'Validé',  '2013-03-13 00:00:00', '2016-06-23 00:00:00')
,(13, 'STATUT_BIO', 'Statut biologique', 'Nomenclature des statuts biologiques.', 'SINP', 'Validé',  '2015-07-29 00:00:00', '2015-12-16 00:00:00')
,(14, 'METH_OBS', 'Méthodes d''observation', 'Nomenclature des méthodes d''observation, indiquant de quelle manière ou avec quel indice on a pu observer le sujet.', 'SINP', 'Validé',  '2015-07-29 00:00:00', '2015-12-16 00:00:00')
,(15, 'PREUVE_EXIST', 'Preuve existante', 'Nomenclature de l''existence des preuves.', 'SINP', 'Validé',  '2015-07-29 00:00:00', '2015-12-16 00:00:00')
,(16, 'SENSIBILITE', 'Niveaux de sensibilité', 'Nomenclature des niveaux de sensibilité possibles', 'SINP', 'Validé',  '2015-06-10 00:00:00', '2016-06-23 00:00:00')
,(17, 'SENSIBLE', 'Valeurs de sensibilité qualitative', 'Nomenclature des valeurs de sensibilité qualitative (oui/non)', 'SINP', 'Validé',  '2015-07-29 00:00:00', '2016-04-07 00:00:00')
,(18, 'STATUT_OBS', 'Statut d''observation', 'Nomenclature des statuts d''observation.', 'SINP', 'Validé',  '2013-12-05 00:00:00', '2016-03-24 00:00:00')
,(19, 'STATUT_SOURCE', 'Statut de la source', 'Nomenclature des statuts possibles de la source.', 'SINP', 'Validé',  '2013-12-04 00:00:00', '2013-12-04 00:00:00')
,(20, 'TYP_ATTR', 'Type de l''attribut', 'Nomenclature des types d''attributs additionnels.', 'SINP', 'Validé',  '2015-09-16 00:00:00', '2015-12-07 00:00:00')
,(21, 'TYP_DENBR', 'Type de dénombrement', 'Nomenclature des types de dénombrement possibles (comptage, estimation...)', 'SINP', 'Validé',  '2014-01-22 00:00:00', '2015-12-16 00:00:00')
,(22, 'TYP_EN', 'Type d''espace naturel', 'Nomenclature des types d''espaces naturels.', 'SINP', 'Validé',  '2014-01-22 00:00:00', '2016-06-15 00:00:00')
,(23, 'TYP_INF_GEO', 'Type d''information géographique', 'Nomenclature des types d''information géographique dans le cas de l''utilisation d''un rattachement à un objet géographique (commune, département, espace naturel, masse d''eau...).', 'SINP', 'Validé',  '2015-09-18 00:00:00', '2015-12-16 00:00:00')
,(24, 'TYP_GRP', 'Type de regroupement', 'Nomenclature listant les valeurs possibles pour le type de regroupement.', 'SINP', 'Validé',  '2015-06-09 00:00:00', '2015-12-07 00:00:00')
,(25, 'VERS_ME', 'Version des masses d''eau', 'Nomenclature des versions du référentiel SANDRE utilisé pour les masses d''eau.', 'SINP', 'Validé',  '2015-09-18 00:00:00', '2015-12-16 00:00:00')
,(26, 'ACC2', 'Raison de niveau d''accessibilité', 'Nomenclature des raisons d''un niveau d''accessibilité', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-04-08 00:00:00')
,(27, 'ACC', 'Niveau d''accessibilité', 'Nomenclature des niveaux d''accessibilité à un site géologique', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-04-08 00:00:00')
,(28, 'AUTPREAL', 'Autorisation préalable pour accès', 'Nomenclature des valeurs concernant l''éventuelle délivrance d''une autorisation préalable pour accéder à un site', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-04-08 00:00:00')
,(29, 'GILGES', 'Code Gilges', 'Nomenclature des codes Gilges', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-04-08 00:00:00')
,(30, 'REGION', 'Code région', 'Nomenclature des codes région', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-04-08 00:00:00')
,(31, 'CONFID', 'Valeur de confidentialité', 'Nomenclatures des valeurs de confidentialité', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-04-08 00:00:00')
,(32, 'COUPGEOL', 'Présence/absence de coupe géologique', 'Nomenclature de présence/absence de coupe géologique', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-04-08 00:00:00')
,(33, 'ETAT1', 'Niveau d''état d''un site géologique', 'Nomenclature des niveaux d''état potentiels d''un site', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-04-08 00:00:00')
,(34, 'ETAT2', 'Raison du niveau d''état d''un site géologique', 'Nomenclature indiquant les raisons du niveau d''état du site', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-04-08 00:00:00')
,(35, 'EXISTPROT', 'Existence d''une protection pour un site géologique', 'Nomenclature indiquant si une protection existe ou non', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-04-08 00:00:00')
,(36, 'INTGEOL', 'Intérêt géologique du site géologique', 'Nomenclature des intérêts géologiques que peut avoir un site', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-04-08 00:00:00')
,(37, 'INTSECTYP', 'Type d''intérêt secondaire du site géologique', 'Nomenclature des types d''intérêt secondaire potentiels d''un site géologique', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-04-08 00:00:00')
,(38, 'INTSEC', 'Intérêt secondaire du site géologique', 'Nomenclature des intérêts secondaires potentiels, fonction des types d''intérêts secondaires.', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-04-08 00:00:00')
,(39, 'MODIF', 'Statut de modification de fiche de site géologique', 'Nomenclature des statuts de modification de fiche de site', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-04-08 00:00:00')
,(40, 'PAY', 'Paiement spécifique à l''accès du site géologique', 'Nomenclature qui indique si un site nécessite un paiement spécifique pour y accéder', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-04-08 00:00:00')
,(41, 'PEROUV', 'Périodes d''ouverture du site géologique', 'Nomenclature des périodes d''ouverture d''un site', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-04-08 00:00:00')
,(42, 'PHENGEOL', 'Phénomène géologique', 'Nomenclature des phénomènes géologiques', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-04-08 00:00:00')
,(43, 'RARETE', 'Niveau de rareté du site géologique', 'Nomenclature des niveaux de rareté pour les sites géologiques', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-04-08 00:00:00')
,(44, 'JUR1', 'Statut de protection, éléments primaires, pour un site géologique', 'Nomenclature des statuts de protection, éléments primaires', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-04-08 00:00:00')
,(45, 'JUR2', 'Statut de protection, éléments secondaires, pour un site géologique', 'Nomenclature des statuts de protection, éléments secondaires', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-04-08 00:00:00')
,(46, 'PROT1', 'Type générique de statut de protection pour un site géologique', 'Nomenclature des types génériques (ou primaires) de statuts de protection et/ou de gestion', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-04-08 00:00:00')
,(47, 'PROT2', 'Type spécifique de statut de protection pour un site  géologique', 'Nomenclature des types spécifiques (ou secondaires) de statuts de protection et/ou gestion d''un site géologique', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-04-08 00:00:00')
,(48, 'VALNAT', 'Statut de validation nationale pour un site géologique', 'Nomenclature des statuts de validation nationaux pour un site géologique', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-04-08 00:00:00')
,(49, 'VALREG', 'Statut de validation régionale pour un site géologique', 'Nomenclature des statuts de validation régionaux pour le site considéré.', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-04-08 00:00:00')
,(50, 'DOC', 'Type de document', 'Nomenclature des types de documents', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-04-08 00:00:00')
,(51, 'INVGEOL', 'Type d''inventaire géologique', 'Nomenclature des types d''inventaires géologiques pouvant être réalisés sur un site', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-09-01 00:00:00')
,(52, 'TYPPERS', 'Intervenant fiche (type de personne)', 'Nomenclature des types de personnes ayant pu intervenir sur une fiche de site géologique, de quelque manière que ce soit, ou types de personnes.', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-04-08 00:00:00')
,(53, 'TYPO1', 'Typologie primaire d''un site géologique', 'Nomenclature des éléments de typologie primaire d''un site géologique', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-04-08 00:00:00')
,(54, 'TYPO2', 'Typologie secondaire d''un site géologique', 'Nomenclature des éléments secondaires de typologie du site géologique. Certains éléments de cette liste sont restreints à certains éléments primaires uniquement (cf. nomenclature 53).', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-04-08 00:00:00')
,(55, 'TYPO3', 'Typologie tertiaire d''un site géologique', 'Nomenclature des éléments tertiaires de typologie du site géologique', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-04-08 00:00:00')
,(56, 'UNITSURF', 'Unité de superficie pour un site géologique', 'Nomenclature des unités de superficie pouvant être utilisées pour indiquer la surface d''un site géologique', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-04-08 00:00:00')
,(57, 'USEACTU', 'Usage d''un site géologique', 'Nomenclature des usages qui peuvent être faits d''un site géologique', 'SINP', 'Validé',  '2016-04-07 00:00:00', '2016-04-08 00:00:00')
,(58, 'AIRECONNUE', 'Aire connue', 'Nomenclature des valeurs indiquant si la surface d''un relevé est connue ou non', 'SINP', 'Validé',  '2016-06-21 00:00:00', '2016-06-21 00:00:00')
,(59, 'BRANCHEMETH', 'Méthodes phytosociologiques, branches', 'Nomenclature des branches de méthodes phytosociologiques', 'SINP', 'Validé',  '2016-06-21 00:00:00', '2016-06-21 00:00:00')
,(60, 'BRAUNBLANQABDOM', 'Braun Blanquet Pavillard, abondance-dominance', 'Nomenclature des valeurs pour l''échelle d''abondance-dominance de Braun-Blanquet Pavillard (1928)', 'SINP', 'Validé',  '2016-06-21 00:00:00', '2016-06-21 00:00:00')
,(61, 'BRAUNBARK', 'Braun Blanquet Barkman, abondance-dominance', 'Nomenclature des valeurs de l''échelle de Braun-Blanquet Barkman complétée telle que dans le dictionnaire de sociologie et synécologie végétales (Géhu, 2006)', 'SINP', 'Validé',  '2016-06-21 00:00:00', '2016-06-21 00:00:00')
,(62, 'BRAUNPAV', 'Braun Blanquet Pavillard, abondance', 'Nomenclature des valeurs de l''échelle d''abondance de Braun-Blanquet Pavillard (1928)', 'SINP', 'Validé',  '2016-06-21 00:00:00', '2016-06-21 00:00:00')
,(63, 'COMPLETREL', 'Complétude des relevés', 'Nomenclature des valeurs de complétude des relevés phytosociologiques détaillés', 'SINP', 'Validé',  '2016-06-21 00:00:00', '2016-06-21 00:00:00')
,(64, 'RATTACH', 'Rattachement au syntaxon, confère', 'Nomenclature des indicateurs de doute dans le rattachement au syntaxon (confère).', 'SINP', 'Validé',  '2016-06-21 00:00:00', '2016-06-21 00:00:00')
,(65, 'DOMIN', 'Echelle de Domin', 'Nomenclature des valeurs de l''échelle de Domin (Source : Evans & Dahl, 1955)', 'SINP', 'Validé',  '2016-06-21 00:00:00', '2016-06-21 00:00:00')
,(66, 'EXPOSITION', 'Exposition d''un terrain', 'Nomenclature des points cardinaux et intercardinaux permettant d''indiquer l''exposition d''un terrain.', 'SINP', 'Validé',  '2016-06-21 00:00:00', '2016-06-21 00:00:00')
,(67, 'FORMES', 'Formes du relevé', 'Nomenclature des formes possibles pour un relevé phytosociologique', 'SINP', 'Validé',  '2016-06-21 00:00:00', '2016-06-21 00:00:00')
,(68, 'LONDO', 'Echelle de Londo', 'Nomenclature des valeurs de l''échelle d''abondance-dominnance de Londo suivant Londo, 1976 (The decimal scale for releves of permanent quadrats)', 'SINP', 'Validé',  '2016-06-21 00:00:00', '2016-06-21 00:00:00')
,(69, 'NIVORGA', 'Niveaux d''organisation des relevés', 'Nomenclature des niveaux d''organisation auxquels peuvent se trouver des relevés phytosociologiques détaillés', 'SINP', 'Validé',  '2016-06-21 00:00:00', '2016-06-21 00:00:00')
,(70, 'ORDIN', 'Echelle ordinale', 'Nomenclature des valeurs de l''échelle ordinale d''abondance-dominance, suivant Barkman (1964)', 'SINP', 'Validé',  '2016-06-21 00:00:00', '2016-06-21 00:00:00')
,(71, 'PRES', 'Présence', 'Nomenclature des cas de présence d''un taxon', 'SINP', 'Validé',  '2016-06-21 00:00:00', '2016-06-21 00:00:00')
,(72, 'SOCIAB', 'Sociabilité', 'Nomenclature des valeurs de sociabilité des taxons végétaux suivant Braun Blanquet (1964)', 'SINP', 'Validé',  '2016-06-21 00:00:00', '2016-06-21 00:00:00')
,(73, 'TYPEAIRE', 'Types de surface', 'Nomenclature des types de surfaces utilisées pour les relevés phytosociologiques', 'SINP', 'Validé',  '2016-06-21 00:00:00', '2016-06-21 00:00:00')
,(74, 'TYPCORR', 'Type de correspondance avec le syntaxon', 'Nomenclature des types de correspondance entre relevés synusiaux et syntaxons sigmatistes', 'SINP', 'Validé',  '2016-06-21 00:00:00', '2016-06-21 00:00:00')
,(75, 'TYPECH', 'Type d''échelle', 'Nomenclature des types d''échelles utilisées pour l''évaluation d''un paramètre de taxon en phytosociologie', 'SINP', 'Validé',  '2016-06-21 00:00:00', '2016-06-21 00:00:00')
,(76, 'TYPEPARM', 'Paramètres suivis pour un taxon, phytosociologie', 'Nomenclature des types de paramètres potentiellement suivis pour un taxon en phytosociologie', 'SINP', 'Validé',  '2016-06-21 00:00:00', '2016-06-21 00:00:00')
,(77, 'UNITOP', 'Unités opérationnelles', 'Liste des modifications morphologiques végétales particulières, génétiquement non fixées (unités morphologiques opérationnelles, unités biologiques opérationnelles, et/ou accommodats), imposées par le milieu', 'SINP', 'Validé',  '2016-06-21 00:00:00', '2016-06-21 00:00:00')
,(0, 'ROOT', 'Racine des nomenclatures', 'Racine. Parent de toutes les nomenclatures', 'GEONATURE', 'Non validé', '2017-06-15 12:51:30.197042', '2017-06-15 12:51:30.197042')
,(100, 'TECHNIQUE_OBS', 'Techniques d''observation', 'Une technique désigne l''ensemble des savoirs-faire, procédés et outils spécifiques, mobilisés de manière logique (règles, étapes et principes) pour collecter des données associées à un paramètre à observer ou à un facteur écologique à prendre en compte. Ce sont les moyens mis en oeuvre sur le terrain pour l''observation d''espèces ou d''habitats. Une technique est définie par rapport à une cible. Dans le cadre d''un protocole, elle doit être reproductible dans le temps et dans l''espace.', 'CAMPANULE', 'Validation en cours', '2017-06-19 15:03:31.135525', '2017-06-19 15:03:31.135525')
,(101, 'STATUT_VALID', 'Statut de validation', 'Nomenclature des statuts de validations de la données', 'GEONATURE', 'Non validé', '2017-08-08 00:00:00', '2017-08-08 00:00:00')
,(102, 'RESOURCE_TYP', 'Type de ressources', 'Nomenclature des types de ressources relatifs aux jeux de données', 'SINP', 'Validé', '2017-10-16 00:00:00', '2017-10-16 00:00:00')
,(103, 'DATA_TYP', 'Type de données', 'Nomenclature des types de données SINP relatifs aux jeux de données', 'SINP', 'Validé', '2017-10-16 00:00:00', '2017-10-16 00:00:00')
,(104, 'SAMPLING_PLAN_TYP', 'Type de plan d''échantillonnage', 'Processus de sélection des unités d''échantillonnage sur lesquelles sont effectuées les mesures des paramètres prévus dans le protocole', 'SINP', 'Validé', '2017-10-16 00:00:00', '2017-10-16 00:00:00')
,(105, 'SAMPLING_UNITS_TYP', 'Type d''unités d''échantillonnage', 'L''unité d''échantillonnage désigne l''unité sur laquelle sont mesurés les paramètres étudiés', 'SINP', 'Validé', '2017-10-16 00:00:00', '2017-10-16 00:00:00')
,(106, 'METH_DETERMIN', 'Méthode de détermination', 'Nomenclature des méthodes de détermination, indiquant quelle méthode a été utilisée pour déterminer le sujet.', 'GEONATURE', 'Non validé', '2017-10-26 00:00:00', '2017-10-26 00:00:00')
,(107, 'NIVEAU_TERRITORIAL', 'Niveau Territorial', 'Nomenclature des valeurs pour le niveau territorial.', 'SINP', 'Validé', '2017-10-30 00:00:00', '2017-10-30 00:00:00')
,(108, 'CA_OBJECTIFS', 'Objectif du cadre d''acquisition', 'Nomenclature des valeurs permises pour les objectifs du cadre d''acquisition.', 'SINP', 'Validé', '2017-10-30 00:00:00', '2017-10-30 00:00:00')
,(109, 'ROLE_ACTEUR', 'Role de l''Acteur', 'Liste des types de rôles pour les acteurs. Chaque valeur correspond exactement à une valeur de la norme ISO 19115. Cela est précisé pour chacune d''entre elles.', 'SINP', 'Validé', '2017-10-30 00:00:00', '2017-10-30 00:00:00')
,(110, 'TERRITOIRE', 'Territoire', 'Nomenclature des territoires.', 'SINP', 'Validé', '2017-10-30 00:00:00', '2017-10-30 00:00:00')
,(111, 'TYPE_FINANCEMENT', 'Type de financement', 'Nomenclature des types de financement.', 'SINP', 'Validé', '2017-10-30 00:00:00', '2017-10-30 00:00:00')
,(112, 'TYPE_PROTOCOLE', 'Type de protocole', 'Nomenclature des types de protocles.', 'SINP', 'Validé', '2017-10-30 00:00:00', '2017-10-30 00:00:00')
,(113, 'VOLET_SINP', 'Volet SINP', 'Nomenclature des volets que peut viser le SINP.', 'SINP', 'Validé', '2017-10-30 00:00:00', '2017-10-30 00:00:00')
,(114, 'JDD_OBJECTIFS', 'Objectif du jeu de données', 'Nomenclature des valeurs permises pour les objectifs du jeu de données.', 'SINP', 'Validé', '2017-11-02 00:00:00', '2017-11-02 00:00:00')
,(115, 'METHO_RECUEIL', 'Méthode de recueil des données', 'Nomenclature de l''ensemble de techniques, savoir-faire et outils mobilisés pour collecter des données.', 'SINP', 'Validé', '2017-11-02 00:00:00', '2017-11-02 00:00:00')
,(116, 'TYPE_SITE', 'Type de sites', 'Nomenclature des types de sites suivi dans gn_monitoring.', 'GEONATURE', 'Non validé', '2018-03-13 00:00:00', '2018-03-13 00:00:00')

;

UPDATE bib_nomenclatures_types SET label_default = label_MYDEFAULTLANGUAGE;
UPDATE bib_nomenclatures_types SET definition_default = definition_MYDEFAULTLANGUAGE;
ALTER TABLE bib_nomenclatures_types ALTER COLUMN label_default SET NOT NULL;
ALTER TABLE bib_nomenclatures_types ALTER COLUMN label_MYDEFAULTLANGUAGE SET NOT NULL;

INSERT INTO t_nomenclatures (id_nomenclature, id_type, cd_nomenclature, mnemonique, label_fr, definition_fr, source, statut, id_broader, hierarchy, meta_create_date, meta_update_date, active) VALUES
(81, 2, 'Re', 'Publique Régie', 'Publique Régie', 'Publique Régie : La Donnée Source est publique et a été produite directement par un organisme ayant autorité publique avec ses moyens humains et techniques propres.', 'SINP', 'Validé', 80, '002.001.001', '2013-12-05 00:00:00', '2013-12-05 00:00:00', true)
,(77, 2, 'Ac', 'Publique acquise', 'Publique acquise', 'Publique Acquise : La donnée-source a été produite par un organisme privé (associations, bureaux d''étude…) ou une personne physique à titre personnel. Les droits patrimoniaux exclusifs ou non exclusifs, de copie, traitement et diffusion sans limitation ont été acquis à titre gracieux ou payant, sur marché ou par convention, par un organisme ayant autorité publique. La donnée-source est devenue publique.  ', 'SINP', 'Validé', 80, '002.001.002', '2013-12-05 00:00:00', '2013-12-05 00:00:00', true)
,(140, 22, 'ZNIEFF1', 'ZNIEFF1', 'ZNIEFF1', 'Zone Naturelle d''Intérêt Ecologique Faunistique et Floristique de type I', 'SINP', 'Validé', 139, '022.029.001', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true)
,(141, 22, 'ZNIEFF2', 'ZNIEFF2', 'ZNIEFF2', 'Zone Naturelle d''Intérêt Ecologique Faunistique et Floristique de type II', 'SINP', 'Validé', 139, '022.029.002', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true)
,(10, 10, '8', 'Têtard', 'Têtard', 'Larve de batracien.', 'SINP', 'Validé', 0, '010.008', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true)
,(16, 10, '14', 'Pupe', 'Pupe', 'Nymphe des diptères.', 'SINP', 'Validé', 0, '010.014', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true)
,(147, 24, 'CAMP', 'CAMP', 'CAMP', 'Campagne de prélèvement', 'SINP', 'Validé', 0, '024.002', '2015-06-09 00:00:00', '2015-06-09 00:00:00', true)
,(0, 0, '0', 'Root', 'Racine des nomenclatures', 'Racine = Parent de toutes les nomenclatures', 'GEONATURE', 'non validé', 0, '000', '2017-06-15 12:53:01.201955', NULL, true)
,(4, 10, '2', 'Adulte', 'Adulte', 'L''individu est au stade adulte.', 'SINP', 'Validé', 0, '010.002', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true)
,(5, 10, '3', 'Juvénile', 'Juvénile', 'L''individu n''a pas encore atteint le stade adulte. C''est un individu jeune.', 'SINP', 'Validé', 0, '010.003', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true)
,(66, 14, '24', 'Oothèque', 'Oothèque', 'Membrane-coque qui protège la ponte de certains insectes et certains mollusques.', 'SINP', 'Validé', 0, '014.024', '2015-12-07 00:00:00', '2015-12-07 00:00:00', true)
,(67, 14, '25', 'Vu et entendu', 'Vu et entendu', 'Vu et entendu : l''occurrence a à la fois été vue et entendue.', 'SINP', 'Validé', 0, '014.025', '2015-12-07 00:00:00', '2015-12-07 00:00:00', true)
,(78, 2, 'NSP', 'Ne sait pas', 'Ne sait pas', 'Ne sait pas : L''information indiquant si la Donnée Source est publique ou privée n''est pas connue.', 'SINP', 'Validé', 0, '002.000', '2013-12-05 00:00:00', '2013-12-05 00:00:00', true)
,(29, 13, '0', 'Inconnu', 'Inconnu', 'Inconnu : Le statut biologique de l''individu n''est pas connu.', 'SINP', 'Validé', 0, '013.000', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true)
,(30, 13, '1', 'Non renseigné', 'Non renseigné', 'Non renseigné : Le statut biologique de l''individu n''a pas été renseigné.', 'SINP', 'Validé', 0, '013.001', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true)
,(31, 13, '2', 'Non Déterminé', 'Non Déterminé', 'Non déterminé : Le statut biologique de l''individu n''a pas pu être déterminé.', 'SINP', 'Validé', 0, '013.002', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true)
,(9, 10, '7', 'Chenille', 'Chenille', 'Larve éruciforme des lépidoptères ou papillons.', 'SINP', 'Validé', 0, '010.007', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true)
,(32, 13, '3', 'Reproduction', 'Reproduction', 'Reproduction : Le sujet d''observation en est au stade de reproduction (nicheur, gravide, carpophore, floraison, fructification…)', 'SINP', 'Validé', 0, '013.003', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true)
,(33, 13, '4', 'Hibernation', 'Hibernation', 'Hibernation : L''hibernation est un état d''hypothermie régulée, durant plusieurs jours ou semaines qui permet aux animaux de conserver leur énergie pendant l''hiver. ', 'SINP', 'Validé', 0, '013.004', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true)
,(34, 13, '5', 'Estivation', 'Estivation', 'Estivation : L''estivation est un phénomène analogue à celui de l''hibernation, au cours duquel les animaux tombent en léthargie. L''estivation se produit durant les périodes les plus chaudes et les plus sèches de l''été.', 'SINP', 'Validé', 0, '013.005', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true)
,(36, 13, '7', 'Swarming', 'Swarming', 'Swarming : Indique que l''individu a un comportement de swarming : il se regroupe avec d''autres individus de taille similaire, sur une zone spécifique, ou en mouvement.', 'SINP', 'Validé', 0, '013.007', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true)
,(37, 13, '8', 'Chasse / alimentation', 'Chasse / alimentation', 'Chasse / alimentation : Indique que l''individu est sur une zone qui lui permet de chasser ou de s''alimenter.', 'SINP', 'Validé', 0, '013.008', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true)
,(35, 13, '6', 'Halte migratoire', 'Halte migratoire', 'Halte migratoire : Indique que l''individu procède à une halte au cours de sa migration, et a été découvert sur sa zone de halte.', 'SINP', 'Validé', 0, '013.006', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true)
,(38, 13, '9', 'Pas de reproduction', 'Pas de reproduction', 'Pas de reproduction : Indique que l''individu n''a pas un comportement reproducteur. Chez les végétaux : absence de fleurs, de fruits…', 'SINP', 'Validé', 0, '013.009', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true)
,(40, 13, '11', 'Erratique', 'Erratique', 'Erratique : Individu d''une ou de populations d''un taxon qui ne se trouve, actuellement, que de manière occasionnelle dans les limites d''une région. Il a été retenu comme seuil, une absence de 80% d''un laps de temps donné (année, saisons...).', 'SINP', 'Validé', 0, '013.011', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true)
,(41, 13, '12', 'Sédentaire', 'Sédentaire', 'Sédentaire : Individu demeurant à un seul emplacement, ou restant toute l''année dans sa région d''origine, même s''il effectue des déplacements locaux.', 'SINP', 'Validé', 0, '013.012', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true)
,(39, 13, '10', 'Passage en vol', 'Passage en vol', 'Passage en vol : Indique que l''individu  est de passage et en vol.', 'SINP', 'Validé', 0, '013.010', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true)
,(74, 19, 'Li', 'Li', 'Littérature', 'Littérature : l''observation a été extraite d''un article ou un ouvrage scientifique.', 'SINP', 'Validé', 0, '019.002', '2013-12-04 00:00:00', '2013-12-04 00:00:00', true)
,(76, 19, 'Te', 'Te', 'Terrain', 'Terrain : l''observation provient directement d''une base de données ou d''un document issu de la prospection sur le terrain.', 'SINP', 'Validé', 0, '019.001', '2013-12-04 00:00:00', '2013-12-04 00:00:00', true)
,(75, 19, 'NSP', 'NSP', 'Ne Sait Pas', 'Ne Sait Pas : la source est inconnue.', 'SINP', 'Validé', 0, '019.000', '2013-12-04 00:00:00', '2013-12-04 00:00:00', true)
,(52, 14, '10', 'Restes dans pelote de réjection', 'Restes dans pelote de réjection', 'Identifie l''espèce à laquelle appartiennent les restes retrouvés dans la pelote de réjection (os ou exosquelettes, par exemple).', 'SINP', 'Validé', 0, '014.010', '2015-07-29 00:00:00', '2015-12-07 00:00:00', true)
,(42, 14, '0', 'Vu', 'Vu', 'Observation directe d''un individu vivant.', 'SINP', 'Validé', 0, '014.000', '2015-07-29 00:00:00', '2015-12-07 00:00:00', true)
,(43, 14, '1', 'Entendu', 'Entendu', 'Observation acoustique d''un individu vivant.', 'SINP', 'Validé', 0, '014.001', '2015-07-29 00:00:00', '2015-12-07 00:00:00', true)
,(44, 14, '2', 'Coquilles d''œuf', 'Coquilles d''œuf', 'Observation indirecte via coquilles d''œuf.', 'SINP', 'Validé', 0, '014.002', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true)
,(45, 14, '3', 'Ultrasons', 'Ultrasons', 'Observation acoustique indirecte d''un individu vivant avec matériel spécifique permettant de transduire des ultrasons en sons perceptibles par un humain.', 'SINP', 'Validé', 0, '014.003', '2015-07-29 00:00:00', '2015-12-07 00:00:00', true)
,(46, 14, '4', 'Empreintes', 'Empreintes', 'Observation indirecte via empreintes.', 'SINP', 'Validé', 0, '014.004', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true)
,(47, 14, '5', 'Exuvie', 'Exuvie', 'Observation indirecte : une exuvie.', 'SINP', 'Validé', 0, '014.005', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true)
,(48, 14, '6', 'Fèces/Guano/Epreintes', 'Fèces/Guano/Epreintes', 'Observation indirecte par les excréments', 'SINP', 'Validé', 0, '014.006', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true)
,(49, 14, '7', 'Mues', 'Mues', 'Observation indirecte par des plumes, poils, phanères, peau, bois... issus d''une mue.', 'SINP', 'Validé', 0, '014.007', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true)
,(50, 14, '8', 'Nid/Gîte', 'Nid/Gîte', 'Observation indirecte par présence d''un nid ou d''un gîte non occupé au moment de l''observation.', 'SINP', 'Validé', 0, '014.008', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true)
,(51, 14, '9', 'Pelote de réjection', 'Pelote de réjection', 'Identifie l''espèce ayant produit la pelote de réjection.', 'SINP', 'Validé', 0, '014.009', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true)
,(68, 16, '0', '0', 'Maximale', 'Précision maximale telle que saisie (non sensible). Statut par défaut', 'SINP', 'Validé', 0, '016.000', '2015-06-10 00:00:00', '2015-06-10 00:00:00', true)
,(69, 16, '1', '1', 'Département, maille, espace, commune, ZNIEFF', 'Département, maille, espace, commune, ZNIEFF.', 'SINP', 'Validé', 0, '016.001', '2015-06-10 00:00:00', '2015-12-16 00:00:00', true)
,(70, 16, '2', '2', 'Département et maille 10 x 10 km', 'Département et maille 10 x 10 km.', 'SINP', 'Validé', 0, '016.002', '2015-06-10 00:00:00', '2015-12-16 00:00:00', true)
,(71, 16, '3', '3', 'Département seulement', 'Département seulement.', 'SINP', 'Validé', 0, '016.003', '2015-06-10 00:00:00', '2015-12-16 00:00:00', true)
,(72, 16, '4', '4', 'Aucune diffusion (cas exceptionnel)', 'Aucune diffusion (cas exceptionnel).', 'SINP', 'Validé', 0, '016.004', '2015-06-10 00:00:00', '2015-12-16 00:00:00', true)
,(73, 19, 'Co', 'Co', 'Collection', 'Collection : l''observation concerne une base de données de collection.', 'SINP', 'Validé', 0, '019.003', '2013-12-04 00:00:00', '2013-12-04 00:00:00', true)
,(2, 10, '0', 'Inconnu', 'Inconnu', 'Le stade de vie de l''individu n''est pas connu.', 'SINP', 'Validé', 0, '010.000', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true)
,(3, 10, '1', 'Indéterminé', 'Indéterminé', 'Le stade de vie de l''individu n''a pu être déterminé (observation insuffisante pour la détermination).', 'SINP', 'Validé', 0, '010.001', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true)
,(6, 10, '4', 'Immature', 'Immature', 'Individu n''ayant pas atteint sa maturité sexuelle.', 'SINP', 'Validé', 0, '010.004', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true)
,(7, 10, '5', 'Sub-adulte', 'Sub-adulte', 'Individu ayant presque atteint la taille adulte mais qui n''est pas considéré en tant que tel par ses congénères.', 'SINP', 'Validé', 0, '010.005', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true)
,(8, 10, '6', 'Larve', 'Larve', 'Individu dans l''état où il est en sortant de l''œuf, état dans lequel il passe un temps plus ou moins long avant métamorphose.', 'SINP', 'Validé', 0, '010.006', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true)
,(11, 10, '9', 'Œuf', 'Œuf', 'L''individu se trouve dans un œuf, ou au sein d''un regroupement d''œufs (ponte)', 'SINP', 'Validé', 0, '010.009', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true)
,(12, 10, '10', 'Mue', 'Mue', 'L''individu est en cours de mue (pour les reptiles : renouvellement de la peau, pour les oiseaux/mammifères : renouvellement du plumage/pelage, pour les cervidés : chute des bois).', 'SINP', 'Validé', 0, '010.010', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true)
,(13, 10, '11', 'Exuvie', 'Exuvie', 'L''individu est en cours d''exuviation : l''exuvie est une enveloppe (cuticule chitineuse ou peau) que le corps de l''animal a quittée lors de la mue ou de la métamorphose.', 'SINP', 'Validé', 0, '010.011', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true)
,(14, 10, '12', 'Chrysalide', 'Chrysalide', 'Nymphe des lépidoptères ou papillons.', 'SINP', 'Validé', 0, '010.012', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true)
,(15, 10, '13', 'Nymphe', 'Nymphe', 'Stade de développement intermédiaire, entre larve et imago, pendant lequel l''individu ne se nourrit pas.', 'SINP', 'Validé', 0, '010.013', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true)
,(53, 14, '11', 'Poils/plumes/phanères', 'Poils/plumes/phanères', 'Observation indirecte de l''espèce par ses poils, plumes ou phanères, non nécessairement issus d''une mue.', 'SINP', 'Validé', 0, '014.011', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true)
,(54, 14, '12', 'Restes de repas', 'Restes de repas', 'Observation indirecte par le biais de restes de l''alimentation de l''individu.', 'SINP', 'Validé', 0, '014.012', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true)
,(55, 14, '13', 'Spore', 'Spore', 'Identification d''un individu ou groupe d''individus d''un taxon par l''observation de spores, corpuscules unicellulaires ou pluricellulaires pouvant donner naissance sans fécondation à un nouvel individu. Chez les végétaux, corpuscules reproducteurs donnant des prothalles rudimentaires mâles et femelles (correspondant respectivement aux grains de pollen et au sac embryonnaire), dont les produits sont les gamètes.', 'SINP', 'Validé', 0, '014.013', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true)
,(80, 2, 'Pu', 'Publique', 'Publique', 'Publique : La Donnée Source est publique qu''elle soit produite en « régie » ou « acquise ».', 'SINP', 'Validé', 0, '002.001', '2013-12-05 00:00:00', '2013-12-05 00:00:00', true)
,(79, 2, 'Pr', 'Privée', 'Privée', 'Privée : La Donnée Source a été produite par un organisme privé ou un individu à titre personnel. Aucun organisme ayant autorité publique n''a acquis les droits patrimoniaux,  la Donnée Source reste la propriété de l''organisme ou de l''individu privé. Seul ce cas autorise un floutage géographique de la DEE.', 'SINP', 'Validé', 0, '002.002', '2013-12-05 00:00:00', '2013-12-05 00:00:00', true)
,(56, 14, '14', 'Pollen', 'Pollen', 'Observation indirecte d''un individu ou groupe d''individus d''un taxon par l''observation de pollen, poussière très fine produite dans les loges des anthères et dont chaque grain microscopique est un utricule ou petit sac membraneux contenant le fluide fécondant (d''apr. Bouillet 1859).', 'SINP', 'Validé', 0, '014.014', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true)
,(57, 14, '15', 'Oosphère', 'Oosphère', 'Observation indirecte. Cellule sexuelle femelle chez les végétaux qui, après sa fécondation, devient l''oeuf.', 'SINP', 'Validé', 0, '014.015', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true)
,(58, 14, '16', 'Ovule', 'Ovule', 'Observation indirecte. Organe contenant le gamète femelle. Macrosporange des spermaphytes.', 'SINP', 'Validé', 0, '014.016', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true)
,(59, 14, '17', 'Fleur', 'Fleur', 'Identification d''un individu ou groupe d''individus d''un taxon par l''observation  de fleurs. La fleur correspond à un ensemble de feuilles modifiées, en enveloppe florale et en organe sexuel, disposées sur un réceptacle. Un pédoncule la relie à la tige. (ex : chaton).', 'SINP', 'Validé', 0, '014.017', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true)
,(60, 14, '18', 'Feuille', 'Feuille', 'Identification d''un individu ou groupe d''individus d''un taxon par l''observation  de feuilles. Organe aérien très important dans la nutrition de la plante, lieu de la photosynthèse qui aboutit à des composés organiques (sucres, protéines) formant la sève.', 'SINP', 'Validé', 0, '014.018', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true)
,(61, 14, '19', 'ADN environnemental', 'ADN environnemental', 'Séquence ADN trouvée dans un prélèvement environnemental (eau ou sol).', 'SINP', 'Validé', 0, '014.019', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true)
,(17, 10, '15', 'Imago', 'Imago', 'Stade final d''un individu dont le développement se déroule en plusieurs phases (en général, œuf, larve, imago).', 'SINP', 'Validé', 0, '010.015', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true)
,(18, 10, '16', 'Sub-imago', 'Sub-imago', 'Stade de développement chez certains insectess : insecte mobile, incomplet et sexuellement immature, bien qu''évoquant assez fortement la forme définitive de l''adulte, l''imago.', 'SINP', 'Validé', 0, '010.016', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true)
,(19, 10, '17', 'Alevin', 'Alevin', 'L''individu, un poisson, est à un stade juvénile.', 'SINP', 'Validé', 0, '010.017', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true)
,(20, 10, '18', 'Germination', 'Germination', 'L''individu est en cours de germination.', 'SINP', 'Validé', 0, '010.018', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true)
,(21, 10, '19', 'Fané', 'Fané', 'L''individu est altéré dans ses couleurs et sa fraîcheur, par rapport à un individu normal.', 'SINP', 'Validé', 0, '010.019', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true)
,(22, 10, '20', 'Graine', 'Graine', 'La graine est la structure qui contient et protège l''embryon végétal.', 'SINP', 'Validé', 0, '010.020', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true)
,(23, 10, '21', 'Thalle, protothalle', 'Thalle, protothalle', 'Un thalle est un appareil végétatif ne possédant ni feuilles, ni tiges, ni racines, produit par certains organismes non mobiles.', 'SINP', 'Validé', 0, '010.021', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true)
,(24, 10, '22', 'Tubercule', 'Tubercule', 'Un tubercule est un organe de réserve, généralement souterrain, assurant la survie des plantes pendant la saison d''hiver ou en période de sécheresse, et souvent leur multiplication par voie végétative.', 'SINP', 'Validé', 0, '010.022', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true)
,(25, 10, '23', 'Bulbe', 'Bulbe', 'Un bulbe est une pousse souterraine verticale disposant de feuilles modifiées utilisées comme organe de stockage de nourriture par une plante à dormance.', 'SINP', 'Validé', 0, '010.023', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true)
,(26, 10, '24', 'Rhizome', 'Rhizome', 'Le rhizome est une tige souterraine et parfois subaquatique remplie de réserves alimentaires chez certaines plantes vivaces.', 'SINP', 'Validé', 0, '010.024', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true)
,(27, 10, '25', 'Emergent', 'Emergent', 'L''individu est au stade émergent : sortie de l''œuf.', 'SINP', 'Validé', 0, '010.025', '2015-07-29 00:00:00', '2015-10-09 00:00:00', true)
,(28, 10, '26', 'Post-Larve', 'Post-Larve', 'Stade qui suit immédiatement celui de la larve et présente certains caractères du juvénile.', 'SINP', 'Validé', 0, '010.026', '2016-03-24 00:00:00', '2016-03-24 00:00:00', true)
,(62, 14, '20', 'Autre', 'Autre', 'Pour tout cas qui ne rentrerait pas dans la présente liste. Le nombre d''apparitions permettra de faire évoluer la nomenclature.', 'SINP', 'Validé', 0, '014.020', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true)
,(63, 14, '21', 'Inconnu', 'Inconnu', 'Inconnu : La méthode n''est pas mentionnée dans les documents de l''observateur (bibliographie par exemple).', 'SINP', 'Validé', 0, '014.021', '2015-07-29 00:00:00', '2015-08-21 00:00:00', true)
,(64, 14, '22', 'Mine', 'Mine', 'Galerie forée dans l''épaisseur d''une feuille, entre l''épiderme supérieur et l''épiderme inférieur par des larves', 'SINP', 'Validé', 0, '014.022', '2015-12-07 00:00:00', '2015-12-16 00:00:00', true)
,(65, 14, '23', 'Galerie/terrier', 'Galerie/terrier', 'Galerie forée dans le bois, les racines ou les tiges, par des larves (Lépidoptères, Coléoptères, Diptères) ou creusée dans la terre (micro-mammifères, mammifères... ).', 'SINP', 'Validé', 0, '014.023', '2015-12-07 00:00:00', '2015-12-07 00:00:00', true)
,(92, 15, '1', 'Oui', 'Oui', 'Indique qu''une preuve existe ou a existé pour la détermination, et est toujours accessible.', 'SINP', 'Validé', 0, '015.001', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true)
,(93, 15, '2', 'Non', 'Non', 'Indique l''absence de preuve.', 'SINP', 'Validé', 0, '015.002', '2015-07-29 00:00:00', '2015-07-29 00:00:00', true)
,(94, 15, '3', 'NonAcquise', 'Non acquise', 'NonAcquise : La donnée de départ mentionne une preuve, ou non, mais n''est pas suffisamment standardisée pour qu''il soit possible de récupérer des informations. L''information n''est donc pas acquise lors du transfert.', 'SINP', 'Validé', 0, '015.003', '2015-07-29 00:00:00', '2015-12-12 00:00:00', true)
,(91, 15, '0', 'NSP', 'Inconnu', 'Indique que la personne ayant fourni la donnée ignore s''il existe une preuve, ou qu''il est indiqué dans la donnée qu''il y a eu une preuve qui a pu servir pour la détermination, sans moyen de le vérifier.', 'SINP', 'Validé', 0, '015.000', '2015-07-29 00:00:00', '2015-12-16 00:00:00', true)
,(96, 17, 'NON', 'Non', 'Non', '"Indique que la donnée n''est pas sensible (par défaut, équivalent au niveau ""0"" des niveaux de sensibilité)."', 'SINP', 'Validé', 0, '017.001', '2015-06-10 00:00:00', '2015-08-21 00:00:00', true)
,(97, 17, 'OUI', 'Oui', 'Oui', 'Indique que la donnée est sensible.', 'SINP', 'Validé', 0, '017.002', '2015-06-10 00:00:00', '2015-08-21 00:00:00', true)
,(99, 18, 'No', 'No', 'Non observé', 'Non Observé : L''observateur n''a pas détecté un taxon particulier, recherché suivant le protocole adéquat à la localisation et à la date de l''observation. Le taxon peut être présent et non vu, temporairement absent, ou réellement absent.', 'SINP', 'Validé', 0, '018.001', '2013-12-05 00:00:00', '2015-12-16 00:00:00', true)
,(100, 18, 'NSP', 'NSP', 'Ne Sait Pas', 'Ne Sait Pas : l''information n''est pas connue', 'SINP', 'Validé', 0, '018.000', '2016-03-24 00:00:00', '2016-03-24 00:00:00', true)
,(101, 18, 'Pr', 'Pr', 'Présent', 'Présent : Un ou plusieurs individus du taxon ont été effectivement observés et/ou des indices témoignant de la présence du taxon', 'SINP', 'Validé', 0, '018.002', '2013-12-05 00:00:00', '2015-12-16 00:00:00', true)
,(103, 20, 'QTA', 'QTA', 'Quantitatif', 'Le paramètre est de type quantitatif : il peut être mesuré par une valeur numérique. Exemples : âge précis, taille, nombre de cercles ligneux...', 'SINP', 'Validé', 0, '020.001', '2015-09-16 00:00:00', '2015-09-16 00:00:00', true)
,(104, 20, 'QUAL', 'QUAL', 'Qualitatif', 'Le paramètre est de type qualitatif : Il décrit une qualité qui ne peut être définie par une quantité numérique. Exemples : individu âgé / individu jeune, eau trouble, milieu clairsemé…', 'SINP', 'Validé', 0, '020.002', '2015-09-16 00:00:00', '2015-12-07 00:00:00', true)
,(106, 21, 'Ca', 'Ca', 'Calculé', 'Calculé : Dénombrement par opération mathématique', 'SINP', 'Validé', 0, '021.002', '2014-01-22 00:00:00', '2015-12-16 00:00:00', true)
,(107, 21, 'Co', 'Co', 'Compté', 'Compté : Dénombrement par énumération des individus', 'SINP', 'Validé', 0, '021.001', '2014-01-22 00:00:00', '2015-12-16 00:00:00', true)
,(108, 21, 'Es', 'Es', 'Estimé', 'Estimé : Dénombrement qualifié d''estimé lorsque le produit concerné n''a fait l''objet d''aucune action de détermination de cette valeur du paramètre par le biais d''une technique de mesure.', 'SINP', 'Validé', 0, '021.003', '2014-01-22 00:00:00', '2015-12-16 00:00:00', true)
,(109, 21, 'NSP', 'NSP', 'Ne sait pas', 'Ne sait Pas : La méthode de dénombrement n''est pas connue', 'SINP', 'Validé', 0, '021.000', '2014-01-22 00:00:00', '2015-12-16 00:00:00', true)
,(111, 22, 'AAPN', 'AAPN', 'AAPN', 'Aire d''adhésion de parc national', 'SINP', 'Validé', 0, '022.001', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true)
,(112, 22, 'ANTAR', 'ANTAR', 'ANTAR', 'Zone protégée du Traité de l''Antarctique', 'SINP', 'Validé', 0, '022.002', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true)
,(113, 22, 'APB', 'APB', 'APB', 'Arrêté de protection de biotope', 'SINP', 'Validé', 0, '022.003', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true)
,(114, 22, 'APIA', 'APIA', 'APIA', 'Zone protégée de la convention d''Apia', 'SINP', 'Validé', 0, '022.004', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true)
,(115, 22, 'ASPIM', 'ASPIM', 'ASPIM', 'Aire spécialement protégée d''importance méditerranéenne', 'SINP', 'Validé', 0, '022.005', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true)
,(116, 22, 'BPM', 'BPM', 'BPM', 'Bien inscrit sur la liste du patrimoine mondial de l''UNESCO', 'SINP', 'Validé', 0, '022.006', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true)
,(117, 22, 'CARTH', 'CARTH', 'CARTH', 'Zone protégée de la convention de Carthagène', 'SINP', 'Validé', 0, '022.007', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true)
,(118, 22, 'CNP', 'CNP', 'CNP', '"Coeur de parc national. Valeur gelée le 15/06/2016 et remplacée par ""CPN"""', 'SINP', 'Gelé', 0, '022.008', '2014-01-22 00:00:00', '2016-06-15 00:00:00', true)
,(119, 22, 'ENS', 'ENS', 'ENS', 'Espace naturel sensible', 'SINP', 'Validé', 0, '022.009', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true)
,(120, 22, 'MAB', 'MAB', 'MAB', 'Réserve de biosphère (Man and Biosphère)', 'SINP', 'Validé', 0, '022.010', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true)
,(121, 22, 'N2000', 'N2000', 'N2000', 'Natura 2000', 'SINP', 'Validé', 0, '022.011', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true)
,(122, 22, 'NAIRO', 'NAIRO', 'NAIRO', 'Zone spécialement protégée de la convention de Nairobi', 'SINP', 'Validé', 0, '022.012', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true)
,(123, 22, 'OSPAR', 'OSPAR', 'OSPAR', 'Zone marine protégée de la convention OSPAR', 'SINP', 'Validé', 0, '022.013', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true)
,(124, 22, 'PNM', 'PNM', 'PNM', 'Parc naturel marin', 'SINP', 'Validé', 0, '022.014', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true)
,(125, 22, 'PNR', 'PNR', 'PNR', 'Parc naturel régional', 'SINP', 'Validé', 0, '022.015', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true)
,(126, 22, 'PRN', 'PRN', 'PRN', 'Périmètre de protection de réserve naturelle', 'SINP', 'Validé', 0, '022.016', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true)
,(127, 22, 'RAMSAR', 'RAMSAR', 'RAMSAR', 'Site Ramsar : Zone humide d''importance internationale', 'SINP', 'Validé', 0, '022.017', '2014-01-22 00:00:00', '2015-12-16 00:00:00', true)
,(128, 22, 'RBD', 'RBD', 'RBD', 'Réserve biologique', 'SINP', 'Validé', 0, '022.018', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true)
,(129, 22, 'RBI', 'RBI', 'RBI', 'Réserve biologique intégrale', 'SINP', 'Validé', 0, '022.019', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true)
,(130, 22, 'RCFS', 'RCFS', 'RCFS', 'Réserve de chasse et de faune sauvage', 'SINP', 'Validé', 0, '022.020', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true)
,(131, 22, 'RIPN', 'RIPN', 'RIPN', 'Réserve intégrale de parc national', 'SINP', 'Validé', 0, '022.021', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true)
,(132, 22, 'RNC', 'RNC', 'RNC', 'Réserve naturelle de Corse', 'SINP', 'Validé', 0, '022.022', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true)
,(133, 22, 'RNCFS', 'RNCFS', 'RNCFS', 'Réserve nationale de chasse et faune sauvage', 'SINP', 'Validé', 0, '022.023', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true)
,(134, 22, 'RNN', 'RNN', 'RNN', 'Réserve naturelle nationale', 'SINP', 'Validé', 0, '022.024', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true)
,(135, 22, 'RNR', 'RNR', 'RNR', 'Réserve naturelle régionale', 'SINP', 'Validé', 0, '022.025', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true)
,(136, 22, 'SCEN', 'SCEN', 'SCEN', 'Site de Conservatoire d''espaces naturels', 'SINP', 'Validé', 0, '022.026', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true)
,(137, 22, 'SCL', 'SCL', 'SCL', 'Site du Conservatoire du littoral', 'SINP', 'Validé', 0, '022.027', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true)
,(138, 22, 'ZHAE', 'ZHAE', 'ZHAE', 'Zone humide acquise par une Agence de l''eau', 'SINP', 'Validé', 0, '022.028', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true)
,(139, 22, 'ZNIEFF', 'ZNIEFF', 'ZNIEFF', 'Zone Naturelle d''Intérêt Ecologique Faunistique et Floristique (type non précisé)', 'SINP', 'Validé', 0, '022.029', '2015-09-15 00:00:00', '2015-12-16 00:00:00', true)
,(143, 23, '1', '1', 'Géoréférencement', 'Géoréférencement de l''objet géographique. L''objet géographique est celui sur lequel on a effectué l''observation.', 'SINP', 'Validé', 0, '023.001', '2015-09-18 00:00:00', '2015-09-18 00:00:00', true)
,(343, 100, '133', 'Non renseigné', 'Non renseigné', 'La  technique d''observation n''est pas renseignée', 'GEONATURE', 'non validé', 0, '100.133', '2017-06-19 15:13:18.161067', NULL, true)
,(144, 23, '2', '2', 'Rattachement', 'Rattachement à l''objet géographique : l''objet géographique n''est pas la géoréférence d''origine, ou a été déduit d''informations autres.', 'SINP', 'Validé', 0, '023.002', '2015-09-18 00:00:00', '2015-12-16 00:00:00', true)
,(146, 24, 'AUTR', 'AUTR', 'AUTR', 'La valeur n''est pas contenue dans la présente liste. Elle doit être complétée par d''autres informations.', 'SINP', 'Validé', 0, '024.001', '2015-06-09 00:00:00', '2015-12-07 00:00:00', true)
,(148, 24, 'INVSTA', 'INVSTA', 'INVSTA', 'Inventaire stationnel', 'SINP', 'Validé', 0, '024.003', '2015-06-09 00:00:00', '2015-06-09 00:00:00', true)
,(149, 24, 'LIEN', 'LIEN', 'LIEN', 'Lien : Indique un lien fort entre 2 observations. (Une occurrence portée par l''autre, une symbiose, un parasitisme…)', 'SINP', 'Validé', 0, '024.004', '2015-06-09 00:00:00', '2015-12-16 00:00:00', true)
,(150, 24, 'NSP', 'NSP', 'NSP', 'Ne sait pas : l''information n''est pas connue.', 'SINP', 'Validé', 0, '024.000', '2015-06-09 00:00:00', '2015-06-09 00:00:00', true)
,(151, 24, 'OBS', 'OBS', 'OBS', 'Observations', 'SINP', 'Validé', 0, '024.005', '2015-06-09 00:00:00', '2015-06-09 00:00:00', true)
,(152, 24, 'OP', 'OP', 'OP', 'Opération de prélèvement', 'SINP', 'Validé', 0, '024.006', '2015-06-09 00:00:00', '2015-06-09 00:00:00', true)
,(153, 24, 'PASS', 'PASS', 'PASS', 'Passage', 'SINP', 'Validé', 0, '024.007', '2015-06-09 00:00:00', '2015-06-09 00:00:00', true)
,(154, 24, 'POINT', 'POINT', 'POINT', 'Point de prélèvement ou point d''observation.', 'SINP', 'Validé', 0, '024.008', '2015-06-09 00:00:00', '2015-06-09 00:00:00', true)
,(155, 24, 'REL', 'REL', 'REL', 'Relevé (qu''il soit phytosociologique, d''observation, ou autre...)', 'SINP', 'Validé', 0, '024.009', '2015-06-09 00:00:00', '2015-06-09 00:00:00', true)
,(156, 24, 'STRAT', 'STRAT', 'STRAT', 'Strate', 'SINP', 'Validé', 0, '024.010', '2015-06-09 00:00:00', '2015-06-09 00:00:00', true)
,(158, 5, '0', 'Standard', 'Standard', 'Diffusion standard : à la maille, à la ZNIEFF, à la commune, à l''espace protégé (statut par défaut).', 'SINP', 'Validé', 0, '005.000', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true)
,(159, 5, '1', 'Commune', 'Commune', 'Diffusion floutée de la DEE par rattachement à la commune.', 'SINP', 'Validé', 0, '005.001', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true)
,(160, 5, '2', 'Maille', 'Maille', 'Diffusion floutée par rattachement à la maille 10 x 10 km', 'SINP', 'Validé', 0, '005.002', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true)
,(161, 5, '3', 'Département', 'Département', 'Diffusion floutée par rattachement au département.', 'SINP', 'Validé', 0, '005.003', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true)
,(162, 5, '4', 'Aucune', 'Aucune', 'Aucune diffusion (cas exceptionnel), correspond à une donnée de sensibilité 4.', 'SINP', 'Validé', 0, '005.004', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true)
,(163, 5, '5', 'Précise', 'Précise', 'Diffusion telle quelle : si une donnée précise existe, elle doit être diffusée telle quelle.', 'SINP', 'Validé', 0, '005.005', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true)
,(165, 6, 'NSP', 'Ne Sait Pas', 'Ne Sait Pas', 'La méthode de dénombrement n''est pas connue.', 'SINP', 'Validé', 0, '006.000', '2014-01-22 00:00:00', '2015-10-15 00:00:00', true)
,(166, 6, 'IND', 'Individu', 'Individu', 'Nombre d''individus observés.', 'SINP', 'Validé', 0, '006.001', '2014-01-22 00:00:00', '2015-10-15 00:00:00', true)
,(167, 6, 'CPL', 'Couple', 'Couple', 'Nombre de couples observé.', 'SINP', 'Validé', 0, '006.002', '2015-07-21 00:00:00', '2015-10-15 00:00:00', true)
,(168, 6, 'COL', 'Colonie', 'Colonie', 'Nombre de colonies observées.', 'SINP', 'Validé', 0, '006.003', '2015-07-21 00:00:00', '2015-10-15 00:00:00', true)
,(169, 6, 'NID', 'Nid', 'Nid', 'Nombre de nids observés.', 'SINP', 'Validé', 0, '006.004', '2015-07-21 00:00:00', '2015-10-15 00:00:00', true)
,(170, 6, 'PON', 'Ponte', 'Ponte', 'Nombre de pontes observées.', 'SINP', 'Validé', 0, '006.005', '2015-07-21 00:00:00', '2015-10-15 00:00:00', true)
,(171, 6, 'HAM', 'Hampe florale', 'Hampe florale', 'Nombre de hampes florales observées.', 'SINP', 'Validé', 0, '006.006', '2015-07-21 00:00:00', '2015-10-15 00:00:00', true)
,(172, 6, 'TIGE', 'Tige', 'Tige', 'Nombre de tiges observées.', 'SINP', 'Validé', 0, '006.007', '2015-07-21 00:00:00', '2015-10-20 00:00:00', true)
,(173, 6, 'TOUF', 'Touffe', 'Touffe', 'Nombre de touffes observées.', 'SINP', 'Validé', 0, '006.008', '2015-07-21 00:00:00', '2015-10-15 00:00:00', true)
,(174, 6, 'SURF', 'Surface', 'Surface', 'Zone aréale occupée par le taxon, en mètres carrés.', 'SINP', 'Validé', 0, '006.009', '2015-07-21 00:00:00', '2015-10-15 00:00:00', true)
,(176, 7, '0', 'NSP', 'NSP', 'Inconnu (peut être utilisé pour les virus ou les végétaux fanés par exemple).', 'SINP', 'Validé', 0, '007.000', '2015-07-29 00:00:00', '2015-10-19 00:00:00', true)
,(177, 7, '1', 'Non renseigné', 'Non renseigné', 'L''information n''a pas été renseignée.', 'SINP', 'Validé', 0, '007.001', '2015-07-29 00:00:00', '2015-10-19 00:00:00', true)
,(178, 7, '2', 'Observé vivant', 'Observé vivant', 'L''individu a été observé vivant.', 'SINP', 'Validé', 0, '007.002', '2015-07-29 00:00:00', '2015-10-19 00:00:00', true)
,(179, 7, '3', 'Trouvé mort', 'Trouvé mort', 'L''individu a été trouvé mort : Cadavre entier ou crâne par exemple. La mort est antérieure au processus d''observation.', 'SINP', 'Validé', 0, '007.003', '2015-07-29 00:00:00', '2015-10-19 00:00:00', true)
,(181, 8, '0', 'Inconnu', 'Inconnu', 'Inconnu : la naturalité du sujet est inconnue', 'SINP', 'Validé', 0, '008.000', '2015-07-29 00:00:00', '2015-10-19 00:00:00', true)
,(182, 8, '1', 'Sauvage', 'Sauvage', 'Sauvage : Qualifie un animal ou végétal à l''état sauvage, individu autochtone, se retrouvant dans son aire de répartition naturelle et dont les individus sont le résultat d''une reproduction naturelle, sans intervention humaine.', 'SINP', 'Validé', 0, '008.001', '2015-07-29 00:00:00', '2015-10-19 00:00:00', true)
,(183, 8, '2', 'Cultivé/élevé', 'Cultivé/élevé', 'Cultivé/élevé : Qualifie un individu d''une population allochtone introduite volontairement dans des espaces non naturels dédiés à la culture, ou à l''élevage.', 'SINP', 'Validé', 0, '008.002', '2015-07-29 00:00:00', '2015-10-19 00:00:00', true)
,(184, 8, '3', 'Planté', 'Planté', 'Planté : Qualifie un végétal d''une population allochtone introduite ponctuellement et  volontairement dans un espace naturel/semi naturel.', 'SINP', 'Validé', 0, '008.003', '2015-07-29 00:00:00', '2015-10-19 00:00:00', true)
,(185, 8, '4', 'Féral', 'Féral', 'Féral : Qualifie un animal élevé retourné à l''état sauvage, individu d''une population allochtone.', 'SINP', 'Validé', 0, '008.004', '2015-07-29 00:00:00', '2015-10-19 00:00:00', true)
,(186, 8, '5', 'Subspontané', 'Subspontané', '"Subspontané : Qualifie un végétal d''une population allochtone, introduite volontairement, qui persiste plus ou moins longtemps dans sa station d''origine et qui a une dynamique propre peu étendue et limitée aux alentours de son implantation initiale. ""Echappée des jardins""."', 'SINP', 'Validé', 0, '008.005', '2015-07-29 00:00:00', '2015-10-19 00:00:00', true)
,(188, 9, '0', 'Inconnu', 'Inconnu', 'Inconnu : Il n''y a pas d''information disponible pour cet individu.', 'SINP', 'Validé', 0, '009.000', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true)
,(189, 9, '1', 'Indéterminé', 'Indéterminé', 'Indéterminé : Le sexe de l''individu n''a pu être déterminé', 'SINP', 'Validé', 0, '009.001', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true)
,(190, 9, '2', 'Femelle', 'Femelle', 'Féminin : L''individu est de sexe féminin.', 'SINP', 'Validé', 0, '009.002', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true)
,(191, 9, '3', 'Mâle', 'Mâle', 'Masculin : L''individu est de sexe masculin.', 'SINP', 'Validé', 0, '009.003', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true)
,(192, 9, '4', 'Hermaphrodite', 'Hermaphrodite', 'Hermaphrodite : L''individu est hermaphrodite.', 'SINP', 'Validé', 0, '009.004', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true)
,(193, 9, '5', 'Mixte', 'Mixte', 'Mixte : Sert lorsque l''on décrit plusieurs individus.', 'SINP', 'Validé', 0, '009.005', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true)
,(194, 9, '6', 'Non renseigné', 'Non renseigné', 'Non renseigné : l''information n''a pas été renseignée dans le document à l''origine de la donnée.', 'SINP', 'Validé', 0, '009.006', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true)
,(196, 3, 'In', 'Inventoriel', 'Inventoriel', 'Inventoriel : Le taxon observé est présent quelque part dans l''objet géographique', 'SINP', 'Validé', 0, '003.001', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true)
,(197, 3, 'NSP', 'Ne sait pas', 'Ne sait pas', 'Ne Sait Pas : L''information est inconnue', 'SINP', 'Validé', 0, '003.000', '2014-01-22 00:00:00', '2015-10-15 00:00:00', true)
,(198, 3, 'St', 'Stationnel', 'Stationnel', 'Stationnel : Le taxon observé est présent sur l''ensemble de l''objet géographique', 'SINP', 'Validé', 0, '003.002', '2014-01-22 00:00:00', '2014-01-22 00:00:00', true)
,(200, 4, 'NON', 'Non', 'Non', 'Non : indique qu''aucun floutage n''a eu lieu.', 'SINP', 'Validé', 0, '004.001', '2015-09-18 00:00:00', '2015-10-15 00:00:00', true)
,(201, 4, 'OUI', 'Oui', 'Oui', 'Oui : indique qu''un floutage a eu lieu.', 'SINP', 'Validé', 0, '004.002', '2015-09-18 00:00:00', '2015-10-15 00:00:00', true)
,(203, 11, '0', 'Inconnu/cryptogène', 'Inconnu/cryptogène', 'Individu dont le taxon a une aire d''origine inconnue qui fait qu''on ne peut donc pas dire s''il est indigène ou introduit.', 'SINP', 'Validé', 0, '011.000', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true)
,(204, 11, '1', 'Non renseigné', 'Non renseigné', 'Individu pour lequel l''information n''a pas été renseignée.', 'SINP', 'Validé', 0, '011.001', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true)
,(205, 11, '2', 'Présent (indigène ou indéterminé)', 'Présent (indigène ou indéterminé)', 'Individu d''un taxon présent au sens large dans la zone géographique considérée, c''est-à-dire taxon indigène ou taxon dont on ne sait pas s''il appartient à l''une des autres catégories. Le défaut de connaissance profite donc à l''indigénat.  Par indigène on entend : taxon qui est issu de la zone géographique considérée et qui s''y est naturellement développé sans contribution humaine, ou taxon qui est arrivé là sans intervention humaine (intentionnelle ou non) à partir d''une zone dans laquelle il est indigène6.  (NB : exclut les hybrides dont l''un des parents au moins est introduit dans la zone considérée)  Sont regroupés sous ce statut tous les taxons catégorisés « natif » ou « autochtone ».  Les taxons hivernant quelques mois de l''année entrent dans cette catégorie.', 'SINP', 'Validé', 0, '011.002', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true)
,(206, 11, '3', 'Introduit', 'Introduit', 'Taxon introduit (établi ou possiblement établi) au niveau local.  Par introduit on entend : taxon dont la présence locale est due à une intervention humaine, intentionnelle ou non, ou taxon qui est arrivé dans la zone sans intervention humaine mais à partir d''une zone dans laquelle il est introduit.  Par établi (terme pour la faune, naturalisé pour la flore) on entend : taxon introduit qui forme des populations viables (se reproduisant) et durables qui se maintiennent dans le milieu naturel sans besoin d''intervention humaine.  Sont regroupés sous ce statut tous les taxons catégorisés « non-indigène », « exotique », « exogène », « allogène », « allochtone », « non-natif », « naturalisé » dans une publication scientifique.', 'SINP', 'Validé', 0, '011.003', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true)
,(207, 11, '4', 'Introduit envahissant', 'Introduit envahissant', '"Individu d''un taxon introduit  localement, qui produit des descendants fertiles souvent en grand nombre, et qui a le potentiel pour s''étendre de façon exponentielle sur une grande aire, augmentant ainsi rapidement son aire de répartition. Cela induit souvent des conséquences écologiques, économiques ou sanitaires négatives. Sont regroupés sous ce statut tous les individus de taxons catégorisés ""introduits envahissants"", ""exotiques envahissants"", ou ""invasif""."', 'SINP', 'Validé', 0, '011.004', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true)
,(208, 11, '5', 'Introduit non établi (dont domestique)', 'Introduit non établi (dont domestique)', 'Individu dont le taxon est introduit, qui se reproduit occasionnellement hors de son aire de culture ou captivité, mais qui ne peut se maintenir à l''état sauvage.', 'SINP', 'Validé', 0, '011.005', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true)
,(209, 11, '6', 'Occasionnel', 'Occasionnel', 'Individu dont le taxon est occasionnel, non nicheur, accidentel ou exceptionnel dans la zone géographique considérée (par exemple migrateur de passage), qui est locale.', 'SINP', 'Validé', 0, '011.006', '2015-07-29 00:00:00', '2015-10-15 00:00:00', true)
,(287, 100, '77', 'Pêche au filet troubleau (chasse au filet troubleau)', 'Pêche au filet troubleau (chasse au filet troubleau)', 'Pêche au filet troubleau (chasse au filet troubleau)', 'CAMPANULE', 'Validation en cours', 0, '100.077', '2017-06-19 15:12:46.794127', NULL, true)
,(288, 100, '78', 'Pêche électrique, électropêche', 'Pêche électrique, électropêche', 'Pêche électrique, électropêche', 'CAMPANULE', 'Validation en cours', 0, '100.078', '2017-06-19 15:12:46.794127', NULL, true)
,(289, 100, '79', 'Piégeage à appât type Plantrou (piège à Charaxes)', 'Piégeage à appât type Plantrou (piège à Charaxes)', 'Piégeage à appât type Plantrou (piège à Charaxes)', 'CAMPANULE', 'Validation en cours', 0, '100.079', '2017-06-19 15:12:46.794127', NULL, true)
,(290, 100, '80', 'Piégeage à cornet (capture par piège cornet unidirectionnel)', 'Piégeage à cornet (capture par piège cornet unidirectionnel)', 'Piégeage à cornet (capture par piège cornet unidirectionnel)', 'CAMPANULE', 'Validation en cours', 0, '100.080', '2017-06-19 15:12:46.794127', NULL, true)
,(291, 100, '81', 'Piégeage à fosse à coprophages', 'Piégeage à fosse à coprophages', 'Piégeage à fosse à coprophages', 'CAMPANULE', 'Validation en cours', 0, '100.081', '2017-06-19 15:12:46.794127', NULL, true)
,(292, 100, '82', 'Piégeage à fosse à nécrophages', 'Piégeage à fosse à nécrophages', 'Piégeage à fosse à nécrophages', 'CAMPANULE', 'Validation en cours', 0, '100.082', '2017-06-19 15:12:46.794127', NULL, true)
,(293, 100, '83', 'Piégeage à fosse appâté (capture par piège à fosse avec liquide conservateur, piège Barber, pot-piège)', 'Piégeage à fosse appâté (capture par piège à fosse avec liquide conservateur, piège Barber, pot-piège)', 'Piégeage à fosse appâté (capture par piège à fosse avec liquide conservateur, piège Barber, pot-piège)', 'CAMPANULE', 'Validation en cours', 0, '100.083', '2017-06-19 15:12:46.794127', NULL, true)
,(294, 100, '84', 'Piégeage à fosse non appâté (piège à fosse sans liquide conservateur)', 'Piégeage à fosse non appâté (piège à fosse sans liquide conservateur)', 'Piégeage à fosse non appâté (piège à fosse sans liquide conservateur)', 'CAMPANULE', 'Validation en cours', 0, '100.084', '2017-06-19 15:12:46.794127', NULL, true)
,(295, 100, '85', 'Piégeage adhésif (piège collant, piège gluant, bande collante)', 'Piégeage adhésif (piège collant, piège gluant, bande collante)', 'Piégeage adhésif (piège collant, piège gluant, bande collante)', 'CAMPANULE', 'Validation en cours', 0, '100.085', '2017-06-19 15:12:46.794127', NULL, true)
,(211, 100, '1', 'Analyse ADN environnemental (ADNe)', 'Analyse ADN environnemental (ADNe)', 'Analyse ADN environnemental (ADNe)', 'CAMPANULE', 'Validation en cours', 0, '100.001', '2017-06-19 15:11:40.590509', NULL, true)
,(212, 100, '2', 'Analyse de restes de prédateurs - pelotes de réjection, restes de repas de carnivores, analyses stomacales', 'Analyse de restes de prédateurs - pelotes de réjection, restes de repas de carnivores, analyses stomacales', 'Analyse de restes de prédateurs - pelotes de réjection, restes de repas de carnivores, analyses stomacales', 'CAMPANULE', 'Validation en cours', 0, '100.002', '2017-06-19 15:11:40.590509', NULL, true)
,(213, 100, '3', 'Aspirateur à air comprimé (marin)', 'Aspirateur à air comprimé (marin)', 'Aspirateur à air comprimé (marin)', 'CAMPANULE', 'Validation en cours', 0, '100.003', '2017-06-19 15:11:40.590509', NULL, true)
,(214, 100, '4', 'Aspiration moteur type D-VAC (aspirateur à moteur)', 'Aspiration moteur type D-VAC (aspirateur à moteur)', 'Aspiration moteur type D-VAC (aspirateur à moteur)', 'CAMPANULE', 'Validation en cours', 0, '100.004', '2017-06-19 15:11:40.590509', NULL, true)
,(215, 100, '5', 'Attraction pour observation (miellée, phéromones…)', 'Attraction pour observation (miellée, phéromones…)', 'Attraction pour observation (miellée, phéromones…)', 'CAMPANULE', 'Validation en cours', 0, '100.005', '2017-06-19 15:11:40.590509', NULL, true)
,(216, 100, '6', 'Battage (battage de la végétation, parapluie japonais)', 'Battage (battage de la végétation, parapluie japonais)', 'Battage (battage de la végétation, parapluie japonais)', 'CAMPANULE', 'Validation en cours', 0, '100.006', '2017-06-19 15:11:40.590509', NULL, true)
,(217, 100, '7', 'Battue avec rabatteurs', 'Battue avec rabatteurs', 'Battue avec rabatteurs', 'CAMPANULE', 'Validation en cours', 0, '100.007', '2017-06-19 15:11:40.590509', NULL, true)
,(218, 100, '8', 'Brossage (terrestre : écorces…)', 'Brossage (terrestre : écorces…)', 'Brossage (terrestre : écorces…)', 'CAMPANULE', 'Validation en cours', 0, '100.008', '2017-06-19 15:11:40.590509', NULL, true)
,(219, 100, '9', 'Capture au collet', 'Capture au collet', 'Capture au collet', 'CAMPANULE', 'Validation en cours', 0, '100.009', '2017-06-19 15:11:40.590509', NULL, true)
,(220, 100, '10', 'Capture au filet Cryldé', 'Capture au filet Cryldé', 'Capture au filet Cryldé', 'CAMPANULE', 'Validation en cours', 0, '100.010', '2017-06-19 15:12:46.794127', NULL, true)
,(221, 100, '11', 'Capture au filet japonais', 'Capture au filet japonais', 'Capture au filet japonais', 'CAMPANULE', 'Validation en cours', 0, '100.011', '2017-06-19 15:12:46.794127', NULL, true)
,(222, 100, '12', 'Capture au filet stationnaire', 'Capture au filet stationnaire', 'Capture au filet stationnaire', 'CAMPANULE', 'Validation en cours', 0, '100.012', '2017-06-19 15:12:46.794127', NULL, true)
,(223, 100, '13', 'Capture directe (capture à vue, capture relâche)', 'Capture directe (capture à vue, capture relâche)', 'Capture directe (capture à vue, capture relâche)', 'CAMPANULE', 'Validation en cours', 0, '100.013', '2017-06-19 15:12:46.794127', NULL, true)
,(224, 100, '14', 'Chalutage terrestre (capture au filet de toit - voiture)', 'Chalutage terrestre (capture au filet de toit - voiture)', 'Chalutage terrestre (capture au filet de toit - voiture)', 'CAMPANULE', 'Validation en cours', 0, '100.014', '2017-06-19 15:12:46.794127', NULL, true)
,(225, 100, '15', 'Création d''habitat refuge : autres techniques', 'Création d''habitat refuge : autres techniques', 'Création d''habitat refuge : autres techniques', 'CAMPANULE', 'Validation en cours', 0, '100.015', '2017-06-19 15:12:46.794127', NULL, true)
,(226, 100, '16', 'Création d''habitat refuge : couverture du sol (plaques, bâches)', 'Création d''habitat refuge : couverture du sol (plaques, bâches)', 'Création d''habitat refuge : couverture du sol (plaques, bâches)', 'CAMPANULE', 'Validation en cours', 0, '100.016', '2017-06-19 15:12:46.794127', NULL, true)
,(227, 100, '17', 'Création d''habitat refuge : dévitalisation de plantes, mutilation', 'Création d''habitat refuge : dévitalisation de plantes, mutilation', 'Création d''habitat refuge : dévitalisation de plantes, mutilation', 'CAMPANULE', 'Validation en cours', 0, '100.017', '2017-06-19 15:12:46.794127', NULL, true)
,(228, 100, '18', 'Création d''habitat refuge : hôtels à insectes, nichoirs', 'Création d''habitat refuge : hôtels à insectes, nichoirs', 'Création d''habitat refuge : hôtels à insectes, nichoirs', 'CAMPANULE', 'Validation en cours', 0, '100.018', '2017-06-19 15:12:46.794127', NULL, true)
,(229, 100, '19', 'Création d''habitat refuge : substrat artificiel aquatique', 'Création d''habitat refuge : substrat artificiel aquatique', 'Création d''habitat refuge : substrat artificiel aquatique', 'CAMPANULE', 'Validation en cours', 0, '100.019', '2017-06-19 15:12:46.794127', NULL, true)
,(230, 100, '20', 'Détection au chien d''arrêt', 'Détection au chien d''arrêt', 'Détection au chien d''arrêt', 'CAMPANULE', 'Validation en cours', 0, '100.020', '2017-06-19 15:12:46.794127', NULL, true)
,(231, 100, '21', 'Détection des ultrasons (écoute indirecte, analyse sonore, détection ultrasonore)', 'Détection des ultrasons (écoute indirecte, analyse sonore, détection ultrasonore)', 'Détection des ultrasons (écoute indirecte, analyse sonore, détection ultrasonore)', 'CAMPANULE', 'Validation en cours', 0, '100.021', '2017-06-19 15:12:46.794127', NULL, true)
,(232, 100, '22', 'Détection nocturne à la lampe frontale (chasse de nuit à la lampe frontale)', 'Détection nocturne à la lampe frontale (chasse de nuit à la lampe frontale)', 'Détection nocturne à la lampe frontale (chasse de nuit à la lampe frontale)', 'CAMPANULE', 'Validation en cours', 0, '100.022', '2017-06-19 15:12:46.794127', NULL, true)
,(233, 100, '23', 'Ecorcage', 'Ecorcage', 'Ecorcage', 'CAMPANULE', 'Validation en cours', 0, '100.023', '2017-06-19 15:12:46.794127', NULL, true)
,(234, 100, '24', 'Ecoute directe (reconnaissance sonore directe, détection auditive)', 'Ecoute directe (reconnaissance sonore directe, détection auditive)', 'Ecoute directe (reconnaissance sonore directe, détection auditive)', 'CAMPANULE', 'Validation en cours', 0, '100.024', '2017-06-19 15:12:46.794127', NULL, true)
,(235, 100, '25', 'Ecoute directe avec hydrophone', 'Ecoute directe avec hydrophone', 'Ecoute directe avec hydrophone', 'CAMPANULE', 'Validation en cours', 0, '100.025', '2017-06-19 15:12:46.794127', NULL, true)
,(236, 100, '26', 'Ecoute directe avec repasse', 'Ecoute directe avec repasse', 'Ecoute directe avec repasse', 'CAMPANULE', 'Validation en cours', 0, '100.026', '2017-06-19 15:12:46.794127', NULL, true)
,(237, 100, '27', 'Enregistrement sonore avec hydrophone', 'Enregistrement sonore avec hydrophone', 'Enregistrement sonore avec hydrophone', 'CAMPANULE', 'Validation en cours', 0, '100.027', '2017-06-19 15:12:46.794127', NULL, true)
,(238, 100, '28', 'Enregistrement sonore simple', 'Enregistrement sonore simple', 'Enregistrement sonore simple', 'CAMPANULE', 'Validation en cours', 0, '100.028', '2017-06-19 15:12:46.794127', NULL, true)
,(239, 100, '29', 'Etude de la banque de graines du sol', 'Etude de la banque de graines du sol', 'Etude de la banque de graines du sol', 'CAMPANULE', 'Validation en cours', 0, '100.029', '2017-06-19 15:12:46.794127', NULL, true)
,(240, 100, '30', 'Examen des hôtes - écrevisses et poissons (sangsues piscicolidae et branchiobdellidae)', 'Examen des hôtes - écrevisses et poissons (sangsues piscicolidae et branchiobdellidae)', 'Examen des hôtes - écrevisses et poissons (sangsues piscicolidae et branchiobdellidae)', 'CAMPANULE', 'Validation en cours', 0, '100.030', '2017-06-19 15:12:46.794127', NULL, true)
,(241, 100, '31', 'Extraction de substrat : délitage de susbtrats durs (marin)', 'Extraction de substrat : délitage de susbtrats durs (marin)', 'Extraction de substrat : délitage de susbtrats durs (marin)', 'CAMPANULE', 'Validation en cours', 0, '100.031', '2017-06-19 15:12:46.794127', NULL, true)
,(242, 100, '32', 'Extraction de substrat par benne (Van Veen, Smith McIntyre, Hamon…)', 'Extraction de substrat par benne (Van Veen, Smith McIntyre, Hamon…)', 'Extraction de substrat par benne (Van Veen, Smith McIntyre, Hamon…)', 'CAMPANULE', 'Validation en cours', 0, '100.032', '2017-06-19 15:12:46.794127', NULL, true)
,(243, 100, '33', 'Extraction de substrat par carottier à main (en plongée)', 'Extraction de substrat par carottier à main (en plongée)', 'Extraction de substrat par carottier à main (en plongée)', 'CAMPANULE', 'Validation en cours', 0, '100.033', '2017-06-19 15:12:46.794127', NULL, true)
,(272, 100, '62', 'Observation manuelle de substrat (litière, sol…)', 'Observation manuelle de substrat (litière, sol…)', 'Observation manuelle de substrat (litière, sol…)', 'CAMPANULE', 'Validation en cours', 0, '100.062', '2017-06-19 15:12:46.794127', NULL, true)
,(244, 100, '34', 'Extraction de substrat par carottier à main (sans plongée - continental ou supra/médiolittoral)', 'Extraction de substrat par carottier à main (sans plongée - continental ou supra/médiolittoral)', 'Extraction de substrat par carottier à main (sans plongée - continental ou supra/médiolittoral)', 'CAMPANULE', 'Validation en cours', 0, '100.034', '2017-06-19 15:12:46.794127', NULL, true)
,(245, 100, '35', 'Extraction de substrat par filet dragueur ou haveneau (drague Rallier du Baty, Charcot Picard…)', 'Extraction de substrat par filet dragueur ou haveneau (drague Rallier du Baty, Charcot Picard…)', 'Extraction de substrat par filet dragueur ou haveneau (drague Rallier du Baty, Charcot Picard…)', 'CAMPANULE', 'Validation en cours', 0, '100.035', '2017-06-19 15:12:46.794127', NULL, true)
,(246, 100, '36', 'Extraction de substrat terrestre : bloc de sol, récolte de litière…', 'Extraction de substrat terrestre : bloc de sol, récolte de litière…', 'Extraction de substrat terrestre : bloc de sol, récolte de litière…', 'CAMPANULE', 'Validation en cours', 0, '100.036', '2017-06-19 15:12:46.794127', NULL, true)
,(247, 100, '37', 'Fauchage marin au filet fauchoir (en plongée)', 'Fauchage marin au filet fauchoir (en plongée)', 'Fauchage marin au filet fauchoir (en plongée)', 'CAMPANULE', 'Validation en cours', 0, '100.037', '2017-06-19 15:12:46.794127', NULL, true)
,(248, 100, '38', 'Fauchage marin au filet fauchoir (sans plongée - supra/médiolittoral)', 'Fauchage marin au filet fauchoir (sans plongée - supra/médiolittoral)', 'Fauchage marin au filet fauchoir (sans plongée - supra/médiolittoral)', 'CAMPANULE', 'Validation en cours', 0, '100.038', '2017-06-19 15:12:46.794127', NULL, true)
,(249, 100, '39', 'Fauchage terrestre au filet fauchoir (fauchage de la végétation)', 'Fauchage terrestre au filet fauchoir (fauchage de la végétation)', 'Fauchage terrestre au filet fauchoir (fauchage de la végétation)', 'CAMPANULE', 'Validation en cours', 0, '100.039', '2017-06-19 15:12:46.794127', NULL, true)
,(250, 100, '40', 'Fumigation (fogging, thermonébulisation insecticide)', 'Fumigation (fogging, thermonébulisation insecticide)', 'Fumigation (fogging, thermonébulisation insecticide)', 'CAMPANULE', 'Validation en cours', 0, '100.040', '2017-06-19 15:12:46.794127', NULL, true)
,(251, 100, '41', 'Grattage, brossage du susbtrat (marin)', 'Grattage, brossage du susbtrat (marin)', 'Grattage, brossage du susbtrat (marin)', 'CAMPANULE', 'Validation en cours', 0, '100.041', '2017-06-19 15:12:46.794127', NULL, true)
,(252, 100, '42', 'Méthode de De Vries (méthode des prélèvements, méthode des poignées)', 'Méthode de De Vries (méthode des prélèvements, méthode des poignées)', 'Méthode de De Vries (méthode des prélèvements, méthode des poignées)', 'CAMPANULE', 'Validation en cours', 0, '100.042', '2017-06-19 15:12:46.794127', NULL, true)
,(253, 100, '43', 'Méthode de l''élastique (lézards arboricoles)', 'Méthode de l''élastique (lézards arboricoles)', 'Méthode de l''élastique (lézards arboricoles)', 'CAMPANULE', 'Validation en cours', 0, '100.043', '2017-06-19 15:12:46.794127', NULL, true)
,(254, 100, '44', 'Observation à la moutarde - vers de terre', 'Observation à la moutarde - vers de terre', 'Observation à la moutarde - vers de terre', 'CAMPANULE', 'Validation en cours', 0, '100.044', '2017-06-19 15:12:46.794127', NULL, true)
,(255, 100, '45', 'Observation aux jumelles (observation à la longue-vue)', 'Observation aux jumelles (observation à la longue-vue)', 'Observation aux jumelles (observation à la longue-vue)', 'CAMPANULE', 'Validation en cours', 0, '100.045', '2017-06-19 15:12:46.794127', NULL, true)
,(256, 100, '46', 'Observation aux lunettes polarisantes', 'Observation aux lunettes polarisantes', 'Observation aux lunettes polarisantes', 'CAMPANULE', 'Validation en cours', 0, '100.046', '2017-06-19 15:12:46.794127', NULL, true)
,(257, 100, '47', 'Observation de détritus d''inondation, débris et laisses de crues', 'Observation de détritus d''inondation, débris et laisses de crues', 'Observation de détritus d''inondation, débris et laisses de crues', 'CAMPANULE', 'Validation en cours', 0, '100.047', '2017-06-19 15:12:46.794127', NULL, true)
,(258, 100, '48', 'Observation de larves (recherche de larves)', 'Observation de larves (recherche de larves)', 'Observation de larves (recherche de larves)', 'CAMPANULE', 'Validation en cours', 0, '100.048', '2017-06-19 15:12:46.794127', NULL, true)
,(259, 100, '49', 'Observation de macro-restes (cadavres, élytres…)', 'Observation de macro-restes (cadavres, élytres…)', 'Observation de macro-restes (cadavres, élytres…)', 'CAMPANULE', 'Validation en cours', 0, '100.049', '2017-06-19 15:12:46.794127', NULL, true)
,(260, 100, '50', 'Observation de micro-habitats (recherche de gîtes, chandelles, polypores, dendrotelmes…) ', 'Observation de micro-habitats (recherche de gîtes, chandelles, polypores, dendrotelmes…) ', 'Observation de micro-habitats (recherche de gîtes, chandelles, polypores, dendrotelmes…) ', 'CAMPANULE', 'Validation en cours', 0, '100.050', '2017-06-19 15:12:46.794127', NULL, true)
,(261, 100, '51', 'Observation de pontes (observation des œufs, recherche des pontes)', 'Observation de pontes (observation des œufs, recherche des pontes)', 'Observation de pontes (observation des œufs, recherche des pontes)', 'CAMPANULE', 'Validation en cours', 0, '100.051', '2017-06-19 15:12:46.794127', NULL, true)
,(262, 100, '52', 'Observation de substrat et tamisage', 'Observation de substrat et tamisage', 'Observation de substrat et tamisage', 'CAMPANULE', 'Validation en cours', 0, '100.052', '2017-06-19 15:12:46.794127', NULL, true)
,(263, 100, '53', 'Observation de substrat par extraction : appareil de Berlèse-Tullgren, Winckler-Moczarski…', 'Observation de substrat par extraction : appareil de Berlèse-Tullgren, Winckler-Moczarski…', 'Observation de substrat par extraction : appareil de Berlèse-Tullgren, Winckler-Moczarski…', 'CAMPANULE', 'Validation en cours', 0, '100.053', '2017-06-19 15:12:46.794127', NULL, true)
,(264, 100, '54', 'Observation de substrat par extraction : par flottaison (par densité)', 'Observation de substrat par extraction : par flottaison (par densité)', 'Observation de substrat par extraction : par flottaison (par densité)', 'CAMPANULE', 'Validation en cours', 0, '100.054', '2017-06-19 15:12:46.794127', NULL, true)
,(265, 100, '55', 'Observation de trous de sortie, trous d''émergence', 'Observation de trous de sortie, trous d''émergence', 'Observation de trous de sortie, trous d''émergence', 'CAMPANULE', 'Validation en cours', 0, '100.055', '2017-06-19 15:12:46.794127', NULL, true)
,(266, 100, '56', 'Observation d''exuvies', 'Observation d''exuvies', 'Observation d''exuvies', 'CAMPANULE', 'Validation en cours', 0, '100.056', '2017-06-19 15:12:46.794127', NULL, true)
,(267, 100, '57', 'Observation d''indices de présence', 'Observation d''indices de présence', 'Observation d''indices de présence', 'CAMPANULE', 'Validation en cours', 0, '100.057', '2017-06-19 15:12:46.794127', NULL, true)
,(268, 100, '58', 'Observation directe marine (observation en plongée)', 'Observation directe marine (observation en plongée)', 'Observation directe marine (observation en plongée)', 'CAMPANULE', 'Validation en cours', 0, '100.058', '2017-06-19 15:12:46.794127', NULL, true)
,(269, 100, '59', 'Observation directe terrestre diurne (chasse à vue de jour)', 'Observation directe terrestre diurne (chasse à vue de jour)', 'Observation directe terrestre diurne (chasse à vue de jour)', 'CAMPANULE', 'Validation en cours', 0, '100.059', '2017-06-19 15:12:46.794127', NULL, true)
,(270, 100, '60', 'Observation directe terrestre nocturne (chasse à vue de nuit)', 'Observation directe terrestre nocturne (chasse à vue de nuit)', 'Observation directe terrestre nocturne (chasse à vue de nuit)', 'CAMPANULE', 'Validation en cours', 0, '100.060', '2017-06-19 15:12:46.794127', NULL, true)
,(271, 100, '61', 'Observation directe terrestre nocturne au phare', 'Observation directe terrestre nocturne au phare', 'Observation directe terrestre nocturne au phare', 'CAMPANULE', 'Validation en cours', 0, '100.061', '2017-06-19 15:12:46.794127', NULL, true)
,(273, 100, '63', 'Observation marine par caméra suspendue', 'Observation marine par caméra suspendue', 'Observation marine par caméra suspendue', 'CAMPANULE', 'Validation en cours', 0, '100.063', '2017-06-19 15:12:46.794127', NULL, true)
,(274, 100, '64', 'Observation marine par traineau vidéo', 'Observation marine par traineau vidéo', 'Observation marine par traineau vidéo', 'CAMPANULE', 'Validation en cours', 0, '100.064', '2017-06-19 15:12:46.794127', NULL, true)
,(345, 101, '0', 'Inconnu', 'Inconnu', 'Le statut de validation n''est pas connu', 'GEONATURE', 'non validé', 0, '101.000', '2017-08-08 10:05:18.161067', NULL, true)
,(275, 100, '65', 'Observation marine par véhicule téléguidé (ROV)', 'Observation marine par véhicule téléguidé (ROV)', 'Observation marine par véhicule téléguidé (ROV)', 'CAMPANULE', 'Validation en cours', 0, '100.065', '2017-06-19 15:12:46.794127', NULL, true)
,(276, 100, '66', 'Observation marine photographique (observation photographique en plongée)', 'Observation marine photographique (observation photographique en plongée)', 'Observation marine photographique (observation photographique en plongée)', 'CAMPANULE', 'Validation en cours', 0, '100.066', '2017-06-19 15:12:46.794127', NULL, true)
,(277, 100, '67', 'Observation par piège photographique', 'Observation par piège photographique', 'Observation par piège photographique', 'CAMPANULE', 'Validation en cours', 0, '100.067', '2017-06-19 15:12:46.794127', NULL, true)
,(278, 100, '68', 'Observation photographique aérienne, prise de vue aérienne', 'Observation photographique aérienne, prise de vue aérienne', 'Observation photographique aérienne, prise de vue aérienne', 'CAMPANULE', 'Validation en cours', 0, '100.068', '2017-06-19 15:12:46.794127', NULL, true)
,(279, 100, '69', 'Observation photographique terrestre (affût photographique)', 'Observation photographique terrestre (affût photographique)', 'Observation photographique terrestre (affût photographique)', 'CAMPANULE', 'Validation en cours', 0, '100.069', '2017-06-19 15:12:46.794127', NULL, true)
,(280, 100, '70', 'Paniers à vers de terre', 'Paniers à vers de terre', 'Paniers à vers de terre', 'CAMPANULE', 'Validation en cours', 0, '100.070', '2017-06-19 15:12:46.794127', NULL, true)
,(281, 100, '71', 'Pêche à la palangre', 'Pêche à la palangre', 'Pêche à la palangre', 'CAMPANULE', 'Validation en cours', 0, '100.071', '2017-06-19 15:12:46.794127', NULL, true)
,(282, 100, '72', 'Pêche à l''épuisette (capture par épuisette, chasse à l''épuisette)', 'Pêche à l''épuisette (capture par épuisette, chasse à l''épuisette)', 'Pêche à l''épuisette (capture par épuisette, chasse à l''épuisette)', 'CAMPANULE', 'Validation en cours', 0, '100.072', '2017-06-19 15:12:46.794127', NULL, true)
,(283, 100, '73', 'Pêche au chalut, chalutage (chalut à perche...)', 'Pêche au chalut, chalutage (chalut à perche...)', 'Pêche au chalut, chalutage (chalut à perche...)', 'CAMPANULE', 'Validation en cours', 0, '100.073', '2017-06-19 15:12:46.794127', NULL, true)
,(284, 100, '74', 'Pêche au filet - à détailler', 'Pêche au filet - à détailler', 'Pêche au filet - à détailler', 'CAMPANULE', 'Validation en cours', 0, '100.074', '2017-06-19 15:12:46.794127', NULL, true)
,(285, 100, '75', 'Pêche au filet lesté (pêche à la senne)', 'Pêche au filet lesté (pêche à la senne)', 'Pêche au filet lesté (pêche à la senne)', 'CAMPANULE', 'Validation en cours', 0, '100.075', '2017-06-19 15:12:46.794127', NULL, true)
,(286, 100, '76', 'Pêche au filet Surber', 'Pêche au filet Surber', 'Pêche au filet Surber', 'CAMPANULE', 'Validation en cours', 0, '100.076', '2017-06-19 15:12:46.794127', NULL, true)
,(296, 100, '86', 'Piégeage aérien à succion (aspirateur échantillonneur, piège à moustiques)', 'Piégeage aérien à succion (aspirateur échantillonneur, piège à moustiques)', 'Piégeage aérien à succion (aspirateur échantillonneur, piège à moustiques)', 'CAMPANULE', 'Validation en cours', 0, '100.086', '2017-06-19 15:12:46.794127', NULL, true)
,(297, 100, '87', 'Piégeage aérien rotatif', 'Piégeage aérien rotatif', 'Piégeage aérien rotatif', 'CAMPANULE', 'Validation en cours', 0, '100.087', '2017-06-19 15:12:46.794127', NULL, true)
,(298, 100, '88', 'Piégeage au sol - à détailler', 'Piégeage au sol - à détailler', 'Piégeage au sol - à détailler', 'CAMPANULE', 'Validation en cours', 0, '100.088', '2017-06-19 15:12:46.794127', NULL, true)
,(299, 100, '89', 'Piégeage bouteille (piège à vin, piège à appât fermenté, piège à cétoines)', 'Piégeage bouteille (piège à vin, piège à appât fermenté, piège à cétoines)', 'Piégeage bouteille (piège à vin, piège à appât fermenté, piège à cétoines)', 'CAMPANULE', 'Validation en cours', 0, '100.089', '2017-06-19 15:12:46.794127', NULL, true)
,(300, 100, '90', 'Piégeage entomologique composite (PEC)', 'Piégeage entomologique composite (PEC)', 'Piégeage entomologique composite (PEC)', 'CAMPANULE', 'Validation en cours', 0, '100.090', '2017-06-19 15:12:46.794127', NULL, true)
,(301, 100, '91', 'Piégeage lumineux aquatique à fluorescence', 'Piégeage lumineux aquatique à fluorescence', 'Piégeage lumineux aquatique à fluorescence', 'CAMPANULE', 'Validation en cours', 0, '100.091', '2017-06-19 15:12:46.794127', NULL, true)
,(302, 100, '92', 'Piégeage lumineux aquatique à incandescence', 'Piégeage lumineux aquatique à incandescence', 'Piégeage lumineux aquatique à incandescence', 'CAMPANULE', 'Validation en cours', 0, '100.092', '2017-06-19 15:12:46.794127', NULL, true)
,(303, 100, '93', 'Piégeage lumineux aquatique à LED', 'Piégeage lumineux aquatique à LED', 'Piégeage lumineux aquatique à LED', 'CAMPANULE', 'Validation en cours', 0, '100.093', '2017-06-19 15:12:46.794127', NULL, true)
,(304, 100, '94', 'Piégeage lumineux automatique à fluorescence', 'Piégeage lumineux automatique à fluorescence', 'Piégeage lumineux automatique à fluorescence', 'CAMPANULE', 'Validation en cours', 0, '100.094', '2017-06-19 15:12:46.794127', NULL, true)
,(305, 100, '95', 'Piégeage lumineux automatique à incandescence', 'Piégeage lumineux automatique à incandescence', 'Piégeage lumineux automatique à incandescence', 'CAMPANULE', 'Validation en cours', 0, '100.095', '2017-06-19 15:12:46.794127', NULL, true)
,(306, 100, '96', 'Piégeage lumineux automatique à LED', 'Piégeage lumineux automatique à LED', 'Piégeage lumineux automatique à LED', 'CAMPANULE', 'Validation en cours', 0, '100.096', '2017-06-19 15:12:46.794127', NULL, true)
,(307, 100, '97', 'Piégeage lumineux manuel à fluorescence', 'Piégeage lumineux manuel à fluorescence', 'Piégeage lumineux manuel à fluorescence', 'CAMPANULE', 'Validation en cours', 0, '100.097', '2017-06-19 15:12:46.794127', NULL, true)
,(308, 100, '98', 'Piégeage lumineux manuel à incandescence', 'Piégeage lumineux manuel à incandescence', 'Piégeage lumineux manuel à incandescence', 'CAMPANULE', 'Validation en cours', 0, '100.098', '2017-06-19 15:12:46.794127', NULL, true)
,(309, 100, '99', 'Piégeage lumineux manuel à LED', 'Piégeage lumineux manuel à LED', 'Piégeage lumineux manuel à LED', 'CAMPANULE', 'Validation en cours', 0, '100.099', '2017-06-19 15:12:46.794127', NULL, true)
,(310, 100, '100', 'Piégeage Malaise (capture par tente Malaise)', 'Piégeage Malaise (capture par tente Malaise)', 'Piégeage Malaise (capture par tente Malaise)', 'CAMPANULE', 'Validation en cours', 0, '100.100', '2017-06-19 15:13:18.161067', NULL, true)
,(311, 100, '101', 'Piégeage Marris House Net (capture par piège Malaise type Marris House Net)', 'Piégeage Marris House Net (capture par piège Malaise type Marris House Net)', 'Piégeage Marris House Net (capture par piège Malaise type Marris House Net)', 'CAMPANULE', 'Validation en cours', 0, '100.101', '2017-06-19 15:13:18.161067', NULL, true)
,(312, 100, '102', 'Piégeage microtube à fourmis', 'Piégeage microtube à fourmis', 'Piégeage microtube à fourmis', 'CAMPANULE', 'Validation en cours', 0, '100.102', '2017-06-19 15:13:18.161067', NULL, true)
,(313, 100, '103', 'Piégeage par assiettes colorées (piège coloré, plaque colorée adhésive)', 'Piégeage par assiettes colorées (piège coloré, plaque colorée adhésive)', 'Piégeage par assiettes colorées (piège coloré, plaque colorée adhésive)', 'CAMPANULE', 'Validation en cours', 0, '100.103', '2017-06-19 15:13:18.161067', NULL, true)
,(314, 100, '104', 'Piégeage par attraction sexuelle avec femelles', 'Piégeage par attraction sexuelle avec femelles', 'Piégeage par attraction sexuelle avec femelles', 'CAMPANULE', 'Validation en cours', 0, '100.104', '2017-06-19 15:13:18.161067', NULL, true)
,(315, 100, '105', 'Piégeage par attraction sexuelle avec phéromones', 'Piégeage par attraction sexuelle avec phéromones', 'Piégeage par attraction sexuelle avec phéromones', 'CAMPANULE', 'Validation en cours', 0, '100.105', '2017-06-19 15:13:18.161067', NULL, true)
,(316, 100, '106', 'Piégeage par enceinte à émergence aquatique (nasse à émergence aquatique)', 'Piégeage par enceinte à émergence aquatique (nasse à émergence aquatique)', 'Piégeage par enceinte à émergence aquatique (nasse à émergence aquatique)', 'CAMPANULE', 'Validation en cours', 0, '100.106', '2017-06-19 15:13:18.161067', NULL, true)
,(317, 100, '107', 'Piégeage par enceinte à émergence terrestre ex situ (nasse à émergence terrestre, éclosoir)', 'Piégeage par enceinte à émergence terrestre ex situ (nasse à émergence terrestre, éclosoir)', 'Piégeage par enceinte à émergence terrestre ex situ (nasse à émergence terrestre, éclosoir)', 'CAMPANULE', 'Validation en cours', 0, '100.107', '2017-06-19 15:13:18.161067', NULL, true)
,(318, 100, '108', 'Piégeage par enceinte à émergence terrestre in situ (nasse à émergence terrestre, éclosoir)', 'Piégeage par enceinte à émergence terrestre in situ (nasse à émergence terrestre, éclosoir)', 'Piégeage par enceinte à émergence terrestre in situ (nasse à émergence terrestre, éclosoir)', 'CAMPANULE', 'Validation en cours', 0, '100.108', '2017-06-19 15:13:18.161067', NULL, true)
,(319, 100, '109', 'Piégeage par enceinte type biocénomètre', 'Piégeage par enceinte type biocénomètre', 'Piégeage par enceinte type biocénomètre', 'CAMPANULE', 'Validation en cours', 0, '100.109', '2017-06-19 15:13:18.161067', NULL, true)
,(320, 100, '110', 'Piégeage par nasse à Coléoptères Hydrocanthares (piège appâté aquatique)', 'Piégeage par nasse à Coléoptères Hydrocanthares (piège appâté aquatique)', 'Piégeage par nasse à Coléoptères Hydrocanthares (piège appâté aquatique)', 'CAMPANULE', 'Validation en cours', 0, '100.110', '2017-06-19 15:13:18.161067', NULL, true)
,(321, 100, '111', 'Piégeage par nasses aquatiques ou filets verveux (appâtés)', 'Piégeage par nasses aquatiques ou filets verveux (appâtés)', 'Piégeage par nasses aquatiques ou filets verveux (appâtés)', 'CAMPANULE', 'Validation en cours', 0, '100.111', '2017-06-19 15:13:18.161067', NULL, true)
,(322, 100, '112', 'Piégeage par nasses aquatiques ou filets verveux (non appâtés)', 'Piégeage par nasses aquatiques ou filets verveux (non appâtés)', 'Piégeage par nasses aquatiques ou filets verveux (non appâtés)', 'CAMPANULE', 'Validation en cours', 0, '100.112', '2017-06-19 15:13:18.161067', NULL, true)
,(323, 100, '113', 'Piégeage par piège à entonnoir terrestre (funnel trap) (appâté)', 'Piégeage par piège à entonnoir terrestre (funnel trap) (appâté)', 'Piégeage par piège à entonnoir terrestre (funnel trap) (appâté)', 'CAMPANULE', 'Validation en cours', 0, '100.113', '2017-06-19 15:13:18.161067', NULL, true)
,(324, 100, '114', 'Piégeage par piège à entonnoir terrestre (funnel trap) (non appâté)', 'Piégeage par piège à entonnoir terrestre (funnel trap) (non appâté)', 'Piégeage par piège à entonnoir terrestre (funnel trap) (non appâté)', 'CAMPANULE', 'Validation en cours', 0, '100.114', '2017-06-19 15:13:18.161067', NULL, true)
,(325, 100, '115', 'Piégeage par piège-vitre bidirectionnel \"mimant une cavité\" (bande noire)', 'Piégeage par piège-vitre bidirectionnel \"mimant une cavité\" (bande noire)', 'Piégeage par piège-vitre bidirectionnel \"mimant une cavité\" (bande noire)', 'CAMPANULE', 'Validation en cours', 0, '100.115', '2017-06-19 15:13:18.161067', NULL, true)
,(326, 100, '116', 'Piégeage par piège-vitre bidirectionnel (piège fenêtre, piège-vitre plan)', 'Piégeage par piège-vitre bidirectionnel (piège fenêtre, piège-vitre plan)', 'Piégeage par piège-vitre bidirectionnel (piège fenêtre, piège-vitre plan)', 'CAMPANULE', 'Validation en cours', 0, '100.116', '2017-06-19 15:13:18.161067', NULL, true)
,(327, 100, '117', 'Piégeage par piège-vitre multidirectionnel avec alcool (piège Polytrap, PIMUL)', 'Piégeage par piège-vitre multidirectionnel avec alcool (piège Polytrap, PIMUL)', 'Piégeage par piège-vitre multidirectionnel avec alcool (piège Polytrap, PIMUL)', 'CAMPANULE', 'Validation en cours', 0, '100.117', '2017-06-19 15:13:18.161067', NULL, true)
,(328, 100, '118', 'Piégeage par piège-vitre multidirectionnel sans alcool (piège Polytrap, PIMUL)', 'Piégeage par piège-vitre multidirectionnel sans alcool (piège Polytrap, PIMUL)', 'Piégeage par piège-vitre multidirectionnel sans alcool (piège Polytrap, PIMUL)', 'CAMPANULE', 'Validation en cours', 0, '100.118', '2017-06-19 15:13:18.161067', NULL, true)
,(329, 100, '119', 'Piégeage par sac collecteur de feuillage et rameaux ligneux', 'Piégeage par sac collecteur de feuillage et rameaux ligneux', 'Piégeage par sac collecteur de feuillage et rameaux ligneux', 'CAMPANULE', 'Validation en cours', 0, '100.119', '2017-06-19 15:13:18.161067', NULL, true)
,(330, 100, '120', 'Piégeage par sélecteur de Chauvin', 'Piégeage par sélecteur de Chauvin', 'Piégeage par sélecteur de Chauvin', 'CAMPANULE', 'Validation en cours', 0, '100.120', '2017-06-19 15:13:18.161067', NULL, true)
,(331, 100, '121', 'Piégeage par tissu imbibé d''insecticide', 'Piégeage par tissu imbibé d''insecticide', 'Piégeage par tissu imbibé d''insecticide', 'CAMPANULE', 'Validation en cours', 0, '100.121', '2017-06-19 15:13:18.161067', NULL, true)
,(332, 100, '122', 'Piégeage SLAM (capture par piège Sand Land and Air Malaise)', 'Piégeage SLAM (capture par piège Sand Land and Air Malaise)', 'Piégeage SLAM (capture par piège Sand Land and Air Malaise)', 'CAMPANULE', 'Validation en cours', 0, '100.122', '2017-06-19 15:13:18.161067', NULL, true)
,(333, 100, '123', 'Piégeages par pièges barrières (pots-pièges associés à une barrière d''interception)', 'Piégeages par pièges barrières (pots-pièges associés à une barrière d''interception)', 'Piégeages par pièges barrières (pots-pièges associés à une barrière d''interception)', 'CAMPANULE', 'Validation en cours', 0, '100.123', '2017-06-19 15:13:18.161067', NULL, true)
,(334, 100, '124', 'Pièges à poils', 'Pièges à poils', 'Pièges à poils', 'CAMPANULE', 'Validation en cours', 0, '100.124', '2017-06-19 15:13:18.161067', NULL, true)
,(335, 100, '125', 'Pièges à traces (pièges à empreintes)', 'Pièges à traces (pièges à empreintes)', 'Pièges à traces (pièges à empreintes)', 'CAMPANULE', 'Validation en cours', 0, '100.125', '2017-06-19 15:13:18.161067', NULL, true)
,(336, 100, '126', 'Pièges aquatiques à sangsues (bouteilles percées, appâtées…)', 'Pièges aquatiques à sangsues (bouteilles percées, appâtées…)', 'Pièges aquatiques à sangsues (bouteilles percées, appâtées…)', 'CAMPANULE', 'Validation en cours', 0, '100.126', '2017-06-19 15:13:18.161067', NULL, true)
,(337, 100, '127', 'Pièges cache-tubes', 'Pièges cache-tubes', 'Pièges cache-tubes', 'CAMPANULE', 'Validation en cours', 0, '100.127', '2017-06-19 15:13:18.161067', NULL, true)
,(338, 100, '128', 'Pièges cache-tubes adhésifs (tubes capteurs de poils)', 'Pièges cache-tubes adhésifs (tubes capteurs de poils)', 'Pièges cache-tubes adhésifs (tubes capteurs de poils)', 'CAMPANULE', 'Validation en cours', 0, '100.128', '2017-06-19 15:13:18.161067', NULL, true)
,(339, 100, '129', 'Prélèvement par râteau ou grappin (macrophytes)', 'Prélèvement par râteau ou grappin (macrophytes)', 'Prélèvement par râteau ou grappin (macrophytes)', 'CAMPANULE', 'Validation en cours', 0, '100.129', '2017-06-19 15:13:18.161067', NULL, true)
,(340, 100, '130', 'Prospection à pied de cours d''eau (macrophytes)', 'Prospection à pied de cours d''eau (macrophytes)', 'Prospection à pied de cours d''eau (macrophytes)', 'CAMPANULE', 'Validation en cours', 0, '100.130', '2017-06-19 15:13:18.161067', NULL, true)
,(341, 100, '131', 'Prospection active dans l''habitat naturel (talus, souches, pierres…)', 'Prospection active dans l''habitat naturel (talus, souches, pierres…)', 'Prospection active dans l''habitat naturel (talus, souches, pierres…)', 'CAMPANULE', 'Validation en cours', 0, '100.131', '2017-06-19 15:13:18.161067', NULL, true)
,(342, 100, '132', 'Recherche dans filtres de piscines, skimmer', 'Recherche dans filtres de piscines, skimmer', 'Recherche dans filtres de piscines, skimmer', 'CAMPANULE', 'Validation en cours', 0, '100.132', '2017-06-19 15:13:18.161067', NULL, true)
,(346, 101, '1', 'Non renseigné', 'Non renseigné', 'Le statut de validation n''est pas renseignée', 'GEONATURE', 'non validé', 0, '101.001', '2017-08-08 10:05:18.161068', NULL, true)
,(347, 101, '2', 'En attente de validation', 'En attente de validation', 'Le travail de validation n''a pas encore été réalisé. Le statut de validation est en attente', 'GEONATURE', 'non validé', 0, '101.002', '2017-08-08 10:05:18.161069', NULL, true)
,(348, 101, '3', 'Valide', 'Valide', 'La donnée d''observation est valide', 'GEONATURE', 'non validé', 0, '101.003', '2017-08-08 10:05:18.16107', NULL, true)
,(349, 101, '4', 'Non valide', 'Non valide', 'La donnée d''observation n''est pas valide', 'GEONATURE', 'non validé', 0, '101.004', '2017-08-08 10:05:18.161071', NULL, true)
,(350, 101, '5', 'Douteux', 'Douteux', 'La donnée est douteuse. Sans information complémentaire permettant d''étayer l''observation, elle ne peut pas être validée', 'GEONATURE', 'non validé', 0, '101.005', '2017-08-08 10:05:18.161072', NULL, true)
,(351, 102, '1', 'Dataset', 'Dataset', 'Jeu de données', 'SINP', 'Validé', 0, '102.001', '2017-10-16 16:05:18', NULL, true)
,(352, 102, '2', 'Series', 'Series', 'ensemble de séries de données', 'SINP', 'Validé', 0, '102.002', '2017-10-16 16:05:18', NULL, true)
,(353, 103, '1', 'DS', 'Données source', 'Jeu de données-source dans les bases de données d''un producteur ou Jeu de données-source transmises par un producteur à une plateforme régionale ou thématique', 'SINP', 'Validé', 0, '103.001', '2017-10-16 16:25:00', NULL, true)
,(354, 103, '2', 'DSR', 'Données source régionale', 'Jeu de données au standard régional dans la plateforme régionale/thématique', 'SINP', 'Validé', 0, '103.002', '2017-10-16 16:25:00', NULL, true)
,(355, 103, '3', 'DEE', 'Données élémentaires d''échange', 'Jeu de données élémentaires d''échange (échangé entre plateforme régionale ou thématique et plateforme nationale)', 'SINP', 'Validé', 0, '103.003', '2017-10-16 16:25:00', NULL, true)
,(356, 104, '1', 'Aléatoire simple', 'Aléatoire simple', 'Les tirages des unités sont équiprobables et indépendants)', 'SINP', 'Validé', 0, '104.001', '2017-10-16 17:15:00', NULL, true)
,(357, 104, '2', 'Systématique', 'Systématique', 'Les unités sont ordonnées (par ex. selon leurs coordonnées). Une première unité est tirée au hasard et les suivantes s''en déduisent en respectant l''agencement', 'SINP', 'Validé', 0, '104.002', '2017-10-16 17:15:00', NULL, true)
,(358, 104, '3', 'Stratifié', 'Stratifié', 'La zone d''étude est découpée en strates plus homogènes (selon les grands types de milieux par ex.), et les unités d''échantillonnage sont sélectionnées au sein de chaque strate selon un plan d''échantillonnage secondaire', 'SINP', 'Validé', 0, '104.003', '2017-10-16 17:15:00', NULL, true)
,(359, 104, '4', 'Adaptative sampling', 'Adaptative sampling', 'Tirage aléatoire d''un premier lot d''unités, puis de nouvelles unités sont ajoutées selon les résultats obtenus sur les premières', 'SINP', 'Validé', 0, '104.004', '2017-10-16 17:15:00', NULL, true)
,(360, 104, '5', 'Probabilités inégales', 'Probabilités inégales (distance sampling, relascope)', 'Le tirage des unités est aléatoire avec probabilités inégales (chaque unité d''échantillonnage n''a pas la même probabilité d''être sélectionnée). C''est souvent le cas pour des unités de taille variable', 'SINP', 'Validé', 0, '104.005', '2017-10-16 17:15:00', NULL, true)
,(361, 104, '6', 'Par degrés, par grappes', 'Par degrés, par grappes', 'La sélection des unités s''effectue dans un système hiérarchisé d''unités primaires, composées d''unités secondaires, etc. Par exemple, des arbres sont sélectionnés au sein de placettes, elles-mêmes sélectionnées au sein de peuplements forestiers, etc', 'SINP', 'Validé', 0, '104.006', '2017-10-16 17:15:00', NULL, true)
,(362, 104, '7', 'Subjectif', 'Subjectif', 'Le choix des unités d''échantillonnage est effectué selon des critères propres à l''observateur (pas toujours précisés)', 'SINP', 'Validé', 0, '104.007', '2017-10-16 17:15:00', NULL, true)
,(363, 104, '8', 'Autre', 'Autre', 'Autre type de plan d''échantillonnage', 'SINP', 'Validé', 0, '104.008', '2017-10-16 17:15:00', NULL, true)
,(364, 105, '1', 'Individus', 'Individus', 'Individus', 'SINP', 'Validé', 0, '105.001', '2017-10-16 17:15:00', NULL, true)
,(365, 105, '2', 'Points', 'Points', 'Points', 'SINP', 'Validé', 0, '105.002', '2017-10-16 17:15:00', NULL, true)
,(366, 105, '3', 'Quadrats', 'Quadrats', 'Surface impérativement carrée.', 'SINP', 'Validé', 0, '105.003', '2017-10-16 17:15:00', NULL, true)
,(367, 105, '4', 'Placettes', 'Placettes', 'Surface de format variable (souvent circulaire, peut également être rectangulaire, etc.)', 'SINP', 'Validé', 0, '105.004', '2017-10-16 17:15:00', NULL, true)
,(368, 105, '5', 'Transects', 'Transects', 'Mesure en continu le long d''un tracé entre deux points (Désigne parfois une série de placettes effectuées le long d''un parcours entre deux points, mais c''est un abus de langage : dans ce cas, l''unité d''échantillonnage est la placette)', 'SINP', 'Validé', 0, '105.005', '2017-10-16 17:15:00', NULL, true)
,(369, 105, '6', 'Autre', 'Autre', 'Autre type d''unités d''échantillonnage', 'SINP', 'Validé', 0, '105.006', '2017-10-16 17:15:00', NULL, true)
,(370, 106, '1', 'Examen macroscopique terrain', 'Examen macroscopique terrain', 'Examen de l''individu sur le terrain sans loupe ni microscope', 'GEONATURE', 'non validé', 0, '106.001', '2017-10-26 00:00:00', NULL, true)
,(371, 106, '2', 'Examen macroscopique laboratoire', 'Examen macroscopique laboratoire', 'Examen de l''individu en laboratoire sans loupe ni microscope', 'GEONATURE', 'non validé', 0, '106.002', '2017-10-26 00:00:00', NULL, true)
,(372, 106, '3', 'Examen genitalia terrain', 'Examen genitalia terrain', 'Examen des pièces génitales de l''individu sur le terrain', 'GEONATURE', 'non validé', 0, '106.003', '2017-10-26 00:00:00', NULL, true)
,(373, 106, '4', 'Examen genitalia laboratoire', 'Examen genitalia laboratoire', 'Examen des pièces génitales de l''individu en laboratoire', 'GEONATURE', 'non validé', 0, '106.004', '2017-10-26 00:00:00', NULL, true)
,(374, 106, '5', 'Examen en collection', 'Examen en collection', 'Examen de l''individu à partir d''une collection', 'GEONATURE', 'non validé', 0, '106.005', '2017-10-26 00:00:00', NULL, true)
,(375, 106, '6', 'Examen sur photo', 'Examen sur photo', 'Examen de l''individu à partir de photo(s)', 'GEONATURE', 'non validé', 0, '106.006', '2017-10-26 00:00:00', NULL, true)
,(376, 106, '7', 'Déterminé après élevage', 'Déterminé après élevage', 'La détermination a été réalisées après élevage ou plantation (chenille, graine par exemple)', 'GEONATURE', 'non validé', 0, '106.007', '2017-10-26 00:00:00', NULL, true)
,(377, 106, '8', 'Analyse génétique', 'Analyse génétique', 'Une analyse génétique a été réalisée à partir d''un échantillon prélevé sur un ou plusieurs individus', 'GEONATURE', 'non validé', 0, '106.008', '2017-10-26 00:00:00', NULL, true)
,(378, 106, '9', 'Examen de la dentition', 'Examen de la dentition', 'La détermination a été réalisées après examen de la dentition', 'GEONATURE', 'non validé', 0, '106.009', '2017-10-26 00:00:00', NULL, true)
,(379, 106, '10', 'Autre critère', 'Autre critère', 'Le critère de détermination n''est pas présent dans cette liste', 'GEONATURE', 'non validé', 0, '106.010', '2017-10-26 00:00:00', NULL, true)
,(473, 106, '11', 'Non renseigné', 'Non renseigné', 'L''information n''a pas été renseignée.', 'GEONATURE', 'non validé', 0, '106.011', '2018-01-11 00:00:00', NULL, true)
,(380, 107, '1', 'International', 'International', 'niveau international', 'SINP', 'Validé', 0, '107.001', '2017-10-30 00:00:00', NULL, true)
,(381, 107, '2', 'Européen', 'Européen', 'niveau européen', 'SINP', 'Validé', 0, '107.002', '2017-10-30 00:00:00', NULL, true)
,(382, 107, '3', 'National', 'National', 'niveau national', 'SINP', 'Validé', 0, '107.003', '2017-10-30 00:00:00', NULL, true)
,(383, 107, '4', 'Inter-régional terrestre, ou région marine', 'Inter-régional terrestre, ou région marine', 'niveau inter-régional terrestre, ou région marine', 'SINP', 'Validé', 0, '107.004', '2017-10-30 00:00:00', NULL, true)
,(384, 107, '5', 'Régional terrestre, ou sous-région marine', 'Régional terrestre, ou sous-région marine', 'niveau régional terrestre, ou sous-région marine', 'SINP', 'Validé', 0, '107.005', '2017-10-30 00:00:00', NULL, true)
,(385, 107, '6', 'Départemental, ou secteur marin', 'Départemental, ou secteur marin', 'niveau départemental, ou secteur marin', 'SINP', 'Validé', 0, '107.006', '2017-10-30 00:00:00', NULL, true)
,(386, 107, '7', 'Communal ou local', 'Communal ou local', 'niveau communal ou local', 'SINP', 'Validé', 0, '107.007', '2017-10-30 00:00:00', NULL, true)
,(387, 108, '1', 'Inventaire espèce', 'Inventaire espèce', 'Inventaire espèce', 'SINP', 'Validé', 0, '108.001', '2017-10-30 00:00:00', NULL, true)
,(388, 108, '2', 'Inventaire habitat centré', 'Inventaire habitat centré', 'Inventaire habitat centré', 'SINP', 'Validé', 0, '108.002', '2017-10-30 00:00:00', NULL, true)
,(472, 108, '3', 'Inventaire logique espace', 'Inventaire logique espace', 'Inventaire logique espace', 'SINP', 'Validé', 0, '108.003', '2017-10-30 00:00:00', NULL, true)
,(389, 108, '4', 'Evaluation interaction', 'Evaluation interaction', 'Evaluation interaction', 'SINP', 'Validé', 0, '108.004', '2017-10-30 00:00:00', NULL, true)
,(390, 108, '5', 'Evolution temporelle', 'Evolution temporelle', 'Evolution temporelle', 'SINP', 'Validé', 0, '108.005', '2017-10-30 00:00:00', NULL, true)
,(391, 108, '6', 'Evolution espace', 'Evolution espace', 'Evolution espace', 'SINP', 'Validé', 0, '108.006', '2017-10-30 00:00:00', NULL, true)
,(392, 108, '7', 'Regroupements et autres études', 'Regroupements et autres études', 'Regroupements et autres études', 'SINP', 'Validé', 0, '108.007', '2017-10-30 00:00:00', NULL, true)
,(393, 109, '1', 'Contact principal', 'Contact principal', 'Contact principal', 'SINP', 'Validé', 0, '109.001', '2017-10-30 00:00:00', NULL, true)
,(394, 109, '2', 'Financeur', 'Financeur', 'Financeur', 'SINP', 'Validé', 0, '109.002', '2017-10-30 00:00:00', NULL, true)
,(395, 109, '3', 'Maître d''ouvrage', 'Maître d''ouvrage', 'Maître d''ouvrage', 'SINP', 'Validé', 0, '109.003', '2017-10-30 00:00:00', NULL, true)
,(396, 109, '4', 'Maître d''oeuvre', 'Maître d''oeuvre', 'Maître d''oeuvre', 'SINP', 'Validé', 0, '109.004', '2017-10-30 00:00:00', NULL, true)
,(397, 109, '5', 'Fournisseur du jeu de données', 'Fournisseur du jeu de données', 'Fournisseur du jeu de données', 'SINP', 'Validé', 0, '109.005', '2017-10-30 00:00:00', NULL, true)
,(398, 109, '6', 'Producteur du jeu de données', 'Producteur du jeu de données', 'Producteur du jeu de données', 'SINP', 'Validé', 0, '109.006', '2017-10-30 00:00:00', NULL, true)
,(399, 109, '7', 'Point de contact base de données de production', 'Point de contact base de données de production', 'Point de contact base de données de productions', 'SINP', 'Validé', 0, '109.007', '2017-10-30 00:00:00', NULL, true)
,(429, 109, '8', 'Point de contact pour les métadonnées', 'Point de contact pour les métadonnées', 'Point de contact pour les métadonnées', 'GEONATURE', 'non validé', 0, '109.008', '2017-11-02 00:00:00', NULL, true)
,(400, 110, 'METROP', 'Métropole', 'Métropole', 'Métropole', 'SINP', 'Validé', 0, '110.001', '2017-10-30 00:00:00', NULL, true)
,(401, 110, 'GUF', 'Guyane française', 'Guyane française', 'Guyane française', 'SINP', 'Validé', 0, '110.002', '2017-10-30 00:00:00', NULL, true)
,(402, 110, 'MTQ', 'Martinique', 'Martinique', 'Martinique', 'SINP', 'Validé', 0, '110.003', '2017-10-30 00:00:00', NULL, true)
,(403, 110, 'GLP', 'Guadeloupe', 'Guadeloupe', 'Guadeloupe', 'SINP', 'Validé', 0, '110.004', '2017-10-30 00:00:00', NULL, true)
,(404, 110, 'MAF', 'Saint-Martin', 'Saint-Martin', 'Saint-Martin', 'SINP', 'Validé', 0, '110.005', '2017-10-30 00:00:00', NULL, true)
,(405, 110, 'BLM', 'Saint-Barthélemy', 'Saint-Barthélemy', 'Saint-Barthélemy', 'SINP', 'Validé', 0, '110.006', '2017-10-30 00:00:00', NULL, true)
,(406, 110, 'SPM', 'Saint-Pierre et Miquelon', 'Saint-Pierre et Miquelon', 'Saint-Pierre et Miquelon', 'SINP', 'Validé', 0, '110.007', '2017-10-30 00:00:00', NULL, true)
,(407, 110, 'MYT', 'Mayotte', 'Mayotte', 'Mayotte', 'SINP', 'Validé', 0, '110.008', '2017-10-30 00:00:00', NULL, true)
,(408, 110, 'REU', 'Réunion', 'Réunion', 'Réunion', 'SINP', 'Validé', 0, '110.009', '2017-10-30 00:00:00', NULL, true)
,(409, 110, 'NCL', 'Nouvelle-Calédonie', 'Nouvelle-Calédonie', 'Nouvelle-Calédonie', 'SINP', 'Validé', 0, '110.010', '2017-10-30 00:00:00', NULL, true)
,(410, 110, 'WLF', 'Wallis-et-Futuna', 'Wallis-et-Futuna', 'Wallis-et-Futuna', 'SINP', 'Validé', 0, '110.011', '2017-10-30 00:00:00', NULL, true)
,(411, 110, 'PYF', 'Polynésie française', 'Polynésie française', 'Polynésie française', 'SINP', 'Validé', 0, '110.012', '2017-10-30 00:00:00', NULL, true)
,(412, 110, 'CLI', 'Clipperton', 'Clipperton', 'Clipperton', 'SINP', 'Validé', 0, '110.013', '2017-10-30 00:00:00', NULL, true)
,(413, 110, 'EPA', 'TAAF : Iles Eparses', 'TAAF : Iles Eparses', 'TAAF : Iles Eparses', 'SINP', 'Validé', 0, '110.014', '2017-10-30 00:00:00', NULL, true)
,(414, 110, 'SUBANT', 'TAAF : Iles sub-Antarctiques', 'TAAF : Iles sub-Antarctiques', 'TAAF : Iles sub-Antarctiques', 'SINP', 'Validé', 0, '110.015', '2017-10-30 00:00:00', NULL, true)
,(415, 110, 'TADL', 'TAAF : Terre-Adélie', 'TAAF : Terre-Adélie', 'TAAF : Terre-Adélie', 'SINP', 'Validé', 0, '110.016', '2017-10-30 00:00:00', NULL, true)
,(416, 110, 'HORSFR', 'Hors territoire', 'Hors territoire', 'Hors territoire', 'SINP', 'Validé', 0, '110.017', '2017-10-30 00:00:00', NULL, true)
,(417, 111, '1', 'Publique', 'Publique', 'Type de financement public', 'SINP', 'Validé', 0, '111.001', '2017-10-30 00:00:00', NULL, true)
,(418, 111, '2', 'Privée', 'Privée', 'Type de financement privé', 'SINP', 'Validé', 0, '111.002', '2017-10-30 00:00:00', NULL, true)
,(419, 111, '3', 'Mixte', 'Mixte', 'Mélange de financement public et privé', 'SINP', 'Validé', 0, '111.003', '2017-10-30 00:00:00', NULL, true)
,(420, 111, '4', 'Non financé', 'Non financé', 'Absence de financement', 'SINP', 'Validé', 0, '111.004', '2017-10-30 00:00:00', NULL, true)
,(421, 112, '0', 'Inconnu', 'Inconnu', 'Inconnu', 'SINP', 'Validé', 0, '112.017', '2017-10-30 00:00:00', NULL, true)
,(422, 112, '1', 'Protocole de collecte', 'Protocole de collecte', 'Protocole de collecte', 'SINP', 'Validé', 0, '1121.001', '2017-10-30 00:00:00', NULL, true)
,(423, 112, '2', 'Protocole de synthèse', 'Protocole de synthèse', 'Protocole de synthèse', 'SINP', 'Validé', 0, '112.002', '2017-10-30 00:00:00', NULL, true)
,(424, 112, '3', 'Protocole de conformité et de cohérence', 'Protocole de conformité et de cohérence', 'Protocole de conformité et de cohérence', 'SINP', 'Validé', 0, '111.003', '2017-10-30 00:00:00', NULL, true)
,(425, 112, '4', 'Protocole de validation', 'Protocole de validation', 'Protocole de validation', 'SINP', 'Validé', 0, '112.004', '2017-10-30 00:00:00', NULL, true)
,(426, 113, '1', 'Terre', 'Terre', 'Toutes les données relatives à la nature/biodiversité française du domaine terrestre (outre-mer compris) : habitats, flore, faune, champignons..., les données relatives aux espaces naturels (protégés / gérés ou non), aux sites géologiques, aux écosystèmes et leur fonctionnement.', 'SINP', 'Validé', 0, '113.001', '2017-10-30 00:00:00', NULL, true)
,(427, 113, '2', 'Mer', 'Mer', 'Toutes les données relatives à la nature / biodiversité française du domaine marin (outre-mer compris) : habitats, flore, faune, champignons..., les données relatives aux espaces naturels (protégés/gérés ou non), aux sites géologiques, aux écosystèmes et leur fonctionnement.', 'SINP', 'Validé', 0, '113.002', '2017-10-30 00:00:00', NULL, true)
,(428, 113, '3', 'Paysage', 'Paysage', 'Toutes les données relatives aux paysages, c''est-à-dire des données relatives aux formes du territoire, aux perceptions sociales et aux dynamiques du territoire. Elles intègrent également des inventaires particuliers. Elles concernent les espaces naturels, ruraux, urbains et périurbains. Elles incluent les espaces terrestres, les eaux intérieures et maritimes. Elles concernent tant les paysages pouvant être considérés comme remarquables que les paysages du quotidien et les paysages dégradés.', 'SINP', 'Validé', 0, '113.003', '2017-10-30 00:00:00', NULL, true)
,(430, 115, '1', 'Observation directe : Vue, écoute, olfactive, tactile', 'Observation directe : Vue, écoute, olfactive, tactile', 'Observation directe : Vue, écoute, olfactive, tactile', 'SINP', 'Validé', 0, '115.001', '2017-11-02 00:00:00', NULL, true)
,(431, 115, '2', 'Pièges photo', 'Pièges photo', 'Pièges photo', 'SINP', 'Validé', 0, '115.002', '2017-11-02 00:00:00', NULL, true)
,(432, 115, '3', 'Détection d''ultrasons', 'Détection d''ultrasons', 'Détection d''ultrasons', 'SINP', 'Validé', 0, '115.003', '2017-11-02 00:00:00', NULL, true)
,(433, 115, '4', 'Recherche d''indices de présence', 'Recherche d''indices de présence', 'Recherche d''indices de présence', 'SINP', 'Validé', 0, '115.004', '2017-11-02 00:00:00', NULL, true)
,(434, 115, '5', 'Photographies aériennes', 'Photographies aériennes', 'Photographies aériennes', 'SINP', 'Validé', 0, '115.005', '2017-11-02 00:00:00', NULL, true)
,(435, 115, '6', 'Télédétection', 'Télédétection', 'Télédétection', 'SINP', 'Validé', 0, '115.006', '2017-11-02 00:00:00', NULL, true)
,(436, 115, '7', 'Télémétrie', 'Télémétrie', 'Télémétrie', 'SINP', 'Validé', 0, '115.007', '2017-11-02 00:00:00', NULL, true)
,(437, 115, '8', 'Capture d''individus (sans capture d''échantillon) : capture-relâcher', 'Capture d''individus (sans capture d''échantillon) : capture-relâcher', 'Capture d''individus (sans capture d''échantillon) : capture-relâcher', 'SINP', 'Validé', 0, '115.008', '2017-11-02 00:00:00', NULL, true)
,(438, 115, '9', 'Prélèvement (capture avec collecte d''échantillon) : capture-conservation', 'Prélèvement (capture avec collecte d''échantillon) : capture-conservation', 'Prélèvement (capture avec collecte d''échantillon) : capture-conservation', 'SINP', 'Validé', 0, '115.009', '2017-11-02 00:00:00', NULL, true)
,(439, 115, '10', 'Capture marquage recapture', 'Capture marquage recapture', 'Capture marquage recapture', 'SINP', 'Validé', 0, '115.010', '2017-11-02 00:00:00', NULL, true)
,(440, 115, '11', 'Capture-suivi (radiotracking)', 'Capture-suivi (radiotracking)', 'Capture-suivi (radiotracking)', 'SINP', 'Validé', 0, '115.011', '2017-11-02 00:00:00', NULL, true)
,(441, 115, '12', 'Autre', 'Autre', 'Autre', 'SINP', 'Validé', 0, '115.011', '2017-11-02 00:00:00', NULL, true)
,(442, 114, '1.1', 'Observations naturalistes opportunistes', 'Observations naturalistes opportunistes', 'Les programmes d’observation participative (tous publics ou experts bénévoles, «recording scheme »), recueillant les données d’observation, sans plan d’échantillonnage particulier ni objectif prédéfini. La saisie de carnet de terrain entre dans cette rubrique. De même des observations annexes (groupe non cible) faites lors d’un programme spécifique entrent dans cette catégorie. Si ces informations sont recueillies dans un programme d’atlas en ligne, elles entrent dans la catégorie 1.2', 'SINP', 'Validé', 0, '114.001', '2017-11-02 00:00:00', NULL, true)
,(443, 114, '1.2', 'Inventaire de répartition', 'Inventaire de répartition', 'Logique de projet avec un échantillonnage visant à couvrir le plus de territoire possible pour une espèce ou un groupe taxonomique donné, afin d’établir sa distribution dans une logique d’atlas, quelques soit son échelle (généralement départemental, régional ou national). Quand l’inventaire de répartition est la logique dominante, et qu’elle s’accompagne d’observations occasionnelles (non cible : exemple observation d’une couleuvre à collier lors d’un carré d’atlas oiseaux nicheur), ces observations occasionnelles peuvent être inclues dans cette catégorie mais devraient le plus possible faire l’objet d’un jdd distinct dans le même CA avec la catégorie « observation naturalistes opportunistes »', 'SINP', 'Validé', 0, '114.002', '2017-11-02 00:00:00', NULL, true)
,(444, 114, '1.3', 'Inventaire pour étude d’espèces ou de communautés', 'Inventaire pour étude d’espèces ou de communautés', 'Logique d’acquisition de données associées à un protocole dans le but d’avoir des informations sur les facteurs qui structurent la présence et/ou l’observation d’une espèce, d’une population ou d’une communauté à l’échelle d’une station ou d’un éco-complexe. Les objectifs peuvent être multiples (conservation, éthologie, dynamique des populations, interactions biologiques, structuration des communautés ...). La mise en place de protocoles pour établir des indices de détectabilité pour les espèces et/ou leur degré de spécialisation vis-à-vis d’un habitat rentre dans ce cas.', 'SINP', 'Validé', 0, '114.003', '2017-11-02 00:00:00', NULL, true)
,(445, 114, '1.4', 'Numérisation de collections', 'Numérisation de collections', 'Jeux de données généré par la mobilisation (saisie) de données d’une ou plusieurs collections de spécimens (herbier, collection entomologiques etc.) et visant à les rendre disponibles pour tout usage. Ce cas n’est à utiliser que si aucun autre motif plus précis à l’origine de la constitution de la collection ne peut être affecté : par exemple dans le cas où une campagne d’exploration génère des collections, le rattachement doit se faire à l’objectif « ATBI et exploration » (cf. libellé 2.5)', 'SINP', 'Validé', 0, '114.004', '2017-11-02 00:00:00', NULL, true)
,(446, 114, '1.5', 'Numérisation de bibliographie', 'Numérisation de bibliographie', 'Cas particulier d’un jeu de données contenant uniquement des données issues de l’analyse de la bibliographie (qu’elle soit publié ou en littérature grise) et visant à les rendre disponibles pour tout usage. Ce cas n’est à utiliser que si aucun autre motif plus précis à l’origine de la constitution de la bibliographie ne peut être affecté : par exemple dans le cas où une campagne d’exploration d’un site génère des publications, le rattachement doit se faire à l’objectif « ATBI et exploration ». Les carnets d’observation de terrain relèvent plutôt du 1.1, Observation opportunistes', 'SINP', 'Validé', 0, '114.005', '2017-11-02 00:00:00', NULL, true)
,(447, 114, '2.1', 'Cartographie habitats', 'Cartographie habitats', 'Données correspondant à une cartographie des végétations-habitats-écosystèmes établie à une échelle large (département, région, PNR, petite région naturelle) et non selon une logique de site ou réseau de site. Les approches terrain, traitement d’image ou la combinaison des deux sont inclues. Relevés de communauté d’espèces (généralement végétation/relevés phytosociologiques ou benthos pour les habitats marins) réalisés dans le cadre d’une cartographie des végétations-habitats-écosystèmes. Si seuls des relevés sont effectués (sans détermination du type de végétation ou habitat), il faut affecter à une autre rubrique.', 'SINP', 'Validé', 0, '114.006', '2017-11-02 00:00:00', NULL, true)
,(448, 114, '2.2', 'Inventaire d’habitat', 'Inventaire d’habitat', 'Plan d’échantillonnage de l’espace avec détermination du type de végétation-habitat-écosystème. Relevés de communauté d’espèces (généralement végétation/relevés phytosociologiques ou benthos pour les habitats marins) réalisé dans le cadre d’un inventaire des végétations-habitats-écosystèmes. Si seuls des relevés sont effectués (sans détermination du type de végétation ou habitat), il faut affecter à une autre rubrique', 'SINP', 'Validé', 0, '114.007', '2017-11-02 00:00:00', NULL, true)
,(449, 114, '2.3', 'Données opportuniste d’habitat', 'Données opportuniste d’habitat', 'Relevé de présence d’un type de végétation-habitat-écosystème n’entrant pas dans un plan d’échantillonnage prédéfini', 'SINP', 'Validé', 0, '114.008', '2017-11-02 00:00:00', NULL, true)
,(450, 114, '2.4', 'Inventaire pour étude d’habitat', 'Inventaire pour étude d’habitat', 'Relevés de communauté d’espèces (généralement végétation/relevés phytosociologiques ou benthos pour les habitats marins) réalisé pour des études ou de la recherche sur les végétations-habitats-écosystèmes. Logique d’acquisition de données associées à un protocole dans le but d’améliorer la connaissance ou la définition d’un habitat, de construire une typologie, ou de préciser son fonctionnement, évaluer son état de conservation... Si seuls des relevés sont effectués (sans lien avec le type de végétation ou habitat), il faut affecter à une autre rubrique (1.3)', 'SINP', 'Validé', 0, '114.009', '2017-11-02 00:00:00', NULL, true)
,(451, 114, '2.5', 'Numérisation de bibliographie habitat', 'Numérisation de bibliographie habitat', 'Cas particulier d’un jeu de données contenant uniquement des données issues de l’analyse de la bibliographie (qu’elle soit publié ou en littérature grise) et visant à les rendre disponibles pour tout usage concernant les habitats et les relevés standardisés associés (phytosociologiques, benthos)', 'SINP', 'Validé', 0, '114.010', '2017-11-02 00:00:00', NULL, true)
,(452, 114, '3.1', 'Inventaire type ABC', 'Inventaire type ABC', 'Inventaires menés dans le cadre de la réalisation d’un atlas de la biodiversité communale, que ce soit la démarche « Ministère » ou une démarche similaire (démarche des PNR, IBC par exemple). Les données pré-existantes numérisées à l’occasion et pour l’ABC entrent dans cette catégorie. Les éventuels suivis temporels initiés dans un ABC n’entrent pas dans cette rubrique', 'SINP', 'Validé', 0, '114.011', '2017-11-02 00:00:00', NULL, true)
,(453, 114, '3.2', 'Inventaire de Zonages d’intérêt', 'Inventaire de Zonages d’intérêt', 'Acquisition de données de terrain (pas de synthèse) pour établir/confirmer ou actualiser les zonages d’inventaires ZNIEFF (et éventuelles approches type ZICO ou IBA). Les inventaires pour accompagner la gestion d’espaces (déjà désignés) entrent dans la rubrique suivante (3.3)', 'SINP', 'Validé', 0, '114.012', '2017-11-02 00:00:00', NULL, true)
,(454, 114, '3.3', 'Inventaire/évaluation pour plans de gestion', 'Inventaire/évaluation pour plans de gestion', 'Acquisition structurée de données naturalistes pour préparer, réviser ou actualiser un plan de gestion (au sens large) d’un espace naturel à statut de protection ou de gestion particulier (Natura 2000, Réserves, Parcs, forêt publique...) ou d’un site privé pour sa gestion écologique (exemple golfs, emprise LGV...). Y compris les évaluations permettant d’évaluer l’intérêt patrimonial du site (type IQE), l’état de conservation de ses habitats, de définir des enjeux par secteurs... Les données « opportunistes » collectées par ces gestionnaires peuvent aussi entrer dans cette catégorie mais devraient mieux faire l’objet de jeux de données distincts des données protocolées (cat. 2.4)', 'SINP', 'Validé', 0, '114.013', '2017-11-02 00:00:00', NULL, true)
,(455, 114, '3.4', 'Observations opportunistes sur un site', 'Observations opportunistes sur un site', 'Données opportunistes collectées dans le cadre d’une logique site-centrée : lors d’opérations de gestion, données connexes d’observation faites lors d’un inventaire ou d''un suivi de site. La notion de site recouvre un espace (ou un réseau d’espace) prédéfini, avec un enjeu de gestion (réserves, site de conservatoire, sites d’une entreprise, espace vert...)', 'SINP', 'Validé', 0, '114.014', '2017-11-02 00:00:00', NULL, true)
,(456, 114, '3.5', 'Inventaires généralisés & exploration', 'Inventaires généralisés & exploration', 'Programme ciblé sur un ou quelques sites, visant à dresser un vaste inventaire des taxons présents, multi-groupes et généralement pour découvrir de nouvelles espèces (pour la Science ou pour le territoire). Exemples : ATBI, IBG... Ces programmes comportent généralement de la mise en collection, du barcode, des travaux de taxonomie etc. Un travail d’inventaire sur un site portant sur un ordre d’invertébrés très vaste (Hyménoptères, ou Diptères, Coléoptères ou Lépidoptères, Arachnides etc.) rentre dans cette catégorie', 'SINP', 'Validé', 0, '114.015', '2017-11-02 00:00:00', NULL, true)
,(457, 114, '3.6', 'Inventaire pour étude d''impact', 'Inventaire pour étude d''impact', 'Inventaires dans le cadre des procédures réglementaires d’études d’impact ou d’études d’incidence, avant la réalisation des impacts. Les suivis réglementaires post-implantatoires (ex mortalité chiroptères) ou de compensation ne sont pas concernés par cette catégorie (relève catégorie 5.4)', 'SINP', 'Validé', 0, '114.016', '2017-11-02 00:00:00', NULL, true)
,(458, 114, '3.7', 'Cartographie d’habitat d’un site', 'Cartographie d’habitat d’un site', 'Données correspondant à une cartographie des végétations-habitats-écosystèmes pour un site, dans une logique d’appui à la gestion (détermination des enjeux, adaptation de la gestion etc.) Les approches terrain, les traitements d’image ou la combinaison des deux sont incluses. Les relevés de communauté d’espèces (généralement végétation/relevés phytosociologiques ou benthos pour les habitats marins) réalisés dans le cadre d’un inventaire ou d’une cartographie des végétations-habitats-écosystèmes d’un site. Si seuls des relevés sont effectués (sans détermination du type de végétation ou habitat), il faut affecter à une autre rubrique.', 'SINP', 'Validé', 0, '114.017', '2017-11-02 00:00:00', NULL, true)
,(459, 114, '4.1', 'Évaluation de la ressource / prélèvements', 'Évaluation de la ressource / prélèvements', 'Inventaires et suivis piscicoles, de pêcheries, halieutiques, cynégétiques, pharmaceutiques ou dendrologiques afin de quantifier la ressource disponible, les stocks ou les prélèvements effectués (tableau de chasse...)', 'SINP', 'Validé', 0, '114.018', '2017-11-02 00:00:00', NULL, true)
,(460, 114, '4.2', 'Évaluation des collisions/échouages', 'Évaluation des collisions/échouages', 'Recensement et suivi des points de collisions faune / infrastructure linéaire de transport. On met également dans cette rubrique les suivis d’échouages d’animaux marins (tortues, cétacés...)', 'SINP', 'Validé', 0, '114.019', '2017-11-02 00:00:00', NULL, true)
,(461, 114, '5.1', 'Suivi individus centré', 'Suivi individus centré', 'Travaux, généralement dans le domaine de la recherche, visant à étudier le comportement à l’échelle d’un individu : dispersion, trajectoire de déplacement, trajectoire migratoire, occupation de l’espace à différentes périodes... etc.', 'SINP', 'Validé', 0, '114.020', '2017-11-02 00:00:00', NULL, true)
,(462, 114, '5.2', 'Surveillance temporelle d''espèces', 'Surveillance temporelle d''espèces', 'Cette catégorie comprend uniquement des données obtenues selon un protocole répété dans le temps qui vise à fournir une image fiable de l’évolution des variables mesurées à l’échelle d’une population, d’une espèce ou de plusieurs espèces mais qui ne constituent pas une communauté en interaction. Elle concerne une échelle généralement assez vaste (réseaux de sites, département à national), un échantillonnage généralement représentatif, exhaustif ou régulier et ne vise pas directement à tester une hypothèse avec manipulation (si c’est le cas, catégorie 5.). Les cas de répétition d’atlas permettant in fine de mesurer des changements de distribution entrent dans la catégorie 1.2', 'SINP', 'Validé', 0, '114.021', '2017-11-02 00:00:00', NULL, true)
,(463, 114, '5.3', 'Surveillance communauté d’espèces', 'Surveillance communauté d’espèces', 'Cette catégorie comprend uniquement des données obtenues selon un protocole de relevés d’espèces en interaction répétés dans le temps, qui vise à fournir une image fiable de l’évolution dans le temps des variables mesurées concernant une communauté d’espèces, éventuellement rattachée à un type d’habitat. Elle concerne une échelle assez vaste (réseaux de sites, département à national), un échantillonnage généralement représentatif, exhaustif ou régulier et ne vise pas directement à tester une hypothèse avec manipulation (si c’est le cas, catégorie 6.2 ou 6.3)', 'SINP', 'Validé', 0, '114.022', '2017-11-02 00:00:00', NULL, true)
,(464, 114, '5.4', 'Surveillance des habitats', 'Surveillance des habitats', 'Cette catégorie comprend uniquement des données obtenues selon un protocole répété dans le temps qui vise à fournir une image fiable de l’évolution dans le temps de la présence et/ou surface d’un habitat au sens large (végétation, écosystème...). Elle concerne une échelle généralement assez vaste (réseaux de sites, département à national), un échantillonnage généralement représentatif, exhaustif ou régulier et ne vise pas directement à tester une hypothèse avec manipulation (si c’est le cas, catégorie 6.2). Les relevés de communauté d’espèces (généralement végétation/relevés phytosociologiques ou benthos pour les habitats marins) réalisé pour la surveillance entrent dans ce cadre. Si seuls des relevés sont effectués (sans détermination du type de végétation ou habitat), il faut affecter à la rubrique précédente', 'SINP', 'Validé', 0, '114.023', '2017-11-02 00:00:00', NULL, true)
,(465, 114, '5.5', 'Surveillance de pathogènes et EEE', 'Surveillance de pathogènes et EEE', 'Dispositifs dédiés à détecter la présence (ou l’abondance...) et suivre l’évolution d’espèces ayant un impact négatif sur l’agriculture, la sylviculture, la santé ou la biodiversité... Participatifs ou professionnels, enquêtes... Les observations connexes de ces protocoles entrent aussi dans cette catégorie mais devraient idéalement faire l’objet d’un autre jeu de données. Les suivis des espèces dites « nuisibles » entrent dans cette catégorie', 'SINP', 'Validé', 0, '114.024', '2017-11-02 00:00:00', NULL, true)
,(466, 114, '6.1', 'Surveillance site', 'Surveillance site', 'Il s’agit des dispositifs de surveillance/ veille dans le temps pour détecter sans a priori des changements des variables mesurées (abondance d’une population d’espèce à enjeux, traits des individus, indice d’abondance, taux d’occupation, traits et autres métriques de communauté d’espèces, surface d’occupation de végétations-habitats-écosystèmes...). Elle concerne une échelle locale (site ou réseau de sites pré-déterminés – réseaux de réserves etc.). Ne vise pas directement à tester une hypothèse avec manipulation (si c’est le cas, catégorie 6.2). Design expérimental : série temporelle', 'SINP', 'Validé', 0, '114.025', '2017-11-02 00:00:00', NULL, true)
,(467, 114, '6.2', 'Suivis de gestion ou expérimental', 'Suivis de gestion ou expérimental', 'Suivi dans le temps (avant/ après, avec éventuellement des contrôles) couplant des espèces ou communautés, des végétations-habitats-écosystèmes, et une action de gestion (y compris la non intervention) ou d’une pression afin d’en déterminer l’effet. Généralement dans un cadre d’espace naturel ou de la restauration ou encore pour la compensation (vérification d’un gain dans le temps) voir des travaux de recherche. Concerne généralement un site ou un réseau de sites. Design expérimental : B/A (before/after) et BACI (before/after control/impact) Un éventuel dispositif adaptatif à large échelle entrerait dans cette catégorie', 'SINP', 'Validé', 0, '114.026', '2017-11-02 00:00:00', NULL, true)
,(468, 114, '6.3', 'Étude effet gestion', 'Étude effet gestion', 'Étude des effets de la gestion (ou de pression, ou non gestion etc.) sur des espèces ou communautés, des végétations-habitats-écosystèmes, avec une substitution espace/temps. C’est-à-dire que l’effet est mesuré uniquement à un temps t, en comparant différents historiques de gestions mais sans mesure avant/après (si avant/après : 6.2). Design expérimental : C/I (control/ impact)', 'SINP', 'Validé', 0, '114.027', '2017-11-02 00:00:00', NULL, true)
,(469, 114, '6.4', 'Suivis réglementaires', 'Suivis réglementaires', 'Il s’agit des suivis temporels visant à suivre les impacts après implantation d’un ouvrage, imposés par la loi ou lors de l’autorisation de réalisation des travaux. Par exemples les suivis de mortalité des oiseaux et chiroptères après mise en place d’un parc éolien. Les suivis réglementaires dans le cadre de compensations entrent aussi dans cette catégorie', 'SINP', 'Validé', 0, '114.028', '2017-11-02 00:00:00', NULL, true)
,(470, 114, '7.1', 'Regroupement de données', 'Regroupement de données', 'Catégorie à utiliser quand le jeu de données mélange divers types de données, sans métadonnées permettant pour l’instant de les séparer en jeux de données plus précis et plus cohérents. On peut inclure ici les CA et JDD constitué par des regroupements de Données Elémentaires d''Echange (DEE) pour réaliser un atlas, uniquement quand l’objectif original de collecte des données n’est pas déterminable. Lorsqu’on ne dispose pas d’information sur les raisons de l’acquisition des données, cette rubrique doit être utilisée', 'SINP', 'Validé', 0, '114.029', '2017-11-02 00:00:00', NULL, true)
,(471, 114, '7.2', 'Autres études et programmes', 'Autres études et programmes', 'Cas n’entrant pas clairement dans les autres rubriques. Dans ce cas les métadonnées (champ libres « description » et « protocole » des fiches de métadonnées) devront bien expliquer en quoi consiste le but de l’acquisition des données', 'SINP', 'Validé', 0, '114.030', '2017-11-02 00:00:00', NULL, true)
,(474, 116, 'CHI', 'Site chiroptère', 'Site chiroptère', 'Site pour le suivi des chiroptères', 'GEONATURE', 'Non validé', 0, '116.001', '2018-03-13 00:00:00', NULL, true)
,(475, 116, '1', 'Grotte', 'Grotte', 'Site chiroptères de type grotte', 'GEONATURE', 'Non validé', 116, '116.001.001', '2018-03-13 00:00:00', NULL, true)
,(476, 116, '2', 'Mine', 'Mine', 'Site chiroptères de type mine', 'GEONATURE', 'Non validé', 116, '116.001.002', '2018-03-13 00:00:00', NULL, true)
,(477, 116, '3', 'Bâti', 'Bâti', 'Site chiroptères de type bâti', 'GEONATURE', 'Non validé', 116, '116.001.003', '2018-03-13 00:00:00', NULL, true)
,(478, 116, '4', 'Arbre', 'Arbre', 'Site chiroptères de type arbre', 'GEONATURE', 'Non validé', 116, '116.001.004', '2018-03-13 00:00:00', NULL, true)
,(479, 116, '5', 'Rocher', 'Rocher', 'Site chiroptères de type rocher', 'GEONATURE', 'Non validé', 116, '116.001.005', '2018-03-13 00:00:00', NULL, true)
,(480, 116, '6', 'Hors gîte', 'Hors gîte', 'Site chiroptères de type hors gîte', 'GEONATURE', 'Non validé', 116, '116.001.006', '2018-03-13 00:00:00', NULL, true)
,(481, 116, '7', 'Indéterminé', 'Indéterminé', 'Site chiroptères de type indéterminé', 'GEONATURE', 'Non validé', 116, '116.001.007', '2018-03-13 00:00:00', NULL, true)
--next 482
;
SELECT pg_catalog.setval('t_nomenclatures_id_nomenclature_seq', 482, true);

UPDATE t_nomenclatures SET label_default = label_MYDEFAULTLANGUAGE;
UPDATE t_nomenclatures SET definition_default = definition_MYDEFAULTLANGUAGE;
ALTER TABLE t_nomenclatures ALTER COLUMN label_default SET NOT NULL;
ALTER TABLE t_nomenclatures ALTER COLUMN label_MYDEFAULTLANGUAGE SET NOT NULL;

-- inserting organism représenting all organisms with 0 as id_organisme
DO
$$
BEGIN
INSERT INTO utilisateurs.bib_organismes (nom_organisme, adresse_organisme, cp_organisme, ville_organisme, tel_organisme, fax_organisme, email_organisme, id_organisme) VALUES ('ALL', 'Représente tous les organismes', NULL, NULL, NULL, NULL, NULL, 0);
EXCEPTION WHEN unique_violation  THEN
        RAISE NOTICE 'Tentative d''insertion de valeur existante. L''instruction a été ignorée.';
END
$$;

INSERT INTO ref_nomenclatures.defaults_nomenclatures_value (id_type, id_organism, id_nomenclature) VALUES
(2,0,80)
,(19,0,76)
,(103,0,353)
,(102,0,351)
,(114,0,442)
,(115,0,430)
,(107,0,382)
,(111,0,417)
;

TRUNCATE TABLE cor_taxref_nomenclature;
----------------------------
--OBSERVATION TECHNIQUES--
----------------------------
INSERT INTO cor_taxref_nomenclature VALUES
(211, 'Animalia', 'Oiseaux', now(), NULL)
,(212, 'Animalia', 'Oiseaux', now(), NULL)
,(221, 'Animalia', 'Oiseaux', now(), NULL)
,(223, 'Animalia', 'Oiseaux', now(), NULL)
,(228, 'Animalia', 'Oiseaux', now(), NULL)
,(230, 'Animalia', 'Oiseaux', now(), NULL)
,(234, 'Animalia', 'Oiseaux', now(), NULL)
,(236, 'Animalia', 'Oiseaux', now(), NULL)
,(238, 'Animalia', 'Oiseaux', now(), NULL)
,(255, 'Animalia', 'Oiseaux', now(), NULL)
,(261, 'Animalia', 'Oiseaux', now(), NULL)
,(267, 'Animalia', 'Oiseaux', now(), NULL)
,(268, 'Animalia', 'Oiseaux', now(), NULL)
,(269, 'Animalia', 'Oiseaux', now(), NULL)
,(273, 'Animalia', 'Oiseaux', now(), NULL)
,(274, 'Animalia', 'Oiseaux', now(), NULL)
,(276, 'Animalia', 'Oiseaux', now(), NULL)
,(277, 'Animalia', 'Oiseaux', now(), NULL)
,(278, 'Animalia', 'Oiseaux', now(), NULL)
,(279, 'Animalia', 'Oiseaux', now(), NULL)
,(287, 'Animalia', 'Insectes', now(), NULL)
,(289, 'Animalia', 'Insectes', now(), NULL)
,(290, 'Animalia', 'Insectes', now(), NULL)
,(291, 'Animalia', 'Insectes', now(), NULL)
,(292, 'Animalia', 'Insectes', now(), NULL)
,(293, 'Animalia', 'Insectes', now(), NULL)
,(294, 'Animalia', 'Insectes', now(), NULL)
,(295, 'Animalia', 'Insectes', now(), NULL)
,(211, 'Animalia', 'Insectes', now(), NULL)
,(212, 'Animalia', 'Insectes', now(), NULL)
,(214, 'Animalia', 'Insectes', now(), NULL)
,(215, 'Animalia', 'Insectes', now(), NULL)
,(216, 'Animalia', 'Insectes', now(), NULL)
,(218, 'Animalia', 'Insectes', now(), NULL)
,(220, 'Animalia', 'Insectes', now(), NULL)
,(222, 'Animalia', 'Insectes', now(), NULL)
,(223, 'Animalia', 'Insectes', now(), NULL)
,(224, 'Animalia', 'Insectes', now(), NULL)
,(225, 'Animalia', 'Insectes', now(), NULL)
,(226, 'Animalia', 'Insectes', now(), NULL)
,(227, 'Animalia', 'Insectes', now(), NULL)
,(228, 'Animalia', 'Insectes', now(), NULL)
,(229, 'Animalia', 'Insectes', now(), NULL)
,(231, 'Animalia', 'Insectes', now(), NULL)
,(232, 'Animalia', 'Insectes', now(), NULL)
,(233, 'Animalia', 'Insectes', now(), NULL)
,(234, 'Animalia', 'Insectes', now(), NULL)
,(236, 'Animalia', 'Insectes', now(), NULL)
,(238, 'Animalia', 'Insectes', now(), NULL)
,(242, 'Animalia', 'Insectes', now(), NULL)
,(243, 'Animalia', 'Insectes', now(), NULL)
,(244, 'Animalia', 'Insectes', now(), NULL)
,(245, 'Animalia', 'Insectes', now(), NULL)
,(246, 'Animalia', 'Insectes', now(), NULL)
,(248, 'Animalia', 'Insectes', now(), NULL)
,(249, 'Animalia', 'Insectes', now(), NULL)
,(250, 'Animalia', 'Insectes', now(), NULL)
,(251, 'Animalia', 'Insectes', now(), NULL)
,(255, 'Animalia', 'Insectes', now(), NULL)
,(257, 'Animalia', 'Insectes', now(), NULL)
,(258, 'Animalia', 'Insectes', now(), NULL)
,(259, 'Animalia', 'Insectes', now(), NULL)
,(260, 'Animalia', 'Insectes', now(), NULL)
,(261, 'Animalia', 'Insectes', now(), NULL)
,(262, 'Animalia', 'Insectes', now(), NULL)
,(263, 'Animalia', 'Insectes', now(), NULL)
,(264, 'Animalia', 'Insectes', now(), NULL)
,(265, 'Animalia', 'Insectes', now(), NULL)
,(266, 'Animalia', 'Insectes', now(), NULL)
,(267, 'Animalia', 'Insectes', now(), NULL)
,(269, 'Animalia', 'Insectes', now(), NULL)
,(270, 'Animalia', 'Insectes', now(), NULL)
,(272, 'Animalia', 'Insectes', now(), NULL)
,(279, 'Animalia', 'Insectes', now(), NULL)
,(282, 'Animalia', 'Insectes', now(), NULL)
,(286, 'Animalia', 'Insectes', now(), NULL)
,(296, 'Animalia', 'Insectes', now(), NULL)
,(297, 'Animalia', 'Insectes', now(), NULL)
,(299, 'Animalia', 'Insectes', now(), NULL)
,(300, 'Animalia', 'Insectes', now(), NULL)
,(301, 'Animalia', 'Insectes', now(), NULL)
,(302, 'Animalia', 'Insectes', now(), NULL)
,(303, 'Animalia', 'Insectes', now(), NULL)
,(304, 'Animalia', 'Insectes', now(), NULL)
,(305, 'Animalia', 'Insectes', now(), NULL)
,(306, 'Animalia', 'Insectes', now(), NULL)
,(307, 'Animalia', 'Insectes', now(), NULL)
,(308, 'Animalia', 'Insectes', now(), NULL)
,(309, 'Animalia', 'Insectes', now(), NULL)
,(310, 'Animalia', 'Insectes', now(), NULL)
,(311, 'Animalia', 'Insectes', now(), NULL)
,(312, 'Animalia', 'Insectes', now(), NULL)
,(313, 'Animalia', 'Insectes', now(), NULL)
,(314, 'Animalia', 'Insectes', now(), NULL)
,(315, 'Animalia', 'Insectes', now(), NULL)
,(316, 'Animalia', 'Insectes', now(), NULL)
,(317, 'Animalia', 'Insectes', now(), NULL)
,(318, 'Animalia', 'Insectes', now(), NULL)
,(319, 'Animalia', 'Insectes', now(), NULL)
,(320, 'Animalia', 'Insectes', now(), NULL)
,(325, 'Animalia', 'Insectes', now(), NULL)
,(326, 'Animalia', 'Insectes', now(), NULL)
,(327, 'Animalia', 'Insectes', now(), NULL)
,(328, 'Animalia', 'Insectes', now(), NULL)
,(329, 'Animalia', 'Insectes', now(), NULL)
,(330, 'Animalia', 'Insectes', now(), NULL)
,(331, 'Animalia', 'Insectes', now(), NULL)
,(332, 'Animalia', 'Insectes', now(), NULL)
,(341, 'Animalia', 'Insectes', now(), NULL)
,(342, 'Animalia', 'Insectes', now(), NULL)
,(343, 'all', 'all', now(), NULL)
,(287, 'Animalia', 'Amphibiens', now(), NULL)
,(295, 'Animalia', 'Amphibiens', now(), NULL)
,(211, 'Animalia', 'Amphibiens', now(), NULL)
,(223, 'Animalia', 'Amphibiens', now(), NULL)
,(225, 'Animalia', 'Amphibiens', now(), NULL)
,(226, 'Animalia', 'Amphibiens', now(), NULL)
,(232, 'Animalia', 'Amphibiens', now(), NULL)
,(234, 'Animalia', 'Amphibiens', now(), NULL)
,(235, 'Animalia', 'Amphibiens', now(), NULL)
,(236, 'Animalia', 'Amphibiens', now(), NULL)
,(237, 'Animalia', 'Amphibiens', now(), NULL)
,(238, 'Animalia', 'Amphibiens', now(), NULL)
,(253, 'Animalia', 'Amphibiens', now(), NULL)
,(255, 'Animalia', 'Amphibiens', now(), NULL)
,(256, 'Animalia', 'Amphibiens', now(), NULL)
,(258, 'Animalia', 'Amphibiens', now(), NULL)
,(261, 'Animalia', 'Amphibiens', now(), NULL)
,(267, 'Animalia', 'Amphibiens', now(), NULL)
,(268, 'Animalia', 'Amphibiens', now(), NULL)
,(269, 'Animalia', 'Amphibiens', now(), NULL)
,(270, 'Animalia', 'Amphibiens', now(), NULL)
,(273, 'Animalia', 'Amphibiens', now(), NULL)
,(274, 'Animalia', 'Amphibiens', now(), NULL)
,(275, 'Animalia', 'Amphibiens', now(), NULL)
,(276, 'Animalia', 'Amphibiens', now(), NULL)
,(277, 'Animalia', 'Amphibiens', now(), NULL)
,(278, 'Animalia', 'Amphibiens', now(), NULL)
,(279, 'Animalia', 'Amphibiens', now(), NULL)
,(282, 'Animalia', 'Amphibiens', now(), NULL)
,(283, 'Animalia', 'Amphibiens', now(), NULL)
,(285, 'Animalia', 'Amphibiens', now(), NULL)
,(298, 'Animalia', 'Amphibiens', now(), NULL)
,(321, 'Animalia', 'Amphibiens', now(), NULL)
,(322, 'Animalia', 'Amphibiens', now(), NULL)
,(323, 'Animalia', 'Amphibiens', now(), NULL)
,(324, 'Animalia', 'Amphibiens', now(), NULL)
,(333, 'Animalia', 'Amphibiens', now(), NULL)
,(341, 'Animalia', 'Amphibiens', now(), NULL)
,(287, 'Animalia', 'Reptiles', now(), NULL)
,(295, 'Animalia', 'Reptiles', now(), NULL)
,(211, 'Animalia', 'Reptiles', now(), NULL)
,(223, 'Animalia', 'Reptiles', now(), NULL)
,(225, 'Animalia', 'Reptiles', now(), NULL)
,(226, 'Animalia', 'Reptiles', now(), NULL)
,(232, 'Animalia', 'Reptiles', now(), NULL)
,(234, 'Animalia', 'Reptiles', now(), NULL)
,(235, 'Animalia', 'Reptiles', now(), NULL)
,(236, 'Animalia', 'Reptiles', now(), NULL)
,(237, 'Animalia', 'Reptiles', now(), NULL)
,(238, 'Animalia', 'Reptiles', now(), NULL)
,(253, 'Animalia', 'Reptiles', now(), NULL)
,(255, 'Animalia', 'Reptiles', now(), NULL)
,(256, 'Animalia', 'Reptiles', now(), NULL)
,(258, 'Animalia', 'Reptiles', now(), NULL)
,(261, 'Animalia', 'Reptiles', now(), NULL)
,(267, 'Animalia', 'Reptiles', now(), NULL)
,(268, 'Animalia', 'Reptiles', now(), NULL)
,(269, 'Animalia', 'Reptiles', now(), NULL)
,(270, 'Animalia', 'Reptiles', now(), NULL)
,(273, 'Animalia', 'Reptiles', now(), NULL)
,(274, 'Animalia', 'Reptiles', now(), NULL)
,(275, 'Animalia', 'Reptiles', now(), NULL)
,(276, 'Animalia', 'Reptiles', now(), NULL)
,(277, 'Animalia', 'Reptiles', now(), NULL)
,(278, 'Animalia', 'Reptiles', now(), NULL)
,(279, 'Animalia', 'Reptiles', now(), NULL)
,(282, 'Animalia', 'Reptiles', now(), NULL)
,(283, 'Animalia', 'Reptiles', now(), NULL)
,(285, 'Animalia', 'Reptiles', now(), NULL)
,(298, 'Animalia', 'Reptiles', now(), NULL)
,(321, 'Animalia', 'Reptiles', now(), NULL)
,(322, 'Animalia', 'Reptiles', now(), NULL)
,(323, 'Animalia', 'Reptiles', now(), NULL)
,(324, 'Animalia', 'Reptiles', now(), NULL)
,(333, 'Animalia', 'Reptiles', now(), NULL)
,(341, 'Animalia', 'Reptiles', now(), NULL)
,(211, 'Plantae', 'all', now(), NULL)
,(213, 'Plantae', 'all', now(), NULL)
,(239, 'Plantae', 'all', now(), NULL)
,(241, 'Plantae', 'all', now(), NULL)
,(242, 'Plantae', 'all', now(), NULL)
,(243, 'Plantae', 'all', now(), NULL)
,(244, 'Plantae', 'all', now(), NULL)
,(245, 'Plantae', 'all', now(), NULL)
,(247, 'Plantae', 'all', now(), NULL)
,(248, 'Plantae', 'all', now(), NULL)
,(251, 'Plantae', 'all', now(), NULL)
,(252, 'Plantae', 'all', now(), NULL)
,(255, 'Plantae', 'all', now(), NULL)
,(268, 'Plantae', 'all', now(), NULL)
,(269, 'Plantae', 'all', now(), NULL)
,(273, 'Plantae', 'all', now(), NULL)
,(274, 'Plantae', 'all', now(), NULL)
,(275, 'Plantae', 'all', now(), NULL)
,(276, 'Plantae', 'all', now(), NULL)
,(278, 'Plantae', 'all', now(), NULL)
,(279, 'Plantae', 'all', now(), NULL)
,(339, 'Plantae', 'all', now(), NULL)
,(340, 'Plantae', 'all', now(), NULL)
,(211, 'Fungi', 'all', now(), NULL)
,(218, 'Fungi', 'all', now(), NULL)
,(233, 'Fungi', 'all', now(), NULL)
,(246, 'Fungi', 'all', now(), NULL)
,(269, 'Fungi', 'all', now(), NULL)
,(279, 'Fungi', 'all', now(), NULL)
,(341, 'Fungi', 'all', now(), NULL)
,(211, 'Animalia', 'Mammifères', now(), NULL)
,(212, 'Animalia', 'Mammifères', now(), NULL)
,(217, 'Animalia', 'Mammifères', now(), NULL)
,(219, 'Animalia', 'Mammifères', now(), NULL)
,(221, 'Animalia', 'Mammifères', now(), NULL)
,(223, 'Animalia', 'Mammifères', now(), NULL)
,(231, 'Animalia', 'Mammifères', now(), NULL)
,(234, 'Animalia', 'Mammifères', now(), NULL)
,(236, 'Animalia', 'Mammifères', now(), NULL)
,(238, 'Animalia', 'Mammifères', now(), NULL)
,(255, 'Animalia', 'Mammifères', now(), NULL)
,(267, 'Animalia', 'Mammifères', now(), NULL)
,(268, 'Animalia', 'Mammifères', now(), NULL)
,(269, 'Animalia', 'Mammifères', now(), NULL)
,(270, 'Animalia', 'Mammifères', now(), NULL)
,(271, 'Animalia', 'Mammifères', now(), NULL)
,(273, 'Animalia', 'Mammifères', now(), NULL)
,(274, 'Animalia', 'Mammifères', now(), NULL)
,(275, 'Animalia', 'Mammifères', now(), NULL)
,(276, 'Animalia', 'Mammifères', now(), NULL)
,(277, 'Animalia', 'Mammifères', now(), NULL)
,(278, 'Animalia', 'Mammifères', now(), NULL)
,(279, 'Animalia', 'Mammifères', now(), NULL)
,(283, 'Animalia', 'Mammifères', now(), NULL)
,(298, 'Animalia', 'Mammifères', now(), NULL)
,(334, 'Animalia', 'Mammifères', now(), NULL)
,(335, 'Animalia', 'Mammifères', now(), NULL)
,(337, 'Animalia', 'Mammifères', now(), NULL)
,(338, 'Animalia', 'Mammifères', now(), NULL)
,(341, 'Animalia', 'Mammifères', now(), NULL)
,(287, 'Animalia', 'Poissons', now(), NULL)
,(288, 'Animalia', 'Poissons', now(), NULL)
,(211, 'Animalia', 'Poissons', now(), NULL)
,(223, 'Animalia', 'Poissons', now(), NULL)
,(232, 'Animalia', 'Poissons', now(), NULL)
,(240, 'Animalia', 'Poissons', now(), NULL)
,(247, 'Animalia', 'Poissons', now(), NULL)
,(248, 'Animalia', 'Poissons', now(), NULL)
,(255, 'Animalia', 'Poissons', now(), NULL)
,(258, 'Animalia', 'Poissons', now(), NULL)
,(261, 'Animalia', 'Poissons', now(), NULL)
,(268, 'Animalia', 'Poissons', now(), NULL)
,(273, 'Animalia', 'Poissons', now(), NULL)
,(274, 'Animalia', 'Poissons', now(), NULL)
,(275, 'Animalia', 'Poissons', now(), NULL)
,(276, 'Animalia', 'Poissons', now(), NULL)
,(277, 'Animalia', 'Poissons', now(), NULL)
,(278, 'Animalia', 'Poissons', now(), NULL)
,(279, 'Animalia', 'Poissons', now(), NULL)
,(281, 'Animalia', 'Poissons', now(), NULL)
,(282, 'Animalia', 'Poissons', now(), NULL)
,(283, 'Animalia', 'Poissons', now(), NULL)
,(284, 'Animalia', 'Poissons', now(), NULL)
,(285, 'Animalia', 'Poissons', now(), NULL)
,(286, 'Animalia', 'Poissons', now(), NULL)
,(321, 'Animalia', 'Poissons', now(), NULL)
,(322, 'Animalia', 'Poissons', now(), NULL)

-----------------
--LIFE STAGES--
-----------------
,(2, 'all', 'all', now(), NULL)
,(3, 'all', 'all', now(), NULL)
,(20, 'Plantae', 'all', now(), NULL)
,(21, 'Plantae', 'all', now(), NULL)
,(22, 'Plantae', 'all', now(), NULL)
,(24, 'Plantae', 'all', now(), NULL)
,(25, 'Plantae', 'all', now(), NULL)
,(26, 'Plantae', 'all', now(), NULL)

--TODO : "Acanthocéphales"

,(11, 'Animalia', 'Bivalves', now(), NULL)
,(8, 'Animalia', 'Bivalves', now(), NULL)
,(5, 'Animalia', 'Bivalves', now(), NULL)
,(4, 'Animalia', 'Bivalves', now(), NULL)

--TODO : "Céphalopodes"

,(11, 'Animalia', 'Insectes', now(), NULL)
,(8, 'Animalia', 'Insectes', now(), NULL)
,(9, 'Animalia', 'Insectes', now(), NULL)
,(12, 'Animalia', 'Insectes', now(), NULL)
,(13, 'Animalia', 'Insectes', now(), NULL)
,(14, 'Animalia', 'Insectes', now(), NULL)
,(15, 'Animalia', 'Insectes', now(), NULL)
,(16, 'Animalia', 'Insectes', now(), NULL)
,(17, 'Animalia', 'Insectes', now(), NULL)
,(18, 'Animalia', 'Insectes', now(), NULL)

,(11, 'Animalia', 'Reptiles', now(), NULL)
,(28, 'Animalia', 'Reptiles', now(), NULL)
,(5, 'Animalia', 'Reptiles', now(), NULL)
,(6, 'Animalia', 'Reptiles', now(), NULL)
,(12, 'Animalia', 'Reptiles', now(), NULL)
,(4, 'Animalia', 'Reptiles', now(), NULL)

,(11, 'Animalia', 'Crustacés', now(), NULL)
,(8, 'Animalia', 'Crustacés', now(), NULL)
,(28, 'Animalia', 'Crustacés', now(), NULL)
,(5, 'Animalia', 'Crustacés', now(), NULL)
,(7, 'Animalia', 'Crustacés', now(), NULL)
,(4, 'Animalia', 'Crustacés', now(), NULL)

--TODO : "Scléractiniaires"

--TODO : "Hydrozoaires"

,(11, 'Animalia', 'Oiseaux', now(), NULL)
,(27, 'Animalia', 'Oiseaux', now(), NULL)
,(5, 'Animalia', 'Oiseaux', now(), NULL)
,(6, 'Animalia', 'Oiseaux', now(), NULL)
,(7, 'Animalia', 'Oiseaux', now(), NULL)
,(4, 'Animalia', 'Oiseaux', now(), NULL)
,(12, 'Animalia', 'Oiseaux', now(), NULL)

,(11, 'Animalia', 'Poissons', now(), NULL)
,(27, 'Animalia', 'Poissons', now(), NULL)
,(19, 'Animalia', 'Poissons', now(), NULL)
,(6, 'Animalia', 'Poissons', now(), NULL)
,(7, 'Animalia', 'Poissons', now(), NULL)
,(4, 'Animalia', 'Poissons', now(), NULL)

--TODO : "Némertes"

,(11, 'Animalia', 'Arachnides', now(), NULL)
,(5, 'Animalia', 'Arachnides', now(), NULL)
,(12, 'Animalia', 'Arachnides', now(), NULL)
,(4, 'Animalia', 'Arachnides', now(), NULL)

,(11, 'Animalia', 'Gastéropodes', now(), NULL)
,(5, 'Animalia', 'Gastéropodes', now(), NULL)
,(4, 'Animalia', 'Gastéropodes', now(), NULL)
--A compléter : Gastéropodes

,(11, 'Animalia', 'Amphibiens', now(), NULL)
,(27, 'Animalia', 'Amphibiens', now(), NULL)
,(8, 'Animalia', 'Amphibiens', now(), NULL)
,(10, 'Animalia', 'Amphibiens', now(), NULL)
,(28, 'Animalia', 'Amphibiens', now(), NULL)
,(4, 'Animalia', 'Amphibiens', now(), NULL)

--TODO : "Octocoralliaires"
--TODO : "Entognathes"
--TODO : "Annélides"
--TODO : "Pycnogonides"
--TODO : "Nématodes"

,(5, 'Animalia', 'Mammifères', now(), NULL)
,(6, 'Animalia', 'Mammifères', now(), NULL)
,(7, 'Animalia', 'Mammifères', now(), NULL)
,(4, 'Animalia', 'Mammifères', now(), NULL)
,(12, 'Animalia', 'Mammifères', now(), NULL)

-- TODO : "Ascidies"
-- TODO : "Myriapodes"
-- TODO : "Plathelminthes"

-- TODO : "Bacteria"

-- TODO : "Chromista"

-- TODO : "Fungi"

-- TODO : "Protozoa"

-------
--SEX--
-------
,(188, 'all', 'all', now(), NULL)
,(189, 'all', 'all', now(), NULL)
,(194, 'all', 'all', now(), NULL)

,(193, 'Plantae', 'all', now(), NULL)
,(193, 'Animalia', 'all', now(), NULL)

,(190, 'Plantae', 'all', now(), NULL)
,(191, 'Plantae', 'all', now(), NULL)
,(192, 'Plantae', 'all', now(), NULL)

,(190, 'Animalia', 'Bivalves', now(), NULL)
,(191, 'Animalia', 'Bivalves', now(), NULL)
,(192, 'Animalia', 'Bivalves', now(), NULL)

,(190, 'Animalia', 'Insectes', now(), NULL)
,(191, 'Animalia', 'Insectes', now(), NULL)

--TODO : "Acanthocéphales"

,(190, 'Animalia', 'Céphalopodes', now(), NULL)
,(191, 'Animalia', 'Céphalopodes', now(), NULL)

,(190, 'Animalia', 'Reptiles', now(), NULL)
,(191, 'Animalia', 'Reptiles', now(), NULL)

,(190, 'Animalia', 'Crustacés', now(), NULL)
,(191, 'Animalia', 'Crustacés', now(), NULL)

--TODO : "Scléractiniaires"

--TODO : "Hydrozoaires"

,(190, 'Animalia', 'Oiseaux', now(), NULL)
,(191, 'Animalia', 'Oiseaux', now(), NULL)

,(190, 'Animalia', 'Poissons', now(), NULL)
,(191, 'Animalia', 'Poissons', now(), NULL)

--TODO : "Némertes"

,(190, 'Animalia', 'Arachnides', now(), NULL)
,(191, 'Animalia', 'Arachnides', now(), NULL)

,(190, 'Animalia', 'Gastéropodes', now(), NULL)
,(191, 'Animalia', 'Gastéropodes', now(), NULL)
,(192, 'Animalia', 'Gastéropodes', now(), NULL)

,(190, 'Animalia', 'Amphibiens', now(), NULL)
,(191, 'Animalia', 'Amphibiens', now(), NULL)

--TODO : "Octocoralliaires"
--TODO : "Entognathes"

,(190, 'Animalia', 'Annélides', now(), NULL)
,(191, 'Animalia', 'Annélides', now(), NULL)
,(192, 'Animalia', 'Annélides', now(), NULL)


--TODO : "Pycnogonides"
--TODO : "Nématodes"

,(190, 'Animalia', 'Mammifères', now(), NULL)
,(191, 'Animalia', 'Mammifères', now(), NULL)

--TODO : "Ascidies"

,(190, 'Animalia', 'Myriapodes', now(), NULL)
,(191, 'Animalia', 'Myriapodes', now(), NULL)

,(190, 'Animalia', 'Plathelminthes', now(), NULL)
,(191, 'Animalia', 'Plathelminthes', now(), NULL)
,(192, 'Animalia', 'Plathelminthes', now(), NULL)


--TODO : "Fungi" à priori il n'y a pas de notion de sexe chez les champignons. Au mieux de polarité + et -.

--TODO : "Bacteria"

-- TODO : "Chromista"

-- TODO : "Protozoa"


-----------------------
--OBSERVATION METHODS--
-----------------------
,(42, 'all', 'all', now(), NULL)
,(61, 'all', 'all', now(), NULL)
,(62, 'all', 'all', now(), NULL)
,(63, 'all', 'all', now(), NULL)

,(57, 'Plantae', 'all', now(), NULL)
,(58, 'Plantae', 'all', now(), NULL)
,(60, 'Plantae', 'all', now(), NULL)

,(56, 'Plantae', 'Angiospermes', now(), NULL)
,(59, 'Plantae', 'Angiospermes', now(), NULL)

,(56, 'Plantae', 'Gymnospermes', now(), NULL)
,(59, 'Plantae', 'Gymnospermes', now(), NULL)

,(55, 'Plantae', 'Fougères', now(), NULL)

--TODO : "Algues vertes"
--TODO : "Algues rouges"

,(55, 'Plantae', 'Mousses', now(), NULL)
,(55, 'Plantae', 'Hépatiques et Anthocérotes', now(), NULL)

,(55, 'Fungi', 'all', now(), NULL)

--TODO : "Bacteria"
--TODO : "Chromista"
--TODO : "Protozoa"

--Aucun critère spécifique identifié pour les bivalves

,(43, 'Animalia', 'Insectes', now(), NULL)
,(45, 'Animalia', 'Insectes', now(), NULL)
,(47, 'Animalia', 'Insectes', now(), NULL)
,(48, 'Animalia', 'Insectes', now(), NULL)
,(49, 'Animalia', 'Insectes', now(), NULL)
,(50, 'Animalia', 'Insectes', now(), NULL)
,(52, 'Animalia', 'Insectes', now(), NULL)
,(53, 'Animalia', 'Insectes', now(), NULL)
,(64, 'Animalia', 'Insectes', now(), NULL)
,(65, 'Animalia', 'Insectes', now(), NULL)
,(66, 'Animalia', 'Insectes', now(), NULL)
,(67, 'Animalia', 'Insectes', now(), NULL)

--Aucun critère spécifique identifié pour les acanthocéphales
--Aucun critère spécifique identifié pour les céphalopodes

,(44, 'Animalia', 'Reptiles', now(), NULL)
,(46, 'Animalia', 'Reptiles', now(), NULL)
,(49, 'Animalia', 'Reptiles', now(), NULL)
,(52, 'Animalia', 'Reptiles', now(), NULL)

,(49, 'Animalia', 'Crustacés', now(), NULL)
,(52, 'Animalia', 'Crustacés', now(), NULL)

--TODO : "Scléractiniaires"
--TODO : "Hydrozoaires"

,(43, 'Animalia', 'Oiseaux', now(), NULL)
,(44, 'Animalia', 'Oiseaux', now(), NULL)
,(46, 'Animalia', 'Oiseaux', now(), NULL)
,(48, 'Animalia', 'Oiseaux', now(), NULL)
,(49, 'Animalia', 'Oiseaux', now(), NULL)
,(50, 'Animalia', 'Oiseaux', now(), NULL)
,(51, 'Animalia', 'Oiseaux', now(), NULL)
,(52, 'Animalia', 'Oiseaux', now(), NULL)
,(53, 'Animalia', 'Oiseaux', now(), NULL)
,(54, 'Animalia', 'Oiseaux', now(), NULL)
,(67, 'Animalia', 'Oiseaux', now(), NULL)

,(52, 'Animalia', 'Poissons', now(), NULL)

--TODO : "Némertes"

,(49, 'Animalia', 'Arachnides', now(), NULL)
,(53, 'Animalia', 'Arachnides', now(), NULL)

,(52, 'Animalia', 'Gastéropodes', now(), NULL)
,(66, 'Animalia', 'Gastéropodes', now(), NULL)
--Manque l'identification par la coquille. TODO : proposer l'ajout à l'INPN

,(43, 'Animalia', 'Amphibiens', now(), NULL)
,(46, 'Animalia', 'Amphibiens', now(), NULL)
,(48, 'Animalia', 'Amphibiens', now(), NULL)
,(52, 'Animalia', 'Amphibiens', now(), NULL)
,(67, 'Animalia', 'Amphibiens', now(), NULL)
--Manque l'identification par la ponte. TODO : proposer l'ajout à l'INPN

--TODO : "Octocoralliaires"
--TODO : "Entognathes"
--Aucun critère spécifique identifié pour les annélides
--TODO : "Pycnogonides"
--TODO : "Nématodes"
--TODO : "Ascidies"
--TODO : "Plathelminthes"

,(43, 'Animalia', 'Mammifères', now(), NULL)
,(45, 'Animalia', 'Mammifères', now(), NULL)
,(46, 'Animalia', 'Mammifères', now(), NULL)
,(48, 'Animalia', 'Mammifères', now(), NULL)
,(49, 'Animalia', 'Mammifères', now(), NULL)
,(50, 'Animalia', 'Mammifères', now(), NULL)
,(52, 'Animalia', 'Mammifères', now(), NULL)
,(53, 'Animalia', 'Mammifères', now(), NULL)
,(54, 'Animalia', 'Mammifères', now(), NULL)
,(65, 'Animalia', 'Mammifères', now(), NULL)
,(67, 'Animalia', 'Mammifères', now(), NULL)

--TODO : "Ascidies"
--Aucun critère spécifique identifié pour les myriapodes
--TODO : "Plathelminthes"

---------------------
--Biological status--
---------------------
,(29, 'all', 'all', now(), NULL)
,(30, 'all', 'all', now(), NULL)
,(31, 'all', 'all', now(), NULL)
,(41, 'all', 'all', now(), NULL)

,(32, 'Plantae', 'all', now(), NULL)
,(38, 'Plantae', 'all', now(), NULL)

,(32, 'Fungi', 'all', now(), NULL)
,(38, 'Fungi', 'all', now(), NULL)

,(32, 'Animalia', 'all', now(), NULL)
,(38, 'Animalia', 'all', now(), NULL)

--TODO : "Bacteria"
--TODO : "Chromista"
--TODO : "Protozoa"

--Aucun critère spécifique identifié pour les bivalves

,(35, 'Animalia', 'Insectes', now(), NULL)
,(37, 'Animalia', 'Insectes', now(), NULL)
,(39, 'Animalia', 'Insectes', now(), NULL)
,(40, 'Animalia', 'Insectes', now(), NULL)

--TODO : "Acanthocéphales"

,(37, 'Animalia', 'Céphalopodes', now(), NULL)

,(33, 'Animalia', 'Reptiles', now(), NULL)
,(34, 'Animalia', 'Reptiles', now(), NULL)
,(37, 'Animalia', 'Reptiles', now(), NULL)

,(37, 'Animalia', 'Crustacés', now(), NULL)

--TODO : "Scléractiniaires"
--TODO : "Hydrozoaires"

,(33, 'Animalia', 'Oiseaux', now(), NULL)
,(34, 'Animalia', 'Oiseaux', now(), NULL)
,(35, 'Animalia', 'Oiseaux', now(), NULL)
,(36, 'Animalia', 'Oiseaux', now(), NULL)
,(37, 'Animalia', 'Oiseaux', now(), NULL)
,(39, 'Animalia', 'Oiseaux', now(), NULL)
,(40, 'Animalia', 'Oiseaux', now(), NULL)

,(35, 'Animalia', 'Poissons', now(), NULL)
,(37, 'Animalia', 'Poissons', now(), NULL)

--TODO : "Némertes"

,(37, 'Animalia', 'Arachnides', now(), NULL)

,(37, 'Animalia', 'Gastéropodes', now(), NULL)


,(33, 'Animalia', 'Amphibiens', now(), NULL)
,(37, 'Animalia', 'Amphibiens', now(), NULL)

--TODO : "Octocoralliaires"
--TODO : "Entognathes"
--TODO : "Annélides"
--TODO : "Pycnogonides"
--TODO : "Nématodes"
--TODO : "Ascidies"
--TODO : "Plathelminthes"

,(33, 'Animalia', 'Mammifères', now(), NULL)
,(34, 'Animalia', 'Mammifères', now(), NULL)
,(35, 'Animalia', 'Mammifères', now(), NULL)
,(37, 'Animalia', 'Mammifères', now(), NULL)
,(39, 'Animalia', 'Mammifères', now(), NULL)
,(40, 'Animalia', 'Mammifères', now(), NULL)

--TODO : "Ascidies"
--TODO : "Myriapodes
--TODO : "Plathelminthes"


------------------
--Counting types--
------------------
,(106, 'all', 'all', now(), NULL)
,(107, 'all', 'all', now(), NULL)
,(108, 'all', 'all', now(), NULL)
,(109, 'all', 'all', now(), NULL)


--------------------
--Counting objects--
--------------------
,(165, 'all', 'all', now(), NULL)


,(166, 'Plantae', 'all', now(), NULL)
,(171, 'Plantae', 'all', now(), NULL)
,(172, 'Plantae', 'all', now(), NULL)
,(173, 'Plantae', 'all', now(), NULL)
,(174, 'Plantae', 'all', now(), NULL)

,(166, 'Fungi', 'all', now(), NULL)
,(174, 'Fungi', 'all', now(), NULL)

,(166, 'Animalia', 'all', now(), NULL)

--TODO : "Bacteria"
--TODO : "Chromista"
--TODO : "Protozoa"

,(168, 'Animalia', 'Bivalves', now(), NULL)

,(167, 'Animalia', 'Insectes', now(), NULL)
,(168, 'Animalia', 'Insectes', now(), NULL)
,(169, 'Animalia', 'Insectes', now(), NULL)
,(170, 'Animalia', 'Insectes', now(), NULL)

--TODO : "Acanthocéphales"

,(167, 'Animalia', 'Céphalopodes', now(), NULL)

,(167, 'Animalia', 'Reptiles', now(), NULL)
,(170, 'Animalia', 'Reptiles', now(), NULL)

,(168, 'Animalia', 'Crustacés', now(), NULL)
,(170, 'Animalia', 'Crustacés', now(), NULL)

--TODO : "Scléractiniaires"
--TODO : "Hydrozoaires"

,(167, 'Animalia', 'Oiseaux', now(), NULL)
,(168, 'Animalia', 'Oiseaux', now(), NULL)
,(169, 'Animalia', 'Oiseaux', now(), NULL)
,(170, 'Animalia', 'Oiseaux', now(), NULL)

,(168, 'Animalia', 'Poissons', now(), NULL)
,(170, 'Animalia', 'Poissons', now(), NULL)

--TODO : "Némertes"

,(168, 'Animalia', 'Arachnides', now(), NULL)
,(170, 'Animalia', 'Arachnides', now(), NULL)

,(168, 'Animalia', 'Gastéropodes', now(), NULL)
,(170, 'Animalia', 'Gastéropodes', now(), NULL)


,(167, 'Animalia', 'Amphibiens', now(), NULL)
,(168, 'Animalia', 'Amphibiens', now(), NULL)
,(170, 'Animalia', 'Amphibiens', now(), NULL)

--TODO : "Octocoralliaires"
--TODO : "Entognathes"
--TODO : "Annélides"
--TODO : "Pycnogonides"
--TODO : "Nématodes"
--TODO : "Ascidies"
--TODO : "Plathelminthes"

,(167, 'Animalia', 'Mammifères', now(), NULL)
,(168, 'Animalia', 'Mammifères', now(), NULL)

--TODO : "Ascidies"
--TODO : "Myriapodes
--TODO : "Plathelminthes"

---------------
--Naturalness--
---------------
,(181, 'all', 'all', now(), NULL)
,(182, 'all', 'all', now(), NULL)


,(183, 'Plantae', 'all', now(), NULL)
,(184, 'Plantae', 'all', now(), NULL)
,(186, 'Plantae', 'all', now(), NULL)


,(183, 'Fungi', 'all', now(), NULL)
,(184, 'Fungi', 'all', now(), NULL)
,(186, 'Fungi', 'all', now(), NULL)

,(183, 'Animalia', 'all', now(), NULL)
,(185, 'Animalia', 'all', now(), NULL)
,(186, 'Animalia', 'all', now(), NULL)

--TODO : "Bacteria"
--TODO : "Chromista"
--TODO : "Protozoa"


-----------
--ETA BIO--
-----------
,(176, 'all', 'all', now(), NULL)
,(177, 'all', 'all', now(), NULL)
,(178, 'all', 'all', now(), NULL)
,(179, 'all', 'all', now(), NULL)


-------------------
--Proof existence--
-------------------
,(91, 'all', 'all', now(), NULL)
,(92, 'all', 'all', now(), NULL)
,(93, 'all', 'all', now(), NULL)
,(94, 'all', 'all', now(), NULL)


----------------------
--Observation status--
----------------------
,(99, 'all', 'all', now(), NULL)
,(100, 'all', 'all', now(), NULL)
,(101, 'all', 'all', now(), NULL)


---------------------
--Validation status--
---------------------
,(345, 'all', 'all', now(), NULL)
,(346, 'all', 'all', now(), NULL)
,(347, 'all', 'all', now(), NULL)
,(348, 'all', 'all', now(), NULL)
,(349, 'all', 'all', now(), NULL)
,(350, 'all', 'all', now(), NULL)


-----------------------------
--Diffusion precision level--
-----------------------------
,(158, 'all', 'all', now(), NULL)
,(159, 'all', 'all', now(), NULL)
,(160, 'all', 'all', now(), NULL)
,(161, 'all', 'all', now(), NULL)
,(162, 'all', 'all', now(), NULL)
,(163, 'all', 'all', now(), NULL)


-------------------------
--DETERMINATION METHODS--
-------------------------
,(370, 'all', 'all', now(), NULL)
,(371, 'all', 'all', now(), NULL)
,(372, 'all', 'all', now(), NULL)
,(374, 'all', 'all', now(), NULL)
,(375, 'all', 'all', now(), NULL)
,(376, 'all', 'all', now(), NULL)
,(377, 'all', 'all', now(), NULL)
,(379, 'all', 'all', now(), NULL)

,(372, 'Animalia', 'Insectes', now(), NULL)
,(373, 'Animalia', 'Insectes', now(), NULL)

,(372, 'Animalia', 'Arachnides', now(), NULL)
,(373, 'Animalia', 'Arachnides', now(), NULL)

,(372, 'Animalia', 'Gastéropodes', now(), NULL)
,(373, 'Animalia', 'Gastéropodes', now(), NULL)

,(378, 'Animalia', 'Mammifères', now(), NULL)
;