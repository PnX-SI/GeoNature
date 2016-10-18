--
-- PostgreSQL database dump
--

-- Dumped from database version 9.3.14
-- Dumped by pg_dump version 9.3.14
-- Started on 2016-08-22 10:09:31 CEST

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 9 (class 2615 OID 101225)
-- Name: taxonomie; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA taxonomie;


SET search_path = taxonomie, pg_catalog;

--
-- TOC entry 1343 (class 1255 OID 184400)
-- Name: fct_build_bibtaxon_attributs_view(character varying); Type: FUNCTION; Schema: taxonomie; Owner: -
--

CREATE FUNCTION fct_build_bibtaxon_attributs_view(sregne character varying) RETURNS void
    LANGUAGE plpgsql
    AS $_$
DECLARE
    r taxonomie.bib_attributs%rowtype;
    sql_select text;
    sql_join text;
    sql_where text;
BEGIN
	sql_join :=' FROM taxonomie.bib_noms b JOIN taxonomie.taxref taxref USING(cd_nom) ';
	sql_select := 'SELECT b.* ';
	sql_where := ' WHERE regne=''' ||$1 || '''';
	FOR r IN
		SELECT id_attribut, nom_attribut, label_attribut, liste_valeur_attribut,
		       obligatoire, desc_attribut, type_attribut, type_widget, regne,
		       group2_inpn
		FROM taxonomie.bib_attributs
		WHERE regne IS NULL OR regne=sregne
	LOOP
		sql_select := sql_select || ', ' || r.nom_attribut || '.valeur_attribut::' || r.type_attribut || ' as ' || r.nom_attribut;
		sql_join := sql_join || ' LEFT OUTER JOIN (SELECT valeur_attribut, cd_ref FROM taxonomie.cor_taxon_attribut WHERE id_attribut= '
			|| r.id_attribut || ') as  ' || r.nom_attribut || '  ON b.cd_ref= ' || r.nom_attribut || '.cd_ref ';

	--RETURN NEXT r; -- return current row of SELECT
	END LOOP;
	EXECUTE 'DROP VIEW IF EXISTS taxonomie.v_bibtaxon_attributs_' || sregne ;
	EXECUTE 'CREATE OR REPLACE VIEW taxonomie.v_bibtaxon_attributs_' || sregne ||  ' AS ' || sql_select || sql_join || sql_where ;
END
$_$;


--
-- TOC entry 1340 (class 1255 OID 101226)
-- Name: find_cdref(integer); Type: FUNCTION; Schema: taxonomie; Owner: -
--

CREATE FUNCTION find_cdref(id integer) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE
    AS $$
--fonction permettant de renvoyer le cd_ref d'un taxon à partir de son cd_nom
--
--Gil DELUERMOZ septembre 2011

  DECLARE ref integer;
  BEGIN
	SELECT INTO ref cd_ref FROM taxonomie.taxref WHERE cd_nom = id;
	return ref;
  END;
$$;


--
-- TOC entry 1342 (class 1255 OID 239038)
-- Name: insert_t_medias(); Type: FUNCTION; Schema: taxonomie; Owner: -
--

CREATE FUNCTION insert_t_medias() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    trimtitre text;
BEGIN
    new.date_media = now();
    trimtitre = replace(new.titre, ' ', '');
    --new.url = new.chemin || new.cd_ref || '_' || trimtitre || '.jpg';
    RETURN NEW;
END;
$$;


CREATE OR REPLACE FUNCTION  trg_fct_refresh_attributesviews_per_kingdom()
  RETURNS trigger AS
$$
DECLARE
   sregne text;
BEGIN
	if NEW.regne IS NULL THEN
		FOR sregne IN
			SELECT DISTINCT regne
			FROM taxonomie.taxref t
			JOIN taxonomie.bib_noms n
			ON t.cd_nom = n.cd_nom
		LOOP
			PERFORM taxonomie.fct_build_bibtaxon_attributs_view(sregne);
		END LOOP;
	ELSE
		PERFORM taxonomie.fct_build_bibtaxon_attributs_view(NEW.regne);
	END IF;
   RETURN NEW;
END
$$  LANGUAGE plpgsql;
--
-- TOC entry 176 (class 1259 OID 101227)
-- Name: bib_attributs_id_attribut_seq; Type: SEQUENCE; Schema: taxonomie; Owner: -
--

CREATE SEQUENCE bib_attributs_id_attribut_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 177 (class 1259 OID 101229)
-- Name: bib_attributs; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace:
--

CREATE TABLE bib_attributs (
    id_attribut integer DEFAULT nextval('bib_attributs_id_attribut_seq'::regclass) NOT NULL,
    nom_attribut character varying(255) NOT NULL,
    label_attribut character varying(50) NOT NULL,
    liste_valeur_attribut text NOT NULL,
    obligatoire boolean NOT NULL DEFAULT(False),
    desc_attribut text,
    type_attribut character varying(50),
    type_widget character varying(50),
    regne character varying(20),
    group2_inpn character varying(255),
    id_theme integer NOT NULL,
    ordre integer
);


--
-- TOC entry 178 (class 1259 OID 101236)
-- Name: bib_listes_id_liste_seq; Type: SEQUENCE; Schema: taxonomie; Owner: -
--

CREATE SEQUENCE bib_listes_id_liste_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 179 (class 1259 OID 101238)
-- Name: bib_listes; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace:
--

CREATE TABLE bib_listes (
    id_liste integer DEFAULT nextval('bib_listes_id_liste_seq'::regclass) NOT NULL,
    nom_liste character varying(255) NOT NULL,
    desc_liste text,
    picto character varying(50),
    regne character varying(20),
    group2_inpn character varying(255)
);


--
-- TOC entry 3534 (class 0 OID 0)
-- Dependencies: 179
-- Name: COLUMN bib_listes.picto; Type: COMMENT; Schema: taxonomie; Owner: -
--

COMMENT ON COLUMN bib_listes.picto IS 'Indique le chemin vers l''image du picto représentant le groupe taxonomique dans les menus déroulants de taxons';


--
-- TOC entry 250 (class 1259 OID 194327)
-- Name: bib_noms; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace:
--

CREATE TABLE bib_noms (
    id_nom integer NOT NULL,
    cd_nom integer,
    cd_ref integer,
    nom_francais character varying(255),
    CONSTRAINT check_is_valid_cd_ref CHECK ((cd_ref = find_cdref(cd_ref)))
);


--
-- TOC entry 249 (class 1259 OID 194325)
-- Name: bib_noms_id_nom_seq; Type: SEQUENCE; Schema: taxonomie; Owner: -
--

CREATE SEQUENCE bib_noms_id_nom_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3535 (class 0 OID 0)
-- Dependencies: 249
-- Name: bib_noms_id_nom_seq; Type: SEQUENCE OWNED BY; Schema: taxonomie; Owner: -
--

ALTER SEQUENCE bib_noms_id_nom_seq OWNED BY bib_noms.id_nom;


--
-- TOC entry 180 (class 1259 OID 101251)
-- Name: bib_taxons_id_taxon_seq; Type: SEQUENCE; Schema: taxonomie; Owner: -
--

CREATE SEQUENCE bib_taxons_id_taxon_seq
    START WITH 2805
    INCREMENT BY 1
    MINVALUE 2805
    NO MAXVALUE
    CACHE 1;

--
-- Name: bib_taxref_categories_lr; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace:
--
    
CREATE TABLE bib_taxref_categories_lr
(
  id_categorie_france character(2) NOT NULL,
  categorie_lr character varying(50) NOT NULL,
  nom_categorie_lr character varying(255) NOT NULL,
  desc_categorie_lr character varying(255)
)

--
-- TOC entry 181 (class 1259 OID 101253)
-- Name: bib_taxref_habitats; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace:
--

CREATE TABLE bib_taxref_habitats (
    id_habitat integer NOT NULL,
    nom_habitat character varying(50) NOT NULL,
    desc_habitat text
);


--
-- TOC entry 182 (class 1259 OID 101259)
-- Name: bib_taxref_rangs; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace:
--

CREATE TABLE bib_taxref_rangs (
    id_rang character(4) NOT NULL,
    nom_rang character varying(20) NOT NULL,
    tri_rang integer
);


--
-- TOC entry 183 (class 1259 OID 101262)
-- Name: bib_taxref_statuts; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace:
--

CREATE TABLE bib_taxref_statuts (
    id_statut character(1) NOT NULL,
    nom_statut character varying(50) NOT NULL
);


--
-- TOC entry 253 (class 1259 OID 194361)
-- Name: bib_themes; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace:
--

CREATE TABLE bib_themes (
    id_theme integer NOT NULL,
    nom_theme character varying(20),
    desc_theme character varying(255),
    ordre integer,
    id_droit integer NOT NULL DEFAULT 0
);


--
-- TOC entry 252 (class 1259 OID 194359)
-- Name: bib_themes_id_theme_seq; Type: SEQUENCE; Schema: taxonomie; Owner: -
--

CREATE SEQUENCE bib_themes_id_theme_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3536 (class 0 OID 0)
-- Dependencies: 252
-- Name: bib_themes_id_theme_seq; Type: SEQUENCE OWNED BY; Schema: taxonomie; Owner: -
--

ALTER SEQUENCE bib_themes_id_theme_seq OWNED BY bib_themes.id_theme;


--
-- TOC entry 260 (class 1259 OID 239030)
-- Name: bib_types_media; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace:
--

CREATE TABLE bib_types_media (
    id_type integer NOT NULL,
    nom_type_media character varying(100) NOT NULL,
    desc_type_media text
);


--
-- TOC entry 251 (class 1259 OID 194344)
-- Name: cor_nom_liste; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace:
--

CREATE TABLE cor_nom_liste (
    id_liste integer NOT NULL,
    id_nom integer NOT NULL
);


--
-- TOC entry 184 (class 1259 OID 101265)
-- Name: cor_taxon_attribut; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace:
--

CREATE TABLE cor_taxon_attribut (
    id_attribut integer NOT NULL,
    valeur_attribut text NOT NULL,
    cd_ref integer,
    CONSTRAINT check_is_cd_ref CHECK ((cd_ref = find_cdref(cd_ref)))
);


--
-- TOC entry 185 (class 1259 OID 101271)
-- Name: import_taxref; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace:
--

CREATE TABLE import_taxref (
    regne character varying(20),
    phylum character varying(50),
    classe character varying(50),
    ordre character varying(50),
    famille character varying(50),
    group1_inpn character varying(50),
    group2_inpn character varying(50),
    cd_nom integer NOT NULL,
    cd_taxsup integer,
    cd_sup integer,
    cd_ref integer,
    rang character varying(10),
    lb_nom character varying(100),
    lb_auteur character varying(250),
    nom_complet character varying(255),
    nom_complet_html character varying(255),
    nom_valide character varying(255),
    nom_vern text,
    nom_vern_eng character varying(500),
    habitat character varying(10),
    fr character varying(10),
    gf character varying(10),
    mar character varying(10),
    gua character varying(10),
    sm character varying(10),
    sb character varying(10),
    spm character varying(10),
    may character varying(10),
    epa character varying(10),
    reu character varying(10),
    taaf character varying(10),
    pf character varying(10),
    nc character varying(10),
    wf character varying(10),
    cli character varying(10),
    url text
);


--
-- TOC entry 259 (class 1259 OID 239016)
-- Name: t_medias; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace:
--

CREATE TABLE t_medias (
    id_media integer NOT NULL,
    cd_ref integer,
    titre character varying(255) NOT NULL,
    url character varying(255),
    chemin character varying(255),
    auteur character varying(100),
    desc_media text,
    date_media date,
    is_public boolean DEFAULT true NOT NULL,
    supprime boolean DEFAULT false NOT NULL,
    id_type integer NOT NULL,
    CONSTRAINT check_cd_ref_is_ref CHECK ((cd_ref = find_cdref(cd_ref)))
);


--
-- TOC entry 258 (class 1259 OID 239014)
-- Name: t_medias_id_media_seq; Type: SEQUENCE; Schema: taxonomie; Owner: -
--

CREATE SEQUENCE t_medias_id_media_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3537 (class 0 OID 0)
-- Dependencies: 258
-- Name: t_medias_id_media_seq; Type: SEQUENCE OWNED BY; Schema: taxonomie; Owner: -
--

ALTER SEQUENCE t_medias_id_media_seq OWNED BY t_medias.id_media;


--
-- TOC entry 186 (class 1259 OID 101277)
-- Name: taxref; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace:
--

CREATE TABLE taxref (
    cd_nom integer NOT NULL,
    id_statut character(1),
    id_habitat integer,
    id_rang character varying(4),
    regne character varying(20),
    phylum character varying(50),
    classe character varying(50),
    ordre character varying(50),
    famille character varying(50),
    cd_taxsup integer,
    cd_sup integer,
    cd_ref integer,
    lb_nom character varying(100),
    lb_auteur character varying(150),
    nom_complet character varying(255),
    nom_complet_html character varying(255),
    nom_valide character varying(255),
    nom_vern character varying(255),
    nom_vern_eng character varying(255),
    group1_inpn character varying(255),
    group2_inpn character varying(255)
);


--
-- TOC entry 187 (class 1259 OID 101283)
-- Name: taxref_changes; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace:
--

CREATE TABLE taxref_changes (
    cd_nom integer NOT NULL,
    num_version_init character varying(5),
    num_version_final character varying(5),
    champ character varying(50) NOT NULL,
    valeur_init character varying(255),
    valeur_final character varying(255),
    type_change character varying(25)
);


--
-- Name: taxref_liste_rouge_fr; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace:
--

CREATE TABLE taxref_liste_rouge_fr
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
  categorie_lr_mondiale character varying(5)
);


--
-- TOC entry 188 (class 1259 OID 101289)
-- Name: taxref_protection_articles; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace:
--

CREATE TABLE taxref_protection_articles (
    cd_protection character varying(20) NOT NULL,
    article character varying(100),
    intitule text,
    arrete text,
    cd_arrete integer,
    url_inpn character varying(250),
    cd_doc integer,
    url character varying(250),
    date_arrete integer,
    type_protection character varying(250),
    concerne_mon_territoire boolean
);


--
-- TOC entry 189 (class 1259 OID 101295)
-- Name: taxref_protection_especes; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace:
--

CREATE TABLE taxref_protection_especes (
    cd_nom integer NOT NULL,
    cd_protection character varying(20) NOT NULL,
    nom_cite character varying(200),
    syn_cite character varying(200),
    nom_francais_cite character varying(100),
    precisions text,
    cd_nom_cite character varying(255) NOT NULL
);



CREATE TABLE taxhub_admin_log
(
  id serial NOT NULL,
  action_time timestamp with time zone NOT NULL DEFAULT now(),
  id_role integer,
  object_type character varying(50),
  object_id integer,
  object_repr character varying(200) NOT NULL,
  change_type character varying(250),
  change_message character varying(250),
  CONSTRAINT taxhub_admin_log_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);

--
-- TOC entry 3343 (class 2604 OID 194330)
-- Name: id_nom; Type: DEFAULT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY bib_noms ALTER COLUMN id_nom SET DEFAULT nextval('bib_noms_id_nom_seq'::regclass);


--
-- TOC entry 3345 (class 2604 OID 194364)
-- Name: id_theme; Type: DEFAULT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY bib_themes ALTER COLUMN id_theme SET DEFAULT nextval('bib_themes_id_theme_seq'::regclass);


--
-- TOC entry 3346 (class 2604 OID 239019)
-- Name: id_media; Type: DEFAULT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY t_medias ALTER COLUMN id_media SET DEFAULT nextval('t_medias_id_media_seq'::regclass);


--
-- TOC entry 3381 (class 2606 OID 194335)
-- Name: bib_noms_cd_nom_key; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace:
--

ALTER TABLE ONLY bib_noms
    ADD CONSTRAINT bib_noms_cd_nom_key UNIQUE (cd_nom);


--
-- TOC entry 3383 (class 2606 OID 194333)
-- Name: bib_noms_pkey; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace:
--

ALTER TABLE ONLY bib_noms
    ADD CONSTRAINT bib_noms_pkey PRIMARY KEY (id_nom);


--
-- TOC entry 3387 (class 2606 OID 194366)
-- Name: bib_themes_pkey; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace:
--

ALTER TABLE ONLY bib_themes
    ADD CONSTRAINT bib_themes_pkey PRIMARY KEY (id_theme);


--
-- TOC entry 3385 (class 2606 OID 194348)
-- Name: cor_nom_liste_pkey; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace:
--

ALTER TABLE ONLY cor_nom_liste
    ADD CONSTRAINT cor_nom_liste_pkey PRIMARY KEY (id_nom, id_liste);


--
-- TOC entry 3393 (class 2606 OID 239037)
-- Name: id; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace:
--

ALTER TABLE ONLY bib_types_media
    ADD CONSTRAINT id PRIMARY KEY (id_type);


--
-- TOC entry 3389 (class 2606 OID 239027)
-- Name: id_media; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace:
--

ALTER TABLE ONLY t_medias
    ADD CONSTRAINT id_media PRIMARY KEY (id_media);


--
-- TOC entry 3351 (class 2606 OID 101306)
-- Name: pk_bib_attributs; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace:
--

ALTER TABLE ONLY bib_attributs
    ADD CONSTRAINT pk_bib_attributs PRIMARY KEY (id_attribut);


--
-- TOC entry 3353 (class 2606 OID 101308)
-- Name: pk_bib_listes; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace:
--

ALTER TABLE ONLY bib_listes
    ADD CONSTRAINT pk_bib_listes PRIMARY KEY (id_liste);


--
-- Name: pk_bib_taxref_id_categorie_france; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace:
--

ALTER TABLE ONLY bib_taxref_categories_lr
    ADD CONSTRAINT pk_bib_taxref_id_categorie_france PRIMARY KEY (id_categorie_france);


--
-- TOC entry 3355 (class 2606 OID 101312)
-- Name: pk_bib_taxref_habitats; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace:
--

ALTER TABLE ONLY bib_taxref_habitats
    ADD CONSTRAINT pk_bib_taxref_habitats PRIMARY KEY (id_habitat);


--
-- TOC entry 3357 (class 2606 OID 101314)
-- Name: pk_bib_taxref_rangs; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace:
--

ALTER TABLE ONLY bib_taxref_rangs
    ADD CONSTRAINT pk_bib_taxref_rangs PRIMARY KEY (id_rang);


--
-- TOC entry 3359 (class 2606 OID 101316)
-- Name: pk_bib_taxref_statuts; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace:
--

ALTER TABLE ONLY bib_taxref_statuts
    ADD CONSTRAINT pk_bib_taxref_statuts PRIMARY KEY (id_statut);


--
-- TOC entry 3362 (class 2606 OID 101318)
-- Name: pk_import_taxref; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace:
--

ALTER TABLE ONLY import_taxref
    ADD CONSTRAINT pk_import_taxref PRIMARY KEY (cd_nom);


--
-- TOC entry 3370 (class 2606 OID 101320)
-- Name: pk_taxref; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace:
--

ALTER TABLE ONLY taxref
    ADD CONSTRAINT pk_taxref PRIMARY KEY (cd_nom);


--
-- TOC entry 3372 (class 2606 OID 101322)
-- Name: pk_taxref_changes; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace:
--

ALTER TABLE ONLY taxref_changes
    ADD CONSTRAINT pk_taxref_changes PRIMARY KEY (cd_nom, champ);


--
-- Name: pk_taxref_liste_rouge_fr; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace:
--

ALTER TABLE ONLY taxref_liste_rouge_fr
    ADD CONSTRAINT pk_taxref_liste_rouge_fr PRIMARY KEY (id_lr);


--
-- TOC entry 3374 (class 2606 OID 101324)
-- Name: taxref_protection_articles_pkey; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace:
--

ALTER TABLE ONLY taxref_protection_articles
    ADD CONSTRAINT taxref_protection_articles_pkey PRIMARY KEY (cd_protection);


--
-- TOC entry 3377 (class 2606 OID 101326)
-- Name: taxref_protection_especes_pkey; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace:
--

ALTER TABLE ONLY taxref_protection_especes
    ADD CONSTRAINT taxref_protection_especes_pkey PRIMARY KEY (cd_nom, cd_protection, cd_nom_cite);


--
-- TOC entry 3375 (class 1259 OID 101327)
-- Name: fki_cd_nom_taxref_protection_especes; Type: INDEX; Schema: taxonomie; Owner: -; Tablespace:
--

CREATE INDEX fki_cd_nom_taxref_protection_especes ON taxref_protection_especes USING btree (cd_nom);


--
-- TOC entry 3360 (class 1259 OID 184395)
-- Name: fki_cor_taxon_attribut; Type: INDEX; Schema: taxonomie; Owner: -; Tablespace:
--

CREATE INDEX fki_cor_taxon_attribut ON cor_taxon_attribut USING btree (valeur_attribut);


--
-- TOC entry 3363 (class 1259 OID 101330)
-- Name: i_fk_taxref_bib_taxref_habitat; Type: INDEX; Schema: taxonomie; Owner: -; Tablespace:
--

CREATE INDEX i_fk_taxref_bib_taxref_habitat ON taxref USING btree (id_habitat);


--
-- TOC entry 3364 (class 1259 OID 101331)
-- Name: i_fk_taxref_bib_taxref_rangs; Type: INDEX; Schema: taxonomie; Owner: -; Tablespace:
--

CREATE INDEX i_fk_taxref_bib_taxref_rangs ON taxref USING btree (id_rang);


--
-- TOC entry 3365 (class 1259 OID 101332)
-- Name: i_fk_taxref_bib_taxref_statuts; Type: INDEX; Schema: taxonomie; Owner: -; Tablespace:
--

CREATE INDEX i_fk_taxref_bib_taxref_statuts ON taxref USING btree (id_statut);


--
-- TOC entry 3366 (class 1259 OID 101333)
-- Name: i_taxref_cd_nom; Type: INDEX; Schema: taxonomie; Owner: -; Tablespace:
--

CREATE INDEX i_taxref_cd_nom ON taxref USING btree (cd_nom);


--
-- TOC entry 3367 (class 1259 OID 101334)
-- Name: i_taxref_cd_ref; Type: INDEX; Schema: taxonomie; Owner: -; Tablespace:
--

CREATE INDEX i_taxref_cd_ref ON taxref USING btree (cd_ref);


--
-- TOC entry 3368 (class 1259 OID 101335)
-- Name: i_taxref_hierarchy; Type: INDEX; Schema: taxonomie; Owner: -; Tablespace:
--

CREATE INDEX i_taxref_hierarchy ON taxref USING btree (regne, phylum, classe, ordre, famille);


--
-- TOC entry 3406 (class 2620 OID 239039)
-- Name: tri_insert_t_medias; Type: TRIGGER; Schema: taxonomie; Owner: -
--

CREATE TRIGGER tri_insert_t_medias BEFORE INSERT ON t_medias FOR EACH ROW EXECUTE PROCEDURE insert_t_medias();



CREATE TRIGGER trg_refresh_attributes_views_per_kingdom
  AFTER INSERT OR UPDATE OR DELETE
  ON bib_attributs
  FOR EACH ROW
  EXECUTE PROCEDURE trg_fct_refresh_attributesviews_per_kingdom();

--
-- TOC entry 3394 (class 2606 OID 194367)
-- Name: bib_attributs_id_theme_fkey; Type: FK CONSTRAINT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY bib_attributs
    ADD CONSTRAINT bib_attributs_id_theme_fkey FOREIGN KEY (id_theme) REFERENCES bib_themes(id_theme);


--
-- TOC entry 3402 (class 2606 OID 194349)
-- Name: cor_nom_listes_bib_listes_fkey; Type: FK CONSTRAINT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY cor_nom_liste
    ADD CONSTRAINT cor_nom_listes_bib_listes_fkey FOREIGN KEY (id_liste) REFERENCES bib_listes(id_liste) ON UPDATE CASCADE;


--
-- TOC entry 3403 (class 2606 OID 194354)
-- Name: cor_nom_listes_bib_noms_fkey; Type: FK CONSTRAINT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY cor_nom_liste
    ADD CONSTRAINT cor_nom_listes_bib_noms_fkey FOREIGN KEY (id_nom) REFERENCES bib_noms(id_nom);


--
-- TOC entry 3395 (class 2606 OID 101336)
-- Name: cor_taxon_attrib_bib_attrib_fkey; Type: FK CONSTRAINT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY cor_taxon_attribut
    ADD CONSTRAINT cor_taxon_attrib_bib_attrib_fkey FOREIGN KEY (id_attribut) REFERENCES bib_attributs(id_attribut);


--
-- TOC entry 3401 (class 2606 OID 194336)
-- Name: fk_bib_nom_taxref; Type: FK CONSTRAINT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY bib_noms
    ADD CONSTRAINT fk_bib_nom_taxref FOREIGN KEY (cd_nom) REFERENCES taxref(cd_nom);


--
-- TOC entry 3404 (class 2606 OID 239052)
-- Name: fk_t_media_bib_noms; Type: FK CONSTRAINT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY t_medias
    ADD CONSTRAINT fk_t_media_bib_noms FOREIGN KEY (cd_ref) REFERENCES bib_noms(cd_nom) MATCH FULL ON UPDATE CASCADE;


--
-- TOC entry 3405 (class 2606 OID 239057)
-- Name: fk_t_media_bib_types_media; Type: FK CONSTRAINT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY t_medias
    ADD CONSTRAINT fk_t_media_bib_types_media FOREIGN KEY (id_type) REFERENCES bib_types_media(id_type) MATCH FULL ON UPDATE CASCADE;


--
-- TOC entry 3396 (class 2606 OID 101361)
-- Name: fk_taxref_bib_taxref_habitats; Type: FK CONSTRAINT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY taxref
    ADD CONSTRAINT fk_taxref_bib_taxref_habitats FOREIGN KEY (id_habitat) REFERENCES bib_taxref_habitats(id_habitat) ON UPDATE CASCADE;


--
-- TOC entry 3397 (class 2606 OID 101366)
-- Name: fk_taxref_bib_taxref_rangs; Type: FK CONSTRAINT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY taxref
    ADD CONSTRAINT fk_taxref_bib_taxref_rangs FOREIGN KEY (id_rang) REFERENCES bib_taxref_rangs(id_rang) ON UPDATE CASCADE;


--
-- TOC entry 3398 (class 2606 OID 101371)
-- Name: taxref_id_statut_fkey; Type: FK CONSTRAINT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY taxref
    ADD CONSTRAINT taxref_id_statut_fkey FOREIGN KEY (id_statut) REFERENCES bib_taxref_statuts(id_statut) ON UPDATE CASCADE;


--
-- Name: fk_taxref_lr_bib_taxref_categories; Type: FK CONSTRAINT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY taxref_liste_rouge_fr
    ADD  CONSTRAINT fk_taxref_lr_bib_taxref_categories FOREIGN KEY (id_categorie_france) REFERENCES taxonomie.bib_taxref_categories_lr (id_categorie_france) MATCH SIMPLE
    ON UPDATE CASCADE ON DELETE NO ACTION;
    

--
-- TOC entry 3399 (class 2606 OID 101376)
-- Name: taxref_protection_especes_cd_nom_fkey; Type: FK CONSTRAINT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY taxref_protection_especes
    ADD CONSTRAINT taxref_protection_especes_cd_nom_fkey FOREIGN KEY (cd_nom) REFERENCES taxref(cd_nom) ON UPDATE CASCADE;

    
--
-- TOC entry 3400 (class 2606 OID 101381)
-- Name: taxref_protection_especes_cd_protection_fkey; Type: FK CONSTRAINT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY taxref_protection_especes
    ADD CONSTRAINT taxref_protection_especes_cd_protection_fkey FOREIGN KEY (cd_protection) REFERENCES taxref_protection_articles(cd_protection);


--
-- TOC entry 3400 (class 2606 OID 101381)
-- Name: is_valid_id_droit_theme; Type: FK CHECK; Schema: taxonomie; Owner: -
--

ALTER TABLE bib_themes
  ADD CONSTRAINT is_valid_id_droit_theme CHECK (id_droit >= 0 AND id_droit <= 6);


-- Completed on 2016-08-22 10:09:31 CEST

--
-- PostgreSQL database dump complete
--
