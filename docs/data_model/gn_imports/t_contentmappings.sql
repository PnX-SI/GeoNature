
\restrict Ftru1glaa12b54kYFRUmT0j9EcQUvPFcR3IjsjeH1T5kvbddVvftzd6vg5xI4rc

CREATE TABLE gn_imports.t_contentmappings (
    id integer NOT NULL,
    "values" json
);

ALTER TABLE ONLY gn_imports.t_contentmappings
    ADD CONSTRAINT t_contentmappings_pkey PRIMARY KEY (id);

ALTER TABLE ONLY gn_imports.t_contentmappings
    ADD CONSTRAINT t_contentmappings_id_fkey FOREIGN KEY (id) REFERENCES gn_imports.t_mappings(id) ON DELETE CASCADE;

\unrestrict Ftru1glaa12b54kYFRUmT0j9EcQUvPFcR3IjsjeH1T5kvbddVvftzd6vg5xI4rc

