
CREATE TABLE gn_imports.cor_role_import (
    id_role integer NOT NULL,
    id_import integer NOT NULL
);

ALTER TABLE ONLY gn_imports.cor_role_import
    ADD CONSTRAINT pk_cor_role_import PRIMARY KEY (id_role, id_import);

ALTER TABLE ONLY gn_imports.cor_role_import
    ADD CONSTRAINT fk_cor_role_import_import FOREIGN KEY (id_import) REFERENCES gn_imports.t_imports(id_import) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_imports.cor_role_import
    ADD CONSTRAINT fk_cor_role_import_role FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_imports.cor_role_import
    ADD CONSTRAINT fk_utilisateurs_t_roles FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;

