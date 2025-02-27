
CREATE TABLE utilisateurs.cor_role_provider (
    id_role integer NOT NULL,
    id_provider integer NOT NULL
);

COMMENT ON TABLE utilisateurs.cor_role_provider IS 'Table de correpondance entre t_roles et t_providers';

ALTER TABLE ONLY utilisateurs.cor_role_provider
    ADD CONSTRAINT cor_role_provider_pkey PRIMARY KEY (id_role, id_provider);

ALTER TABLE ONLY utilisateurs.cor_role_provider
    ADD CONSTRAINT cor_role_provider_id_provider_fkey FOREIGN KEY (id_provider) REFERENCES utilisateurs.t_providers(id_provider);

ALTER TABLE ONLY utilisateurs.cor_role_provider
    ADD CONSTRAINT cor_role_provider_id_role_fkey FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role);

