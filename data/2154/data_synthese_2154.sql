--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public, pg_catalog;

INSERT INTO cor_boolean VALUES('oui',true);
INSERT INTO cor_boolean VALUES('non',false);


SET search_path = synthese, pg_catalog;

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


SET search_path = layers, pg_catalog;

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


SET search_path = public, pg_catalog;

INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'synthese', 'syntheseff', 'the_geom_2154', 2, 2154, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'synthese', 'syntheseff', 'the_geom_point', 2, 3857, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'synthese', 'syntheseff', 'the_geom_3857', 2, 3857, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'layers', 'l_zonesstatut', 'the_geom', 2, 2154, 'MULTIPOLYGON');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'layers', 'l_communes', 'the_geom', 2, 2154, 'MULTIPOLYGON');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'layers', 'l_secteurs', 'the_geom', 2, 2154, 'MULTIPOLYGON');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'layers', 'l_aireadhesion', 'the_geom', 2, 2154, 'MULTIPOLYGON');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'layers', 'l_unites_geo', 'the_geom', 2, 2154, 'MULTIPOLYGON');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'layers', 'l_isolines20', 'the_geom', 2, 2154, 'MULTILINESTRING');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'layers', 'l_territoires', 'the_geom', 2, 2154, 'MULTIPOLYGON');


SET search_path = synthese, pg_catalog;

INSERT INTO bib_sources (id_source, nom_source, desc_source, host, port, username, pass, db_name, db_schema, db_table, db_field, url, target, picto, groupe, actif) VALUES (0, 'Web API', 'Donnée externe non définie (insérée dans la synthese à partir du service reste de la web API sans id_source fourni)', 'localhost', 22, NULL, NULL, 'geonaturedb', 'synthese', 'syntheseff', 'id_fiche_source', NULL, NULL, NULL, 'NONE', false);


SET search_path = meta, pg_catalog;

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