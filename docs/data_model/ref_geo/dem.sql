
\restrict thYqxZvDaur6uh28p71weSZx61ibuDWMIb0DUogNAW0ryD7QtWvaxlB1Lr7J0BM

CREATE TABLE ref_geo.dem (
    rid integer NOT NULL,
    rast public.raster
);

CREATE SEQUENCE ref_geo.dem_rid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE ref_geo.dem_rid_seq OWNED BY ref_geo.dem.rid;

ALTER TABLE ONLY ref_geo.dem
    ADD CONSTRAINT pk_dem PRIMARY KEY (rid);

\unrestrict thYqxZvDaur6uh28p71weSZx61ibuDWMIb0DUogNAW0ryD7QtWvaxlB1Lr7J0BM

