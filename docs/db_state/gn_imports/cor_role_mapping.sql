
CREATE TABLE gn_imports.cor_role_mapping (
    id_role integer NOT NULL,
    id_mapping integer NOT NULL
);

ALTER TABLE ONLY gn_imports.cor_role_mapping
    ADD CONSTRAINT pk_cor_role_mapping PRIMARY KEY (id_role, id_mapping);

ALTER TABLE ONLY gn_imports.cor_role_mapping
    ADD CONSTRAINT fk_gn_imports_t_mappings_id_mapping FOREIGN KEY (id_mapping) REFERENCES gn_imports.t_mappings(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_imports.cor_role_mapping
    ADD CONSTRAINT fk_utilisateurs_t_roles FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;

