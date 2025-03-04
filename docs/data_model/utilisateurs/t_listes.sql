
CREATE TABLE utilisateurs.t_listes (
    id_liste integer NOT NULL,
    code_liste character varying(20) NOT NULL,
    nom_liste character varying(50) NOT NULL,
    desc_liste text
);

COMMENT ON TABLE utilisateurs.t_listes IS 'Table des listes déroulantes des applications. Les roles (groupes ou utilisateurs) devant figurer dans une liste sont gérés dans la table cor_role_liste';

CREATE SEQUENCE utilisateurs.t_listes_id_liste_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE utilisateurs.t_listes_id_liste_seq OWNED BY utilisateurs.t_listes.id_liste;

ALTER TABLE ONLY utilisateurs.t_listes
    ADD CONSTRAINT pk_t_listes PRIMARY KEY (id_liste);

