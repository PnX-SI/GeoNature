
CREATE TABLE ref_geo.bib_linears_types (
    id_type integer NOT NULL,
    type_name character varying(200) NOT NULL,
    type_code character varying(25) NOT NULL,
    type_desc text,
    ref_name character varying(200),
    ref_version integer,
    num_version character varying(50),
    meta_create_date timestamp without time zone,
    meta_update_date timestamp without time zone
);

CREATE SEQUENCE ref_geo.bib_linears_types_id_type_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE ref_geo.bib_linears_types_id_type_seq OWNED BY ref_geo.bib_linears_types.id_type;

ALTER TABLE ONLY ref_geo.bib_linears_types
    ADD CONSTRAINT bib_linears_types_type_code_key UNIQUE (type_code);

ALTER TABLE ONLY ref_geo.bib_linears_types
    ADD CONSTRAINT pk_ref_geo_bib_linears_types_id_type PRIMARY KEY (id_type);

