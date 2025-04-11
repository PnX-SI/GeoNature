
CREATE TABLE gn_imports.matching_tables (
    id_matching_table integer NOT NULL,
    source_schema text NOT NULL,
    source_table text NOT NULL,
    target_schema text NOT NULL,
    target_table text NOT NULL,
    matching_comments text
);

CREATE SEQUENCE gn_imports.matching_tables_id_matching_table_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_imports.matching_tables_id_matching_table_seq OWNED BY gn_imports.matching_tables.id_matching_table;

ALTER TABLE ONLY gn_imports.matching_tables
    ADD CONSTRAINT pk_matching_tables PRIMARY KEY (id_matching_table);

