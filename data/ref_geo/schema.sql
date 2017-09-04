-- DROP SCHEMA IF EXISTS ref_geo CASCADE;

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

CREATE SCHEMA IF NOT EXISTS ref_geo;

SET search_path = ref_geo, pg_catalog;

--
-- TOC entry 302 (class 1259 OID 111560)
-- Name: l_areas; Type: TABLE; Schema: ref_geo
--

CREATE TABLE l_areas (
    id_area integer NOT NULL,
    id_type integer NOT NULL,
    area_name character varying(250),
    geom public.geometry(MultiPolygon,MYLOCALSRID),
    source character varying(250),
    code_source character varying(20),
    comment text,
    meta_create_date timestamp without time zone,
    meta_update_date timestamp without time zone,
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(geom) = 'MULTIPOLYGON'::text) OR (geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(geom) = MYLOCALSRID))
);


--
-- TOC entry 304 (class 1259 OID 111572)
-- Name: bib_areas_types; Type: TABLE; Schema: ref_geo
--

CREATE TABLE bib_areas_types (
    id_type integer NOT NULL,
    type_name character varying(200),
    type_desc text,
    code character varying(5)
);


--
-- TOC entry 305 (class 1259 OID 111575)
-- Name: l_municipalities; Type: TABLE; Schema: ref_geo
--

CREATE TABLE l_municipalities (
    id_municipality character varying(25) NOT NULL,
    geom public.geometry(MultiPolygon,MYLOCALSRID),
    plani_precision double precision,
    municipality_name character varying(250),
    insee_code character varying(5),
    siren_code character varying(10),
    status character varying(20),
    canton character varying(200),
    arrondisst character varying(45),
    depart_code character varying(3),
    depart character varying(30),
    region character varying(30),
    population integer,
    multican character varying(3),
    cc_nom character varying(250),
    cc_siren bigint,
    cc_nature character varying(5),
    cc_date_creation character varying(10),
    cc_date_effet character varying(10),
    zc boolean,
    aa boolean,
    pec boolean,
    apa boolean,
    massif character varying(50),
    insee_commune_nouvelle character varying(5)
);


CREATE TABLE l_grids (
    code_grid character varying(50) NOT NULL,
    geom public.geometry(Polygon,MYLOCALSRID),
    centroid public.geometry(Point,MYLOCALSRID),
    cxmin integer,
    cxmax integer,
    cymin integer,
    cymax integer,
    code_grid_10k character varying(20),
    zc boolean
);


-- Add sequence on l_areas ?

--CREATE SEQUENCE l_zonesstructure_id_zone_seq
--    START WITH 1
--    INCREMENT BY 1
--    NO MINVALUE
--    NO MAXVALUE
--    CACHE 1;

-- ALTER TABLE ONLY l_zonesstructure ALTER COLUMN id_zone SET DEFAULT nextval('l_zonesstructure_id_zone_seq'::regclass);


ALTER TABLE ONLY l_municipalities
    ADD CONSTRAINT l_municipalities_pkey PRIMARY KEY (id);

ALTER TABLE ONLY l_grids
    ADD CONSTRAINT l_grids_pkey PRIMARY KEY (code_grid);

ALTER TABLE ONLY l_areas
    ADD CONSTRAINT pk_l_areas PRIMARY KEY (id_zone);

ALTER TABLE ONLY bib_areas_types
    ADD CONSTRAINT pk_typeszones PRIMARY KEY (id_type);

CREATE INDEX index_l_municipalities_geom ON l_municipalities USING gist (geom);

CREATE TRIGGER trg_date_changes BEFORE INSERT OR UPDATE ON l_areas FOR EACH ROW EXECUTE PROCEDURE public.fct_trg_date_changes();

ALTER TABLE ONLY l_areas
    ADD CONSTRAINT l_areas_id_type_fkey FOREIGN KEY (id_type) REFERENCES bib_areas_types(id_type) ON UPDATE CASCADE;

