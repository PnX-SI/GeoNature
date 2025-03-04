
CREATE TABLE gn_imports.cor_entity_field (
    id_entity integer NOT NULL,
    id_field integer NOT NULL,
    desc_field character varying(1000),
    id_theme integer NOT NULL,
    order_field integer NOT NULL,
    comment character varying
);

ALTER TABLE ONLY gn_imports.cor_entity_field
    ADD CONSTRAINT cor_entity_field_pkey PRIMARY KEY (id_entity, id_field);

ALTER TABLE ONLY gn_imports.cor_entity_field
    ADD CONSTRAINT cor_entity_field_id_entity_fkey FOREIGN KEY (id_entity) REFERENCES gn_imports.bib_entities(id_entity) ON DELETE CASCADE;

ALTER TABLE ONLY gn_imports.cor_entity_field
    ADD CONSTRAINT cor_entity_field_id_field_fkey FOREIGN KEY (id_field) REFERENCES gn_imports.bib_fields(id_field) ON DELETE CASCADE;

ALTER TABLE ONLY gn_imports.cor_entity_field
    ADD CONSTRAINT cor_entity_field_id_theme_fkey FOREIGN KEY (id_theme) REFERENCES gn_imports.bib_themes(id_theme);

