
CREATE TABLE ref_geo.bib_areas_types (
    id_type integer NOT NULL,
    type_name character varying(200) NOT NULL,
    type_code character varying(25) NOT NULL,
    type_desc text,
    ref_name character varying(200),
    ref_version integer,
    num_version character varying(50),
    size_hierarchy integer
);

COMMENT ON COLUMN ref_geo.bib_areas_types.ref_name IS 'Indique le nom du référentiel géographique utilisé pour ce type';

COMMENT ON COLUMN ref_geo.bib_areas_types.ref_version IS 'Indique l''année du référentiel utilisé';

COMMENT ON COLUMN ref_geo.bib_areas_types.size_hierarchy IS 'Diamètre moyen en mètres de ce type zone. Permet d''établir une hiérarchie des types de zone géographique. Utile pour le floutage des observations.';

CREATE SEQUENCE ref_geo.bib_areas_types_id_type_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE ref_geo.bib_areas_types_id_type_seq OWNED BY ref_geo.bib_areas_types.id_type;

ALTER TABLE ONLY ref_geo.bib_areas_types
    ADD CONSTRAINT pk_bib_areas_types PRIMARY KEY (id_type);

ALTER TABLE ONLY ref_geo.bib_areas_types
    ADD CONSTRAINT unique_bib_areas_types_type_code UNIQUE (type_code);

CREATE UNIQUE INDEX i_unique_bib_areas_types_type_code ON ref_geo.bib_areas_types USING btree (type_code);

