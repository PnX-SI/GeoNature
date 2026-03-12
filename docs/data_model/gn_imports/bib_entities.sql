

CREATE TABLE gn_imports.bib_entities (
    id_entity integer NOT NULL,
    id_destination integer,
    code character varying(16),
    label character varying(64),
    "order" integer,
    validity_column character varying(64),
    destination_table_schema character varying(63),
    destination_table_name character varying(63),
    id_unique_column integer,
    id_parent integer,
    id_object integer DEFAULT 1,
    id_uuid_column integer
);

CREATE SEQUENCE gn_imports.bib_entities_id_entity_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_imports.bib_entities_id_entity_seq OWNED BY gn_imports.bib_entities.id_entity;

ALTER TABLE ONLY gn_imports.bib_entities
    ADD CONSTRAINT bib_entities_pkey PRIMARY KEY (id_entity);

ALTER TABLE ONLY gn_imports.bib_entities
    ADD CONSTRAINT bib_entities_id_destination_fkey FOREIGN KEY (id_destination) REFERENCES gn_imports.bib_destinations(id_destination) ON DELETE CASCADE;

ALTER TABLE ONLY gn_imports.bib_entities
    ADD CONSTRAINT bib_entities_id_object_fkey FOREIGN KEY (id_object) REFERENCES gn_permissions.t_objects(id_object);

ALTER TABLE ONLY gn_imports.bib_entities
    ADD CONSTRAINT bib_entities_id_parent_fkey FOREIGN KEY (id_parent) REFERENCES gn_imports.bib_entities(id_entity);

ALTER TABLE ONLY gn_imports.bib_entities
    ADD CONSTRAINT bib_entities_id_unique_column_fkey FOREIGN KEY (id_unique_column) REFERENCES gn_imports.bib_fields(id_field);

ALTER TABLE ONLY gn_imports.bib_entities
    ADD CONSTRAINT bib_entities_id_uuid_column_fkey FOREIGN KEY (id_uuid_column) REFERENCES gn_imports.bib_fields(id_field);

ALTER TABLE ONLY gn_imports.bib_entities
    ADD CONSTRAINT bib_entities_t_objects_fk FOREIGN KEY (id_object) REFERENCES gn_permissions.t_objects(id_object);


