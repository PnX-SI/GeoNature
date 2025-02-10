
CREATE TABLE ref_geo.l_linears (
    id_linear integer NOT NULL,
    id_type integer NOT NULL,
    linear_name character varying(250) NOT NULL,
    linear_code character varying(25) NOT NULL,
    enable boolean DEFAULT true NOT NULL,
    geom public.geometry(Geometry,2154),
    geojson_4326 character varying,
    source character varying(250),
    additional_data jsonb,
    meta_create_date timestamp without time zone,
    meta_update_date timestamp without time zone
);

CREATE SEQUENCE ref_geo.l_linears_id_linear_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE ref_geo.l_linears_id_linear_seq OWNED BY ref_geo.l_linears.id_linear;

ALTER TABLE ONLY ref_geo.l_linears
    ADD CONSTRAINT l_linears_id_type_linear_code_key UNIQUE (id_type, linear_code);

ALTER TABLE ONLY ref_geo.l_linears
    ADD CONSTRAINT pk_ref_geo_l_linears_id_linear PRIMARY KEY (id_linear);

CREATE INDEX ref_geo_l_linears_geom_idx ON ref_geo.l_linears USING gist (geom);

ALTER TABLE ONLY ref_geo.l_linears
    ADD CONSTRAINT fk_ref_geo_l_linears_id_type FOREIGN KEY (id_type) REFERENCES ref_geo.bib_linears_types(id_type) ON UPDATE CASCADE;

