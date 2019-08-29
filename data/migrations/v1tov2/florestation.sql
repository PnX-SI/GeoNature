IMPORT FOREIGN SCHEMA florestation FROM SERVER geonature1server INTO v1_compat;

CREATE SCHEMA v1_florestation;

SET default_tablespace = '';
SET default_with_oids = false;

-------------
--FUNCTIONS--
-------------
CREATE FUNCTION v1_florestation.etiquette_utm(mongeom public.geometry) RETURNS character
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

CREATE FUNCTION v1_florestation.application_rang_sp(id integer) RETURNS integer
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

CREATE OR REPLACE FUNCTION v1_florestation.application_aggregate_taxons_rang_sp(id integer)
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

CREATE OR REPLACE FUNCTION v1_florestation.application_aggregate_taxons_all_rang_sp(id integer)
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

CREATE OR REPLACE FUNCTION v1_florestation.application_find_cdref_rang_sp(id integer)
  RETURNS integer AS
$BODY$
--fonction permettant de renvoyer le cd_ref au rang espèce d'une sous-espèce, une variété ou une convariété à partir de son cd_nom
--si le cd_nom passé est d'un rang espèce ou supérieur (genre, famille...), la fonction renvoie simplement le cd_ref du cd_nom passé en entré
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
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION v1_florestation.application_find_lbnom_ref(id integer)
  RETURNS integer AS
$BODY$
--fonction permettant de renvoyer le lb_nom du taxon de référence d'un taxon synonyme à partir de son cd_nom
--
--Gil DELUERMOZ septembre 2011

  DECLARE 
  nomref varchar(100);
  ref integer;
  BEGIN
	SELECT INTO ref cd_ref FROM taxonomie.taxref WHERE cd_nom = id;
	SELECT INTO nomref lb_nom FROM taxonomie.taxref WHERE cd_nom = ref;
	return nomref;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION v1_florestation.application_find_nomcomplet_ref(id integer)
  RETURNS integer AS
$BODY$
--fonction permettant de renvoyer le nom_complet du taxon de référence d'un taxon synonyme à partir de son cd_nom
--
--Gil DELUERMOZ septembre 2011

  DECLARE 
  nomcompletref varchar(255);
  ref integer;
  BEGIN
	SELECT INTO ref cd_ref FROM taxonomie.taxref WHERE cd_nom = id;
	SELECT INTO nomcompletref nom_complet FROM taxonomie.taxref WHERE cd_nom = ref;
	return nomcompletref;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION v1_florestation.application_nobs2obs(
    ids integer[],
    rang integer)
  RETURNS integer AS
$BODY$
--fonction pour la bdf05 permettant de renvoyer une surface à partir des classes de surface de flore station
--Gil DELUERMOZ avril 2012

  DECLARE 
  id_role integer;
  BEGIN
	return ids[rang];
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION v1_florestation.application_strate2abondance(frequence character)
  RETURNS integer AS
$BODY$
--fonction pour la bdf05 permettant de renvoyer le niveau d'abondance des taxons d'un relevé flore station à partir de l'abondance dans les relevés station
--Gil DELUERMOZ avril 2012

  DECLARE 
  abondance integer;
  BEGIN
	IF frequence = '+' OR frequence = '1' THEN abondance = 1;
	ELSIF frequence = '2' OR frequence = '3' THEN abondance = 2;
	ELSIF frequence = '4' OR frequence = '5' THEN abondance = 3;
	ELSIF frequence = '' OR frequence IS NULL THEN abondance = NULL;
	ELSE abondance = 0;
	END IF;
	RETURN abondance;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION v1_florestation.application_surfacefs2surface(id integer)
  RETURNS integer AS
$BODY$
--fonction pour la bdf05 permettant de renvoyer une surface à partir des classes de surface de flore station
--Gil DELUERMOZ avril 2012

  DECLARE 
  surface integer;
  BEGIN
	IF id  = 1 THEN surface = 100;
	ELSIF id  = 2  THEN surface = 10;
	ELSE surface = NULL;
	END IF;
	RETURN surface;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

--TODO : analyser ce qui sert et déplacer les functions et leur usage dans un schéma métier.

--TABLES--
CREATE TABLE v1_florestation.bib_supports
(
  id_support integer NOT NULL,
  nom_support character varying(20) NOT NULL
);

CREATE TABLE v1_florestation.bib_abondances (
    id_abondance character(1) NOT NULL,
    nom_abondance character varying(128) NOT NULL
);

CREATE TABLE v1_florestation.bib_expositions (
    id_exposition character(2) NOT NULL,
    nom_exposition character varying(10) NOT NULL,
    tri_exposition integer
);

CREATE TABLE v1_florestation.bib_homogenes (
    id_homogene integer NOT NULL,
    nom_homogene character varying(20) NOT NULL
);

CREATE TABLE v1_florestation.bib_microreliefs (
    id_microrelief integer NOT NULL,
    nom_microrelief character varying(128) NOT NULL
);

CREATE TABLE v1_florestation.bib_programmes_fs (
    id_programme_fs integer NOT NULL,
    nom_programme_fs character varying(255) NOT NULL
);

CREATE TABLE v1_florestation.bib_surfaces (
    id_surface integer NOT NULL,
    nom_surface character varying(20) NOT NULL
);

CREATE TABLE v1_florestation.cor_fs_delphine (
    id_station bigint NOT NULL,
    id_delphine character varying(5) NOT NULL
);

CREATE TABLE v1_florestation.cor_fs_microrelief (
    id_station bigint NOT NULL,
    id_microrelief integer NOT NULL
);

CREATE TABLE v1_florestation.cor_fs_observateur (
    id_role integer NOT NULL,
    id_station bigint NOT NULL
);

CREATE SEQUENCE v1_florestation.cor_fs_taxon_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE TABLE v1_florestation.cor_fs_taxon (
    id_station bigint NOT NULL,
    cd_nom integer NOT NULL,
    herb character(1),
    inf_1m character(1),
    de_1_4m character(1),
    sup_4m character(1),
    taxon_saisi character varying(150),
    supprime boolean DEFAULT false,
    id_station_cd_nom integer NOT NULL,
    gid integer DEFAULT nextval('v1_florestation.cor_fs_taxon_gid_seq'::regclass) NOT NULL,
    diffusable boolean DEFAULT true
);
CREATE SEQUENCE v1_florestation.cor_fs_taxon_id_station_cd_nom_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE v1_florestation.cor_fs_taxon_id_station_cd_nom_seq OWNED BY v1_florestation.cor_fs_taxon.id_station_cd_nom;
ALTER TABLE ONLY v1_florestation.cor_fs_taxon ALTER COLUMN id_station_cd_nom SET DEFAULT nextval('v1_florestation.cor_fs_taxon_id_station_cd_nom_seq'::regclass);

CREATE TABLE v1_florestation.t_stations_fs (
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
    the_geom_3857 public.geometry(Point,3857),
    the_geom_local public.geometry(Point,2154),
    insee character(5),
    gid integer NOT NULL,
    validation boolean DEFAULT false,
    CONSTRAINT enforce_dims_the_geom_3857 CHECK ((public.st_ndims(the_geom_3857) = 2)),
    CONSTRAINT enforce_dims_the_geom_local CHECK ((public.st_ndims(the_geom_local) = 2)),
    CONSTRAINT enforce_geotype_the_geom_3857 CHECK (((public.geometrytype(the_geom_3857) = 'POINT'::text) OR (the_geom_3857 IS NULL))),
    CONSTRAINT enforce_geotype_the_geom_local CHECK (((public.geometrytype(the_geom_local) = 'POINT'::text) OR (the_geom_local IS NULL))),
    CONSTRAINT enforce_srid_the_geom_3857 CHECK ((public.st_srid(the_geom_3857) = 3857)),
    CONSTRAINT enforce_srid_the_geom_local CHECK ((public.st_srid(the_geom_local) = 2154))
);
CREATE SEQUENCE v1_florestation.t_stations_fs_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE v1_florestation.t_stations_fs_gid_seq OWNED BY v1_florestation.t_stations_fs.gid;
ALTER TABLE ONLY v1_florestation.t_stations_fs ALTER COLUMN gid SET DEFAULT nextval('v1_florestation.t_stations_fs_gid_seq'::regclass);


--PRIMARY KEY--
ALTER TABLE ONLY v1_florestation.bib_supports
    ADD CONSTRAINT bib_supports_pkey PRIMARY KEY (id_support);

ALTER TABLE ONLY v1_florestation.bib_abondances
    ADD CONSTRAINT pk_bib_abondances PRIMARY KEY (id_abondance);

ALTER TABLE ONLY v1_florestation.bib_expositions
    ADD CONSTRAINT pk_bib_expositions PRIMARY KEY (id_exposition);

ALTER TABLE ONLY v1_florestation.bib_homogenes
    ADD CONSTRAINT pk_bib_homogenes PRIMARY KEY (id_homogene);

ALTER TABLE ONLY v1_florestation.bib_microreliefs
    ADD CONSTRAINT pk_bib_microreliefs PRIMARY KEY (id_microrelief);

ALTER TABLE ONLY v1_florestation.bib_programmes_fs
    ADD CONSTRAINT pk_bib_programmes_fs PRIMARY KEY (id_programme_fs);

ALTER TABLE ONLY v1_florestation.bib_surfaces
    ADD CONSTRAINT pk_bib_surfaces PRIMARY KEY (id_surface);

ALTER TABLE ONLY v1_florestation.cor_fs_delphine
    ADD CONSTRAINT pk_cor_fs_delphine PRIMARY KEY (id_station, id_delphine);

ALTER TABLE ONLY v1_florestation.cor_fs_microrelief
    ADD CONSTRAINT pk_cor_fs_microrelief PRIMARY KEY (id_station, id_microrelief);

ALTER TABLE ONLY v1_florestation.cor_fs_observateur
    ADD CONSTRAINT pk_cor_fs_observateur PRIMARY KEY (id_role, id_station);

ALTER TABLE ONLY v1_florestation.cor_fs_taxon
    ADD CONSTRAINT pk_cor_fs_taxons PRIMARY KEY (id_station, cd_nom);

ALTER TABLE ONLY v1_florestation.t_stations_fs
    ADD CONSTRAINT pk_t_stations_fs PRIMARY KEY (id_station);


--FOREIGN KEY--
ALTER TABLE ONLY v1_florestation.cor_fs_delphine
    ADD CONSTRAINT cor_fs_delphine_id_station_fkey FOREIGN KEY (id_station) REFERENCES v1_florestation.t_stations_fs(id_station) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY v1_florestation.cor_fs_microrelief
    ADD CONSTRAINT cor_fs_microrelief_id_station_fkey FOREIGN KEY (id_station) REFERENCES v1_florestation.t_stations_fs(id_station) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY v1_florestation.cor_fs_observateur
    ADD CONSTRAINT cor_fs_observateur_id_station_fkey FOREIGN KEY (id_station) REFERENCES v1_florestation.t_stations_fs(id_station) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY v1_florestation.cor_fs_taxon
    ADD CONSTRAINT cor_fs_taxons_cd_nom_fkey FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;

ALTER TABLE ONLY v1_florestation.cor_fs_taxon
    ADD CONSTRAINT cor_fs_taxons_id_station_fkey FOREIGN KEY (id_station) REFERENCES v1_florestation.t_stations_fs(id_station) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY v1_florestation.cor_fs_microrelief
    ADD CONSTRAINT fk_cor_fs_microrelief_bib_microreliefs FOREIGN KEY (id_microrelief) REFERENCES v1_florestation.bib_microreliefs(id_microrelief) ON UPDATE CASCADE;

ALTER TABLE ONLY v1_florestation.cor_fs_observateur
    ADD CONSTRAINT fk_cor_fs_observateur_t_roles FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

ALTER TABLE ONLY v1_florestation.cor_fs_taxon
    ADD CONSTRAINT fk_de_1_4m FOREIGN KEY (de_1_4m) REFERENCES v1_florestation.bib_abondances(id_abondance) ON UPDATE CASCADE;

ALTER TABLE ONLY v1_florestation.cor_fs_taxon
    ADD CONSTRAINT fk_herb FOREIGN KEY (herb) REFERENCES v1_florestation.bib_abondances(id_abondance) ON UPDATE CASCADE;

ALTER TABLE ONLY v1_florestation.cor_fs_taxon
    ADD CONSTRAINT fk_inf_1m FOREIGN KEY (inf_1m) REFERENCES v1_florestation.bib_abondances(id_abondance) ON UPDATE CASCADE;

ALTER TABLE ONLY v1_florestation.cor_fs_taxon
    ADD CONSTRAINT fk_sup_4m FOREIGN KEY (sup_4m) REFERENCES v1_florestation.bib_abondances(id_abondance) ON UPDATE CASCADE;

ALTER TABLE ONLY v1_florestation.t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_bib_expositions FOREIGN KEY (id_exposition) REFERENCES v1_florestation.bib_expositions(id_exposition) ON UPDATE CASCADE;

ALTER TABLE ONLY v1_florestation.t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_bib_homogenes FOREIGN KEY (id_homogene) REFERENCES v1_florestation.bib_homogenes(id_homogene) ON UPDATE CASCADE;

ALTER TABLE ONLY v1_florestation.t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_datasets FOREIGN KEY (id_lot) REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE;

ALTER TABLE ONLY v1_florestation.t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_bib_organismes FOREIGN KEY (id_organisme) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY v1_florestation.t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_bib_programmes_fs FOREIGN KEY (id_programme_fs) REFERENCES v1_florestation.bib_programmes_fs(id_programme_fs) ON UPDATE CASCADE;

ALTER TABLE ONLY v1_florestation.t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_bib_supports FOREIGN KEY (id_support) REFERENCES v1_florestation.bib_supports(id_support) ON UPDATE CASCADE;

ALTER TABLE ONLY v1_florestation.t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_bib_surfaces FOREIGN KEY (id_surface) REFERENCES v1_florestation.bib_surfaces(id_surface) ON UPDATE CASCADE;

ALTER TABLE ONLY v1_florestation.t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_sinp_datatype_protocols FOREIGN KEY (id_protocole) REFERENCES gn_meta.sinp_datatype_protocols(id_protocol) ON UPDATE CASCADE;


--CONSTRAINTS--
ALTER TABLE ONLY v1_florestation.t_stations_fs
    ADD CONSTRAINT t_stations_fs_gid_key UNIQUE (gid);


--DATA--
INSERT INTO v1_florestation.bib_abondances SELECT * FROM v1_compat.bib_abondances;
INSERT INTO v1_florestation.bib_expositions SELECT * FROM v1_compat.bib_expositions;
INSERT INTO v1_florestation.bib_homogenes SELECT * FROM v1_compat.bib_homogenes;
INSERT INTO v1_florestation.bib_microreliefs SELECT * FROM v1_compat.bib_microreliefs;
INSERT INTO v1_florestation.bib_programmes_fs SELECT * FROM v1_compat.bib_programmes_fs;
INSERT INTO v1_florestation.bib_supports SELECT * FROM v1_compat.bib_supports;
INSERT INTO v1_florestation.bib_surfaces SELECT * FROM v1_compat.bib_surfaces;
INSERT INTO v1_florestation.t_stations_fs SELECT * FROM v1_compat.t_stations_fs;
INSERT INTO v1_florestation.cor_fs_taxon SELECT * FROM v1_compat.cor_fs_taxon;
INSERT INTO v1_florestation.cor_fs_observateur SELECT * FROM v1_compat.cor_fs_observateur;
INSERT INTO v1_florestation.cor_fs_microrelief SELECT * FROM v1_compat.cor_fs_microrelief;
INSERT INTO v1_florestation.cor_fs_delphine SELECT * FROM v1_compat.cor_fs_delphine;


--INDEX--
CREATE INDEX fki_t_stations_fs_bib_homogenes ON v1_florestation.t_stations_fs USING btree (id_homogene);

CREATE INDEX fki_t_stations_fs_gid ON v1_florestation.t_stations_fs USING btree (gid);
COMMENT ON INDEX v1_florestation.fki_t_stations_fs_gid IS 'pour le fonctionnement de qgis';

CREATE INDEX i_fk_t_stations_fs_bib_exposit ON v1_florestation.t_stations_fs USING btree (id_exposition);

CREATE INDEX i_fk_t_stations_fs_bib_program ON v1_florestation.t_stations_fs USING btree (id_programme_fs);

CREATE INDEX i_fk_t_stations_fs_bib_support ON v1_florestation.t_stations_fs USING btree (id_support);

CREATE INDEX index_cd_nom ON v1_florestation.cor_fs_taxon USING btree (cd_nom);

CREATE INDEX index_gist_t_stations_fs_the_geom_3857 ON v1_florestation.t_stations_fs USING gist (the_geom_3857);

CREATE INDEX index_gist_t_stations_fs_the_geom_local ON v1_florestation.t_stations_fs USING gist (the_geom_local);

CREATE INDEX i_fk_insee_com_li_municipalities ON ref_geo.li_municipalities USING btree (insee_com);


--SET UUID FOR SYNTHESE
ALTER TABLE v1_florestation.t_stations_fs ADD COLUMN unique_id_sinp_grp uuid;
UPDATE v1_florestation.t_stations_fs SET unique_id_sinp_grp = uuid_generate_v4();
ALTER TABLE v1_florestation.t_stations_fs ALTER COLUMN unique_id_sinp_grp SET NOT NULL;
ALTER TABLE v1_florestation.t_stations_fs ALTER COLUMN unique_id_sinp_grp SET DEFAULT uuid_generate_v4();

ALTER TABLE v1_florestation.cor_fs_taxon ADD COLUMN unique_id_sinp_fs uuid;
UPDATE v1_florestation.cor_fs_taxon SET unique_id_sinp_fs = uuid_generate_v4();
ALTER TABLE v1_florestation.cor_fs_taxon ALTER COLUMN unique_id_sinp_fs SET NOT NULL;
ALTER TABLE v1_florestation.cor_fs_taxon ALTER COLUMN unique_id_sinp_fs SET DEFAULT uuid_generate_v4();


--VIEWS--
CREATE VIEW v1_florestation.v_florestation_all AS
 SELECT cor.id_station_cd_nom AS indexbidon,
    fs.id_station,
    fs.dateobs,
    cor.cd_nom,
    btrim((tr.nom_valide)::text) AS nom_valid,
    btrim((tr.nom_vern)::text) AS nom_vern,
    public.st_transform(fs.the_geom_local, 2154) AS the_geom
   FROM ((v1_florestation.t_stations_fs fs
     JOIN v1_florestation.cor_fs_taxon cor ON ((cor.id_station = fs.id_station)))
     JOIN taxonomie.taxref tr ON ((cor.cd_nom = tr.cd_nom)))
  WHERE ((fs.supprime = false) AND (cor.supprime = false));

CREATE VIEW v1_florestation.v_florestation_patrimoniale AS
 SELECT cft.id_station_cd_nom AS indexbidon,
    fs.id_station,
    tx.nom_vern AS francais,
    tx.nom_complet AS latin,
    fs.dateobs,
    fs.the_geom_local
   FROM ((((v1_florestation.t_stations_fs fs
     JOIN v1_florestation.cor_fs_taxon cft ON ((cft.id_station = fs.id_station)))
     JOIN taxonomie.bib_noms n ON ((n.cd_nom = cft.cd_nom)))
     LEFT JOIN taxonomie.taxref tx ON ((tx.cd_nom = cft.cd_nom)))
     JOIN taxonomie.cor_taxon_attribut cta ON (((cta.cd_ref = n.cd_ref) AND (cta.id_attribut = 1) AND (cta.valeur_attribut = 'oui'::text))))
  WHERE ((fs.supprime = false) AND (cft.supprime = false))
  ORDER BY fs.id_station, tx.nom_vern;

CREATE VIEW v1_florestation.v_taxons_fs AS
 SELECT tx.cd_nom,
    tx.nom_complet
   FROM ((taxonomie.bib_noms n
     JOIN taxonomie.taxref tx ON ((tx.cd_nom = n.cd_nom)))
     JOIN taxonomie.cor_nom_liste cnl ON ((cnl.id_nom = n.id_nom)))
  WHERE ((n.id_nom IN ( SELECT cor_nom_liste.id_nom
           FROM taxonomie.cor_nom_liste
          WHERE (cor_nom_liste.id_liste = 500))) AND (cnl.id_liste = ANY (ARRAY[305, 306, 307, 308])));

CREATE OR REPLACE VIEW v1_florestation.v_export_fs_all AS 
 SELECT DISTINCT s.id_station,
    s.id_sophie,
    s.dateobs,
    s.info_acces,
    s.complet_partiel,
    s.meso_longitudinal,
    s.meso_lateral,
    s.canopee,
    s.ligneux_hauts,
    s.ligneux_bas,
    s.ligneux_tbas,
    s.herbaces,
    s.mousses,
    s.litiere,
    s.remarques,
    s.altitude_retenue AS altitude,
    s.pdop,
    s.validation AS relue,
    t.nom_complet AS taxon,
    o.observateurs,
    p.nom_programme_fs,
    mr.microreliefs,
    d.delphines,
    e.nom_exposition,
    su.nom_support,
    h.nom_homogene,
    g.nom_surface,
    com.nom_com AS nomcommune,
    --se.nom_secteur,
    cft.herb,
    cft.inf_1m,
    cft.de_1_4m,
    cft.sup_4m,
    cft.taxon_saisi,
    z.nom_complet AS taxon_ref,
    z.nom_complet AS taxon_complet,
    st_x(s.the_geom_local) AS x_local,
    st_y(s.the_geom_local) AS y_local
   FROM v1_florestation.t_stations_fs s
     LEFT JOIN v1_florestation.cor_fs_taxon cft ON cft.id_station = s.id_station
     LEFT JOIN taxonomie.taxref t ON t.cd_nom = cft.cd_nom
     LEFT JOIN ( SELECT taxref.cd_nom,
            taxref.nom_complet
           FROM taxonomie.taxref
          WHERE (taxref.cd_nom IN ( SELECT DISTINCT t_1.cd_ref
                   FROM taxonomie.taxref t_1
                     JOIN v1_florestation.cor_fs_taxon c ON c.cd_nom = t_1.cd_nom))) z ON z.cd_nom = t.cd_ref
     LEFT JOIN v1_florestation.cor_fs_observateur cfo ON s.id_station = cfo.id_station
     LEFT JOIN v1_florestation.bib_programmes_fs p ON p.id_programme_fs = s.id_programme_fs
     LEFT JOIN v1_florestation.bib_expositions e ON e.id_exposition = s.id_exposition
     LEFT JOIN v1_florestation.bib_supports su ON su.id_support = s.id_support
     LEFT JOIN v1_florestation.bib_homogenes h ON h.id_homogene = s.id_homogene
     LEFT JOIN v1_florestation.bib_surfaces g ON g.id_surface = s.id_surface
     LEFT JOIN ref_geo.li_municipalities com ON com.insee_com = s.insee
     --LEFT JOIN ref_geo.l_areas se ON se.id_area = com.id_secteur
     LEFT JOIN ( SELECT c.id_station,
            array_to_string(array_agg((r.prenom_role::text || ' '::text) || r.nom_role::text), ', '::text) AS observateurs
           FROM v1_florestation.cor_fs_observateur c
             JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
          GROUP BY c.id_station) o ON o.id_station = s.id_station
     LEFT JOIN ( SELECT c.id_station,
            array_to_string(array_agg((c.id_microrelief || ' '::text) || m.nom_microrelief::text), ', '::text) AS microreliefs
           FROM v1_florestation.cor_fs_microrelief c
             JOIN v1_florestation.bib_microreliefs m ON m.id_microrelief = c.id_microrelief
          GROUP BY c.id_station) mr ON mr.id_station = s.id_station
     LEFT JOIN ( SELECT c.id_station,
            array_to_string(array_agg(c.id_delphine), ', '::text) AS delphines
           FROM v1_florestation.cor_fs_delphine c
          GROUP BY c.id_station) d ON d.id_station = s.id_station
  WHERE s.supprime = false AND cft.supprime = false
  ORDER BY s.dateobs;

---------------------
--FUNCTIONS TRIGGER--
---------------------
CREATE OR REPLACE FUNCTION v1_florestation.delete_synthese_cor_fs_taxon() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
--il n'y a pas de trigger delete sur la table t_stations_fs parce qu'il un delete cascade dans la fk id_station de cor_fs_taxon
--donc si on supprime la station, on supprime sa ou ces taxons relevés et donc ce trigger sera déclanché et fera le ménage dans la table synthese
BEGIN
        --on fait le delete dans synthese --TODO : adapter
        DELETE FROM gn_synthese.synthese WHERE id_source = 105 AND entity_source_pk_value = old.gid::character varying;
	RETURN old; 			
END;
$$;
--TODO id_source = 105 = PNE

CREATE FUNCTION v1_florestation.florestation_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN	
new.date_insert= 'now';	 -- mise a jour de date insert
new.date_update= 'now';	 -- mise a jour de date update
--new.the_geom_local = public.st_transform(new.the_geom_3857,2154);
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

CREATE OR REPLACE FUNCTION v1_florestation.florestation_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
    theinsee character varying(25);
    thealtitude integer;
BEGIN
--si aucun geom n'existait et qu'au moins un geom est ajouté, on créé les 2 geom
IF (old.the_geom_local is null AND old.the_geom_3857 is null) THEN
    IF (new.the_geom_local is NOT NULL) THEN
        new.the_geom_3857 = public.st_transform(new.the_geom_local,3857);
		new.srid_dessin = 2154;
    END IF;
    IF (new.the_geom_3857 is NOT NULL) THEN
        new.the_geom_local = public.st_transform(new.the_geom_3857,2154);
		new.srid_dessin = 3857;
    END IF;
    -- on calcul la commune...
    SELECT INTO theinsee m.insee_com 
    FROM ref_geo.l_areas lc 
    JOIN ref_geo.li_municipalities m ON m.id_area = lc.id_area
    WHERE public.st_intersects(lc.geom, new.the_geom_local) AND lc.id_type = 25
    ORDER BY public.ST_area(public.ST_intersection(lc.geom, new.the_geom_local)) DESC LIMIT 1;
    new.insee = theinsee;-- mise à jour du code insee
    -- on calcul l'altitude
    SELECT altitude_min INTO thealtitude FROM (SELECT * FROM ref_geo.fct_get_altitude_intersection(new.the_geom_local) LIMIT 1) a;
    new.altitude_sig = thealtitude;-- mise à jour de l'altitude sig
    IF new.altitude_saisie IS null OR new.altitude_saisie = -1 THEN-- mis à jour de l'altitude retenue
        new.altitude_retenue = new.altitude_sig;
    ELSE
        new.altitude_retenue = new.altitude_saisie;
    END IF;
END IF;
--si au moins un geom existait et qu'il a changé on fait une mise à jour
IF (old.the_geom_local is NOT NULL OR old.the_geom_3857 is NOT NULL) THEN
    --si c'est le 2154 qui existait on teste s'il a changé
    IF (old.the_geom_local is NOT NULL AND new.the_geom_local is NOT NULL) THEN
        IF NOT public.st_equals(new.the_geom_local,old.the_geom_local) THEN
            new.the_geom_3857 = public.st_transform(new.the_geom_local,3857);
            new.srid_dessin = 2154;
        END IF;
    END IF;
    --si c'est le 3857 qui existait on teste s'il a changé
    IF (old.the_geom_3857 is NOT NULL AND new.the_geom_3857 is NOT NULL) THEN
        IF NOT public.st_equals(new.the_geom_3857,old.the_geom_3857) THEN
            new.the_geom_local = public.st_transform(new.the_geom_3857,2154);
            new.srid_dessin = 3857;
        END IF;
    END IF;
    -- on calcul la commune...
    SELECT INTO theinsee m.insee_com 
    FROM ref_geo.l_areas lc 
    JOIN ref_geo.li_municipalities m ON m.id_area = lc.id_area
    WHERE public.st_intersects(lc.geom, new.the_geom_local) AND lc.id_type = 25
    ORDER BY public.ST_area(public.ST_intersection(lc.geom, new.the_geom_local)) DESC LIMIT 1;
    new.insee = theinsee;-- mise à jour du code insee
    -- on calcul l'altitude
    SELECT altitude_min INTO thealtitude FROM (SELECT * FROM ref_geo.fct_get_altitude_intersection(new.the_geom_local) LIMIT 1) a;
    new.altitude_sig = thealtitude;-- mise à jour de l'altitude sig
    IF new.altitude_saisie IS null OR new.altitude_saisie = -1 THEN-- mis à jour de l'altitude retenue
        new.altitude_retenue = new.altitude_sig;
    ELSE
        new.altitude_retenue = new.altitude_saisie;
    END IF;
END IF;
IF (new.altitude_saisie <> old.altitude_saisie OR old.altitude_saisie is null OR new.altitude_saisie is null OR old.altitude_saisie=0 OR new.altitude_saisie=0) then  -- mis à jour de l'altitude retenue
	BEGIN
		if new.altitude_saisie is null or new.altitude_saisie = 0 then
			-- on calcul l'altitude
			SELECT altitude_min INTO thealtitude FROM (SELECT ref_geo.fct_get_altitude_intersection(new.the_geom_local) LIMIT 1) a;
			new.altitude_retenue = thealtitude;-- mise à jour de l'altitude retenue
		else
			new.altitude_retenue = new.altitude_saisie;
		end if;
	END;	
END IF;
new.date_update= 'now';	 -- mise a jour de date insert
RETURN new; -- return new procède à l'insertion de la donnée dans PG avec les nouvelles valeures.			
END;
$$;
--TODO vérifier l'ID type d'area pour les communes ou utiliser le code

--TODO gérer cor_observer_synthese
CREATE OR REPLACE FUNCTION v1_florestation.insert_synthese_cor_fs_taxon()
  RETURNS trigger AS
$BODY$
DECLARE
    fiche RECORD;
    theobservers character varying(255);
    thetaxrefversion text;
    thevalidationstatus integer;
BEGIN
    --Récupération des données dans la table t_stations_fs
    SELECT INTO fiche * FROM v1_florestation.t_stations_fs WHERE id_station = new.id_station;
    --Récupération de la liste des observateurs
    SELECT INTO theobservers array_to_string(array_agg(r.nom_role || ' ' || r.prenom_role), ', ') AS observateurs 
    FROM v1_florestation.cor_fs_observateur c
    JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
    JOIN v1_florestation.t_stations_fs s ON s.id_station = c.id_station
    WHERE c.id_station = new.id_station;
    --Récupération de la version taxref
    SELECT parameter_value INTO thetaxrefversion FROM gn_commons.t_parameters WHERE parameter_name = 'taxref_version';
    --Récupération du statut de validation
    IF (fiche.validation) THEN 
	SELECT ref_nomenclatures.get_id_nomenclature('STATUT_VALID','1') INTO thevalidationstatus;
    ELSE
	SELECT ref_nomenclatures.get_id_nomenclature('STATUT_VALID','2') INTO thevalidationstatus;
    END IF;
    -- MAJ de la synthese
    INSERT INTO gn_synthese.synthese
    (
      unique_id_sinp,
      unique_id_sinp_grp,
      id_source,
      entity_source_pk_value,
      id_dataset,
      id_nomenclature_geo_object_nature,
      id_nomenclature_grp_typ,
      id_nomenclature_obs_meth,
      id_nomenclature_bio_status,
      id_nomenclature_bio_condition,
      id_nomenclature_naturalness,
      id_nomenclature_exist_proof,
      id_nomenclature_valid_status,
      id_nomenclature_diffusion_level,
      id_nomenclature_life_stage,
      id_nomenclature_sex,
      id_nomenclature_obj_count,
      id_nomenclature_type_count,
      id_nomenclature_sensitivity,
      id_nomenclature_observation_status,
      id_nomenclature_blurring,
      id_nomenclature_source_status,
      id_nomenclature_info_geo_type,
      count_min,
      count_max,
      cd_nom,
      nom_cite,
      meta_v_taxref,
      altitude_min,
      altitude_max,
      the_geom_4326,
      the_geom_point,
      the_geom_local,
      date_min,
      date_max,
      observers,
      determiner,
      comment_context,
      last_action
    )
    VALUES
    ( 
      new.unique_id_sinp_fs,
      fiche.unique_id_sinp_grp,
      105, --TODO 105 = PNE
      new.gid,
      fiche.id_lot,
      ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO','St'),
      ref_nomenclatures.get_id_nomenclature('TYP_GRP','INVSTA'),
      ref_nomenclatures.get_id_nomenclature('METH_OBS','0'),
      ref_nomenclatures.get_id_nomenclature('STATUT_BIO','12'),
      ref_nomenclatures.get_id_nomenclature('ETA_BIO','2'),
      ref_nomenclatures.get_id_nomenclature('NATURALITE','1'),
      ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST','2'),
      thevalidationstatus,
      ref_nomenclatures.get_id_nomenclature('NIV_PRECIS','5'),
      ref_nomenclatures.get_id_nomenclature('STADE_VIE','1'),
      ref_nomenclatures.get_id_nomenclature('SEXE','6'),
      ref_nomenclatures.get_id_nomenclature('OBJ_DENBR','NSP'),
      ref_nomenclatures.get_id_nomenclature('TYP_DENBR','NSP'),
      NULL,--todo sensitivity
      ref_nomenclatures.get_id_nomenclature('STATUT_OBS','Pr'),
      ref_nomenclatures.get_id_nomenclature('DEE_FLOU','NON'),
      ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE','Te'),
      ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO','1'),
      -1,--count_min
      -1,--count_max
      new.cd_nom,
      COALESCE(new.taxon_saisi,'non disponible'),
      thetaxrefversion,
      fiche.altitude_retenue,--altitude_min
      fiche.altitude_retenue,--altitude_max
      public.st_transform(fiche.the_geom_3857,4326),
      public.st_transform(fiche.the_geom_3857,4326),
      fiche.the_geom_local,
      fiche.dateobs,--date_min
      fiche.dateobs,--date_max
      theobservers,--observers
      theobservers,--determiner
      fiche.remarques,
      'c'
    );
RETURN NEW;       
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


CREATE OR REPLACE FUNCTION v1_florestation.update_synthese_cor_fs_observateur() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
    myreleve RECORD;
    theobservers character varying(255);
    theidsynthese integer;
    thesql text;
BEGIN
    --Récupération de la liste des observateurs 
    --ici on va mettre à jour l'enregistrement dans synthese autant de fois qu'on insert dans cette table
    SELECT INTO theobservers array_to_string(array_agg(r.nom_role || ' ' || r.prenom_role), ', ') AS observateurs 
    FROM v1_florestation.cor_fs_observateur c
    JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
    JOIN v1_florestation.t_stations_fs s ON s.id_station = c.id_station
    WHERE c.id_station = new.id_station;
    --on boucle sur tous les enregistrements de la station
    FOR myreleve IN SELECT gid FROM v1_florestation.cor_fs_taxon WHERE id_station = new.id_station  LOOP
        --on fait le update du champ observateurs dans synthese
        UPDATE gn_synthese.synthese 
        SET 
            observers = theobservers,
            last_action = 'u'
        WHERE id_source = 105 AND entity_source_pk_value = myreleve.gid::character varying;
	-- on met à jour les observateurs dans gn_synthese.cor_observer_synthese
        SELECT INTO theidsynthese id_synthese FROM gn_synthese.synthese WHERE id_source = 105 AND entity_source_pk_value = myreleve.gid::character varying;
	thesql = format(
		'INSERT INTO gn_synthese.cor_observer_synthese (id_synthese, id_role) VALUES(%L, %L)'
		,theidsynthese, new.id_role);
	EXECUTE thesql;
    END LOOP;
  RETURN NEW;       
END;
$$;

CREATE OR REPLACE FUNCTION v1_florestation.delete_cor_observer_synthese() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
    myreleve RECORD;
    theobservers character varying(255);
    theidsynthese integer;
    thesql text;
BEGIN
    --Récupération de la liste des observateurs 
    --ici on va mettre à jour l'enregistrement dans synthese autant de fois qu'on delete dans cette table
    SELECT INTO theobservers array_to_string(array_agg(r.nom_role || ' ' || r.prenom_role), ', ') AS observateurs 
    FROM v1_florestation.cor_fs_observateur c
    JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
    JOIN v1_florestation.t_stations_fs s ON s.id_station = c.id_station
    WHERE c.id_station = old.id_station;
    --on boucle sur tous les enregistrements de la station
    FOR myreleve IN SELECT gid FROM v1_florestation.cor_fs_taxon WHERE id_station = old.id_station  LOOP
        --on fait le update du champ observateurs dans synthese
        UPDATE gn_synthese.synthese 
        SET 
            observers = theobservers,
            last_action = 'u'
        WHERE id_source = 105 AND entity_source_pk_value = myreleve.gid::character varying;
	-- on met à jour les observateurs dans gn_synthese.cor_observer_synthese
        SELECT INTO theidsynthese id_synthese FROM gn_synthese.synthese WHERE id_source = 105 AND entity_source_pk_value = myreleve.gid::character varying;
	DELETE FROM gn_synthese.cor_observer_synthese WHERE id_synthese = theidsynthese AND id_role = old.id_role;
    END LOOP;
  RETURN OLD;       
END;
$$;
--TODO 105 = PNE

CREATE OR REPLACE FUNCTION v1_florestation.update_synthese_cor_fs_taxon() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
--On ne fait qq chose que si l'un des champs de la table cor_fs_taxon concerné dans synthese a changé
IF (
        new.id_station <> old.id_station 
        OR new.unique_id_sinp_fs <> old.unique_id_sinp_fs 
        OR new.gid <> old.gid 
        OR new.cd_nom <> old.cd_nom 
        OR new.supprime <> old.supprime 
    ) THEN
    --on fait le update dans synthese
    UPDATE gn_synthese.synthese 
    SET 
	unique_id_sinp = new.unique_id_sinp_fs,
	entity_source_pk_value = new.gid,
	cd_nom = new.cd_nom,
	last_action = 'u'
    WHERE id_source = 105 AND entity_source_pk_value = old.gid::character varying;
END IF;
IF (new.supprime = true) THEN
    --on delete dans la synthese
    DELETE FROM gn_synthese.synthese 
    WHERE id_source = 105 AND entity_source_pk_value = old.gid::character varying;
END IF;
IF (new.supprime = false) THEN
    RAISE NOTICE 'Attention cette action n''insert pas le taxon réactivé en synthese. Cette action doit être faite manuellement.'; 
END IF;
RETURN NEW; 			
END;
$$;

CREATE OR REPLACE FUNCTION v1_florestation.update_synthese_stations_fs() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
    monreleve RECORD;
    thevalidationstatus integer;
BEGIN
--On ne fait qq chose que si l'un des champs de la table t_stations_fs concerné dans synthese a changé
IF (
        new.id_station <> old.id_station 
        OR new.unique_id_sinp_grp <> old.unique_id_sinp_grp 
        OR ((new.remarques <> old.remarques) OR (new.remarques is null and old.remarques is NOT NULL) OR (new.remarques is NOT NULL and old.remarques is null))
        OR ((NOT ST_EQUALS(old.the_geom_local, new.the_geom_local)) OR (new.the_geom_local is null and old.the_geom_local is NOT NULL) OR (new.the_geom_local is NOT NULL and old.the_geom_local is null))
        OR ((new.dateobs <> old.dateobs) OR (new.dateobs is null and old.dateobs is NOT NULL) OR (new.dateobs is NOT NULL and old.dateobs is null))
        OR ((new.altitude_retenue <> old.altitude_retenue) OR (new.altitude_retenue is null and old.altitude_retenue is NOT NULL) OR (new.altitude_retenue is NOT NULL and old.altitude_retenue is null))
	OR ((new.validation <> old.validation) OR (new.validation is null and old.validation is NOT NULL) OR (new.validation is NOT NULL and old.validation is null))
) THEN
        --Récupération du statut de validation
	IF (new.validation) THEN 
		SELECT ref_nomenclatures.get_id_nomenclature('STATUT_VALID','1') INTO thevalidationstatus;
	ELSE
		SELECT ref_nomenclatures.get_id_nomenclature('STATUT_VALID','2') INTO thevalidationstatus;
	END IF;
	FOR monreleve IN SELECT gid, cd_nom FROM v1_florestation.cor_fs_taxon WHERE id_station = new.id_station  LOOP
		--on fait le update dans synthese
		UPDATE gn_synthese.synthese 
		SET 
		  id_nomenclature_valid_status = thevalidationstatus,
		  unique_id_sinp_grp = new.unique_id_sinp_grp,
		  date_min = new.dateobs,
		  date_max = new.dateobs,
		  altitude_min = new.altitude_retenue,
		  altitude_max = new.altitude_retenue,
		  comment_context = new.remarques,
		  last_action = 'u',
		  the_geom_4326 = public.st_transform(new.the_geom_3857,4326),
		  the_geom_local = new.the_geom_local,
		  the_geom_point = public.st_transform(new.the_geom_3857,4326)
		WHERE id_source = 105 AND entity_source_pk_value = monreleve.gid::character varying;
	END LOOP;
END IF;
RETURN NEW; 
END;
$$;

--TRIGGERS--
CREATE TRIGGER tri_delete_synthese_cor_fs_taxon AFTER DELETE ON v1_florestation.cor_fs_taxon FOR EACH ROW EXECUTE PROCEDURE v1_florestation.delete_synthese_cor_fs_taxon();

CREATE TRIGGER tri_insert BEFORE INSERT ON v1_florestation.t_stations_fs FOR EACH ROW EXECUTE PROCEDURE v1_florestation.florestation_insert();

CREATE TRIGGER tri_insert_synthese_cor_fs_observateur AFTER INSERT ON v1_florestation.cor_fs_observateur FOR EACH ROW EXECUTE PROCEDURE v1_florestation.update_synthese_cor_fs_observateur();

CREATE TRIGGER tri_insert_synthese_cor_fs_taxon AFTER INSERT ON v1_florestation.cor_fs_taxon FOR EACH ROW EXECUTE PROCEDURE v1_florestation.insert_synthese_cor_fs_taxon();

CREATE TRIGGER tri_update BEFORE UPDATE ON v1_florestation.t_stations_fs FOR EACH ROW EXECUTE PROCEDURE v1_florestation.florestation_update();

CREATE TRIGGER tri_update_synthese_cor_fs_taxon AFTER UPDATE ON v1_florestation.cor_fs_taxon FOR EACH ROW EXECUTE PROCEDURE v1_florestation.update_synthese_cor_fs_taxon();

CREATE TRIGGER tri_delete_synthese_cor_fs_observateur AFTER DELETE ON v1_florestation.cor_fs_observateur FOR EACH ROW EXECUTE PROCEDURE v1_florestation.delete_cor_observer_synthese();

CREATE TRIGGER tri_update_synthese_stations_fs AFTER UPDATE ON v1_florestation.t_stations_fs FOR EACH ROW EXECUTE PROCEDURE v1_florestation.update_synthese_stations_fs();

------------------
--LIENS AVEC GN2--
------------------
UPDATE utilisateurs.t_listes SET nom_liste = 'Observateurs flore station' WHERE nom_liste ILIKE 'flore_observateurs';
--Création du module --
DELETE FROM gn_commons.t_modules WHERE module_code = 'FS';
INSERT INTO gn_commons.t_modules (module_code, module_label, module_picto, module_path, module_external_url, module_target, active_backend, active_frontend) 
VALUES ('FS','Flore station','fa-flower-tulip',NULL,'https://mondomaine.fr/fs','_blank', false, false); 

INSERT INTO gn_permissions.cor_object_module (id_object, id_module)
SELECT o.id_object, t.id_module
FROM gn_permissions.t_objects o, gn_commons.t_modules t
WHERE o.code_object = 'TDatasets' AND t.module_code = 'FS';   

------------
--SYNTHESE--
------------
INSERT INTO gn_synthese.synthese
    (
      unique_id_sinp,
      unique_id_sinp_grp,
      id_source,
      entity_source_pk_value,
      id_dataset,
      id_nomenclature_geo_object_nature,
      id_nomenclature_grp_typ,
      id_nomenclature_obs_meth,
      id_nomenclature_bio_status,
      id_nomenclature_bio_condition,
      id_nomenclature_naturalness,
      id_nomenclature_exist_proof,
      id_nomenclature_valid_status,
      id_nomenclature_diffusion_level,
      id_nomenclature_life_stage,
      id_nomenclature_sex,
      id_nomenclature_obj_count,
      id_nomenclature_type_count,
      id_nomenclature_sensitivity,
      id_nomenclature_observation_status,
      id_nomenclature_blurring,
      id_nomenclature_source_status,
      id_nomenclature_info_geo_type,
      count_min,
      count_max,
      cd_nom,
      nom_cite,
      meta_v_taxref,
      altitude_min,
      altitude_max,
      the_geom_4326,
      the_geom_point,
      the_geom_local,
      date_min,
      date_max,
      observers,
      determiner,
      comment_context,
      last_action
    )
    SELECT
      cft.unique_id_sinp_fs,
      s.unique_id_sinp_grp,
      105, --TODO 105 = PNE
      cft.gid,
      s.id_lot,
      ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO','St'),
      ref_nomenclatures.get_id_nomenclature('TYP_GRP','INVSTA'),
      ref_nomenclatures.get_id_nomenclature('METH_OBS','0'),
      ref_nomenclatures.get_id_nomenclature('STATUT_BIO','12'),
      ref_nomenclatures.get_id_nomenclature('ETA_BIO','2'),
      ref_nomenclatures.get_id_nomenclature('NATURALITE','1'),
      ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST','2'),
      CASE 
        WHEN s.validation = true THEN ref_nomenclatures.get_id_nomenclature('STATUT_VALID','1')
        ELSE ref_nomenclatures.get_id_nomenclature('STATUT_VALID','2')
      END,
      ref_nomenclatures.get_id_nomenclature('NIV_PRECIS','5'),
      ref_nomenclatures.get_id_nomenclature('STADE_VIE','1'),
      ref_nomenclatures.get_id_nomenclature('SEXE','6'),
      ref_nomenclatures.get_id_nomenclature('OBJ_DENBR','NSP'),
      ref_nomenclatures.get_id_nomenclature('TYP_DENBR','NSP'),
      NULL,--todo sensitivity
      ref_nomenclatures.get_id_nomenclature('STATUT_OBS','Pr'),
      ref_nomenclatures.get_id_nomenclature('DEE_FLOU','NON'),
      ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE','Te'),
      ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO','1'),
      -1,--count_min
      -1,--count_max
      cft.cd_nom,
      COALESCE(cft.taxon_saisi,'non disponible'),
      'Taxref V11.0',
      s.altitude_retenue,--altitude_min
      s.altitude_retenue,--altitude_max
      public.st_transform(s.the_geom_3857,4326),
      public.st_transform(s.the_geom_3857,4326),
      s.the_geom_local,
      s.dateobs,--date_min
      s.dateobs,--date_max
      o.observateurs,--observers
      o.observateurs,--determiner
      s.remarques,
      CASE 
         WHEN s.date_insert = s.date_update THEN 'c'
         ELSE 'u'
      END
    FROM v1_florestation.t_stations_fs s
      JOIN v1_florestation.cor_fs_taxon cft ON cft.id_station = s.id_station
      JOIN (
        SELECT c.id_station, array_to_string(array_agg(r.nom_role || ' ' || r.prenom_role), ', ') AS observateurs 
        FROM v1_florestation.cor_fs_observateur c
        JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
        JOIN v1_florestation.t_stations_fs s ON s.id_station = c.id_station
        GROUP BY c.id_station
      ) o ON o.id_station = s.id_station
    WHERE s.supprime = false AND cft.supprime = false;

INSERT INTO gn_synthese.cor_observer_synthese (id_synthese, id_role)
SELECT syn.id_synthese, c.id_role
FROM v1_florestation.cor_fs_observateur c 
JOIN v1_florestation.cor_fs_taxon cft ON cft.id_station = c.id_station
JOIN gn_synthese.synthese syn ON syn.entity_source_pk_value::integer = cft.gid AND syn.id_source = 105;


-- TODO Vérifier que le champ secteur de la vue v1_florestation.v_export_fs_all n'est pas utilisé dans l'appli  symfony florestation
-- Globalement vérifier l'usage des schémas layers (devient ref_geo), meta (devient gn_meta) dans l'appli symfony
