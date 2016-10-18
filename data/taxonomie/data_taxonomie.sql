
SET search_path = taxonomie, pg_catalog;


--
-- TOC entry 3122 (class 0 OID 126729)
-- Dependencies: 194
-- Data for Name: bib_noms; Type: TABLE DATA; Schema: taxonomie; Owner: -
--

INSERT INTO bib_noms (id_nom, cd_nom, cd_ref, nom_francais) VALUES (704, 67111, 67111, 'Ablette');
INSERT INTO bib_noms (id_nom, cd_nom, cd_ref, nom_francais) VALUES (64, 60612, 60612, 'Lynx boréal');
INSERT INTO bib_noms (id_nom, cd_nom, cd_ref, nom_francais) VALUES (23, 351, 351, 'Grenouille rousse');
INSERT INTO bib_noms (id_nom, cd_nom, cd_ref, nom_francais) VALUES (1950, 8326, 8326, 'Cicindela hybrida');
INSERT INTO bib_noms (id_nom, cd_nom, cd_ref, nom_francais) VALUES (2804, 11165, 11165, 'Coccinella septempunctata');
INSERT INTO bib_noms (id_nom, cd_nom, cd_ref, nom_francais) VALUES (816, 18437, 18437, 'Ecrevisse à pieds blancs');
INSERT INTO bib_noms (id_nom, cd_nom, cd_ref, nom_francais) VALUES (100001, 81065, 81065, 'Alchémille rampante');
INSERT INTO bib_noms (id_nom, cd_nom, cd_ref, nom_francais) VALUES (100002, 95186, 95186, 'Inule fétide');


--
-- 
-- Data for Name: bib_themes; Type: TABLE DATA; Schema: taxonomie; Owner: -
--

INSERT INTO bib_themes (id_theme, nom_theme, desc_theme, ordre, id_droit) VALUES (1, 'GeoNature', 'Informations nécessaires au fonctionnement de GeoNature', 1, 4);
INSERT INTO bib_themes (id_theme, nom_theme, desc_theme, ordre, id_droit) VALUES (2, 'Atlas', 'Informations relative à GeoNature Atlas', 2, 3);
INSERT INTO bib_themes (id_theme, nom_theme, desc_theme, ordre, id_droit) VALUES (3, 'Mon territoire', 'Informations relatives à mon territoire', 3, 4);

SELECT pg_catalog.setval('bib_themes_id_theme_seq', 4, true);
--
-- 
-- Data for Name: bib_attributs; Type: TABLE DATA; Schema: taxonomie; Owner: -
--

INSERT INTO bib_attributs (id_attribut, nom_attribut, label_attribut, liste_valeur_attribut, obligatoire, desc_attribut, type_attribut, type_widget, regne, group2_inpn, id_theme, ordre) VALUES (1, 'patrimonial', 'Patrimonial', '{"values":["oui", "non"]}', false, 'Défini si le taxon est patrimonial pour le territoire', 'text', 'radio', NULL, NULL, 1, 2);
INSERT INTO bib_attributs (id_attribut ,nom_attribut, label_attribut, liste_valeur_attribut, obligatoire, desc_attribut, type_attribut, type_widget, regne, group2_inpn, id_theme, ordre) VALUES (2, 'protection_stricte', 'Protégé', '{"values":["oui", "non"]}',true,'Défini si le taxon bénéficie d''une protection juridique stricte pour le territoire', 'text', 'radio', NULL, NULL, 1, 3);
INSERT INTO bib_attributs (id_attribut ,nom_attribut, label_attribut, liste_valeur_attribut, obligatoire, desc_attribut, type_attribut, type_widget, regne, group2_inpn, id_theme, ordre) VALUES (3, 'saisie', 'Saisie possible', '{"values":["oui", "non"]}',true,'Permet d''exclure des taxons des menus déroulants de saisie', 'text', 'radio', NULL, NULL, 1, 1);

INSERT INTO bib_attributs (id_attribut, nom_attribut, label_attribut, liste_valeur_attribut, obligatoire, desc_attribut, type_attribut, type_widget, regne, group2_inpn, id_theme, ordre) VALUES (100, 'atlas_description', 'Description', '{}', false, 'Donne une description du taxon pour l''atlas', 'text', 'textarea', NULL, NULL, 2, 100);
INSERT INTO bib_attributs (id_attribut, nom_attribut, label_attribut, liste_valeur_attribut, obligatoire, desc_attribut, type_attribut, type_widget, regne, group2_inpn, id_theme, ordre) VALUES (101, 'atlas_commentaire', 'Commentaire', '{}', false, 'Commentaire contextualisé sur le taxon pour GeoNature-Atlas', 'text', 'textarea', NULL, NULL, 2, 101);
INSERT INTO bib_attributs (id_attribut, nom_attribut, label_attribut, liste_valeur_attribut, obligatoire, desc_attribut, type_attribut, type_widget, regne, group2_inpn, id_theme, ordre) VALUES (102, 'atlas_milieu', 'Milieu', '{"values":["Forêt","Prairie","eau"]}', false, 'Habitat, milieu principal du taxon', 'text', 'multiselect', NULL, NULL, 2, 102);
INSERT INTO bib_attributs (id_attribut, nom_attribut, label_attribut, liste_valeur_attribut, obligatoire, desc_attribut, type_attribut, type_widget, regne, group2_inpn, id_theme, ordre) VALUES (103, 'atlas_chorologie', 'Chorologie', '{"values":["Méditéranéenne","Alpine","Océanique"]}', false, 'Distribution, répartition, région à grande échelle du taxon', 'text', 'select', NULL, NULL, 2, 103);

INSERT INTO bib_attributs (id_attribut, nom_attribut, label_attribut, liste_valeur_attribut, obligatoire, desc_attribut, type_attribut, type_widget, regne, group2_inpn, id_theme, ordre) VALUES (4, 'migrateur', 'Migrateur', '{"values":["migrateur","migrateur partiel","sédentaire"]}', false, 'Défini le statut de migration pour le territoire', 'varchar(50)', 'select', 'Animalia', 'Oiseaux', 3, 200);


--
-- 
-- Data for Name: cor_taxon_attribut; Type: TABLE DATA; Schema: taxonomie; Owner: -
--

INSERT INTO cor_taxon_attribut (cd_ref ,id_attribut, valeur_attribut) VALUES (67111, 1, 'non');
INSERT INTO cor_taxon_attribut (cd_ref ,id_attribut, valeur_attribut) VALUES (67111, 2, 'non');
INSERT INTO cor_taxon_attribut (cd_ref ,id_attribut, valeur_attribut) VALUES (60612, 1, 'oui');
INSERT INTO cor_taxon_attribut (cd_ref ,id_attribut, valeur_attribut) VALUES (60612, 2, 'oui');
INSERT INTO cor_taxon_attribut (cd_ref ,id_attribut, valeur_attribut) VALUES (351, 1, 'non');
INSERT INTO cor_taxon_attribut (cd_ref ,id_attribut, valeur_attribut) VALUES (351, 2, 'oui');
INSERT INTO cor_taxon_attribut (cd_ref ,id_attribut, valeur_attribut) VALUES (8326, 1, 'non');
INSERT INTO cor_taxon_attribut (cd_ref ,id_attribut, valeur_attribut) VALUES (8326, 2, 'non');
INSERT INTO cor_taxon_attribut (cd_ref ,id_attribut, valeur_attribut) VALUES (11165, 1, 'non');
INSERT INTO cor_taxon_attribut (cd_ref ,id_attribut, valeur_attribut) VALUES (11165, 2, 'non');
INSERT INTO cor_taxon_attribut (cd_ref ,id_attribut, valeur_attribut) VALUES (18437, 1, 'non');
INSERT INTO cor_taxon_attribut (cd_ref ,id_attribut, valeur_attribut) VALUES (18437, 2, 'oui');
INSERT INTO cor_taxon_attribut (cd_ref ,id_attribut, valeur_attribut) VALUES (81065, 1, 'non');
INSERT INTO cor_taxon_attribut (cd_ref ,id_attribut, valeur_attribut) VALUES (81065, 2, 'non');
INSERT INTO cor_taxon_attribut (cd_ref ,id_attribut, valeur_attribut) VALUES (95186, 1, 'non');
INSERT INTO cor_taxon_attribut (cd_ref ,id_attribut, valeur_attribut) VALUES (95186, 2, 'non');

--
-- 
-- Data for Name: bib_listes; Type: TABLE DATA; Schema: taxonomie; Owner: -
--

INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto,regne,group2_inpn) VALUES (1, 'Amphibiens',null, 'images/pictos/amphibien.gif','Animalia','Amphibiens');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto,regne,group2_inpn) VALUES (2, 'Vers',null, 'images/pictos/nopicto.gif','Animalia','Annélides');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto,regne,group2_inpn) VALUES (3, 'Entognathes',null, 'images/pictos/nopicto.gif','Animalia','Entognathes');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto,regne,group2_inpn) VALUES (4, 'Echinodermes',null, 'images/pictos/nopicto.gif','Animalia','<Autres>');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto,regne,group2_inpn) VALUES (5, 'Crustacés',null, 'images/pictos/ecrevisse.gif','Animalia','Crustacés');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto,regne,group2_inpn) VALUES (7, 'Pycnogonides',null, 'images/pictos/nopicto.gif','Animalia','Pycnogonides');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto,regne,group2_inpn) VALUES (8, 'Gastéropodes',null, 'images/pictos/nopicto.gif','Animalia','Gastéropodes');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto,regne,group2_inpn) VALUES (9, 'Insectes',null, 'images/pictos/insecte.gif','Animalia','Insectes');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto,regne,group2_inpn) VALUES (10, 'Bivalves',null, 'images/pictos/nopicto.gif','Animalia','Bivalves');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto,regne,group2_inpn) VALUES (11, 'Mammifères',null, 'images/pictos/mammifere.gif','Animalia','Mammifères');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto,regne,group2_inpn) VALUES (12, 'Oiseaux',null, 'images/pictos/oiseau.gif','Animalia','Oiseaux');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto,regne,group2_inpn) VALUES (13, 'Poissons',null, 'images/pictos/poisson.gif','Animalia','Poissons' );
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto,regne,group2_inpn) VALUES (14, 'Reptiles',null, 'images/pictos/reptile.gif','Animalia','Reptiles');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto,regne,group2_inpn) VALUES (15, 'Myriapodes',null, 'images/pictos/nopicto.gif','Animalia','Myriapodes');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto,regne,group2_inpn) VALUES (16, 'Arachnides',null, 'images/pictos/araignee.gif','Animalia','Arachnides');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto,regne,group2_inpn) VALUES (20, 'Rotifères',null, 'images/pictos/nopicto.gif','Animalia','<Autres>');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto,regne,group2_inpn) VALUES (21, 'Tardigrades',null, 'images/pictos/nopicto.gif','Animalia','<Autres>');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto,regne,group2_inpn) VALUES (101, 'Mollusques',null, 'images/pictos/mollusque.gif','Animalia','<Autres>');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto,regne,group2_inpn) VALUES (301, 'Bryophytes',null, 'images/pictos/mousse.gif','Plantae','Mousses');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto,regne,group2_inpn) VALUES (302, 'Lichens',null, 'images/pictos/nopicto.gif','Plantae','Lichens');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto,regne,group2_inpn) VALUES (303, 'Algues',null, 'images/pictos/nopicto.gif','Plantae','Algues');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto,regne,group2_inpn) VALUES (305, 'Ptéridophytes',null, 'images/pictos/nopicto.gif','Plantae','Angiospermes');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto,regne,group2_inpn) VALUES (306, 'Monocotylédones',null, 'images/pictos/nopicto.gif','Plantae','Angiospermes');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto,regne,group2_inpn) VALUES (307, 'Dycotylédones',null, 'images/pictos/nopicto.gif','Plantae','Angiospermes');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto) VALUES (666, 'Nuisibles',null, 'images/pictos/nopicto.gif');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto,regne) VALUES (1001, 'Faune vertébrée', 'Liste servant à l''affichage des taxons de la faune vertébré pouvant être saisis', 'images/pictos/nopicto.gif','Animalia');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto,regne) VALUES (1002, 'Faune invertébrée', 'Liste servant à l''affichage des taxons de la faune invertébré pouvant être saisis', 'images/pictos/nopicto.gif','Animalia');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto,regne) VALUES (1003, 'Flore', 'Liste servant à l''affichage des taxons de la flore pouvant être saisis', 'images/pictos/nopicto.gif','Plantae');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto,regne) VALUES (1004, 'Fonge','Liste servant à l''affichage des taxons de la fonge pouvant être saisis', 'images/pictos/champignon.gif','Fungi');


--
-- 
-- Data for Name: cor_nom_liste; Type: TABLE DATA; Schema: taxonomie; Owner: -
--

INSERT INTO cor_nom_liste (id_nom ,id_liste) VALUES (704, 1001);
INSERT INTO cor_nom_liste (id_nom ,id_liste) VALUES (64, 1001);
INSERT INTO cor_nom_liste (id_nom ,id_liste) VALUES (23, 1001);
INSERT INTO cor_nom_liste (id_nom ,id_liste) VALUES (1950, 1002);
INSERT INTO cor_nom_liste (id_nom ,id_liste) VALUES (2804, 1002);
INSERT INTO cor_nom_liste (id_nom ,id_liste) VALUES (816, 1002);
INSERT INTO cor_nom_liste (id_nom ,id_liste) VALUES (23, 1);
INSERT INTO cor_nom_liste (id_nom ,id_liste) VALUES (64, 11);
INSERT INTO cor_nom_liste (id_nom ,id_liste) VALUES (704, 13);
INSERT INTO cor_nom_liste (id_nom ,id_liste) VALUES (816, 5);
INSERT INTO cor_nom_liste (id_nom ,id_liste) VALUES (1950, 9);
INSERT INTO cor_nom_liste (id_nom ,id_liste) VALUES (2804,9);
INSERT INTO cor_nom_liste (id_nom ,id_liste) VALUES (100001,1003);
INSERT INTO cor_nom_liste (id_nom ,id_liste) VALUES (100002,1003);
INSERT INTO cor_nom_liste (id_nom ,id_liste) VALUES (100001,306);
INSERT INTO cor_nom_liste (id_nom ,id_liste) VALUES (100002,307);

