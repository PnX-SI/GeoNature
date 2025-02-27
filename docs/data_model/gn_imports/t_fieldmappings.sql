
CREATE TABLE gn_imports.t_fieldmappings (
    id integer NOT NULL,
    "values" json
);

ALTER TABLE ONLY gn_imports.t_fieldmappings
    ADD CONSTRAINT t_fieldmappings_pkey PRIMARY KEY (id);

ALTER TABLE ONLY gn_imports.t_fieldmappings
    ADD CONSTRAINT t_fieldmappings_id_fkey FOREIGN KEY (id) REFERENCES gn_imports.t_mappings(id) ON DELETE CASCADE;

