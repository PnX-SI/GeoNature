--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 13 (class 2615 OID 2747600)
-- Name: florestation; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA florestation;


SET search_path = florestation, pg_catalog;

--
-- TOC entry 1478 (class 1255 OID 2747647)
-- Name: application_rang_sp(integer); Type: FUNCTION; Schema: florestation; Owner: -
--

CREATE FUNCTION application_rang_sp(id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
--fonction permettant de renvoyer le cd_ref au rang espèce d'une sous-espèce, une variété ou une convariété à partir de son cd_nom
--si le cd_nom passé est d'un rang espèce ou supérieur (genre, famille...), la fonction renvoie le cd_ref du même rang que le cd_nom passé en entré
--
--Gil DELUERMOZ septembre 2011

  DECLARE
  rang character(4);
  rangsup character(4);
  ref integer;
  sup integer;
  BEGIN
	SELECT INTO rang id_rang FROM taxonomie.taxref WHERE cd_nom = id;
	IF(rang='SSES' OR rang = 'VAR' OR rang = 'CVAR') THEN
	    IF(rang = 'SSES') THEN
		SELECT INTO ref cd_taxsup FROM taxonomie.taxref WHERE cd_nom = id;
	    END IF;
	    
	    IF(rang = 'VAR' OR rang = 'CVAR') THEN
		SELECT INTO sup cd_taxsup FROM taxonomie.taxref WHERE cd_nom = id;
		SELECT INTO rangsup id_rang FROM taxonomie.taxref WHERE cd_nom = sup;
		IF(rangsup = 'ES') THEN
			SELECT INTO ref cd_ref FROM taxonomie.taxref WHERE cd_nom = sup;
		END IF;
		IF(rangsup = 'SSES') THEN
			SELECT INTO ref cd_taxsup FROM taxonomie.taxref WHERE cd_nom = sup;
		END IF;
	    END IF;
	ELSE
	   SELECT INTO ref cd_ref FROM taxonomie.taxref WHERE cd_nom = id;
	END IF;
	return ref;
  END;
$$;


--
-- TOC entry 1503 (class 1255 OID 2747648)
-- Name: delete_synthese_cor_fs_taxon(); Type: FUNCTION; Schema: florestation; Owner: -
--

CREATE FUNCTION delete_synthese_cor_fs_taxon() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
--il n'y a pas de trigger delete sur la table t_stations_fs parce qu'il un delete cascade dans la fk id_station de cor_fs_taxon
--donc si on supprime la station, on supprime sa ou ces taxons relevés et donc ce trigger sera déclanché et fera le ménage dans la table syntheseff

BEGIN
        --on fait le delete dans syntheseff
        DELETE FROM synthese.syntheseff WHERE id_source = 5 AND id_fiche_source = CAST(old.gid AS VARCHAR(25));
	RETURN old; 			
END;
$$;


--
-- TOC entry 1502 (class 1255 OID 2747649)
-- Name: etiquette_utm(public.geometry); Type: FUNCTION; Schema: florestation; Owner: -
--

CREATE FUNCTION etiquette_utm(mongeom public.geometry) RETURNS character
    LANGUAGE plpgsql
    AS $$
DECLARE
monx char(6);
mony char(7);
monetiquette char(24);
BEGIN
-- on prend le centroid du géom comme ça la fonction marchera avec tous les objets point ligne ou polygon
-- si la longitude en WGS84 degré decimal est < à 6 degrés on est en zone UTM 31
IF public.st_x(public.st_transform(public.st_centroid(mongeom),4326))< 6 then
	monx = CAST(public.st_x(public.st_transform(public.st_centroid(mongeom),32631)) AS integer)as string;
	mony = CAST(public.st_y(public.st_transform(public.st_centroid(mongeom),32631)) AS integer)as string;
	monetiquette = 'UTM31 x:'|| monx || ' y:' || mony;
ELSE
	-- sinon on est en zone UTM 32
	monx = CAST(public.st_x(public.st_transform(public.st_centroid(mongeom),32632)) AS integer)as string;
	mony = CAST(public.st_y(public.st_transform(public.st_centroid(mongeom),32632)) AS integer)as string;
	monetiquette = 'UTM32 x:'|| monx || ' y:' || mony;
END IF;
RETURN monetiquette;
END;
$$;


--
-- TOC entry 1479 (class 1255 OID 2747650)
-- Name: florestation_insert(); Type: FUNCTION; Schema: florestation; Owner: -
--

CREATE FUNCTION florestation_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN	
new.date_insert= 'now';	 -- mise a jour de date insert
new.date_update= 'now';	 -- mise a jour de date update
--new.the_geom_local = public.st_transform(new.the_geom_3857,MYLOCALSRID);
--new.insee = layers.f_insee(new.the_geom_local);-- mise a jour du code insee
--new.altitude_sig = layers.f_isolines20(new.the_geom_local); -- mise à jour de l'altitude sig

--if new.altitude_saisie is null or new.altitude_saisie = 0 then -- mis à jour de l'altitude retenue
  --new.altitude_retenue = new.altitude_sig;
--else
  --new.altitude_retenue = new.altitude_saisie;
--end if;

return new; -- return new procède à l'insertion de la donnée dans PG avec les nouvelles valeures.			

END;
$$;


--
-- TOC entry 1480 (class 1255 OID 2747651)
-- Name: florestation_update(); Type: FUNCTION; Schema: florestation; Owner: -
--

CREATE FUNCTION florestation_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
--si aucun geom n'existait et qu'au moins un geom est ajouté, on créé les 2 geom
IF (old.the_geom_local is null AND old.the_geom_3857 is null) THEN
    IF (new.the_geom_local is NOT NULL) THEN
        new.the_geom_3857 = public.st_transform(new.the_geom_local,3857);
		new.srid_dessin = MYLOCALSRID;
    END IF;
    IF (new.the_geom_3857 is NOT NULL) THEN
        new.the_geom_local = public.st_transform(new.the_geom_3857,MYLOCALSRID);
		new.srid_dessin = 3857;
    END IF;
    -- on calcul la commune...
    new.insee = layers.f_insee(new.the_geom_local);-- mise à jour du code insee
    -- on calcul l'altitude
    new.altitude_sig = layers.f_isolines20(new.the_geom_local); -- mise à jour de l'altitude sig
    IF new.altitude_saisie IS null OR new.altitude_saisie = -1 THEN-- mis à jour de l'altitude retenue
        new.altitude_retenue = new.altitude_sig;
    ELSE
        new.altitude_retenue = new.altitude_saisie;
    END IF;
END IF;
--si au moins un geom existait et qu'il a changé on fait une mise à jour
IF (old.the_geom_local is NOT NULL OR old.the_geom_3857 is NOT NULL) THEN
    --si c'est le MYLOCALSRID qui existait on teste s'il a changé
    IF (old.the_geom_local is NOT NULL AND new.the_geom_local is NOT NULL) THEN
        IF NOT public.st_equals(new.the_geom_local,old.the_geom_local) THEN
            new.the_geom_3857 = public.st_transform(new.the_geom_local,3857);
            new.srid_dessin = MYLOCALSRID;
        END IF;
    END IF;
    --si c'est le 3857 qui existait on teste s'il a changé
    IF (old.the_geom_3857 is NOT NULL AND new.the_geom_3857 is NOT NULL) THEN
        IF NOT public.st_equals(new.the_geom_3857,old.the_geom_3857) THEN
            new.the_geom_local = public.st_transform(new.the_geom_3857,MYLOCALSRID);
            new.srid_dessin = 3857;
        END IF;
    END IF;
    -- on calcul la commune...
    new.insee = layers.f_insee(new.the_geom_local);-- mise à jour du code insee
    -- on calcul l'altitude
    new.altitude_sig = layers.f_isolines20(new.the_geom_local); -- mise à jour de l'altitude sig
    IF new.altitude_saisie IS null OR new.altitude_saisie = -1 THEN-- mis à jour de l'altitude retenue
        new.altitude_retenue = new.altitude_sig;
    ELSE
        new.altitude_retenue = new.altitude_saisie;
    END IF;
END IF;

IF (new.altitude_saisie <> old.altitude_saisie OR old.altitude_saisie is null OR new.altitude_saisie is null OR old.altitude_saisie=0 OR new.altitude_saisie=0) then  -- mis à jour de l'altitude retenue
	BEGIN
		if new.altitude_saisie is null or new.altitude_saisie = 0 then
			new.altitude_retenue = layers.f_isolines20(new.the_geom_local);
		else
			new.altitude_retenue = new.altitude_saisie;
		end if;
	END;	
END IF;

new.date_update= 'now';	 -- mise a jour de date insert

RETURN new; -- return new procède à l'insertion de la donnée dans PG avec les nouvelles valeures.			
END;
$$;


--
-- TOC entry 1481 (class 1255 OID 2747652)
-- Name: insert_synthese_cor_fs_taxon(); Type: FUNCTION; Schema: florestation; Owner: -
--

CREATE FUNCTION insert_synthese_cor_fs_taxon() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    fiche RECORD;
    mesobservateurs character varying(255);
BEGIN
    SELECT INTO fiche * FROM florestation.t_stations_fs WHERE id_station = new.id_station;
    --Récupération des données dans la table t_zprospection et de la liste des observateurs	
    SELECT INTO mesobservateurs array_to_string(array_agg(r.prenom_role || ' ' || r.nom_role), ', ') AS observateurs 
    FROM florestation.cor_fs_observateur c
    JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
    JOIN florestation.t_stations_fs s ON s.id_station = c.id_station
    WHERE c.id_station = new.id_station;
    
    -- MAJ de la table cor_unite_taxon, on commence par récupérer les zonnes à statuts à partir du pointage (table t_fiches_cf)
    INSERT INTO synthese.syntheseff
    (
      id_source,
      id_fiche_source,
      code_fiche_source,
      id_organisme,
      id_protocole,
      id_precision,
      cd_nom,
      insee,
      dateobs,
      observateurs,
      altitude_retenue,
      remarques,
      derniere_action,
      supprime,
      id_lot,
      the_geom_3857,
      the_geom_local,
      the_geom_point
    )
    VALUES
    ( 
      5, 
      new.gid,
      'st' || new.id_station || '-' || 'cdnom' || new.cd_nom,
      fiche.id_organisme,
      fiche.id_protocole,
      1,
      new.cd_nom,
      fiche.insee,
      fiche.dateobs,
      mesobservateurs,
      fiche.altitude_retenue,
      fiche.remarques,
      'c',
      new.supprime,
      fiche.id_lot,
      fiche.the_geom_3857,
      fiche.the_geom_local,
      fiche.the_geom_3857
    );
	
RETURN NEW; 			
END;
$$;


--
-- TOC entry 1482 (class 1255 OID 2747653)
-- Name: update_synthese_cor_fs_observateur(); Type: FUNCTION; Schema: florestation; Owner: -
--

CREATE FUNCTION update_synthese_cor_fs_observateur() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
    monreleve RECORD;
    mesobservateurs character varying(255);
BEGIN
    --Récupération de la liste des observateurs	
    --ici on va mettre à jour l'enregistrement dans syntheseff autant de fois qu'on insert dans cette table
	SELECT INTO mesobservateurs array_to_string(array_agg(r.prenom_role || ' ' || r.nom_role), ', ') AS observateurs 
    FROM florestation.cor_fs_observateur c
    JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
    JOIN florestation.t_stations_fs s ON s.id_station = c.id_station
    WHERE c.id_station = new.id_station;
    --on boucle sur tous les enregistrements de la station
    FOR monreleve IN SELECT gid FROM florestation.cor_fs_taxon WHERE id_station = new.id_station  LOOP
        --on fait le update du champ observateurs dans syntheseff
        UPDATE synthese.syntheseff 
        SET 
            observateurs = mesobservateurs,
            derniere_action = 'u'
        WHERE id_source = 5 AND id_fiche_source = CAST(monreleve.gid AS VARCHAR(25));
    END LOOP;
	RETURN NEW; 			
END;
$$;


--
-- TOC entry 1487 (class 1255 OID 2747654)
-- Name: update_synthese_cor_fs_taxon(); Type: FUNCTION; Schema: florestation; Owner: -
--

CREATE FUNCTION update_synthese_cor_fs_taxon() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
--On ne fait qq chose que si l'un des champs de la table cor_fs_taxon concerné dans syntheseff a changé
IF (
        new.id_station <> old.id_station 
        OR new.gid <> old.gid 
        OR new.cd_nom <> old.cd_nom 
        OR new.supprime <> old.supprime 
    ) THEN
    --on fait le update dans syntheseff
    UPDATE synthese.syntheseff 
    SET 
	id_fiche_source = new.gid,
	code_fiche_source = 'st' || new.id_station || '-' || 'cdnom' || new.cd_nom,
	cd_nom = new.cd_nom,
	derniere_action = 'u',
	supprime = new.supprime
    WHERE id_source = 5 AND id_fiche_source = CAST(old.gid AS VARCHAR(25));
END IF;

RETURN NEW; 			
END;
$$;


--
-- TOC entry 1512 (class 1255 OID 2747655)
-- Name: update_synthese_stations_fs(); Type: FUNCTION; Schema: florestation; Owner: -
--

CREATE FUNCTION update_synthese_stations_fs() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
    monreleve RECORD;
BEGIN
FOR monreleve IN SELECT gid, cd_nom FROM florestation.cor_fs_taxon WHERE id_station = new.id_station  LOOP
    --On ne fait qq chose que si l'un des champs de la table t_stations_fs concerné dans syntheseff a changé
    IF (
            new.id_station <> old.id_station 
            OR ((new.remarques <> old.remarques) OR (new.remarques is null and old.remarques is NOT NULL) OR (new.remarques is NOT NULL and old.remarques is null))
            OR ((new.insee <> old.insee) OR (new.insee is null and old.insee is NOT NULL) OR (new.insee is NOT NULL and old.insee is null))
            OR ((new.dateobs <> old.dateobs) OR (new.dateobs is null and old.dateobs is NOT NULL) OR (new.dateobs is NOT NULL and old.dateobs is null))
            OR ((new.altitude_retenue <> old.altitude_retenue) OR (new.altitude_retenue is null and old.altitude_retenue is NOT NULL) OR (new.altitude_retenue is NOT NULL and old.altitude_retenue is null))
        ) THEN
        --on fait le update dans syntheseff
        UPDATE synthese.syntheseff 
        SET 
            code_fiche_source = 'st' || new.id_station || '-' || 'cdnom' || monreleve.cd_nom,
            insee = new.insee,
            dateobs = new.dateobs,
            altitude_retenue = new.altitude_retenue,
            remarques = new.remarques,
            derniere_action = 'u',
            the_geom_3857 = new.the_geom_3857,
            the_geom_local = new.the_geom_local,
            the_geom_point = new.the_geom_3857
        WHERE id_source = 5 AND id_fiche_source = CAST(monreleve.gid AS VARCHAR(25));
    END IF;
END LOOP;
	RETURN NEW; 
END;
$$;


SET default_with_oids = false;

--
-- TOC entry 280 (class 1259 OID 2747845)
-- Name: bib_abondances; Type: TABLE; Schema: florestation; Owner: -
--

CREATE TABLE bib_abondances (
    id_abondance character(1) NOT NULL,
    nom_abondance character varying(128) NOT NULL
);


--
-- TOC entry 281 (class 1259 OID 2747848)
-- Name: bib_expositions; Type: TABLE; Schema: florestation; Owner: -
--

CREATE TABLE bib_expositions (
    id_exposition character(2) NOT NULL,
    nom_exposition character varying(10) NOT NULL,
    tri_exposition integer
);


--
-- TOC entry 282 (class 1259 OID 2747851)
-- Name: bib_homogenes; Type: TABLE; Schema: florestation; Owner: -
--

CREATE TABLE bib_homogenes (
    id_homogene integer NOT NULL,
    nom_homogene character varying(20) NOT NULL
);


--
-- TOC entry 283 (class 1259 OID 2747854)
-- Name: bib_microreliefs; Type: TABLE; Schema: florestation; Owner: -
--

CREATE TABLE bib_microreliefs (
    id_microrelief integer NOT NULL,
    nom_microrelief character varying(128) NOT NULL
);


--
-- TOC entry 284 (class 1259 OID 2747857)
-- Name: bib_programmes_fs; Type: TABLE; Schema: florestation; Owner: -
--

CREATE TABLE bib_programmes_fs (
    id_programme_fs integer NOT NULL,
    nom_programme_fs character varying(255) NOT NULL
);


--
-- TOC entry 285 (class 1259 OID 2747860)
-- Name: bib_surfaces; Type: TABLE; Schema: florestation; Owner: -
--

CREATE TABLE bib_surfaces (
    id_surface integer NOT NULL,
    nom_surface character varying(20) NOT NULL
);


--
-- TOC entry 286 (class 1259 OID 2747863)
-- Name: cor_fs_delphine; Type: TABLE; Schema: florestation; Owner: -
--

CREATE TABLE cor_fs_delphine (
    id_station bigint NOT NULL,
    id_delphine character varying(5) NOT NULL
);


--
-- TOC entry 287 (class 1259 OID 2747866)
-- Name: cor_fs_microrelief; Type: TABLE; Schema: florestation; Owner: -
--

CREATE TABLE cor_fs_microrelief (
    id_station bigint NOT NULL,
    id_microrelief integer NOT NULL
);


--
-- TOC entry 288 (class 1259 OID 2747869)
-- Name: cor_fs_observateur; Type: TABLE; Schema: florestation; Owner: -
--

CREATE TABLE cor_fs_observateur (
    id_role integer NOT NULL,
    id_station bigint NOT NULL
);


--
-- TOC entry 289 (class 1259 OID 2747872)
-- Name: cor_fs_taxon_gid_seq; Type: SEQUENCE; Schema: florestation; Owner: -
--

CREATE SEQUENCE cor_fs_taxon_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 290 (class 1259 OID 2747874)
-- Name: cor_fs_taxon; Type: TABLE; Schema: florestation; Owner: -
--

CREATE TABLE cor_fs_taxon (
    id_station bigint NOT NULL,
    cd_nom integer NOT NULL,
    herb character(1),
    inf_1m character(1),
    de_1_4m character(1),
    sup_4m character(1),
    taxon_saisi character varying(150),
    supprime boolean DEFAULT false,
    id_station_cd_nom integer NOT NULL,
    gid integer DEFAULT nextval('cor_fs_taxon_gid_seq'::regclass) NOT NULL
);


--
-- TOC entry 291 (class 1259 OID 2747879)
-- Name: cor_fs_taxon_id_station_cd_nom_seq; Type: SEQUENCE; Schema: florestation; Owner: -
--

CREATE SEQUENCE cor_fs_taxon_id_station_cd_nom_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3974 (class 0 OID 0)
-- Dependencies: 291
-- Name: cor_fs_taxon_id_station_cd_nom_seq; Type: SEQUENCE OWNED BY; Schema: florestation; Owner: -
--

ALTER SEQUENCE cor_fs_taxon_id_station_cd_nom_seq OWNED BY cor_fs_taxon.id_station_cd_nom;


--
-- TOC entry 292 (class 1259 OID 2747881)
-- Name: t_stations_fs; Type: TABLE; Schema: florestation; Owner: -
--

CREATE TABLE t_stations_fs (
    id_station bigint NOT NULL,
    id_exposition character(2) NOT NULL,
    id_sophie character varying(5),
    id_programme_fs integer DEFAULT 999 NOT NULL,
    id_support integer NOT NULL,
    id_protocole integer NOT NULL,
    id_lot integer NOT NULL,
    id_organisme integer NOT NULL,
    id_homogene integer,
    dateobs date,
    info_acces character varying(255),
    id_surface integer DEFAULT 1,
    complet_partiel character(1),
    meso_longitudinal integer DEFAULT 0,
    meso_lateral integer DEFAULT 0,
    canopee real DEFAULT 0,
    ligneux_hauts integer DEFAULT 0,
    ligneux_bas integer DEFAULT 0,
    ligneux_tbas integer DEFAULT 0,
    herbaces integer DEFAULT 0,
    mousses integer DEFAULT 0,
    litiere integer DEFAULT 0,
    altitude_saisie integer DEFAULT 0,
    altitude_sig integer DEFAULT 0,
    altitude_retenue integer DEFAULT 0,
    remarques text,
    pdop real DEFAULT 0,
    supprime boolean DEFAULT false,
    date_insert timestamp without time zone,
    date_update timestamp without time zone,
    srid_dessin integer,
    the_geom_3857 public.geometry,
    the_geom_local public.geometry,
    insee character(5),
    gid integer NOT NULL,
    validation boolean DEFAULT false,
    CONSTRAINT enforce_dims_the_geom_local CHECK ((public.st_ndims(the_geom_local) = 2)),
    CONSTRAINT enforce_dims_the_geom_3857 CHECK ((public.st_ndims(the_geom_3857) = 2)),
    CONSTRAINT enforce_geotype_the_geom_local CHECK (((public.geometrytype(the_geom_local) = 'POINT'::text) OR (the_geom_local IS NULL))),
    CONSTRAINT enforce_geotype_the_geom_3857 CHECK (((public.geometrytype(the_geom_3857) = 'POINT'::text) OR (the_geom_3857 IS NULL))),
    CONSTRAINT enforce_srid_the_geom_local CHECK ((public.st_srid(the_geom_local) = MYLOCALSRID)),
    CONSTRAINT enforce_srid_the_geom_3857 CHECK ((public.st_srid(the_geom_3857) = 3857))
);


--
-- TOC entry 293 (class 1259 OID 2747910)
-- Name: t_stations_fs_gid_seq; Type: SEQUENCE; Schema: florestation; Owner: -
--

CREATE SEQUENCE t_stations_fs_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3975 (class 0 OID 0)
-- Dependencies: 293
-- Name: t_stations_fs_gid_seq; Type: SEQUENCE OWNED BY; Schema: florestation; Owner: -
--

ALTER SEQUENCE t_stations_fs_gid_seq OWNED BY t_stations_fs.gid;


--
-- TOC entry 365 (class 1259 OID 2748266)
-- Name: v_florestation_all; Type: VIEW; Schema: florestation; Owner: -
--

CREATE VIEW v_florestation_all AS
 SELECT cor.id_station_cd_nom AS indexbidon,
    fs.id_station,
    fs.dateobs,
    cor.cd_nom,
    btrim((tr.nom_valide)::text) AS nom_valid,
    btrim((tr.nom_vern)::text) AS nom_vern,
    public.st_transform(fs.the_geom_local, MYLOCALSRID) AS the_geom
   FROM ((t_stations_fs fs
     JOIN cor_fs_taxon cor ON ((cor.id_station = fs.id_station)))
     JOIN taxonomie.taxref tr ON ((cor.cd_nom = tr.cd_nom)))
  WHERE ((fs.supprime = false) AND (cor.supprime = false));


--
-- TOC entry 366 (class 1259 OID 2748271)
-- Name: v_florestation_patrimoniale; Type: VIEW; Schema: florestation; Owner: -
--

CREATE OR REPLACE VIEW v_florestation_patrimoniale AS
 SELECT cft.id_station_cd_nom AS indexbidon,
    fs.id_station,
    tx.nom_vern AS francais,
    tx.nom_complet AS latin,
    fs.dateobs,
    fs.the_geom_local
  FROM t_stations_fs fs
     JOIN cor_fs_taxon cft ON cft.id_station = fs.id_station
     JOIN taxonomie.bib_noms n ON n.cd_nom = cft.cd_nom
     LEFT JOIN taxonomie.taxref tx ON tx.cd_nom = cft.cd_nom
     JOIN taxonomie.cor_taxon_attribut cta ON cta.cd_ref = n.cd_ref AND id_attribut = 1 AND valeur_attribut = 'oui'
  WHERE fs.supprime = false AND cft.supprime = false
  ORDER BY fs.id_station, tx.nom_vern;


--
-- TOC entry 367 (class 1259 OID 2748276)
-- Name: v_taxons_fs; Type: VIEW; Schema: florestation; Owner: -
--

CREATE VIEW v_taxons_fs AS
SELECT tx.cd_nom,
    tx.nom_complet
  FROM taxonomie.bib_noms n
     JOIN taxonomie.taxref tx ON tx.cd_nom = n.cd_nom
     JOIN taxonomie.cor_nom_liste cnl ON cnl.id_nom = n.id_nom
  WHERE n.id_nom IN(SELECT id_nom FROM taxonomie.cor_nom_liste WHERE id_liste = 500)
  AND cnl.id_liste = ANY (ARRAY[305, 306, 307, 308]);

--
-- TOC entry 3726 (class 2604 OID 2748296)
-- Name: id_station_cd_nom; Type: DEFAULT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY cor_fs_taxon ALTER COLUMN id_station_cd_nom SET DEFAULT nextval('cor_fs_taxon_id_station_cd_nom_seq'::regclass);


--
-- TOC entry 3744 (class 2604 OID 2748297)
-- Name: gid; Type: DEFAULT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY t_stations_fs ALTER COLUMN gid SET DEFAULT nextval('t_stations_fs_gid_seq'::regclass);


--
-- TOC entry 3752 (class 2606 OID 2748383)
-- Name: pk_bib_abondances; Type: CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY bib_abondances
    ADD CONSTRAINT pk_bib_abondances PRIMARY KEY (id_abondance);


--
-- TOC entry 3754 (class 2606 OID 2748385)
-- Name: pk_bib_expositions; Type: CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY bib_expositions
    ADD CONSTRAINT pk_bib_expositions PRIMARY KEY (id_exposition);


--
-- TOC entry 3756 (class 2606 OID 2748387)
-- Name: pk_bib_homogenes; Type: CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY bib_homogenes
    ADD CONSTRAINT pk_bib_homogenes PRIMARY KEY (id_homogene);


--
-- TOC entry 3758 (class 2606 OID 2748389)
-- Name: pk_bib_microreliefs; Type: CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY bib_microreliefs
    ADD CONSTRAINT pk_bib_microreliefs PRIMARY KEY (id_microrelief);


--
-- TOC entry 3760 (class 2606 OID 2748391)
-- Name: pk_bib_programmes_fs; Type: CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY bib_programmes_fs
    ADD CONSTRAINT pk_bib_programmes_fs PRIMARY KEY (id_programme_fs);


--
-- TOC entry 3762 (class 2606 OID 2748393)
-- Name: pk_bib_surfaces; Type: CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY bib_surfaces
    ADD CONSTRAINT pk_bib_surfaces PRIMARY KEY (id_surface);


--
-- TOC entry 3764 (class 2606 OID 2748395)
-- Name: pk_cor_fs_delphine; Type: CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY cor_fs_delphine
    ADD CONSTRAINT pk_cor_fs_delphine PRIMARY KEY (id_station, id_delphine);


--
-- TOC entry 3766 (class 2606 OID 2748397)
-- Name: pk_cor_fs_microrelief; Type: CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY cor_fs_microrelief
    ADD CONSTRAINT pk_cor_fs_microrelief PRIMARY KEY (id_station, id_microrelief);


--
-- TOC entry 3768 (class 2606 OID 2748399)
-- Name: pk_cor_fs_observateur; Type: CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY cor_fs_observateur
    ADD CONSTRAINT pk_cor_fs_observateur PRIMARY KEY (id_role, id_station);


--
-- TOC entry 3771 (class 2606 OID 2748401)
-- Name: pk_cor_fs_taxons; Type: CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY cor_fs_taxon
    ADD CONSTRAINT pk_cor_fs_taxons PRIMARY KEY (id_station, cd_nom);


--
-- TOC entry 3778 (class 2606 OID 2748403)
-- Name: pk_t_stations_fs; Type: CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY t_stations_fs
    ADD CONSTRAINT pk_t_stations_fs PRIMARY KEY (id_station);


--
-- TOC entry 3780 (class 2606 OID 2748405)
-- Name: t_stations_fs_gid_key; Type: CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY t_stations_fs
    ADD CONSTRAINT t_stations_fs_gid_key UNIQUE (gid);


--
-- TOC entry 3772 (class 1259 OID 2748481)
-- Name: fki_t_stations_fs_bib_homogenes; Type: INDEX; Schema: florestation; Owner: -
--

CREATE INDEX fki_t_stations_fs_bib_homogenes ON t_stations_fs USING btree (id_homogene);


--
-- TOC entry 3773 (class 1259 OID 2748482)
-- Name: fki_t_stations_fs_gid; Type: INDEX; Schema: florestation; Owner: -
--

CREATE INDEX fki_t_stations_fs_gid ON t_stations_fs USING btree (gid);


--
-- TOC entry 3976 (class 0 OID 0)
-- Dependencies: 3773
-- Name: INDEX fki_t_stations_fs_gid; Type: COMMENT; Schema: florestation; Owner: -
--

COMMENT ON INDEX fki_t_stations_fs_gid IS 'pour le fonctionnement de qgis';


--
-- TOC entry 3774 (class 1259 OID 2748483)
-- Name: i_fk_t_stations_fs_bib_exposit; Type: INDEX; Schema: florestation; Owner: -
--

CREATE INDEX i_fk_t_stations_fs_bib_exposit ON t_stations_fs USING btree (id_exposition);


--
-- TOC entry 3775 (class 1259 OID 2748484)
-- Name: i_fk_t_stations_fs_bib_program; Type: INDEX; Schema: florestation; Owner: -
--

CREATE INDEX i_fk_t_stations_fs_bib_program ON t_stations_fs USING btree (id_programme_fs);


--
-- TOC entry 3776 (class 1259 OID 2748485)
-- Name: i_fk_t_stations_fs_bib_support; Type: INDEX; Schema: florestation; Owner: -
--

CREATE INDEX i_fk_t_stations_fs_bib_support ON t_stations_fs USING btree (id_support);


--
-- TOC entry 3769 (class 1259 OID 2748486)
-- Name: index_cd_nom; Type: INDEX; Schema: florestation; Owner: -
--

CREATE INDEX index_cd_nom ON cor_fs_taxon USING btree (cd_nom);


--
-- TOC entry 3801 (class 2620 OID 2748534)
-- Name: tri_delete_synthese_cor_fs_taxon; Type: TRIGGER; Schema: florestation; Owner: -
--

CREATE TRIGGER tri_delete_synthese_cor_fs_taxon AFTER DELETE ON cor_fs_taxon FOR EACH ROW EXECUTE PROCEDURE delete_synthese_cor_fs_taxon();


--
-- TOC entry 3804 (class 2620 OID 2748535)
-- Name: tri_insert; Type: TRIGGER; Schema: florestation; Owner: -
--

CREATE TRIGGER tri_insert BEFORE INSERT ON t_stations_fs FOR EACH ROW EXECUTE PROCEDURE florestation_insert();


--
-- TOC entry 3800 (class 2620 OID 2748536)
-- Name: tri_insert_synthese_cor_fs_observateur; Type: TRIGGER; Schema: florestation; Owner: -
--

CREATE TRIGGER tri_insert_synthese_cor_fs_observateur AFTER INSERT ON cor_fs_observateur FOR EACH ROW EXECUTE PROCEDURE update_synthese_cor_fs_observateur();


--
-- TOC entry 3802 (class 2620 OID 2748537)
-- Name: tri_insert_synthese_cor_fs_taxon; Type: TRIGGER; Schema: florestation; Owner: -
--

CREATE TRIGGER tri_insert_synthese_cor_fs_taxon AFTER INSERT ON cor_fs_taxon FOR EACH ROW EXECUTE PROCEDURE insert_synthese_cor_fs_taxon();


--
-- TOC entry 3805 (class 2620 OID 2748538)
-- Name: tri_update; Type: TRIGGER; Schema: florestation; Owner: -
--

CREATE TRIGGER tri_update BEFORE UPDATE ON t_stations_fs FOR EACH ROW EXECUTE PROCEDURE florestation_update();


--
-- TOC entry 3803 (class 2620 OID 2748539)
-- Name: tri_update_synthese_cor_fs_taxon; Type: TRIGGER; Schema: florestation; Owner: -
--

CREATE TRIGGER tri_update_synthese_cor_fs_taxon AFTER UPDATE ON cor_fs_taxon FOR EACH ROW EXECUTE PROCEDURE update_synthese_cor_fs_taxon();


--
-- TOC entry 3806 (class 2620 OID 2748540)
-- Name: tri_update_synthese_stations_fs; Type: TRIGGER; Schema: florestation; Owner: -
--

CREATE TRIGGER tri_update_synthese_stations_fs AFTER UPDATE ON t_stations_fs FOR EACH ROW EXECUTE PROCEDURE update_synthese_stations_fs();


--
-- TOC entry 3781 (class 2606 OID 2748826)
-- Name: cor_fs_delphine_id_station_fkey; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY cor_fs_delphine
    ADD CONSTRAINT cor_fs_delphine_id_station_fkey FOREIGN KEY (id_station) REFERENCES t_stations_fs(id_station) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3782 (class 2606 OID 2748831)
-- Name: cor_fs_microrelief_id_station_fkey; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY cor_fs_microrelief
    ADD CONSTRAINT cor_fs_microrelief_id_station_fkey FOREIGN KEY (id_station) REFERENCES t_stations_fs(id_station) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3784 (class 2606 OID 2748836)
-- Name: cor_fs_observateur_id_station_fkey; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY cor_fs_observateur
    ADD CONSTRAINT cor_fs_observateur_id_station_fkey FOREIGN KEY (id_station) REFERENCES t_stations_fs(id_station) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3786 (class 2606 OID 2748841)
-- Name: cor_fs_taxons_cd_nom_fkey; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY cor_fs_taxon
    ADD CONSTRAINT cor_fs_taxons_cd_nom_fkey FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;


--
-- TOC entry 3787 (class 2606 OID 2748846)
-- Name: cor_fs_taxons_id_station_fkey; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY cor_fs_taxon
    ADD CONSTRAINT cor_fs_taxons_id_station_fkey FOREIGN KEY (id_station) REFERENCES t_stations_fs(id_station) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3783 (class 2606 OID 2748851)
-- Name: fk_cor_fs_microrelief_bib_microreliefs; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY cor_fs_microrelief
    ADD CONSTRAINT fk_cor_fs_microrelief_bib_microreliefs FOREIGN KEY (id_microrelief) REFERENCES bib_microreliefs(id_microrelief) ON UPDATE CASCADE;


--
-- TOC entry 3785 (class 2606 OID 2748856)
-- Name: fk_cor_fs_observateur_t_roles; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY cor_fs_observateur
    ADD CONSTRAINT fk_cor_fs_observateur_t_roles FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;


--
-- TOC entry 3788 (class 2606 OID 2748861)
-- Name: fk_de_1_4m; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY cor_fs_taxon
    ADD CONSTRAINT fk_de_1_4m FOREIGN KEY (de_1_4m) REFERENCES bib_abondances(id_abondance) ON UPDATE CASCADE;


--
-- TOC entry 3789 (class 2606 OID 2748866)
-- Name: fk_herb; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY cor_fs_taxon
    ADD CONSTRAINT fk_herb FOREIGN KEY (herb) REFERENCES bib_abondances(id_abondance) ON UPDATE CASCADE;


--
-- TOC entry 3790 (class 2606 OID 2748871)
-- Name: fk_inf_1m; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY cor_fs_taxon
    ADD CONSTRAINT fk_inf_1m FOREIGN KEY (inf_1m) REFERENCES bib_abondances(id_abondance) ON UPDATE CASCADE;


--
-- TOC entry 3791 (class 2606 OID 2748876)
-- Name: fk_sup_4m; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY cor_fs_taxon
    ADD CONSTRAINT fk_sup_4m FOREIGN KEY (sup_4m) REFERENCES bib_abondances(id_abondance) ON UPDATE CASCADE;


--
-- TOC entry 3792 (class 2606 OID 2748881)
-- Name: fk_t_stations_fs_bib_expositions; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_bib_expositions FOREIGN KEY (id_exposition) REFERENCES bib_expositions(id_exposition) ON UPDATE CASCADE;


--
-- TOC entry 3793 (class 2606 OID 2748886)
-- Name: fk_t_stations_fs_bib_homogenes; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_bib_homogenes FOREIGN KEY (id_homogene) REFERENCES bib_homogenes(id_homogene) ON UPDATE CASCADE;


--
-- TOC entry 3798 (class 2606 OID 2748911)
-- Name: fk_t_stations_fs_bib_lots; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_bib_lots FOREIGN KEY (id_lot) REFERENCES meta.bib_lots(id_lot) ON UPDATE CASCADE;


--
-- TOC entry 3797 (class 2606 OID 2748906)
-- Name: fk_t_stations_fs_bib_organismes; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_bib_organismes FOREIGN KEY (id_organisme) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;


--
-- TOC entry 3794 (class 2606 OID 2748891)
-- Name: fk_t_stations_fs_bib_programmes_; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_bib_programmes_ FOREIGN KEY (id_programme_fs) REFERENCES bib_programmes_fs(id_programme_fs) ON UPDATE CASCADE;


--
-- TOC entry 3795 (class 2606 OID 2748896)
-- Name: fk_t_stations_fs_bib_supports; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_bib_supports FOREIGN KEY (id_support) REFERENCES meta.bib_supports(id_support) ON UPDATE CASCADE;


--
-- TOC entry 3799 (class 2606 OID 2748916)
-- Name: fk_t_stations_fs_bib_surfaces; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_bib_surfaces FOREIGN KEY (id_surface) REFERENCES bib_surfaces(id_surface) ON UPDATE CASCADE;


--
-- TOC entry 3796 (class 2606 OID 2748901)
-- Name: fk_t_stations_fs_t_protocoles; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_t_protocoles FOREIGN KEY (id_protocole) REFERENCES meta.t_protocoles(id_protocole) ON UPDATE CASCADE;


--------------------------------------------------------------------------------------
--------------------INSERTION DES DONNEES DES TABLES DICTIONNAIRES--------------------
--------------------------------------------------------------------------------------

SET search_path = florestation, pg_catalog;

INSERT INTO bib_abondances (id_abondance, nom_abondance) VALUES ('+', 'Moins de 1 %');
INSERT INTO bib_abondances (id_abondance, nom_abondance) VALUES ('1', 'Moins de 5 %');
INSERT INTO bib_abondances (id_abondance, nom_abondance) VALUES ('2', 'De 5 à 25 %');
INSERT INTO bib_abondances (id_abondance, nom_abondance) VALUES ('3', 'De 25 à 50 %');
INSERT INTO bib_abondances (id_abondance, nom_abondance) VALUES ('4', 'De 50 à 75 %');
INSERT INTO bib_abondances (id_abondance, nom_abondance) VALUES ('5', 'Plus de 75 %');
INSERT INTO bib_abondances (id_abondance, nom_abondance) VALUES ('9', 'Aucune');

INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('N ', 'Nord', 1);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('NE', 'Nord Est', 2);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('E ', 'Est', 3);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('SE', 'Sud Est', 4);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('S ', 'Sud', 5);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('SO', 'Sud Ouest', 6);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('O ', 'Ouest', 7);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('NO', 'Nord Ouest', 8);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('I ', 'Indéfinie', 9);

INSERT INTO bib_homogenes (id_homogene, nom_homogene) VALUES (1, 'Oui');
INSERT INTO bib_homogenes (id_homogene, nom_homogene) VALUES (2, 'Non');
INSERT INTO bib_homogenes (id_homogene, nom_homogene) VALUES (9, 'Ne sait pas');

INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (1, 'Roche en place : rocher compact');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (2, 'Roche en place : rocher brisé, jamais surplombant');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (3, 'Formations détritiques : matériel grossier dominant');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (35, 'cône ou tablier d''éboulis (partie médiane à éléments moyens)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (36, 'cône d''avalanche (aucun tri des matériaux entre le haut et le bas)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (37, 'blocs épars dans une pelouse');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (4, 'Formations détritiques : matériel fin dominant (graviers, sables limons, argiles)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (41, 'moraines frontales, latérales ou de fond');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (42, 'creux et bosses (cas général)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (43, 'sommet déboulis (éléments les plus fins)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (44, 'guirlandes de solifluxion');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (45, 'laves torrentielles');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (46, 'alluvions : chenaux, méandres, tresses (le tout privé d''eau)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (47, 'talus naturel (cicatrice d''arrachement ou sapement à la base)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (48, 'berge de lac, de rivière ou de torrent');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (49, 'zone de limon à proximité des glaciers');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (5, 'Microformes liées aux activités humaines présentes (si non, voir 8)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (51, 'talus articficiel (en particulier de piste)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (52, 'piste non goudronnée');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (53, 'sillons de labour');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (54, 'canaux (d''irrigation ou de draînage) / fossé');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (55, 'bordure de sentier et sentier');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (56, 'bourrelet de bulldozer ');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (57, 'ornières');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (58, 'toile en plastique (pour éviter les mauvaises herbes autour des jeunes arbres)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (59, 'petite construction en ciment');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (6, 'Microformes liées aux animaux');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (61, 'draille des ovins, des bovins ou des chamois');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (62, 'labour de sanglier / boutis / gouille / grattis');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (63, 'galeries d''Arvicola terrestris');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (64, 'galeries de campagnols');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (65, 'déblais (devant un terrier de marmotte)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (66, 'autres terriers sans déblais');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (67, 'nids de fourmis');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (7, 'Microformes de nature végétale');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (71, 'bombements à sphaignes');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (72, 'touradons (de grand carex)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (73, 'chablis (racines mise à l''''air)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (74, 'arbres cassés et souches');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (8, 'Microformes liées aux activités humaines passées sauf murets (3.2) et clapier d''épierrement (3.3)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (81, 'brou, talus limitant une terrasse de culture');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (82, 'bombement entre chemin et champs');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (83, 'canal d''irrigation abandonné');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (9, 'Microformes liées à un pergélisol');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (91, 'buttes gazonnées (Emparis)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (92, 'langues gazonnées');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (93, 'sols polygonaux');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (94, 'glaciers rocheux');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (11, 'Poli glaciaire, roches moutonnées, dalles rocheuses lisses,"lauze"');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (12, 'Lapiaz (forme de dissolution du calcaire)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (13, 'Portion de falaise avec surplombs');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (14, 'Pied de falaise surplombante : balme " chemin de pluie" blocs écroulés');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (21, 'Eperons rocheux, rochers brisés, rochillons, petites vires, gradins rocheux');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (22, '"Fesses d''éléphant" (roubines)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (24, 'Ravines (entre les fesses d''éléphant), rigoles et autres talwegs');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (25, 'Petites barres (1 à 5 mètres)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (26, 'Débris rocheux en place ; pente très faible');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (27, 'Fond d''oukane  (crevasse rocheuse)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (28, 'Fond de doline');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (31, 'Falaise délabrée, disloquée  (fissures ouvertes)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (23, 'Couloir (entre les éprerons rocheux)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (32, 'Muret de pierres sèches, ruine   (si non voir 5.9)');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (33, 'Clapier d''épierrement');
INSERT INTO bib_microreliefs (id_microrelief, nom_microrelief) VALUES (34, 'Casse, éboulis (partie inférieure à éléments les plus grossiers)');

INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (3, 'IPA');
INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (4, 'STERF');
INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (5, 'Phytomasse');
INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (2, 'Natura 2000');
INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (1, 'Complément flore patrimoniale');
INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (6, 'Relevé sur un sommet');
INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (7, 'Milieux');
INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (8, 'Messicoles');
INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (9, 'M.A.E et C.A.D');
INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (10, 'Programme Bocage');
INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (101, 'Sophie');
INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (102, 'Autre');
INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (999, 'Aucun programme complémentaire');
INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (11, 'Ecologie verticale');
INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (12, 'Combes à neige');
INSERT INTO bib_programmes_fs (id_programme_fs, nom_programme_fs) VALUES (13, 'E.N.S');

INSERT INTO bib_surfaces (id_surface, nom_surface) VALUES (1, '100 m2');
INSERT INTO bib_surfaces (id_surface, nom_surface) VALUES (2, '10 m2');
INSERT INTO bib_surfaces (id_surface, nom_surface) VALUES (4, 'de 11 à 100 m2');
INSERT INTO bib_surfaces (id_surface, nom_surface) VALUES (5, 'de 101 à 1000 m2');
INSERT INTO bib_surfaces (id_surface, nom_surface) VALUES (3, 'Inf à 10 m2');
INSERT INTO bib_surfaces (id_surface, nom_surface) VALUES (999, 'Pas d''info');


--------------------------------------------------------------------------------------
--------------------AJOUT DU MODULE DANS LES TABLES DE DESCRIPTION--------------------
--------------------------------------------------------------------------------------

SET search_path = meta, pg_catalog;
INSERT INTO bib_programmes (id_programme, nom_programme, desc_programme, actif, programme_public, desc_programme_public) VALUES (5, 'Flore station', 'Relevés stationnels et stratifiés de la flore.', true, true, 'Relevés stationnels et stratifiés de la flore.');
INSERT INTO bib_lots (id_lot, nom_lot, desc_lot, menu_cf, pn, menu_inv, id_programme) VALUES (5, 'flore station', 'Relevés stationnels et stratifiés de la flore', false, true, false, 5);
INSERT INTO t_protocoles VALUES (5, 'Flore station', 'à compléter', 'à compléter', 'à compléter', 'non', NULL, NULL);
SET search_path = synthese, pg_catalog;
INSERT INTO bib_sources (id_source, nom_source, desc_source, host, port, username, pass, db_name, db_schema, db_table, db_field, url, target, picto, groupe, actif) VALUES (5, 'Flore station', 'Données de relevés floristique stationnels complets ou partiel', 'localhost', 22, NULL, NULL, 'geonaturedb', 'florestation', 'cor_fs_taxon', 'gid', 'fs', NULL, 'images/pictos/plante.gif', 'FLORE', true);


--------------------------------------------------------------------------------------
--------------------AJOUT DU MODULE DANS LES TABLES SPATIALES-------------------------
--------------------------------------------------------------------------------------

SET search_path = public, pg_catalog;
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florestation', 't_stations_fs', 'the_geom_local', 2, MYLOCALSRID, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florestation', 'v_florestation_all', 'the_geom', 2, MYLOCALSRID, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florestation', 'v_florestation_patrimoniale', 'the_geom', 2, 27572, 'POINT');