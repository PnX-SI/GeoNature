
CREATE TABLE ref_geo.l_areas (
    id_area integer NOT NULL,
    id_type integer NOT NULL,
    area_name character varying(250),
    area_code character varying(25),
    geom public.geometry(MultiPolygon,2154),
    centroid public.geometry(Point,2154),
    source character varying(250),
    comment text,
    enable boolean DEFAULT true NOT NULL,
    additional_data jsonb,
    meta_create_date timestamp without time zone,
    meta_update_date timestamp without time zone,
    geom_4326 public.geometry(MultiPolygon,4326),
    CONSTRAINT enforce_geotype_l_areas_centroid CHECK (((public.geometrytype(centroid) = 'POINT'::text) OR (centroid IS NULL))),
    CONSTRAINT enforce_geotype_l_areas_geom CHECK (((public.geometrytype(geom) = 'MULTIPOLYGON'::text) OR (geom IS NULL))),
    CONSTRAINT enforce_srid_l_areas_centroid CHECK ((public.st_srid(centroid) = 2154)),
    CONSTRAINT enforce_srid_l_areas_geom CHECK ((public.st_srid(geom) = 2154))
);

CREATE SEQUENCE ref_geo.l_areas_id_area_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE ref_geo.l_areas_id_area_seq OWNED BY ref_geo.l_areas.id_area;

ALTER TABLE ONLY ref_geo.l_areas
    ADD CONSTRAINT pk_l_areas PRIMARY KEY (id_area);

ALTER TABLE ONLY ref_geo.l_areas
    ADD CONSTRAINT unique_id_type_area_code UNIQUE (id_type, area_code);

CREATE UNIQUE INDEX i_unique_l_areas_id_type_area_code ON ref_geo.l_areas USING btree (id_type, area_code);

CREATE INDEX idx_l_areas_geom_4326 ON ref_geo.l_areas USING gist (geom_4326);

CREATE INDEX index_l_areas_centroid ON ref_geo.l_areas USING gist (centroid);

CREATE INDEX index_l_areas_geom ON ref_geo.l_areas USING gist (geom);

CREATE TRIGGER tri_insert_cor_area_synthese AFTER INSERT ON ref_geo.l_areas REFERENCING NEW TABLE AS new FOR EACH STATEMENT EXECUTE FUNCTION gn_synthese.fct_trig_l_areas_insert_cor_area_synthese_on_each_statement();

CREATE TRIGGER tri_meta_dates_change_l_areas BEFORE INSERT OR UPDATE ON ref_geo.l_areas FOR EACH ROW EXECUTE FUNCTION public.fct_trg_meta_dates_change();

CREATE TRIGGER tri_transform_geom_insert BEFORE INSERT ON ref_geo.l_areas FOR EACH ROW EXECUTE FUNCTION ref_geo.fct_tri_transform_geom();

CREATE TRIGGER tri_transform_geom_update BEFORE UPDATE ON ref_geo.l_areas FOR EACH ROW EXECUTE FUNCTION ref_geo.fct_tri_transform_geom();

ALTER TABLE ONLY ref_geo.l_areas
    ADD CONSTRAINT fk_l_areas_id_type FOREIGN KEY (id_type) REFERENCES ref_geo.bib_areas_types(id_type) ON UPDATE CASCADE;

