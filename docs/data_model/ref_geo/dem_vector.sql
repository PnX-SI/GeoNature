
CREATE TABLE ref_geo.dem_vector (
    gid integer NOT NULL,
    geom public.geometry(Geometry,2154),
    val double precision
);

CREATE SEQUENCE ref_geo.dem_vector_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE ref_geo.dem_vector_gid_seq OWNED BY ref_geo.dem_vector.gid;

ALTER TABLE ONLY ref_geo.dem_vector
    ADD CONSTRAINT pk_dem_vector PRIMARY KEY (gid);

CREATE INDEX index_dem_vector_geom ON ref_geo.dem_vector USING gist (geom);

