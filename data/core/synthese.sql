--
--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: layers; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA layers;


--
-- Name: SCHEMA layers; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA layers IS 'schéma contenant les couches SIG nécéssaires au fonctionnement de la base ou des applications qui s''y connectent. (exemple, communes, secteurs, zone à statut...)';


--
-- Name: meta; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA meta;


--
-- Name: synthese; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA synthese;


--
-- Name: synchronomade; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA synchronomade;


SET search_path = public, pg_catalog;

--function visant à restaurer le fonctionnement du wms dans l'application fonctionnant avec un mapserver non compatible avec st_geomfromtext
CREATE OR REPLACE FUNCTION geomfromtext(text, integer)
  RETURNS geometry AS
'SELECT st_geometryfromtext($1, $2)'
  LANGUAGE sql IMMUTABLE STRICT
  COST 100;

-- Function: public.periode(date, date, date)

-- DROP FUNCTION public.periode(date, date, date);

CREATE OR REPLACE FUNCTION public.periode(dateobs date, datedebut date, datefin date)
  RETURNS boolean AS
$BODY$
declare
 
jo int; jd int; jf int; test int; 
 
 
BEGIN
jo = extract(doy FROM dateobs);--jour de la date passée
jd = extract(doy FROM datedebut);--jour début
jf = extract(doy FROM datefin); --jour fin
test = jf - jd; --test si la période est sur 2 année ou pas
 
--si on est sur 2 années
IF test < 0 then
	IF jo BETWEEN jd AND 366 OR jo BETWEEN 1 AND jf THEN RETURN true;
	END IF;
-- si on est dans la même année
else 
	IF jo BETWEEN jd AND jf THEN RETURN true;
	END IF;
END IF;
	RETURN false;	
END;
 
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  

CREATE OR REPLACE FUNCTION public.application_aggregate_taxons_rang_sp(id integer)
  RETURNS text AS
$BODY$
--fonction permettant de regroupper dans un tableau tous les cd_nom d'une espèce et de ces sous espèces, variétés et convariétés à partir du cd_nom d'un taxon
--si le cd_nom passé est d'un rang différent de l'espèce (genre, famille... ou sous-espèce, variété...), la fonction renvoie simplement le cd_ref du cd_nom passé en entré
--
--Gil DELUERMOZ septembre 2011
  DECLARE
  rang character(4);
  rangsup character(4);
  ref integer;
  sup integer;
  cd integer;
  tab integer;
  r text; 
  BEGIN
	SELECT INTO rang id_rang FROM taxonomie.taxref WHERE cd_nom = id;
	IF(rang='ES') THEN
		cd = taxonomie.find_cdref(id);
		--SELECT INTO tab cd_nom FROM taxonomie.taxref WHERE id_rang = 'SSES' AND cd_taxsup = taxonomie.find_cdref(id);
		SELECT INTO r array_agg(a.cd_nom) FROM (
		SELECT cd_nom FROM taxonomie.taxref WHERE cd_ref = cd
		UNION
		SELECT cd_nom FROM taxonomie.taxref WHERE id_rang = 'SSES' AND cd_taxsup = cd
		UNION
		SELECT cd_nom FROM taxonomie.taxref WHERE id_rang = 'VAR' AND cd_taxsup = cd
		UNION
		SELECT cd_nom FROM taxonomie.taxref WHERE id_rang = 'CVAR' AND cd_taxsup = cd
		UNION
		SELECT cd_nom FROM taxonomie.taxref WHERE id_rang = 'VAR' AND cd_taxsup IN (SELECT cd_nom FROM taxonomie.taxref WHERE id_rang = 'SSES' AND cd_taxsup = cd)
		UNION
		SELECT cd_nom FROM taxonomie.taxref WHERE id_rang = 'CVAR' AND cd_taxsup IN (SELECT cd_nom FROM taxonomie.taxref WHERE id_rang = 'SSES' AND cd_taxsup = cd)
		) a;   
	ELSE
	   SELECT INTO r array_agg(cd_ref) FROM taxonomie.taxref WHERE cd_nom = id;
	END IF;
	return r;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


CREATE OR REPLACE FUNCTION public.application_aggregate_taxons_all_rang_sp(id integer)
  RETURNS text AS
$BODY$
--fonction permettant de regroupper dans un tableau au rang espèce tous les cd_nom d'une espèce et de ces sous espèces, variétés et convariétés à partir du cd_nom d'un taxon
--si le cd_nom passé est d'un rang supérieur à l'espèce (genre, famille...), la fonction renvoie simplement le cd_ref du cd_nom passé en entré
--
--Gil DELUERMOZ septembre 2011
  DECLARE
  rang character(4);
  rangsup character(4);
  ref integer;
  sup integer;
  cd integer;
  tab integer;
  r text; 
  BEGIN
	SELECT INTO rang id_rang FROM taxonomie.taxref WHERE cd_nom = id;
	IF(rang='ES' OR rang='SSES' OR rang = 'VAR' OR rang = 'CVAR') THEN
	    IF(rang = 'ES') THEN
		cd = taxonomie.find_cdref(id);
	    END IF;
	    IF(rang = 'SSES') THEN
		SELECT INTO cd cd_taxsup FROM taxonomie.taxref WHERE cd_nom = taxonomie.find_cdref(id);
	    END IF;
	    IF(rang = 'VAR' OR rang = 'CVAR') THEN
		SELECT INTO sup cd_taxsup FROM taxonomie.taxref WHERE cd_nom = taxonomie.find_cdref(id);
		SELECT INTO rangsup id_rang FROM taxonomie.taxref WHERE cd_nom = taxonomie.find_cdref(sup);
		IF(rangsup = 'ES') THEN
			cd = sup;
		ELSE
			SELECT INTO cd cd_taxsup FROM taxonomie.taxref WHERE cd_nom = taxonomie.find_cdref(sup);
		END IF;
	    END IF;

		--SELECT INTO tab cd_nom FROM taxonomie.taxref WHERE id_rang = 'SSES' AND cd_taxsup = taxonomie.find_cdref(id);
		SELECT INTO r array_agg(a.cd_nom) FROM (
		SELECT cd_nom FROM taxonomie.taxref WHERE cd_ref = cd
		UNION
		SELECT cd_nom FROM taxonomie.taxref WHERE id_rang = 'SSES' AND cd_taxsup = cd
		UNION
		SELECT cd_nom FROM taxonomie.taxref WHERE id_rang = 'VAR' AND cd_taxsup = cd
		UNION
		SELECT cd_nom FROM taxonomie.taxref WHERE id_rang = 'CVAR' AND cd_taxsup = cd
		UNION
		SELECT cd_nom FROM taxonomie.taxref WHERE id_rang = 'VAR' AND cd_taxsup IN (SELECT cd_nom FROM taxonomie.taxref WHERE id_rang = 'SSES' AND cd_taxsup = cd)
		UNION
		SELECT cd_nom FROM taxonomie.taxref WHERE id_rang = 'CVAR' AND cd_taxsup IN (SELECT cd_nom FROM taxonomie.taxref WHERE id_rang = 'SSES' AND cd_taxsup = cd)
		) a;   
	ELSE
	   SELECT INTO r cd_ref FROM taxonomie.taxref WHERE cd_nom = id;
	END IF;
	return r;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


SET search_path = layers, pg_catalog;

--
-- Name: f_dist_maille_commune(public.geometry, character); Type: FUNCTION; Schema: layers; Owner: -
--

CREATE FUNCTION f_dist_maille_commune(mon_geom public.geometry, mon_insee character) RETURNS real
    LANGUAGE plpgsql
    AS $$
DECLARE
ma_distance real;
ma_commune geometry;
BEGIN
-- vérif si le code insee saisi est bien dans la couche commune
IF mon_insee IN (SELECT insee FROM layers.l_communes) THEN
	-- calcul la distance entre la maille et la commune (vérifie d'abord si la maille intersect la commune)
	SELECT INTO ma_commune lc.the_geom FROM layers.l_communes lc WHERE lc.insee = mon_insee;
	IF public.st_intersects(mon_geom, ma_commune) THEN
		  RETURN  0;		-- on est bon la maille est dans la commune saisie a la main
	ELSE
		 SELECT INTO ma_distance ST_Distance(mon_geom, ma_commune);
		 RETURN ma_distance;
	END IF;
ELSE
	RETURN  -1; -- le code insee saisi est mauvais
END IF;

END
$$;


--
-- Name: f_insee(public.geometry); Type: FUNCTION; Schema: layers; Owner: -
--

CREATE FUNCTION f_insee(mongeom public.geometry) RETURNS character
    LANGUAGE plpgsql
    AS $$
DECLARE
mavariableinsee char(5);
BEGIN

select insee into mavariableinsee from 
layers.l_communes c where public.st_intersects(c.the_geom, mongeom)= true;

if mavariableinsee ISNULL then
	return null;
else
	return mavariableinsee; 
end if;

END
$$;


--
-- Name: f_isolines20(public.geometry); Type: FUNCTION; Schema: layers; Owner: -
--

CREATE FUNCTION f_isolines20(mongeom public.geometry) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
mavariableiso integer;
BEGIN
select iso into mavariableiso from 
(
select i.iso, st_distance(mongeom, i.the_geom) 
from layers.l_isolines20 i
where mongeom&&i.the_geom  -- && renvoit true quand la bouding box de mon geom intersect la bounding box d'isolines20
order by st_distance asc limit 1
) SR;

if mavariableiso ISNULL then 	
	return  0;
else
	return mavariableiso; 
end if;

END
$$;


--
-- Name: f_nomcommune(public.geometry); Type: FUNCTION; Schema: layers; Owner: -
--

CREATE FUNCTION f_nomcommune(mongeom public.geometry) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
macommmune character varying(40);
BEGIN

select commune_min into macommmune from 
layers.l_communes c where public.st_intersects(c.the_geom, mongeom)= true;

if macommmune ISNULL then
	return null;
else
	return macommmune; 
end if;

END
$$;


SET search_path = synthese, public, pg_catalog;

--
-- Name: insert_syntheseff(); Type: FUNCTION; Schema: synthese; Owner: -
--

CREATE FUNCTION insert_syntheseff() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	new.date_insert= 'now';
	new.date_update= 'now';
	RETURN NEW; 			
END;
$$;


--
-- Name: maj_cor_unite_synthese(); Type: FUNCTION; Schema: synthese; Owner: -
--

CREATE FUNCTION maj_cor_unite_synthese() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
-- apres travail dans la table synthèsefaune on supprime la donnée correspondante dans la table cor_unite_synthese
IF (TG_OP = 'DELETE') or (TG_OP = 'UPDATE') THEN
	DELETE FROM synthese.cor_unite_synthese WHERE id_synthese = old.id_synthese;
END IF;
-- insert la donnée depuis la table synthèsefaune dans la table cor_unite_synthese :
-- La donnée dans la table synthèsefaune doit etre en supprime = FALSE sinon on ne l'insert pas,
-- S'il n'y a pas d'intersection avec une ou des unité geographique on ne l'insert pas.
IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE') THEN
	IF new.supprime = FALSE THEN
		INSERT INTO synthese.cor_unite_synthese (id_synthese, cd_nom, dateobs, id_unite_geo)
		SELECT s.id_synthese, s.cd_nom, s.dateobs,u.id_unite_geo 
        FROM synthese.syntheseff s, layers.l_unites_geo u
		WHERE public.st_intersects(u.the_geom, s.the_geom_local) 
		AND s.id_synthese = new.id_synthese;
	END IF;
END IF;	
RETURN NULL;	
END;
$$;


--
-- Name: maj_cor_zonesstatut_synthese(); Type: FUNCTION; Schema: synthese; Owner: -
--

CREATE FUNCTION maj_cor_zonesstatut_synthese() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
-- apres travail dans la table synthèsefaune on supprime la donnée correspondante dans la table cor_zonesstatut_synthese
IF (TG_OP = 'DELETE') or (TG_OP = 'UPDATE') THEN
	DELETE FROM synthese.cor_zonesstatut_synthese WHERE id_synthese = old.id_synthese;
END IF;
-- insert la donnée depuis la table synthèsefaune dans la table cor_zonesstatut_synthese :
-- La donnée dans la table synthèsefaune doit etre en supprime = FALSE sinon on ne l'insert pas,
-- on calcul la ou les zones à statuts correspondant à la donnée.
-- ces intersections  servent à eviter des intersect lourd en requete spatiale dans l'appli web, ainsi
-- les intersections avec les zones à statut principales sont déja calculées en tables relationelles
IF (TG_OP = 'INSERT') or (TG_OP = 'UPDATE') THEN
	IF new.supprime = FALSE THEN
		INSERT INTO synthese.cor_zonesstatut_synthese (id_zone,id_synthese)
		SELECT z.id_zone,s.id_synthese FROM synthese.syntheseff s, layers.l_zonesstatut z 
		WHERE public.st_intersects(z.the_geom, s.the_geom_local)
		AND z.id_type IN(1,4,5,6,7,8,9,10,11) -- typologie limitée au coeur, reserve, natura2000 etc...
		AND s.id_synthese = new.id_synthese;
	END IF;
END IF;
RETURN NULL; 
END;
$$;


--
-- Name: update_syntheseff(); Type: FUNCTION; Schema: synthese; Owner: -
--

CREATE FUNCTION update_syntheseff() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	new.date_update= 'now';
	RETURN NEW; 			
END;
$$;


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: cor_boolean; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE cor_boolean
(
  expression character varying(25) NOT NULL,
  bool boolean NOT NULL
);


SET search_path = layers, pg_catalog;

--
-- Name: l_unites_geo; Type: TABLE; Schema: layers; Owner: -; Tablespace: 
--

CREATE TABLE l_unites_geo (
    id_unite_geo integer NOT NULL,
    coeur character varying(80),
    secteur character varying(80),
    code_insee character varying(80),
    commune character varying(80),
    reserve character varying(80),
    surface_ha character varying(80),
    n2000 character varying(50),
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (public.geometrytype(the_geom) = 'POLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = MYLOCALSRID))
);


SET search_path = layers, pg_catalog;

--
-- Name: bib_typeszones; Type: TABLE; Schema: layers; Owner: -; Tablespace: 
--

CREATE TABLE bib_typeszones (
    id_type integer NOT NULL,
    typezone character varying(200)
);


--
-- Name: l_aireadhesion; Type: TABLE; Schema: layers; Owner: -; Tablespace: 
--

CREATE TABLE l_aireadhesion (
    gid integer NOT NULL,
    id integer,
    nouveaucha integer,
    count integer,
    length double precision,
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'LINESTRING'::text) OR (public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (public.geometrytype(the_geom) = 'POLYGON'::text) OR the_geom IS NULL)),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = MYLOCALSRID))
);


--
-- Name: l_communes; Type: TABLE; Schema: layers; Owner: -; Tablespace: 
--

CREATE TABLE l_communes (
    insee character(5) NOT NULL,
    idbdcarto bigint,
    commune_maj character varying(50),
    commune_min character varying(50),
    inseedep character varying(3),
    nomdep character varying(30),
    inseereg character varying(2),
    nomreg character varying(30),
    inseearr character varying(1),
    inseecan character varying(2),
    statut character varying(20),
    xcom bigint,
    ycom bigint,
    surface bigint,
    epci character varying(40),
    coeur_aoa character varying(5),
    codenum integer,
    pays character varying(50),
    id_secteur integer,
    saisie boolean,
    organisme boolean,
    id_secteur_fp integer,
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = MYLOCALSRID))
);

--
-- Name: l_isolines20; Type: TABLE; Schema: layers; Owner: -; Tablespace: 
--

CREATE TABLE l_isolines20 (
    gid integer NOT NULL,
    iso bigint,
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTILINESTRING'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = MYLOCALSRID))
);


--
-- Name: l_isolines20_gid_seq; Type: SEQUENCE; Schema: layers; Owner: -
--

CREATE SEQUENCE l_isolines20_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: l_isolines20_gid_seq; Type: SEQUENCE OWNED BY; Schema: layers; Owner: -
--

ALTER SEQUENCE l_isolines20_gid_seq OWNED BY l_isolines20.gid;


--
-- Name: l_secteurs; Type: TABLE; Schema: layers; Owner: -; Tablespace: 
--

CREATE TABLE l_secteurs (
    nom_secteur character varying(50),
    id_secteur integer NOT NULL,
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = MYLOCALSRID))
);


--
-- Name: l_zonesstatut; Type: TABLE; Schema: layers; Owner: -; Tablespace: 
--

CREATE TABLE l_zonesstatut (
    id_zone integer NOT NULL,
    id_type integer NOT NULL,
    id_mnhn character varying(20),
    nomzone character varying(250),
    the_geom public.geometry,
    --CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2) OR (public.st_ndims(the_geom) = 4)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = MYLOCALSRID))
);


SET search_path = meta, pg_catalog;

--
-- Name: bib_lots; Type: TABLE; Schema: meta; Owner: -; Tablespace: 
--

CREATE TABLE bib_lots (
    id_lot integer NOT NULL,
    nom_lot character varying(255),
    desc_lot text,
    menu_cf boolean DEFAULT false,
    pn boolean DEFAULT true,
    menu_inv boolean DEFAULT false,
    id_programme integer NOT NULL
);


--
-- Name: bib_programmes; Type: TABLE; Schema: meta; Owner: -; Tablespace: 
--

CREATE TABLE bib_programmes (
    id_programme integer NOT NULL,
    nom_programme character varying(255),
    desc_programme text,
    actif boolean,
    programme_public boolean,
    desc_programme_public text
);

--
-- Name: bib_supports; Type: TABLE; Schema: meta; Owner: -; Tablespace: 
--

CREATE TABLE bib_supports
(
  id_support integer NOT NULL,
  nom_support character varying(20) NOT NULL
);


--
-- Name: t_precisions; Type: TABLE; Schema: meta; Owner: -; Tablespace: 
--

CREATE TABLE t_precisions (
    id_precision integer NOT NULL,
    nom_precision character varying(50),
    desc_precision text
);


--
-- Name: t_protocoles; Type: TABLE; Schema: meta; Owner: -; Tablespace: 
--

CREATE TABLE t_protocoles (
    id_protocole integer NOT NULL,
    nom_protocole character varying(250),
    question text,
    objectifs text,
    methode text,
    avancement character varying(50),
    date_debut date,
    date_fin date
);


SET search_path = synthese, pg_catalog;

--
-- Name: bib_criteres_synthese; Type: TABLE; Schema: synthese; Owner: -; Tablespace: 
--

CREATE TABLE bib_criteres_synthese (
    id_critere_synthese integer NOT NULL,
    code_critere_synthese character varying(3),
    nom_critere_synthese character varying(90),
    tri integer
);


--
-- Name: syntheseff; Type: TABLE; Schema: synthese; Owner: -; Tablespace: 
--

CREATE TABLE syntheseff (
    id_synthese integer NOT NULL,
    id_source integer,
    id_fiche_source character varying(50),
    code_fiche_source character varying(50),
    id_organisme integer,
    id_protocole integer,
    id_precision integer,
    cd_nom integer,
    insee character(5),
    dateobs date NOT NULL,
    observateurs character varying(255),
    determinateur character varying(255),
    altitude_retenue integer,
    remarques text,
    date_insert timestamp without time zone,
    date_update timestamp without time zone,
    derniere_action character(1),
    supprime boolean,
    the_geom_point public.geometry,
    id_lot integer,
    id_critere_synthese integer,
    the_geom_3857 public.geometry,
    effectif_total integer,
    the_geom_local public.geometry,
    diffusable boolean DEFAULT true,
    CONSTRAINT enforce_dims_the_geom_local CHECK ((public.st_ndims(the_geom_local) = 2)),
    CONSTRAINT enforce_dims_the_geom_3857 CHECK ((public.st_ndims(the_geom_3857) = 2)),
    CONSTRAINT enforce_dims_the_geom_point CHECK ((public.st_ndims(the_geom_point) = 2)),
    CONSTRAINT enforce_geotype_the_geom_point CHECK (((public.geometrytype(the_geom_point) = 'POINT'::text) OR (the_geom_point IS NULL))),
    CONSTRAINT enforce_srid_the_geom_local CHECK ((public.st_srid(the_geom_local) = MYLOCALSRID)),
    CONSTRAINT enforce_srid_the_geom_3857 CHECK ((public.st_srid(the_geom_3857) = 3857)),
    CONSTRAINT enforce_srid_the_geom_point CHECK ((public.st_srid(the_geom_point) = 3857))
);


--
-- Name: TABLE syntheseff; Type: COMMENT; Schema: synthese; Owner: -
--

COMMENT ON TABLE syntheseff IS 'Table de synthèse destinée à recevoir les données de tous les schémas.Pour consultation uniquement';


SET search_path = synthese, pg_catalog;

--
-- Name: bib_sources; Type: TABLE; Schema: synthese; Owner: -; Tablespace: 
--

CREATE TABLE bib_sources (
    id_source integer NOT NULL,
    nom_source character varying(255),
    desc_source text,
    host character varying(100),
    port integer,
    username character varying(50),
    pass character varying(50),
    db_name character varying(50),
    db_schema character varying(50),
    db_table character varying(50),
    db_field character varying(50),
    url character varying(255),
    target character varying(10),
    picto character varying(255),
    groupe character varying(50) NOT NULL,
    actif boolean NOT NULL
);


--
-- Name: cor_unite_synthese; Type: TABLE; Schema: synthese; Owner: -; Tablespace: 
--

CREATE TABLE cor_unite_synthese (
    id_unite_geo integer NOT NULL,
    id_synthese integer NOT NULL,
    dateobs date,
    cd_nom integer
);


--
-- Name: cor_zonesstatut_synthese; Type: TABLE; Schema: synthese; Owner: -; Tablespace: 
--

CREATE TABLE cor_zonesstatut_synthese (
    id_zone integer NOT NULL,
    id_synthese integer NOT NULL
);


--
-- Name: syntheseff_id_synthese_seq; Type: SEQUENCE; Schema: synthese; Owner: -
--

CREATE SEQUENCE syntheseff_id_synthese_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: syntheseff_id_synthese_seq; Type: SEQUENCE OWNED BY; Schema: synthese; Owner: -
--

ALTER SEQUENCE syntheseff_id_synthese_seq OWNED BY syntheseff.id_synthese;


--
-- Name: v_tree_taxons_synthese; Type: VIEW; Schema: synthese; Owner: -
--

CREATE OR REPLACE VIEW v_tree_taxons_synthese AS 
 WITH taxon AS (
         SELECT n.id_nom,
            t_1.cd_ref,
            t_1.lb_nom AS nom_latin,
                CASE
                    WHEN n.nom_francais IS NULL THEN t_1.lb_nom
                    WHEN n.nom_francais::text = ''::text THEN t_1.lb_nom
                    ELSE n.nom_francais
                END AS nom_francais,
            t_1.cd_nom,
            t_1.id_rang,
            t_1.regne,
            t_1.phylum,
            t_1.classe,
            t_1.ordre,
            t_1.famille,
            t_1.lb_nom
           FROM taxonomie.taxref t_1
             LEFT JOIN taxonomie.bib_noms n ON n.cd_nom = t_1.cd_nom
          WHERE (t_1.cd_nom IN ( SELECT DISTINCT syntheseff.cd_nom
                   FROM synthese.syntheseff))
        ), cd_regne AS (
         SELECT DISTINCT t_1.cd_nom,
            t_1.regne
           FROM taxonomie.taxref t_1
          WHERE t_1.id_rang::bpchar = 'KD'::bpchar AND t_1.cd_nom = t_1.cd_ref
        )
 SELECT t.id_nom,
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
   FROM ( SELECT DISTINCT t_1.id_nom,
            t_1.cd_ref,
            t_1.nom_latin,
            t_1.nom_francais,
            ( SELECT DISTINCT r.cd_nom
                   FROM cd_regne r
                  WHERE r.regne::text = t_1.regne::text) AS id_regne,
            t_1.regne AS nom_regne,
            ph.cd_nom AS id_embranchement,
            t_1.phylum AS nom_embranchement,
            t_1.phylum AS desc_embranchement,
            cl.cd_nom AS id_classe,
            t_1.classe AS nom_classe,
            t_1.classe AS desc_classe,
            ord.cd_nom AS id_ordre,
            t_1.ordre AS nom_ordre,
            f.cd_nom AS id_famille,
            t_1.famille AS nom_famille
           FROM taxon t_1
             LEFT JOIN taxonomie.taxref ph ON ph.id_rang::bpchar = 'PH'::bpchar AND ph.cd_nom = ph.cd_ref AND ph.lb_nom::text = t_1.phylum::text AND NOT t_1.phylum IS NULL
             LEFT JOIN taxonomie.taxref cl ON cl.id_rang::bpchar = 'CL'::bpchar AND cl.cd_nom = cl.cd_ref AND cl.lb_nom::text = t_1.classe::text AND NOT t_1.classe IS NULL
             LEFT JOIN taxonomie.taxref ord ON ord.id_rang::bpchar = 'OR'::bpchar AND ord.cd_nom = ord.cd_ref AND ord.lb_nom::text = t_1.ordre::text AND NOT t_1.ordre IS NULL
             LEFT JOIN taxonomie.taxref f ON f.id_rang::bpchar = 'FM'::bpchar AND f.cd_nom = f.cd_ref AND f.lb_nom::text = t_1.famille::text AND f.phylum::text = t_1.phylum::text AND NOT t_1.famille IS NULL) t;

CREATE OR REPLACE VIEW v_taxons_synthese AS 
 SELECT DISTINCT n.nom_francais,
    txr.lb_nom AS nom_latin,
    CASE pat.valeur_attribut 
	WHEN 'oui' THEN TRUE
	WHEN 'non' THEN FALSE
	ELSE NULL
    END AS patrimonial,
    CASE pr.valeur_attribut 
	WHEN 'oui' THEN TRUE
	WHEN 'non' THEN FALSE
	ELSE NULL
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
    JOIN taxonomie.bib_noms n ON txr.cd_nom = n.cd_nom
    LEFT JOIN taxonomie.cor_taxon_attribut pat ON pat.cd_ref = n.cd_ref AND pat.id_attribut = 1
    LEFT JOIN taxonomie.cor_taxon_attribut pr ON pr.cd_ref = n.cd_ref AND pr.id_attribut = 2
    JOIN taxonomie.cor_nom_liste cnl ON cnl.id_nom = n.id_nom
    JOIN taxonomie.bib_listes l ON l.id_liste = cnl.id_liste AND (l.id_liste = ANY (ARRAY[1001, 1002, 1003, 1004]))
    LEFT JOIN ( SELECT tpe.cd_nom,
            string_agg((((tpa.arrete || ' '::text) || tpa.article::text) || '__'::text) || tpa.url::text, '#'::text) AS protections
           FROM taxonomie.taxref_protection_especes tpe
             JOIN taxonomie.taxref_protection_articles tpa ON tpa.cd_protection::text = tpe.cd_protection::text AND tpa.concerne_mon_territoire = true
          GROUP BY tpe.cd_nom) prot ON prot.cd_nom = n.cd_nom
    JOIN ( SELECT DISTINCT syntheseff.cd_nom
           FROM synthese.syntheseff) s ON s.cd_nom = n.cd_nom
    ORDER BY n.nom_francais;
                
CREATE OR REPLACE VIEW v_export_sinp AS 
 SELECT s.id_synthese,
    o.nom_organisme,
    s.dateobs,
    s.observateurs,
    n.cd_nom,
    tx.lb_nom AS nom_latin,
    c.nom_critere_synthese AS critere,
    s.effectif_total,
    s.remarques,
    p.nom_programme,
    s.insee,
    s.altitude_retenue AS altitude,
    public.st_x(public.st_transform(s.the_geom_point, MYLOCALSRID))::integer AS x,
    public.st_y(public.st_transform(s.the_geom_point, MYLOCALSRID))::integer AS y,
    s.derniere_action,
    s.date_insert,
    s.date_update
   FROM synthese.syntheseff s
     JOIN taxonomie.taxref tx ON tx.cd_nom = s.cd_nom
     LEFT JOIN utilisateurs.bib_organismes o ON o.id_organisme = s.id_organisme
     JOIN taxonomie.bib_noms n ON n.cd_nom = s.cd_nom
     LEFT JOIN synthese.bib_criteres_synthese c ON c.id_critere_synthese = s.id_critere_synthese
     LEFT JOIN meta.bib_lots l ON l.id_lot = s.id_lot
     LEFT JOIN meta.bib_programmes p ON p.id_programme = l.id_programme
  WHERE s.supprime = false;
  
CREATE OR REPLACE VIEW v_export_sinp_deleted AS 
 SELECT s.id_synthese
   FROM synthese.syntheseff s
     JOIN taxonomie.taxref tx ON tx.cd_nom = s.cd_nom
  WHERE s.supprime = true;

  
SET search_path = layers, pg_catalog;

--
-- Name: gid; Type: DEFAULT; Schema: layers; Owner: -
--

ALTER TABLE ONLY l_isolines20 ALTER COLUMN gid SET DEFAULT nextval('l_isolines20_gid_seq'::regclass);


SET search_path = synthese, pg_catalog;

--
-- Name: id_synthese; Type: DEFAULT; Schema: synthese; Owner: -
--

ALTER TABLE ONLY syntheseff ALTER COLUMN id_synthese SET DEFAULT nextval('syntheseff_id_synthese_seq'::regclass);


SET search_path = public, pg_catalog;

--
-- Name: pk_cor_boolean; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE cor_boolean
  ADD CONSTRAINT pk_cor_boolean PRIMARY KEY(expression);


SET search_path = layers, pg_catalog;

--
-- Name: aireadhesion_pkey; Type: CONSTRAINT; Schema: layers; Owner: -; Tablespace: 
--

ALTER TABLE ONLY l_aireadhesion
    ADD CONSTRAINT aireadhesion_pkey PRIMARY KEY (gid);


--
-- Name: l_communes_pkey; Type: CONSTRAINT; Schema: layers; Owner: -; Tablespace: 
--

ALTER TABLE ONLY l_communes
    ADD CONSTRAINT l_communes_pkey PRIMARY KEY (insee);


--
-- Name: l_isolines20_pkey; Type: CONSTRAINT; Schema: layers; Owner: -; Tablespace: 
--

ALTER TABLE ONLY l_isolines20
    ADD CONSTRAINT l_isolines20_pkey PRIMARY KEY (gid);


--
-- Name: pk_l_secteurs; Type: CONSTRAINT; Schema: layers; Owner: -; Tablespace: 
--

ALTER TABLE ONLY l_secteurs
    ADD CONSTRAINT pk_l_secteurs PRIMARY KEY (id_secteur);


--
-- Name: pk_l_unites_geo; Type: CONSTRAINT; Schema: layers; Owner: -; Tablespace: 
--

ALTER TABLE ONLY l_unites_geo
    ADD CONSTRAINT pk_l_unites_geo PRIMARY KEY (id_unite_geo);


--
-- Name: pk_l_zonesstatut; Type: CONSTRAINT; Schema: layers; Owner: -; Tablespace: 
--

ALTER TABLE ONLY l_zonesstatut
    ADD CONSTRAINT pk_l_zonesstatut PRIMARY KEY (id_zone);


--
-- Name: pk_typeszones; Type: CONSTRAINT; Schema: layers; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_typeszones
    ADD CONSTRAINT pk_typeszones PRIMARY KEY (id_type);


SET search_path = meta, pg_catalog;

--
-- Name: bib_lots_pkey; Type: CONSTRAINT; Schema: meta; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_lots
    ADD CONSTRAINT bib_lots_pkey PRIMARY KEY (id_lot);


--
-- Name: bib_programmes_pkey; Type: CONSTRAINT; Schema: meta; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_programmes
    ADD CONSTRAINT bib_programmes_pkey PRIMARY KEY (id_programme);


--
-- Name: bib_supports_pkey; Type: CONSTRAINT; Schema: meta; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_supports
    ADD CONSTRAINT bib_supports_pkey PRIMARY KEY (id_support);


--
-- Name: pk_bib_precision; Type: CONSTRAINT; Schema: meta; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_precisions
    ADD CONSTRAINT pk_bib_precision PRIMARY KEY (id_precision);


--
-- Name: pk_bib_protocoles; Type: CONSTRAINT; Schema: meta; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_protocoles
    ADD CONSTRAINT pk_bib_protocoles PRIMARY KEY (id_protocole);


SET search_path = synthese, pg_catalog;

--
-- Name: bib_sources_pkey; Type: CONSTRAINT; Schema: synthese; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_sources
    ADD CONSTRAINT bib_sources_pkey PRIMARY KEY (id_source);


--
-- Name: pk_bib_criteres_synthese; Type: CONSTRAINT; Schema: synthese; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_criteres_synthese
    ADD CONSTRAINT pk_bib_criteres_synthese PRIMARY KEY (id_critere_synthese);


--
-- Name: pk_cor_unite_synthese; Type: CONSTRAINT; Schema: synthese; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cor_unite_synthese
    ADD CONSTRAINT pk_cor_unite_synthese PRIMARY KEY (id_unite_geo, id_synthese);


--
-- Name: pk_cor_zonesstatut_synthese; Type: CONSTRAINT; Schema: synthese; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cor_zonesstatut_synthese
    ADD CONSTRAINT pk_cor_zonesstatut_synthese PRIMARY KEY (id_zone, id_synthese);


--
-- Name: syntheseff_pkey; Type: CONSTRAINT; Schema: synthese; Owner: -; Tablespace: 
--

ALTER TABLE ONLY syntheseff
    ADD CONSTRAINT syntheseff_pkey PRIMARY KEY (id_synthese);


SET search_path = layers, pg_catalog;

--
-- Name: fki_; Type: INDEX; Schema: layers; Owner: -; Tablespace: 
--

CREATE INDEX fki_ ON l_communes USING btree (id_secteur);


SET search_path = synthese, pg_catalog;

--
-- Name: fki_synthese_bib_proprietaires; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX fki_synthese_bib_proprietaires ON syntheseff USING btree (id_organisme);


--
-- Name: fki_synthese_bib_protocoles_id; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX fki_synthese_bib_protocoles_id ON syntheseff USING btree (id_protocole);


--
-- Name: fki_synthese_insee_fkey; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX fki_synthese_insee_fkey ON syntheseff USING btree (insee);


--
-- Name: fki_syntheseff_bib_sources; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX fki_syntheseff_bib_sources ON syntheseff USING btree (id_source);


--
-- Name: i_fk_cor_cor_zonesstatut_synthese_l_zonesstatut; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_cor_cor_zonesstatut_synthese_l_zonesstatut ON cor_zonesstatut_synthese USING btree (id_zone);


--
-- Name: i_fk_cor_cor_zonesstatut_synthese_syntheseff; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_cor_cor_zonesstatut_synthese_syntheseff ON cor_zonesstatut_synthese USING btree (id_synthese);


--
-- Name: i_fk_cor_unite_synthese_l_unites; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_cor_unite_synthese_l_unites ON cor_unite_synthese USING btree (id_unite_geo);


--
-- Name: i_fk_cor_unite_synthese_syntheseff; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_cor_unite_synthese_syntheseff ON cor_unite_synthese USING btree (id_synthese);


--
-- Name: i_synthese_cd_nom; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX i_synthese_cd_nom ON syntheseff USING btree (cd_nom);


--
-- Name: i_synthese_dateobs; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX i_synthese_dateobs ON syntheseff USING btree (dateobs DESC);


--
-- Name: i_synthese_id_lot; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX i_synthese_id_lot ON syntheseff USING btree (id_lot);


--
-- Name: index_gist_synthese_the_geom_point; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX index_gist_synthese_the_geom_point ON syntheseff USING gist (the_geom_point);


--
-- Name: index_gist_synthese_the_geom_2154; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX index_gist_synthese_the_geom_2154 ON syntheseff USING gist (the_geom_local);


--
-- Name: index_gist_synthese_the_geom_3857; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX index_gist_synthese_the_geom_3857 ON syntheseff USING gist (the_geom_3857);


SET search_path = layers, pg_catalog;

--
-- Name: index_gist_l_communes_the_geom; Type: INDEX; Schema: layers; Owner: -; Tablespace: 
--

CREATE INDEX index_gist_l_communes_the_geom ON l_communes USING gist (the_geom);


--
-- Name: index_gist_l_unites_geo_the_geom; Type: INDEX; Schema: layers; Owner: -; Tablespace: 
--

CREATE INDEX index_gist_l_unites_geo_the_geom ON l_unites_geo USING gist (the_geom);


--
-- Name: index_gist_l_secteurs_the_geom; Type: INDEX; Schema: layers; Owner: -; Tablespace: 
--


CREATE INDEX index_gist_l_secteurs_the_geom ON l_secteurs USING gist (the_geom);

--
-- Name: index_gist_l_zonesstatut_the_geom; Type: INDEX; Schema: layers; Owner: -; Tablespace: 
--

CREATE INDEX index_gist_l_zonesstatut_the_geom ON l_zonesstatut USING gist (the_geom);


--
-- Name: index_gist_l_aireadhesion_the_geom; Type: INDEX; Schema: layers; Owner: -; Tablespace: 
--

CREATE INDEX index_gist_l_aireadhesion_the_geom ON l_aireadhesion USING gist (the_geom);


--
-- Name: index_gist_l_isolines20_the_geom; Type: INDEX; Schema: layers; Owner: -; Tablespace: 
--

CREATE INDEX index_gist_l_isolines20_the_geom ON l_isolines20 USING gist (the_geom);


SET search_path = synthese, pg_catalog;

--
-- Name: tri_insert_syntheseff; Type: TRIGGER; Schema: synthese; Owner: -
--

CREATE TRIGGER tri_insert_syntheseff BEFORE INSERT ON syntheseff FOR EACH ROW EXECUTE PROCEDURE insert_syntheseff();


--
-- Name: tri_maj_cor_unite_synthese; Type: TRIGGER; Schema: synthese; Owner: -
--

CREATE TRIGGER tri_maj_cor_unite_synthese AFTER INSERT OR DELETE OR UPDATE ON syntheseff FOR EACH ROW EXECUTE PROCEDURE maj_cor_unite_synthese();


--
-- Name: tri_maj_cor_zonesstatut_synthese; Type: TRIGGER; Schema: synthese; Owner: -
--

CREATE TRIGGER tri_maj_cor_zonesstatut_synthese AFTER INSERT OR DELETE OR UPDATE ON syntheseff FOR EACH ROW EXECUTE PROCEDURE maj_cor_zonesstatut_synthese();


--
-- Name: tri_update_syntheseff; Type: TRIGGER; Schema: synthese; Owner: -
--

CREATE TRIGGER tri_update_syntheseff BEFORE UPDATE ON syntheseff FOR EACH ROW EXECUTE PROCEDURE update_syntheseff();


SET search_path = layers, pg_catalog;

--
-- Name: l_communes_id_secteur_fkey; Type: FK CONSTRAINT; Schema: layers; Owner: -
--

ALTER TABLE ONLY l_communes
    ADD CONSTRAINT l_communes_id_secteur_fkey FOREIGN KEY (id_secteur) REFERENCES l_secteurs(id_secteur);


--
-- Name: l_zonesstatut_id_type_fkey; Type: FK CONSTRAINT; Schema: layers; Owner: -
--

ALTER TABLE ONLY l_zonesstatut
    ADD CONSTRAINT l_zonesstatut_id_type_fkey FOREIGN KEY (id_type) REFERENCES bib_typeszones(id_type) ON UPDATE CASCADE;


SET search_path = meta, pg_catalog;

--
-- Name: fk_bib_programmes_bib_lots; Type: FK CONSTRAINT; Schema: meta; Owner: -
--

ALTER TABLE ONLY bib_lots
    ADD CONSTRAINT fk_bib_programmes_bib_lots FOREIGN KEY (id_programme) REFERENCES bib_programmes(id_programme) ON UPDATE CASCADE;


SET search_path = synthese, pg_catalog;

--
-- Name: fk_cor_unite_synthese_syntheseff; Type: FK CONSTRAINT; Schema: synthese; Owner: -
--

ALTER TABLE ONLY cor_unite_synthese
    ADD CONSTRAINT fk_cor_unite_synthese_syntheseff FOREIGN KEY (id_synthese) REFERENCES syntheseff(id_synthese) ON UPDATE CASCADE ON DELETE CASCADE;

  
--
-- Name: fk_cor_zonesstatut_synthese_syntheseff; Type: FK CONSTRAINT; Schema: synthese; Owner: -
--

ALTER TABLE ONLY cor_zonesstatut_synthese
    ADD CONSTRAINT fk_cor_zonesstatut_synthese_syntheseff FOREIGN KEY (id_synthese) REFERENCES syntheseff(id_synthese) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_synthese_bib_organismes; Type: FK CONSTRAINT; Schema: synthese; Owner: -
--

ALTER TABLE ONLY syntheseff
    ADD CONSTRAINT fk_synthese_bib_organismes FOREIGN KEY (id_organisme) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;


--
-- Name: synthese_id_critere_synthese_fkey; Type: FK CONSTRAINT; Schema: synthese; Owner: -
--

ALTER TABLE ONLY syntheseff
    ADD CONSTRAINT synthese_id_critere_synthese_fkey FOREIGN KEY (id_critere_synthese) REFERENCES bib_criteres_synthese(id_critere_synthese) ON UPDATE CASCADE;


--
-- Name: synthese_id_lot_fkey; Type: FK CONSTRAINT; Schema: synthese; Owner: -
--

ALTER TABLE ONLY syntheseff
    ADD CONSTRAINT synthese_id_lot_fkey FOREIGN KEY (id_lot) REFERENCES meta.bib_lots(id_lot) ON UPDATE CASCADE;


--
-- Name: synthese_id_precision_fkey; Type: FK CONSTRAINT; Schema: synthese; Owner: -
--

ALTER TABLE ONLY syntheseff
    ADD CONSTRAINT synthese_id_precision_fkey FOREIGN KEY (id_precision) REFERENCES meta.t_precisions(id_precision) ON UPDATE CASCADE;


--
-- Name: synthese_id_protocole_fkey; Type: FK CONSTRAINT; Schema: synthese; Owner: -
--

ALTER TABLE ONLY syntheseff
    ADD CONSTRAINT synthese_id_protocole_fkey FOREIGN KEY (id_protocole) REFERENCES meta.t_protocoles(id_protocole) ON UPDATE CASCADE;


--
-- Name: synthese_id_source_fkey; Type: FK CONSTRAINT; Schema: synthese; Owner: -
--

ALTER TABLE ONLY syntheseff
    ADD CONSTRAINT synthese_id_source_fkey FOREIGN KEY (id_source) REFERENCES bib_sources(id_source) ON UPDATE CASCADE;
