
CREATE TABLE gn_imports.t_mappings (
    id integer NOT NULL,
    label character varying(255) NOT NULL,
    type character varying(10) NOT NULL,
    active boolean DEFAULT true NOT NULL,
    public boolean DEFAULT false NOT NULL,
    id_destination integer NOT NULL,
    CONSTRAINT check_mapping_type_in_t_mappings CHECK (((type)::text = ANY ((ARRAY['FIELD'::character varying, 'CONTENT'::character varying])::text[])))
);

CREATE SEQUENCE gn_imports.t_mappings_id_mapping_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_imports.t_mappings_id_mapping_seq OWNED BY gn_imports.t_mappings.id;

ALTER TABLE ONLY gn_imports.t_mappings
    ADD CONSTRAINT pk_t_mappings PRIMARY KEY (id);

ALTER TABLE ONLY gn_imports.t_mappings
    ADD CONSTRAINT t_mappings_un UNIQUE (label, type);

ALTER TABLE ONLY gn_imports.t_mappings
    ADD CONSTRAINT t_mappings_id_destination_fkey FOREIGN KEY (id_destination) REFERENCES gn_imports.bib_destinations(id_destination) ON DELETE CASCADE;

