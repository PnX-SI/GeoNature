
CREATE TABLE gn_imports.matching_fields (
    id_matching_field integer NOT NULL,
    source_field text,
    source_default_value text,
    target_field text NOT NULL,
    target_field_type text,
    field_comments text,
    id_matching_table integer NOT NULL,
    CONSTRAINT check_source_exists CHECK (((source_field IS NOT NULL) OR (source_default_value IS NOT NULL)))
);

COMMENT ON COLUMN gn_imports.matching_fields.source_default_value IS 'Valeur par défaut à insérer si la valeur attendue dans le champ de la table de destination n''existe pas dans la table source';

CREATE SEQUENCE gn_imports.matching_fields_id_matching_field_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_imports.matching_fields_id_matching_field_seq OWNED BY gn_imports.matching_fields.id_matching_field;

ALTER TABLE ONLY gn_imports.matching_fields
    ADD CONSTRAINT pk_matching_fields PRIMARY KEY (id_matching_field);

ALTER TABLE ONLY gn_imports.matching_fields
    ADD CONSTRAINT fk_matching_fields_matching_tables FOREIGN KEY (id_matching_table) REFERENCES gn_imports.matching_tables(id_matching_table) ON UPDATE CASCADE;

