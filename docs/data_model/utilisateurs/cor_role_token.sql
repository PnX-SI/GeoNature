
CREATE TABLE utilisateurs.cor_role_token (
    id_role integer NOT NULL,
    token text
);

ALTER TABLE ONLY utilisateurs.cor_role_token
    ADD CONSTRAINT cor_role_token_pk_id_role PRIMARY KEY (id_role);

ALTER TABLE ONLY utilisateurs.cor_role_token
    ADD CONSTRAINT cor_role_token_fk_id_role FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;

