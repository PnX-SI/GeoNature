
CREATE TABLE ref_geo.l_points (
    id_point integer NOT NULL,
    id_type integer NOT NULL,
    point_name character varying(250) NOT NULL,
    point_code character varying(25) NOT NULL,
    enable boolean DEFAULT true NOT NULL,
    geom public.geometry(Geometry,2154),
    geojson_4326 character varying,
    source character varying(250),
    additional_data jsonb,
    meta_create_date timestamp without time zone,
    meta_update_date timestamp without time zone
);

CREATE SEQUENCE ref_geo.l_points_id_point_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE ref_geo.l_points_id_point_seq OWNED BY ref_geo.l_points.id_point;

ALTER TABLE ONLY ref_geo.l_points
    ADD CONSTRAINT l_points_id_type_point_code_key UNIQUE (id_type, point_code);

ALTER TABLE ONLY ref_geo.l_points
    ADD CONSTRAINT pk_ref_geo_l_points_id_point PRIMARY KEY (id_point);

ALTER TABLE ONLY ref_geo.l_points
    ADD CONSTRAINT fk_ref_geo_l_points_id_type FOREIGN KEY (id_type) REFERENCES ref_geo.bib_points_types(id_type) ON UPDATE CASCADE;

