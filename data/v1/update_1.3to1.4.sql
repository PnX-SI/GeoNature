DROP INDEX taxonomie.fki_bib_taxons_bib_groupes;
DROP VIEW contactfaune.v_nomade_taxons_faune;
DROP VIEW contactinv.v_nomade_taxons_inv;
DROP VIEW contactfaune.v_nomade_classes;
DROP VIEW contactinv.v_nomade_classes;
DROP VIEW contactfaune.v_nomade_criteres_cf;
DROP TABLE contactfaune.cor_critere_groupe;
ALTER TABLE taxonomie.bib_taxons DROP CONSTRAINT bib_taxons_id_groupe_fkey;
ALTER TABLE taxonomie.bib_taxons DROP COLUMN id_groupe;
DROP TABLE taxonomie.bib_groupes;

DROP VIEW synthese.v_tree_taxons_synthese;

DROP TRIGGER tri_maj_cor_unite_taxon ON synthese.cor_unite_synthese;


CREATE SEQUENCE taxonomie.bib_listes_id_liste_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1000000
  CACHE 1;
ALTER TABLE taxonomie.bib_listes_id_liste_seq OWNER TO geonatuser;
  

CREATE SEQUENCE taxonomie.bib_attributs_id_attribut_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1000000
  CACHE 1;
ALTER TABLE taxonomie.bib_attributs_id_attribut_seq OWNER TO geonatuser;
  

CREATE TABLE taxonomie.bib_listes
(
  id_liste integer NOT NULL DEFAULT nextval('taxonomie.bib_listes_id_liste_seq'::regclass),
  nom_liste character varying(255) NOT NULL,
  desc_liste text,
  picto character varying(50), -- Indique le chemin vers l'image du picto représentant le groupe taxonomique dans les menus déroulants de taxons
  CONSTRAINT pk_bib_listes PRIMARY KEY (id_liste)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE taxonomie.bib_listes OWNER TO geonatuser;
GRANT ALL ON TABLE taxonomie.bib_listes TO geonatuser;
COMMENT ON COLUMN taxonomie.bib_listes.picto IS 'Indique le chemin vers l''image du picto représentant le groupe taxonomique dans les menus déroulants de taxons';



--
-- Data for Name: bib_listes; Type: TABLE DATA; Schema: taxonomie; Owner: geonatuser
--

INSERT INTO taxonomie.bib_listes VALUES (1, 'liste faune vertébré', 'Liste de test servant à l''affichage des taxons de la faune vertébré pouvant être saisis', 'images/pictos/nopicto.gif');
INSERT INTO taxonomie.bib_listes VALUES (3, 'liste flore', 'Liste de test servant à l''affichage des taxons de la flore pouvant être saisis', 'images/pictos/nopicto.gif');
INSERT INTO taxonomie.bib_listes VALUES (2, 'liste faune invertébré', 'Liste de test servant à l''affichage des taxons de la faune invertébré pouvant être saisis', 'images/pictos/nopicto.gif');
INSERT INTO taxonomie.bib_listes VALUES (102, 'Pycnogonides', NULL, 'images/pictos/nopicto.gif');
INSERT INTO taxonomie.bib_listes VALUES (104, 'Echinodermes', NULL, 'images/pictos/nopicto.gif');
INSERT INTO taxonomie.bib_listes VALUES (103, 'Entognathes', NULL, 'images/pictos/nopicto.gif');
INSERT INTO taxonomie.bib_listes VALUES (111, 'Myriapodes', NULL, 'images/pictos/nopicto.gif');
INSERT INTO taxonomie.bib_listes VALUES (114, 'Vers', NULL, 'images/pictos/nopicto.gif');
INSERT INTO taxonomie.bib_listes VALUES (116, 'Tardigrades', NULL, 'images/pictos/nopicto.gif');
INSERT INTO taxonomie.bib_listes VALUES (202, 'Gastéropodes', NULL, 'images/pictos/nopicto.gif');
INSERT INTO taxonomie.bib_listes VALUES (115, 'Rotifères', NULL, 'images/pictos/nopicto.gif');
INSERT INTO taxonomie.bib_listes VALUES (201, 'Bivalves', NULL, 'images/pictos/nopicto.gif');
INSERT INTO taxonomie.bib_listes VALUES (666, 'Nuisibles', NULL, 'images/pictos/nopicto.gif');
INSERT INTO taxonomie.bib_listes VALUES (1003, 'Algues', NULL, 'images/pictos/nopicto.gif');
INSERT INTO taxonomie.bib_listes VALUES (1002, 'Lichens', NULL, 'images/pictos/nopicto.gif');
INSERT INTO taxonomie.bib_listes VALUES (1001, 'Bryophytes', NULL, 'images/pictos/mousse.gif');
INSERT INTO taxonomie.bib_listes VALUES (1004, 'Champignons', NULL, 'images/pictos/champignnon.gif');
INSERT INTO taxonomie.bib_listes VALUES (1000, 'Plantes vasculaires', NULL, 'images/pictos/plante.gif');
INSERT INTO taxonomie.bib_listes VALUES (113, 'Mollusques', NULL, 'images/pictos/mollusque.gif');
INSERT INTO taxonomie.bib_listes VALUES (112, 'Arachnides', NULL, 'images/pictos/araignee.gif');
INSERT INTO taxonomie.bib_listes VALUES (110, 'Reptiles', NULL, 'images/pictos/reptile.gif');
INSERT INTO taxonomie.bib_listes VALUES (109, 'Poissons', NULL, 'images/pictos/poisson.gif');
INSERT INTO taxonomie.bib_listes VALUES (108, 'Oiseaux', NULL, 'images/pictos/oiseau.gif');
INSERT INTO taxonomie.bib_listes VALUES (107, 'Mammifères', NULL, 'images/pictos/mammifere.gif');
INSERT INTO taxonomie.bib_listes VALUES (106, 'Insectes', NULL, 'images/pictos/insecte.gif');
INSERT INTO taxonomie.bib_listes VALUES (105, 'Ecrevisses', NULL, 'images/pictos/ecrevisse.gif');
INSERT INTO taxonomie.bib_listes VALUES (101, 'Amphibiens', NULL, 'images/pictos/amphibien.gif');


CREATE TABLE contactfaune.cor_critere_liste
(
  id_critere_cf integer NOT NULL,
  id_liste integer NOT NULL,
  CONSTRAINT pk_cor_critere_liste PRIMARY KEY (id_critere_cf, id_liste),
  CONSTRAINT fk_cor_critere_liste_bib_criter FOREIGN KEY (id_critere_cf)
      REFERENCES contactfaune.bib_criteres_cf (id_critere_cf) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION,
  CONSTRAINT fk_cor_critere_liste_bib_listes FOREIGN KEY (id_liste)
      REFERENCES taxonomie.bib_listes (id_liste) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE contactfaune.cor_critere_liste OWNER TO geonatuser;
GRANT ALL ON TABLE contactfaune.cor_critere_liste TO geonatuser;


CREATE TABLE taxonomie.cor_taxon_liste
(
  id_liste integer NOT NULL,
  id_taxon integer NOT NULL,
  CONSTRAINT cor_taxon_liste_pkey PRIMARY KEY (id_taxon, id_liste),
  CONSTRAINT cor_taxon_liste_bib_listes_fkey FOREIGN KEY (id_liste)
      REFERENCES taxonomie.bib_listes (id_liste) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION,
  CONSTRAINT cor_taxon_liste_bib_taxons_fkey FOREIGN KEY (id_taxon)
      REFERENCES taxonomie.bib_taxons (id_taxon) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE taxonomie.cor_taxon_liste
  OWNER TO geonatuser;
GRANT ALL ON TABLE taxonomie.cor_taxon_liste TO geonatuser;
GRANT ALL ON TABLE contactfaune.cor_critere_liste TO geonatuser;

CREATE TABLE taxonomie.bib_filtres
(
  id_filtre integer NOT NULL,
  nom_filtre character varying(50),
  label1 character varying(50),
  label2 character varying(50),
  label3 character varying(50),
  descr_filtre character varying(500),
  img character varying(250),
  valeur_filtre character varying(1000),
  obligatoire boolean DEFAULT false,
  CONSTRAINT bib_filtres_pkey PRIMARY KEY (id_filtre)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE taxonomie.bib_filtres OWNER TO geonatuser;
INSERT INTO taxonomie.bib_filtres VALUES (2, 'patrimonial', 'Patrimoniale', NULL, NULL, 'Défini si le taxon est patrimonial pour le territoire', NULL, 'oui;non', true);
INSERT INTO taxonomie.bib_filtres VALUES (4, 'reproducteur', 'Reproducteur', NULL, NULL, 'Indique si le taxon est reproducteur sur le territoire', NULL, 'oui;non', false);
INSERT INTO taxonomie.bib_filtres VALUES (1, 'saisie', NULL, NULL, NULL, 'Permet d''exclure des taxons des menus déroulants de saisie', NULL, 'oui;non', true);
INSERT INTO taxonomie.bib_filtres VALUES (5, 'responsabilite_pne', 'Responsabilité', 'Responsabilité du PN Ecrins', NULL, 'Indique le niveau de responsabilité du PNE vis à vis de la conservation de ce taxon', NULL, 'nulle;faible;moyenne;forte;indéterminée', true);
INSERT INTO taxonomie.bib_filtres VALUES (6, 'statut_migration', 'Migrateur', 'Statut de migrateur', NULL, 'Indique le comportement de migrateur du taxon', NULL, 'sédentaire;migrateur-erratique-hivernant;estivant;disparu;absent;inconnu', true);
INSERT INTO taxonomie.bib_filtres VALUES (7, 'importance_population', 'Population', 'Importance de la population', NULL, 'Indique l''importance de la population pour le territoire', NULL, 'inexistante;anecdoctique;localisée;faible;moyenne;significative;inconnue', false);
INSERT INTO taxonomie.bib_filtres VALUES (3, 'protection_stricte', 'Protection stricte', 'Taxon protégé', NULL, 'Indique si le taxon est bénéficie d''un statut de protection sur le territoire (en excluant les statuts de réglementation)', NULL, 'oui;non', true);
INSERT INTO taxonomie.bib_filtres VALUES (8, 'règlementé', 'Règlementation', 'Taxon règlementé', NULL, 'Indique que le taxon fait l''objet d''une réglementation sur le territoire', NULL, 'oui;non', false);

-- Pour la compatibilité avec le futur TaxHub mais la notion d'attribut n'est pas utilisée dans GeoNature pour le moment
CREATE TABLE taxonomie.bib_attributs
(
  id_attribut integer NOT NULL DEFAULT nextval('taxonomie.bib_attributs_id_attribut_seq'::regclass),
  nom_attribut character varying(255) NOT NULL,
  label_attribut character varying(50) NOT NULL,
  liste_valeur_attribut text NOT NULL,
  obligatoire boolean NOT NULL,
  desc_attribut text,
  type_attribut character varying(50),
  CONSTRAINT pk_bib_attributs PRIMARY KEY (id_attribut)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE taxonomie.bib_attributs OWNER TO geonatuser;
GRANT ALL ON TABLE taxonomie.bib_attributs TO geonatuser;
INSERT INTO taxonomie.bib_attributs VALUES (1, 'patrimonial', 'Patrimonial', 'oui;non', true, 'Défini si le taxon est patrimonial pour le territoire', NULL);
INSERT INTO taxonomie.bib_attributs VALUES (2, 'protection_stricte', 'Protégé', 'oui;non', true, 'Défini si le taxon bénéficie d''une protection juridique stricte pour le territoire', NULL);


CREATE TABLE taxonomie.cor_taxon_attribut
(
  id_taxon integer NOT NULL,
  id_attribut integer NOT NULL,
  valeur_attribut character varying(50) NOT NULL,
  CONSTRAINT cor_taxon_attribut_pkey PRIMARY KEY (id_taxon, id_attribut),
  CONSTRAINT cor_taxon_attrib_bib_attrib_fkey FOREIGN KEY (id_attribut)
      REFERENCES taxonomie.bib_attributs (id_attribut) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT cor_taxon_attrib_bib_taxons_fkey FOREIGN KEY (id_taxon)
      REFERENCES taxonomie.bib_taxons (id_taxon) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE taxonomie.cor_taxon_attribut OWNER TO geonatuser;
GRANT ALL ON TABLE taxonomie.cor_taxon_attribut TO geonatuser;


ALTER TABLE taxonomie.bib_taxons DROP COLUMN saisie_autorisee;
ALTER TABLE taxonomie.bib_taxons DROP COLUMN patrimonial;
ALTER TABLE taxonomie.bib_taxons DROP COLUMN protection_stricte;
ALTER TABLE taxonomie.bib_taxons ADD COLUMN filtre1 character varying(255);
ALTER TABLE taxonomie.bib_taxons ADD COLUMN filtre2 character varying(255);
ALTER TABLE taxonomie.bib_taxons ADD COLUMN filtre3 character varying(255);
ALTER TABLE taxonomie.bib_taxons ADD COLUMN filtre4 character varying(255);
ALTER TABLE taxonomie.bib_taxons ADD COLUMN filtre5 character varying(255);
ALTER TABLE taxonomie.bib_taxons ADD COLUMN filtre6 character varying(255);
ALTER TABLE taxonomie.bib_taxons ADD COLUMN filtre7 character varying(255);
ALTER TABLE taxonomie.bib_taxons ADD COLUMN filtre8 character varying(255);
ALTER TABLE taxonomie.bib_taxons ADD COLUMN filtre9 character varying(255);
ALTER TABLE taxonomie.bib_taxons ADD COLUMN filtre10 character varying(255);

-- Préparation taxref V8. Non utilisé dans GeoNature
ALTER TABLE taxonomie.taxref ADD COLUMN nom_complet_html character varying(255);
--évolution de généricité
ALTER TABLE taxonomie.taxref_protection_articles RENAME pn  TO concerne_mon_territoire;


--INSERT INTO taxonomie.cor_taxon_liste VALUES (101, 23);
--INSERT INTO taxonomie.cor_taxon_liste VALUES (107, 64);
--INSERT INTO taxonomie.cor_taxon_liste VALUES (109, 704);
--INSERT INTO taxonomie.cor_taxon_liste VALUES (105, 816);
--INSERT INTO taxonomie.cor_taxon_liste VALUES (106, 1950);
--INSERT INTO taxonomie.cor_taxon_liste VALUES (106, 2804);


INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (31, 101);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (32, 101);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (33, 101);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (34, 101);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (21, 107);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (22, 107);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (23, 107);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (24, 107);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (25, 107);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (26, 107);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (6, 108);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (7, 108);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (8, 108);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (9, 108);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (10, 108);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (11, 108);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (12, 108);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (13, 108);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (14, 108);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (15, 108);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (16, 108);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (17, 108);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (18, 108);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (19, 108);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (20, 108);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (35, 109);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (36, 109);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (37, 109);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (38, 109);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (27, 110);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (28, 110);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (29, 110);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (30, 110);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (5, 101);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (5, 107);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (5, 108);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (5, 109);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (5, 110);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (4, 101);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (4, 107);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (4, 108);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (3, 108);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (3, 107);
INSERT INTO contactfaune.cor_critere_liste (id_critere_cf, id_liste) VALUES (3, 110);


ALTER TABLE florestation.t_stations_fs ALTER COLUMN info_acces TYPE character varying(1000);


DROP FUNCTION contactinv.couleur_taxon(integer, date);
CREATE OR REPLACE FUNCTION contactinv.couleur_taxon(
    id integer,
    maxdateobs date)
  RETURNS text AS
$BODY$
  DECLARE
  couleur text;
  patri boolean;
  BEGIN
	SELECT patrimonial INTO patri 
    FROM taxonomie.bib_taxons t 
    LEFT JOIN taxonomie.cor_taxon_attribut cta ON cta.id_taxon = t.id_taxon
    LEFT JOIN taxonomie.bib_attributs a ON a.id_attribut = cta.id_attribut
    WHERE a.nom_attribut = 'patrimonial' AND t.id_taxon = id;
	IF patri = 't' THEN
		IF date_part('year',maxdateobs)=date_part('year',now()) THEN couleur = 'gray';
		ELSE couleur = 'red';
		END IF;
	ELSIF patri = 'f' THEN
		IF date_part('year',maxdateobs)>=date_part('year',now())-3 THEN couleur = 'gray';
		ELSE couleur = 'red';
		END IF;
	ELSE
	return false;	
	END IF;
	return couleur;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION contactinv.couleur_taxon(integer, date)
  OWNER TO geonatuser;

DROP FUNCTION contactinv.couleur_taxon(integer, date);
CREATE OR REPLACE FUNCTION contactinv.couleur_taxon(
    id integer,
    maxdateobs date)
  RETURNS text AS
$BODY$
  DECLARE
  couleur text;
  patri boolean;
  BEGIN
	SELECT patrimonial INTO patri 
    FROM taxonomie.bib_taxons t 
    LEFT JOIN taxonomie.cor_taxon_attribut cta ON cta.id_taxon = t.id_taxon
    LEFT JOIN taxonomie.bib_attributs a ON a.id_attribut = cta.id_attribut
    WHERE a.nom_attribut = 'patrimonial' AND t.id_taxon = id;
	IF patri = 't' THEN
		IF date_part('year',maxdateobs)=date_part('year',now()) THEN couleur = 'gray';
		ELSE couleur = 'red';
		END IF;
	ELSIF patri = 'f' THEN
		IF date_part('year',maxdateobs)>=date_part('year',now())-3 THEN couleur = 'gray';
		ELSE couleur = 'red';
		END IF;
	ELSE
	return false;	
	END IF;
	return couleur;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION contactinv.couleur_taxon(integer, date) OWNER TO geonatuser;

DROP FUNCTION synthese.maj_cor_unite_taxon();
CREATE OR REPLACE FUNCTION synthese.maj_cor_unite_taxon()
  RETURNS trigger AS
$BODY$
DECLARE
monembranchement varchar;
monregne varchar;
BEGIN

IF (TG_OP = 'DELETE') THEN
	--calcul du règne du taxon supprimé
		SELECT  INTO monregne tx.regne FROM taxonomie.taxref tx WHERE tx.cd_nom = old.cd_nom;
	IF monregne = 'Animalia' THEN
		--calcul de l'embranchement du taxon supprimé
			SELECT  INTO monembranchement tx.phylum FROM taxonomie.taxref tx WHERE tx.cd_nom = old.cd_nom;
		-- puis recalul des couleurs avec old.id_unite_geo et old.taxon selon que le taxon est vertébrés (embranchemet 1) ou invertébres
			IF monembranchement = 'Chordata' THEN
				IF (SELECT count(*) FROM synthese.cor_unite_synthese WHERE cd_nom = old.cd_nom AND id_unite_geo = old.id_unite_geo)= 0 THEN
					DELETE FROM contactfaune.cor_unite_taxon WHERE cd_nom = old.cd_nom AND id_unite_geo = old.id_unite_geo;
				ELSE
					PERFORM synthese.calcul_cor_unite_taxon_cf(old.cd_nom, old.id_unite_geo);
				END IF;
			ELSE
				IF (SELECT count(*) FROM synthese.cor_unite_synthese WHERE cd_nom = old.cd_nom AND id_unite_geo = old.id_unite_geo)= 0 THEN
					DELETE FROM contactinv.cor_unite_taxon_inv WHERE cd_nom = old.cd_nom AND id_unite_geo = old.id_unite_geo;
				ELSE
					PERFORM synthese.calcul_cor_unite_taxon_inv(old.cd_nom, old.id_unite_geo);
				END IF;
			END IF;
		END IF;
		RETURN OLD;		
ELSIF (TG_OP = 'INSERT') THEN
	--calcul du règne du taxon inséré
		SELECT  INTO monregne tx.regne FROM taxonomie.taxref tx WHERE tx.cd_nom = new.cd_nom;
	IF monregne = 'Animalia' THEN
		--calcul de l'embranchement du taxon inséré
		SELECT INTO monembranchement tx.phylum FROM taxonomie.taxref tx WHERE tx.cd_nom = new.cd_nom;
		-- puis recalul des couleurs avec new.id_unite_geo et new.taxon selon que le taxon est vertébrés (embranchemet 1) ou invertébres
		IF monembranchement = 'Chordata' THEN
		    PERFORM synthese.calcul_cor_unite_taxon_cf(new.cd_nom, new.id_unite_geo);
		ELSE
		    PERFORM synthese.calcul_cor_unite_taxon_inv(new.cd_nom, new.id_unite_geo);
		END IF;
        END IF;
	RETURN NEW;
END IF;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION synthese.maj_cor_unite_taxon()
  OWNER TO geonatuser;
GRANT EXECUTE ON FUNCTION synthese.maj_cor_unite_taxon() TO geonatuser;


CREATE OR REPLACE VIEW contactfaune.v_nomade_classes AS 
 SELECT g.id_liste AS id_classe,
    g.nom_liste AS nom_classe_fr,
    g.desc_liste AS desc_classe
   FROM ( SELECT l.id_liste,
            l.nom_liste,
            l.desc_liste,
            min(taxonomie.find_cdref(tx.cd_nom)) AS cd_ref
           FROM taxonomie.bib_listes l
             JOIN taxonomie.cor_taxon_liste ctl ON ctl.id_liste = l.id_liste
             JOIN taxonomie.bib_taxons tx ON tx.id_taxon = ctl.id_taxon
          GROUP BY l.id_liste, l.nom_liste, l.desc_liste) g
     JOIN taxonomie.taxref t ON t.cd_nom = g.cd_ref
  WHERE t.phylum::text = 'Chordata'::text;
ALTER TABLE contactfaune.v_nomade_classes OWNER TO geonatuser;
GRANT ALL ON TABLE contactfaune.v_nomade_classes TO geonatuser;

CREATE OR REPLACE VIEW contactinv.v_nomade_classes AS 
 SELECT g.id_liste AS id_classe,
    g.nom_liste AS nom_classe_fr,
    g.desc_liste AS desc_classe
   FROM ( SELECT l.id_liste,
            l.nom_liste,
            l.desc_liste,
            min(taxonomie.find_cdref(tx.cd_nom)) AS cd_ref
           FROM taxonomie.bib_listes l
             JOIN taxonomie.cor_taxon_liste ctl ON ctl.id_liste = l.id_liste
             JOIN taxonomie.bib_taxons tx ON tx.id_taxon = ctl.id_taxon
          GROUP BY l.id_liste, l.nom_liste, l.desc_liste) g
     JOIN taxonomie.taxref t ON t.cd_nom = g.cd_ref
  WHERE t.phylum::text <> 'Chordata'::text AND t.regne::text = 'Animalia'::text;
ALTER TABLE contactinv.v_nomade_classes OWNER TO geonatuser;
GRANT ALL ON TABLE contactinv.v_nomade_classes TO geonatuser;


CREATE OR REPLACE VIEW contactfaune.v_nomade_criteres_cf AS 
 SELECT c.id_critere_cf,
    c.nom_critere_cf,
    c.tri_cf,
    ccl.id_liste AS id_classe
   FROM contactfaune.bib_criteres_cf c
     JOIN contactfaune.cor_critere_liste ccl ON ccl.id_critere_cf = c.id_critere_cf
  ORDER BY ccl.id_liste, c.tri_cf;
ALTER TABLE contactfaune.v_nomade_criteres_cf OWNER TO geonatuser;
GRANT ALL ON TABLE contactfaune.v_nomade_criteres_cf TO geonatuser;


CREATE OR REPLACE VIEW contactfaune.v_nomade_taxons_faune AS 
 SELECT DISTINCT t.id_taxon,
    taxonomie.find_cdref(tx.cd_nom) AS cd_ref,
    tx.cd_nom,
    t.nom_latin,
    t.nom_francais,
    g.id_classe,
    5 AS denombrement,
        CASE
            WHEN t.filtre2::text = 'oui'::text THEN true
            WHEN t.filtre2::text = 'non'::text THEN false
            ELSE NULL::boolean
        END AS patrimonial,
    m.texte_message_cf AS message,
    true AS contactfaune,
    true AS mortalite
   FROM taxonomie.bib_taxons t
     LEFT JOIN contactfaune.cor_message_taxon cmt ON cmt.id_taxon = t.id_taxon
     LEFT JOIN contactfaune.bib_messages_cf m ON m.id_message_cf = cmt.id_message_cf
     JOIN taxonomie.cor_taxon_liste ctl ON ctl.id_taxon = t.id_taxon
     JOIN contactfaune.v_nomade_classes g ON g.id_classe = ctl.id_liste
     JOIN taxonomie.taxref tx ON tx.cd_nom = t.cd_nom
  WHERE ctl.id_liste = ANY (ARRAY[101, 107, 108, 109, 110])
  ORDER BY t.id_taxon, taxonomie.find_cdref(tx.cd_nom), t.nom_latin, t.nom_francais, g.id_classe,
        CASE
            WHEN t.filtre2::text = 'oui'::text THEN true
            WHEN t.filtre2::text = 'non'::text THEN false
            ELSE NULL::boolean
        END, m.texte_message_cf;
ALTER TABLE contactfaune.v_nomade_taxons_faune OWNER TO geonatuser;
GRANT ALL ON TABLE contactfaune.v_nomade_taxons_faune TO geonatuser;


CREATE OR REPLACE VIEW contactinv.v_nomade_taxons_inv AS 
 SELECT DISTINCT t.id_taxon,
    taxonomie.find_cdref(tx.cd_nom) AS cd_ref,
    tx.cd_nom,
    t.nom_latin,
    t.nom_francais,
    g.id_classe,
        CASE
            WHEN t.filtre2::text = 'oui'::text THEN true
            WHEN t.filtre2::text = 'non'::text THEN false
            ELSE NULL::boolean
        END AS patrimonial,
    m.texte_message_inv AS message
   FROM taxonomie.bib_taxons t
     LEFT JOIN contactinv.cor_message_taxon cmt ON cmt.id_taxon = t.id_taxon
     LEFT JOIN contactinv.bib_messages_inv m ON m.id_message_inv = cmt.id_message_inv
     JOIN taxonomie.cor_taxon_liste ctl ON ctl.id_taxon = t.id_taxon
     JOIN contactinv.v_nomade_classes g ON g.id_classe = ctl.id_liste
     JOIN taxonomie.taxref tx ON tx.cd_nom = t.cd_nom
  WHERE ctl.id_liste = ANY (ARRAY[104, 105, 106, 111, 112, 113, 114]);
ALTER TABLE contactinv.v_nomade_taxons_inv OWNER TO geonatuser;
GRANT ALL ON TABLE contactinv.v_nomade_taxons_inv TO geonatuser;

-- View: synthese.v_tree_taxons_synthese

-- DROP VIEW synthese.v_tree_taxons_synthese;

CREATE OR REPLACE VIEW synthese.v_tree_taxons_synthese AS 
 WITH taxon AS (
         SELECT tx.id_taxon,
            tx.nom_latin,
            tx.nom_francais,
            taxref.cd_nom,
            taxref.id_statut,
            taxref.id_habitat,
            taxref.id_rang,
            taxref.regne,
            taxref.phylum,
            taxref.classe,
            taxref.ordre,
            taxref.famille,
            taxref.cd_taxsup,
            taxref.cd_ref,
            taxref.lb_nom,
            taxref.lb_auteur,
            taxref.nom_complet,
            taxref.nom_valide,
            taxref.nom_vern,
            taxref.nom_vern_eng,
            taxref.group1_inpn,
            taxref.group2_inpn
           FROM ( SELECT tx_1.id_taxon,
                    taxref_1.cd_nom,
                    taxonomie.find_cdref(taxref_1.cd_nom) AS cd_ref,
                    taxref_1.lb_nom AS nom_latin,
                        CASE
                            WHEN tx_1.nom_francais IS NULL THEN taxref_1.lb_nom
                            WHEN tx_1.nom_francais::text = ''::text THEN taxref_1.lb_nom
                            ELSE tx_1.nom_francais
                        END AS nom_francais
                   FROM taxonomie.taxref taxref_1
                     LEFT JOIN taxonomie.bib_taxons tx_1 ON tx_1.cd_nom = taxref_1.cd_nom
                  WHERE (taxref_1.cd_nom IN ( SELECT DISTINCT syntheseff.cd_nom
                           FROM synthese.syntheseff
                          ORDER BY syntheseff.cd_nom))) tx
             JOIN taxonomie.taxref taxref ON taxref.cd_nom = tx.cd_ref
        )
 SELECT t.id_taxon,
    t.cd_ref,
    t.nom_latin,
    t.nom_francais,
    t.id_regne,
    t.nom_regne,
    COALESCE(t.id_embranchement, t.id_regne) AS id_embranchement,
    COALESCE(t.nom_embranchement, ' Sans embranchement dans taxref'::character varying) AS nom_embranchement,
    COALESCE(t.id_classe, t.id_embranchement) AS id_classe,
    COALESCE(t.nom_classe, ' Sans classe dans taxref'::character varying) AS nom_classe,
    COALESCE(t.desc_classe, ' Sans classe dans taxref'::character varying) AS desc_classe,
    COALESCE(t.id_ordre, t.id_classe) AS id_ordre,
    COALESCE(t.nom_ordre, ' Sans ordre dans taxref'::character varying) AS nom_ordre,
    COALESCE(t.id_famille, t.id_ordre) AS id_famille,
    COALESCE(t.nom_famille, ' Sans famille dans taxref'::character varying) AS nom_famille
   FROM ( SELECT DISTINCT t_1.id_taxon,
            t_1.cd_ref,
            t_1.nom_latin,
            t_1.nom_francais,
            ( SELECT taxref.cd_nom
                   FROM taxonomie.taxref
                  WHERE taxref.id_rang = 'KD'::bpchar AND taxref.lb_nom::text = t_1.regne::text) AS id_regne,
            t_1.regne AS nom_regne,
                CASE
                    WHEN t_1.phylum IS NULL THEN NULL::integer
                    ELSE ( SELECT taxref.cd_nom
                       FROM taxonomie.taxref
                      WHERE taxref.id_rang = 'PH'::bpchar AND taxref.lb_nom::text = t_1.phylum::text AND taxref.cd_nom = taxref.cd_ref)
                END AS id_embranchement,
            t_1.phylum AS nom_embranchement,
            t_1.phylum AS desc_embranchement,
                CASE
                    WHEN t_1.classe IS NULL THEN NULL::integer
                    ELSE ( SELECT taxref.cd_nom
                       FROM taxonomie.taxref
                      WHERE taxref.id_rang = 'CL'::bpchar AND taxref.lb_nom::text = t_1.classe::text AND taxref.cd_nom = taxref.cd_ref)
                END AS id_classe,
            t_1.classe AS nom_classe,
            t_1.classe AS desc_classe,
                CASE
                    WHEN t_1.ordre IS NULL THEN NULL::integer
                    ELSE ( SELECT taxref.cd_nom
                       FROM taxonomie.taxref
                      WHERE taxref.id_rang = 'OR'::bpchar AND taxref.lb_nom::text = t_1.ordre::text AND taxref.cd_nom = taxref.cd_ref)
                END AS id_ordre,
            t_1.ordre AS nom_ordre,
                CASE
                    WHEN t_1.famille IS NULL THEN NULL::integer
                    ELSE ( SELECT taxref.cd_nom
                       FROM taxonomie.taxref
                      WHERE taxref.id_rang = 'FM'::bpchar AND taxref.lb_nom::text = t_1.famille::text AND taxref.phylum::text = t_1.phylum::text AND taxref.cd_nom = taxref.cd_ref)
                END AS id_famille,
            t_1.famille AS nom_famille
           FROM taxon t_1) t;

ALTER TABLE synthese.v_tree_taxons_synthese OWNER TO geonatuser;
GRANT ALL ON TABLE synthese.v_tree_taxons_synthese TO geonatuser;


CREATE OR REPLACE VIEW synthese.v_taxons_synthese AS 
 SELECT DISTINCT
        CASE
            WHEN (t.nom_francais::text = ''::text OR t.nom_francais IS NULL) AND txr.nom_vern IS NOT NULL AND txr.nom_vern::text <> ''::text THEN txr.nom_vern
            WHEN t.nom_francais IS NULL OR txr.nom_vern IS NULL THEN txr.lb_nom
            WHEN t.nom_francais::text = ''::text OR txr.nom_vern::text = ''::text THEN txr.lb_nom
            ELSE t.nom_francais
        END AS nom_francais,
    txr.lb_nom AS nom_latin,
        CASE
            WHEN t.filtre2::text = 'oui'::text THEN true
            WHEN t.filtre2::text = 'non'::text THEN false
            ELSE NULL::boolean
        END AS patrimonial,
        CASE
            WHEN t.filtre3::text = 'oui'::text THEN true
            WHEN t.filtre3::text = 'non'::text THEN false
            ELSE NULL::boolean
        END AS protection_stricte,
    txr.cd_ref,
    txr.cd_nom,
    txr.nom_valide,
    txr.famille,
    txr.ordre,
    txr.classe,
    txr.regne,
    prot.protections,
    l.id_liste,
    l.picto
   FROM taxonomie.taxref txr
     LEFT JOIN taxonomie.bib_taxons t ON txr.cd_nom = t.cd_nom
     JOIN taxonomie.cor_taxon_liste ctl ON ctl.id_taxon = t.id_taxon
     JOIN taxonomie.bib_listes l ON l.id_liste = ctl.id_liste AND (l.id_liste = ANY (ARRAY[3, 101, 105, 106, 107, 108, 109, 110, 111, 112, 113]))
     LEFT JOIN ( SELECT a.cd_nom,
            array_to_string(array_agg((((a.arrete || ' '::text) || a.article::text) || '__'::text) || a.url::text), '#'::text) AS protections
           FROM ( SELECT tpe.cd_nom,
                    tpa.url,
                    tpa.arrete,
                    tpa.article
                   FROM taxonomie.taxref_protection_especes tpe
                     JOIN taxonomie.taxref_protection_articles tpa ON tpa.cd_protection::text = tpe.cd_protection::text AND tpa.concerne_mon_territoire = true) a
          GROUP BY a.cd_nom) prot ON prot.cd_nom = txr.cd_nom
  WHERE (txr.cd_nom IN ( SELECT DISTINCT syntheseff.cd_nom
           FROM synthese.syntheseff))
  ORDER BY
        CASE
            WHEN (t.nom_francais::text = ''::text OR t.nom_francais IS NULL) AND txr.nom_vern IS NOT NULL AND txr.nom_vern::text <> ''::text THEN txr.nom_vern
            WHEN t.nom_francais IS NULL OR txr.nom_vern IS NULL THEN txr.lb_nom
            WHEN t.nom_francais::text = ''::text OR txr.nom_vern::text = ''::text THEN txr.lb_nom
            ELSE t.nom_francais
        END;

ALTER TABLE synthese.v_taxons_synthese OWNER TO geonatuser;
GRANT ALL ON TABLE synthese.v_taxons_synthese TO geonatuser;


CREATE TRIGGER tri_maj_cor_unite_taxon
  AFTER INSERT OR DELETE
  ON synthese.cor_unite_synthese
  FOR EACH ROW
  EXECUTE PROCEDURE synthese.maj_cor_unite_taxon();
