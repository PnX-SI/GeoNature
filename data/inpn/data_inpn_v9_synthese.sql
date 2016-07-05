-------------------------------------------------------------
------------Insertion des dictionnaires taxref --------------
-------------------------------------------------------------

SET search_path = taxonomie, pg_catalog;
--
-- TOC entry 3270 (class 0 OID 17759)
-- Dependencies: 242
-- Data for Name: bib_taxref_habitats; Type: TABLE DATA; Schema: taxonomie; Owner: geonatuser
--

INSERT INTO bib_taxref_habitats (id_habitat, nom_habitat) VALUES (1, 'Marin');
INSERT INTO bib_taxref_habitats (id_habitat, nom_habitat) VALUES (2, 'Eau douce');
INSERT INTO bib_taxref_habitats (id_habitat, nom_habitat) VALUES (3, 'Terrestre');
INSERT INTO bib_taxref_habitats (id_habitat, nom_habitat) VALUES (5, 'Marin et Terrestre');
INSERT INTO bib_taxref_habitats (id_habitat, nom_habitat) VALUES (6, 'Eau Saumâtre');
INSERT INTO bib_taxref_habitats (id_habitat, nom_habitat) VALUES (7, 'Continental (Terrestre et/ou Eau douce)');
INSERT INTO bib_taxref_habitats (id_habitat, nom_habitat) VALUES (0, 'Non renseigné');
INSERT INTO bib_taxref_habitats (id_habitat, nom_habitat) VALUES (4, 'Marin et Eau douce');
INSERT INTO bib_taxref_habitats (id_habitat, nom_habitat) VALUES (8, 'Continental (Terrestre et Eau douce)');


--
-- TOC entry 3271 (class 0 OID 17762)
-- Dependencies: 243
-- Data for Name: bib_taxref_rangs; Type: TABLE DATA; Schema: taxonomie; Owner: geonatuser
--

INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('Dumm', 'Domaine');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('SPRG', 'Super-Règne');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('KD  ', 'Règne');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('SSRG', 'Sous-Règne');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('IFRG', 'Infra-Règne');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('PH  ', 'Embranchement');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('SBPH', 'Sous-Phylum');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('IFPH', 'Infra-Phylum');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('DV  ', 'Division');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('SBDV', 'Sous-division');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('SPCL', 'Super-Classe');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('CLAD', 'Cladus');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('CL  ', 'Classe');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('SBCL', 'Sous-Classe');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('IFCL', 'Infra-classe');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('LEG ', 'Legio');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('SPOR', 'Super-Ordre');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('COH ', 'Cohorte');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('OR  ', 'Ordre');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('SBOR', 'Sous-Ordre');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('IFOR', 'Infra-Ordre');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('SPFM', 'Super-Famille');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('FM  ', 'Famille');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('SBFM', 'Sous-Famille');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('TR  ', 'Tribu');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('SSTR', 'Sous-Tribu');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('GN  ', 'Genre');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('SSGN', 'Sous-Genre');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('SC  ', 'Section');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('SBSC', 'Sous-Section');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('SER', 'Série');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('SSER', 'Sous-Série');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('AGES', 'Agrégat');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('ES  ', 'Espèce');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('SMES', 'Semi-espèce');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('MES ', 'Micro-Espèce');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('SSES', 'Sous-espèce');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('NAT ', 'Natio');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('VAR ', 'Variété');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('SVAR ', 'Sous-Variété');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('FO  ', 'Forme');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('SSFO', 'Sous-Forme');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('FOES', 'Forma species');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('LIN ', 'Linea');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('CLO ', 'Clône');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('RACE', 'Race');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('CAR ', 'Cultivar');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('MO  ', 'Morpha');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('AB  ', 'Abberatio');
--n'existe plus dans taxref V9
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('CVAR', 'Convariété');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('HYB ', 'Hybride');
--non documenté dans la doc taxref
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('SPTR', 'Supra-Tribu');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('SCO ', '?');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('PVOR', '?');
INSERT INTO bib_taxref_rangs (id_rang, nom_rang) VALUES ('SSCO', '?');



--
-- TOC entry 3272 (class 0 OID 17765)
-- Dependencies: 244
-- Data for Name: bib_taxref_statuts; Type: TABLE DATA; Schema: taxonomie; Owner: geonatuser
--

INSERT INTO bib_taxref_statuts (id_statut, nom_statut) VALUES ('A', 'Absente');
INSERT INTO bib_taxref_statuts (id_statut, nom_statut) VALUES ('B', 'Accidentelle / Visiteuse');
INSERT INTO bib_taxref_statuts (id_statut, nom_statut) VALUES ('C', 'Cryptogène');
INSERT INTO bib_taxref_statuts (id_statut, nom_statut) VALUES ('D', 'Douteux');
INSERT INTO bib_taxref_statuts (id_statut, nom_statut) VALUES ('E', 'Endemique');
INSERT INTO bib_taxref_statuts (id_statut, nom_statut) VALUES ('F', 'Trouvé en fouille');
INSERT INTO bib_taxref_statuts (id_statut, nom_statut) VALUES ('I', 'Introduite');
INSERT INTO bib_taxref_statuts (id_statut, nom_statut) VALUES ('J', 'Introduite envahissante');
INSERT INTO bib_taxref_statuts (id_statut, nom_statut) VALUES ('M', 'Domestique / Introduite non établie');
INSERT INTO bib_taxref_statuts (id_statut, nom_statut) VALUES ('P', 'Présente');
INSERT INTO bib_taxref_statuts (id_statut, nom_statut) VALUES ('S', 'Subendémique');
INSERT INTO bib_taxref_statuts (id_statut, nom_statut) VALUES ('W', 'Disparue');
INSERT INTO bib_taxref_statuts (id_statut, nom_statut) VALUES ('X', 'Eteinte');
INSERT INTO bib_taxref_statuts (id_statut, nom_statut) VALUES ('Y', 'Introduite éteinte');
INSERT INTO bib_taxref_statuts (id_statut, nom_statut) VALUES ('Z', 'Endémique éteinte');
INSERT INTO bib_taxref_statuts (id_statut, nom_statut) VALUES ('0', 'Non renseigné');
INSERT INTO bib_taxref_statuts (id_statut, nom_statut) VALUES ('Q', 'Mentionné par erreur');
INSERT INTO bib_taxref_statuts (id_statut, nom_statut) VALUES (' ', 'Non précisé');

--
-- 
-- Data for Name: bib_taxref_categories_lr; Type: TABLE DATA; Schema: taxonomie; Owner: -
--

INSERT INTO bib_taxref_categories_lr VALUES ('EX', 'Disparues', 'Eteinte à l''état sauvage', 'Eteinte au niveau mondial');
INSERT INTO bib_taxref_categories_lr VALUES ('EW', 'Disparues', 'Eteinte à l''état sauvage', 'Eteinte à l''état sauvage');
INSERT INTO bib_taxref_categories_lr VALUES ('RE', 'Disparues', 'Disparue au niveau régional', 'Disparue au niveau régional');
INSERT INTO bib_taxref_categories_lr VALUES ('CR', 'Menacées de disparition', 'En danger critique', 'En danger critique');
INSERT INTO bib_taxref_categories_lr VALUES ('EN', 'Menacées de disparition', 'En danger', 'En danger');
INSERT INTO bib_taxref_categories_lr VALUES ('VU', 'Menacées de disparition', 'Vulnérable', 'Vulnérable');
INSERT INTO bib_taxref_categories_lr VALUES ('NT', 'Autre', 'Quasi menacée', 'Espèce proche du seuil des espèces menacées ou qui pourrait être menacée si des mesures de conservation spécifiques n''étaient pas prises');
INSERT INTO bib_taxref_categories_lr VALUES ('LC', 'Autre', 'Préoccupation mineure', 'Espèce pour laquelle le risque de disparition est faible');
INSERT INTO bib_taxref_categories_lr VALUES ('DD', 'Autre', 'Données insuffisantes', 'Espèce pour laquelle l''évaluation n''a pas pu être réalisée faute de données suffisantes');
INSERT INTO bib_taxref_categories_lr VALUES ('NA', 'Autre', 'Non applicable', 'Espèce non soumise à évaluation car (a) introduite dans la période récente ou (b) présente en métropole de manière occasionnelle ou marginale');
INSERT INTO bib_taxref_categories_lr VALUES ('NE', 'Autre', 'Non évaluée', 'Espèce non encore confrontée aux critères de la Liste rouge');


-------------------------------------------------------------
------------Insertion des données taxref	-------------
-------------------------------------------------------------

---import taxref--
TRUNCATE TABLE import_taxref;
COPY import_taxref (regne, phylum, classe, ordre, famille, group1_inpn, group2_inpn, 
          cd_nom, cd_taxsup, cd_sup, cd_ref, rang, lb_nom, lb_auteur, nom_complet, nom_complet_html,
          nom_valide, nom_vern, nom_vern_eng, habitat, fr, gf, mar, gua, 
          sm, sb, spm, may, epa, reu, taaf, pf, nc, wf, cli, url)
FROM  '/home/synthese/geonature/data/inpn/TAXREFv90.txt'
WITH  CSV HEADER 
DELIMITER E'\t'  encoding 'LATIN1';

---selection des taxons faune-flore-fonge uniquement--
TRUNCATE TABLE taxref CASCADE;
INSERT INTO taxref
      SELECT cd_nom, fr as id_statut, habitat::int as id_habitat, rang as  id_rang, regne, phylum, classe, 
             ordre, famille, cd_taxsup, cd_sup, cd_ref, lb_nom, substring(lb_auteur, 1, 150), nom_complet, 
             nom_valide, nom_vern, nom_vern_eng, group1_inpn, group2_inpn
        FROM import_taxref
        WHERE regne = 'Animalia'
        OR regne = 'Fungi'
        OR regne = 'Plantae';


----PROTECTION

---import des statuts de protections
TRUNCATE TABLE taxref_protection_articles CASCADE;
COPY taxref_protection_articles (
cd_protection, article, intitule, arrete, url_inpn, cd_doc, url, date_arrete, type_protection
)
FROM  '/home/synthese/geonature/data/inpn/PROTECTION_ESPECES_TYPES_90.csv'
WITH  CSV HEADER 
DELIMITER ';'  encoding 'LATIN1';


---import des statuts de protections associés au taxon
CREATE TABLE import_protection_especes (
	cd_nom int,
	cd_protection varchar(250),
	nom_cite text,
	syn_cite text,
	nom_francais_cite text,
	precisions varchar(500),
	cd_nom_cite int
);

COPY import_protection_especes
FROM  '/home/synthese/geonature/data/inpn/PROTECTION_ESPECES_90.csv'
WITH  CSV HEADER 
DELIMITER ';'  encoding 'LATIN1';

---import liste rouge--
TRUNCATE TABLE taxonomie.taxref_liste_rouge_fr;
COPY taxonomie.taxref_liste_rouge_fr (ordre_statut,vide,cd_nom,cd_ref,nomcite,nom_scientifique,auteur,nom_vernaculaire,nom_commun,
    rang,famille,endemisme,population,commentaire,id_categorie_france,criteres_france,liste_rouge,fiche_espece,tendance,
    liste_rouge_source,annee_publication,categorie_lr_europe,categorie_lr_mondiale)
FROM  '/home/synthese/geonature/data/inpn/LR_FRANCE.csv'
WITH  CSV HEADER 
DELIMITER E'\;'  encoding 'UTF-8';


TRUNCATE TABLE taxref_protection_especes;
INSERT INTO taxref_protection_especes
SELECT DISTINCT  p.* 
FROM  (
  SELECT cd_nom , cd_protection , string_agg(DISTINCT nom_cite, ',') nom_cite, 
    string_agg(DISTINCT syn_cite, ',')  syn_cite, string_agg(DISTINCT nom_francais_cite, ',')  nom_francais_cite,
    string_agg(DISTINCT precisions, ',')  precisions, cd_nom_cite 
  FROM   import_protection_especes
  GROUP BY cd_nom , cd_protection , cd_nom_cite 
) p
JOIN taxref t
USING(cd_nom) ;

DROP TABLE  import_protection_especes;


--- Nettoyage des statuts de protections non utilisés
DELETE FROM  taxref_protection_articles
WHERE cd_protection IN (
  SELECT cd_protection 
  FROM taxref_protection_articles
  WHERE NOT cd_protection IN (SELECT DISTINCT cd_protection FROM  taxref_protection_especes)
);


--- Activation des textes valides pour la structure
--      Par défaut activation de tous les textes nationaux et internationaux
--          Pour des considérations locales à faire au cas par cas !!!
--UPDATE  taxonomie.taxref_protection_articles SET concerne_mon_territoire = true
--WHERE cd_protection IN (
	--SELECT cd_protection
	--FROM  taxonomie.taxref_protection_articles
	--WHERE
		--niveau IN ('international', 'national', 'communautaire')
		--AND type_protection = 'Protection'
--);
