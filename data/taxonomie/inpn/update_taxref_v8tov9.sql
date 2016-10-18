--TODO
--En console :
-- cd data/inpn
-- unzip TAXREF_INPN_v9.0.zip
-- unzip ESPECES_REGLEMENTEES_v9.zip
-- unzip LR_FRANCE.zip


--Sauvegarde des statuts de protection du territoire
CREATE SCHEMA save;
CREATE TABLE save.taxref_protection_articles AS
SELECT * FROM taxonomie.taxref_protection_articles;



--Insertion des données de dictionnaire manquantes
ALTER TABLE taxonomie.taxref DROP CONSTRAINT fk_taxref_bib_taxref_rangs;
TRUNCATE TABLE taxonomie.bib_taxref_rangs;
ALTER TABLE taxonomie.bib_taxref_rangs ADD tri_rang integer;
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('Dumm', 'Domaine', 1);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('SPRG', 'Super-Règne', 2);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('KD  ', 'Règne', 3);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('SSRG', 'Sous-Règne', 4);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('IFRG', 'Infra-Règne', 5);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('PH  ', 'Embranchement', 6);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('SBPH', 'Sous-Phylum', 7);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('IFPH', 'Infra-Phylum', 8);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('DV  ', 'Division', 9);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('SBDV', 'Sous-division', 10);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('SPCL', 'Super-Classe', 11);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('CLAD', 'Cladus', 12);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('CL  ', 'Classe', 13);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('SBCL', 'Sous-Classe', 14);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('IFCL', 'Infra-classe', 15);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('LEG ', 'Legio', 16);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('SPOR', 'Super-Ordre', 17);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('COH ', 'Cohorte', 18);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('OR  ', 'Ordre', 19);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('SBOR', 'Sous-Ordre', 20);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('IFOR', 'Infra-Ordre', 21);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('SPFM', 'Super-Famille', 22);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('FM  ', 'Famille', 23);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('SBFM', 'Sous-Famille', 24);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('TR  ', 'Tribu', 26);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('SSTR', 'Sous-Tribu', 27);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('GN  ', 'Genre', 28);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('SSGN', 'Sous-Genre', 29);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('SC  ', 'Section', 30);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('SBSC', 'Sous-Section', 31);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('SER', 'Série', 32);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('SSER', 'Sous-Série', 33);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('AGES', 'Agrégat', 34);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('ES  ', 'Espèce', 35);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('SMES', 'Semi-espèce', 36);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('MES ', 'Micro-Espèce',37);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('SSES', 'Sous-espèce', 38);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('NAT ', 'Natio', 39);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('VAR ', 'Variété', 40);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('SVAR ', 'Sous-Variété', 41);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('FO  ', 'Forme', 42);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('SSFO', 'Sous-Forme', 43);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('FOES', 'Forma species', 44);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('LIN ', 'Linea', 45);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('CLO ', 'Clône', 46);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('RACE', 'Race', 47);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('CAR ', 'Cultivar', 48);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('MO  ', 'Morpha', 49);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('AB  ', 'Abberatio',50);
--n'existe plus dans taxref V9
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang) VALUES ('CVAR', 'Convariété');
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang) VALUES ('HYB ', 'Hybride');
--non documenté dans la doc taxref
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('SPTR', 'Supra-Tribu', 25);
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang) VALUES ('SCO ', '?');
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang) VALUES ('PVOR', '?');
INSERT INTO taxonomie.bib_taxref_rangs (id_rang, nom_rang) VALUES ('SSCO', '?');
ALTER TABLE taxonomie.taxref
  ADD CONSTRAINT fk_taxref_bib_taxref_rangs FOREIGN KEY (id_rang)
      REFERENCES taxonomie.bib_taxref_rangs (id_rang) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION;
      
INSERT INTO taxonomie.bib_taxref_statuts (id_statut, nom_statut) VALUES (' ', 'Non précisé');


--------------------Liste rouge--------------------
CREATE TABLE taxonomie.bib_taxref_categories_lr
(
  id_categorie_france character(2) NOT NULL,
  type_categorie_lr character varying(50) NOT NULL,
  nom_categorie_lr character varying(255) NOT NULL,
  desc_categorie_lr character varying(255),
  CONSTRAINT pk_bib_taxref_categories_lr PRIMARY KEY (id_categorie_france)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE taxonomie.bib_taxref_categories_lr OWNER TO geonatuser;

CREATE TABLE taxonomie.taxref_liste_rouge_fr
(
  id_lr serial NOT NULL,
  ordre_statut integer,
  vide character varying(255),
  cd_nom integer,
  cd_ref integer,
  nomcite character varying(255),
  nom_scientifique character varying(255),
  auteur character varying(255),
  nom_vernaculaire character varying(255),
  nom_commun character varying(255),
  rang character(4),
  famille character varying(50),
  endemisme character varying(255),
  population character varying(255),
  commentaire text,
  id_categorie_france character(2) NOT NULL,
  criteres_france character varying(255),
  liste_rouge character varying(255),
  fiche_espece character varying(255),
  tendance character varying(255),
  liste_rouge_source character varying(255),
  annee_publication integer,
  categorie_lr_europe character varying(2),
  categorie_lr_mondiale character varying(5),
  CONSTRAINT pk_taxref_liste_rouge_fr PRIMARY KEY (id_lr),
  CONSTRAINT fk_taxref_lr_bib_taxref_categories FOREIGN KEY (id_categorie_france)
      REFERENCES taxonomie.bib_taxref_categories_lr (id_categorie_france) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE taxonomie.taxref_liste_rouge_fr
  OWNER TO geonatuser;
  
INSERT INTO taxonomie.bib_taxref_categories_lr VALUES ('EX', 'Disparues', 'Eteinte à l''état sauvage', 'Eteinte au niveau mondial');
INSERT INTO taxonomie.bib_taxref_categories_lr VALUES ('EW', 'Disparues', 'Eteinte à l''état sauvage', 'Eteinte à l''état sauvage');
INSERT INTO taxonomie.bib_taxref_categories_lr VALUES ('RE', 'Disparues', 'Disparue au niveau régional', 'Disparue au niveau régional');
INSERT INTO taxonomie.bib_taxref_categories_lr VALUES ('CR', 'Menacées de disparition', 'En danger critique', 'En danger critique');
INSERT INTO taxonomie.bib_taxref_categories_lr VALUES ('EN', 'Menacées de disparition', 'En danger', 'En danger');
INSERT INTO taxonomie.bib_taxref_categories_lr VALUES ('VU', 'Menacées de disparition', 'Vulnérable', 'Vulnérable');
INSERT INTO taxonomie.bib_taxref_categories_lr VALUES ('NT', 'Autre', 'Quasi menacée', 'Espèce proche du seuil des espèces menacées ou qui pourrait être menacée si des mesures de conservation spécifiques n''étaient pas prises');
INSERT INTO taxonomie.bib_taxref_categories_lr VALUES ('LC', 'Autre', 'Préoccupation mineure', 'Espèce pour laquelle le risque de disparition est faible');
INSERT INTO taxonomie.bib_taxref_categories_lr VALUES ('DD', 'Autre', 'Données insuffisantes', 'Espèce pour laquelle l''évaluation n''a pas pu être réalisée faute de données suffisantes');
INSERT INTO taxonomie.bib_taxref_categories_lr VALUES ('NA', 'Autre', 'Non applicable', 'Espèce non soumise à évaluation car (a) introduite dans la période récente ou (b) présente en métropole de manière occasionnelle ou marginale');
INSERT INTO taxonomie.bib_taxref_categories_lr VALUES ('NE', 'Autre', 'Non évaluée', 'Espèce non encore confrontée aux critères de la Liste rouge');

TRUNCATE TABLE taxonomie.taxref_liste_rouge_fr;
COPY taxonomie.taxref_liste_rouge_fr (ordre_statut,vide,cd_nom,cd_ref,nomcite,nom_scientifique,auteur,nom_vernaculaire,nom_commun,
    rang,famille,endemisme,population,commentaire,id_categorie_france,criteres_france,liste_rouge,fiche_espece,tendance,
    liste_rouge_source,annee_publication,categorie_lr_europe,categorie_lr_mondiale)
FROM  '/home/synthese/geonature/data/inpn/LR_FRANCE.csv'
WITH  CSV HEADER 
DELIMITER E'\;'  encoding 'UTF-8';


--------------------import taxref--------------------
TRUNCATE TABLE taxonomie.import_taxref;
ALTER TABLE taxonomie.import_taxref ADD cd_sup integer;
COPY taxonomie.import_taxref (regne, phylum, classe, ordre, famille, group1_inpn, group2_inpn, 
          cd_nom, cd_taxsup, cd_sup, cd_ref, rang, lb_nom, lb_auteur, nom_complet, nom_complet_html,
          nom_valide, nom_vern, nom_vern_eng, habitat, fr, gf, mar, gua, 
          sm, sb, spm, may, epa, reu, taaf, pf, nc, wf, cli, url)
FROM  '/home/synthese/geonature/data/inpn/TAXREFv90.txt'
WITH  CSV HEADER 
DELIMITER E'\t'  encoding 'UTF-8';
--MAJ taxref
ALTER TABLE taxonomie.bib_taxons DROP CONSTRAINT fk_bib_taxons_taxref;
ALTER TABLE taxonomie.taxref_protection_especes DROP CONSTRAINT taxref_protection_especes_cd_nom_fkey;
ALTER TABLE bryophytes.cor_bryo_taxon DROP CONSTRAINT cor_bryo_taxons_cd_nom_fkey;
ALTER TABLE florestation.cor_fs_taxon DROP CONSTRAINT cor_fs_taxons_cd_nom_fkey;
ALTER TABLE florepatri.bib_taxons_fp DROP CONSTRAINT bib_taxons_fp_cd_nom_fkey;
--PNE
--ALTER TABLE associations.bdf05_t_releves DROP CONSTRAINT fk_bdf05_t_releves_cd_nom;
TRUNCATE TABLE taxonomie.taxref;
ALTER TABLE taxonomie.taxref ADD cd_sup integer;
INSERT INTO taxonomie.taxref
      SELECT cd_nom, fr as id_statut, habitat::int as id_habitat, rang as  id_rang, regne, phylum, classe, 
             ordre, famille, cd_taxsup, cd_ref, lb_nom, substring(lb_auteur, 1, 150), nom_complet, 
             nom_valide, nom_vern, nom_vern_eng, group1_inpn, group2_inpn, nom_complet_html, cd_sup
        FROM taxonomie.import_taxref
        WHERE regne = 'Animalia' ---selection des taxons faune-flore-fonge uniquement--
        OR regne = 'Fungi'
        OR regne = 'Plantae';
        
--restauration des clés étrangères
--Cette opération peut nécessiter un nettoyage des données (voir taxref_change)
ALTER TABLE taxonomie.bib_taxons
  ADD CONSTRAINT fk_bib_taxons_taxref FOREIGN KEY (cd_nom)
      REFERENCES taxonomie.taxref (cd_nom) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE bryophytes.cor_bryo_taxon
  ADD CONSTRAINT cor_bryo_taxons_cd_nom_fkey FOREIGN KEY (cd_nom)
      REFERENCES taxonomie.taxref (cd_nom) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE florestation.cor_fs_taxon
  ADD CONSTRAINT cor_fs_taxons_cd_nom_fkey FOREIGN KEY (cd_nom)
      REFERENCES taxonomie.taxref (cd_nom) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION;
      
ALTER TABLE florepatri.bib_taxons_fp
  ADD CONSTRAINT bib_taxons_fp_cd_nom_fkey FOREIGN KEY (cd_nom)
      REFERENCES taxonomie.taxref (cd_nom) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION;
--PNE     
--ALTER TABLE associations.bdf05_t_releves
  --ADD CONSTRAINT fk_bdf05_t_releves_cd_nom FOREIGN KEY (cd_nom)
     -- REFERENCES taxonomie.taxref (cd_nom) MATCH SIMPLE
     -- ON UPDATE CASCADE ON DELETE NO ACTION;
      
       
--------------------Statuts juridiques--------------------

TRUNCATE TABLE taxonomie.taxref_protection_articles CASCADE;
ALTER TABLE taxonomie.taxref_protection_articles DROP COLUMN protection;
ALTER TABLE taxonomie.taxref_protection_articles DROP COLUMN fichier;
ALTER TABLE taxonomie.taxref_protection_articles DROP COLUMN fg_afprot;
ALTER TABLE taxonomie.taxref_protection_articles DROP COLUMN niveau;
ALTER TABLE taxonomie.taxref_protection_articles DROP COLUMN cd_arrete;
ALTER TABLE taxonomie.taxref_protection_articles ADD COLUMN url_inpn character varying(250);
ALTER TABLE taxonomie.taxref_protection_articles ADD COLUMN cd_doc integer;

COPY taxonomie.taxref_protection_articles (cd_protection, article, intitule, arrete, url_inpn, cd_doc, url, date_arrete, type_protection)
FROM  '/home/synthese/geonature/data/inpn/PROTECTION_ESPECES_TYPES_90.csv'
WITH  CSV HEADER 
DELIMITER ';'  encoding 'LATIN1';

---import des statuts de protections associés aux taxons
CREATE TABLE taxonomie.import_protection_especes (
	cd_nom int,
	cd_protection varchar(250),
	nom_cite text,
	syn_cite text,
	nom_francais_cite text,
	precisions varchar(500),
	cd_nom_cite int
);

COPY taxonomie.import_protection_especes
FROM  '/home/synthese/geonature/data/inpn/PROTECTION_ESPECES_90.csv'
WITH  CSV HEADER 
DELIMITER ';'  encoding 'LATIN1';


INSERT INTO taxonomie.taxref_protection_especes
SELECT DISTINCT  p.* 
FROM  (
  SELECT cd_nom , cd_protection , string_agg(DISTINCT nom_cite, ',') nom_cite, 
    string_agg(DISTINCT syn_cite, ',')  syn_cite, string_agg(DISTINCT nom_francais_cite, ',')  nom_francais_cite,
    string_agg(DISTINCT precisions, ',')  precisions, cd_nom_cite 
  FROM taxonomie.import_protection_especes
  GROUP BY cd_nom , cd_protection , cd_nom_cite 
) p
JOIN taxonomie.taxref t
USING(cd_nom) ;

DROP TABLE taxonomie.import_protection_especes;

ALTER TABLE taxonomie.taxref_protection_especes
  ADD CONSTRAINT taxref_protection_especes_cd_nom_fkey FOREIGN KEY (cd_nom)
      REFERENCES taxonomie.taxref (cd_nom) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION;

--- Nettoyage des statuts de protections non utilisés
DELETE FROM  taxonomie.taxref_protection_articles
WHERE cd_protection IN (
  SELECT cd_protection 
  FROM taxonomie.taxref_protection_articles
  WHERE NOT cd_protection IN (SELECT DISTINCT cd_protection FROM taxonomie.taxref_protection_especes)
);

