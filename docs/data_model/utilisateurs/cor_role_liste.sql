
CREATE TABLE utilisateurs.cor_role_liste (
    id_role integer NOT NULL,
    id_liste integer NOT NULL
);

COMMENT ON TABLE utilisateurs.cor_role_liste IS 'Equivalent de l''ancienne cor_role_menu. Permet de créer des listes de roles (observateurs par ex.), sans notion de permission';

ALTER TABLE ONLY utilisateurs.cor_role_liste
    ADD CONSTRAINT pk_cor_role_liste PRIMARY KEY (id_liste, id_role);

ALTER TABLE ONLY utilisateurs.cor_role_liste
    ADD CONSTRAINT fk_cor_role_liste_id_liste FOREIGN KEY (id_liste) REFERENCES utilisateurs.t_listes(id_liste) ON UPDATE CASCADE;

ALTER TABLE ONLY utilisateurs.cor_role_liste
    ADD CONSTRAINT fk_cor_role_liste_id_role FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

