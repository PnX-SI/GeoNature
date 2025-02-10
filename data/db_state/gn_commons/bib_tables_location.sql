
CREATE TABLE gn_commons.bib_tables_location (
    id_table_location integer NOT NULL,
    table_desc character varying(255),
    schema_name character varying(50) NOT NULL,
    table_name character varying(50) NOT NULL,
    pk_field character varying(50) NOT NULL,
    uuid_field_name character varying(50) NOT NULL
);

CREATE SEQUENCE gn_commons.bib_tables_location_id_table_location_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_commons.bib_tables_location_id_table_location_seq OWNED BY gn_commons.bib_tables_location.id_table_location;

ALTER TABLE ONLY gn_commons.bib_tables_location
    ADD CONSTRAINT pk_bib_tables_location PRIMARY KEY (id_table_location);

ALTER TABLE ONLY gn_commons.bib_tables_location
    ADD CONSTRAINT unique_bib_tables_location_schema_name_table_name UNIQUE (schema_name, table_name);

