
CREATE TABLE gn_imports.matching_geoms (
    id_matching_geom integer NOT NULL,
    source_x_field text,
    source_y_field text,
    source_geom_field text,
    source_geom_format text,
    source_srid integer,
    target_geom_field text,
    target_geom_srid integer,
    geom_comments text,
    id_matching_table integer NOT NULL
);

CREATE SEQUENCE gn_imports.matching_geoms_id_matching_geom_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_imports.matching_geoms_id_matching_geom_seq OWNED BY gn_imports.matching_geoms.id_matching_geom;

ALTER TABLE ONLY gn_imports.matching_geoms
    ADD CONSTRAINT pk_matching_synthese PRIMARY KEY (id_matching_geom);

ALTER TABLE ONLY gn_imports.matching_geoms
    ADD CONSTRAINT fk_matching_geoms_matching_tables FOREIGN KEY (id_matching_table) REFERENCES gn_imports.matching_tables(id_matching_table) ON UPDATE CASCADE;

