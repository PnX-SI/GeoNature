

CREATE TABLE gn_permissions.cor_permission_taxref (
    id_permission integer NOT NULL,
    cd_nom integer NOT NULL
);

ALTER TABLE ONLY gn_permissions.cor_permission_taxref
    ADD CONSTRAINT cor_permission_taxref_pkey PRIMARY KEY (id_permission, cd_nom);

ALTER TABLE ONLY gn_permissions.cor_permission_taxref
    ADD CONSTRAINT cor_permission_taxref_cd_nom_fkey FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom);

ALTER TABLE ONLY gn_permissions.cor_permission_taxref
    ADD CONSTRAINT cor_permission_taxref_id_permission_fkey FOREIGN KEY (id_permission) REFERENCES gn_permissions.t_permissions(id_permission);


