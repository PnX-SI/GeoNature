
CREATE TABLE gn_imports.bib_destinations (
    id_destination integer NOT NULL,
    id_module integer,
    code character varying(64),
    label character varying(128),
    table_name character varying(64)
);

CREATE SEQUENCE gn_imports.bib_destinations_id_destination_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_imports.bib_destinations_id_destination_seq OWNED BY gn_imports.bib_destinations.id_destination;

ALTER TABLE ONLY gn_imports.bib_destinations
    ADD CONSTRAINT bib_destinations_code_key UNIQUE (code);

ALTER TABLE ONLY gn_imports.bib_destinations
    ADD CONSTRAINT bib_destinations_pkey PRIMARY KEY (id_destination);

ALTER TABLE ONLY gn_imports.bib_destinations
    ADD CONSTRAINT bib_destinations_id_module_fkey FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules(id_module) ON DELETE CASCADE;

