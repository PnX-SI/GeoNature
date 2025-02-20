
CREATE TABLE utilisateurs.t_profils (
    id_profil integer NOT NULL,
    code_profil integer,
    nom_profil character varying(255),
    desc_profil text
);

COMMENT ON TABLE utilisateurs.t_profils IS 'Table des profils d''utilisateurs génériques ou applicatifs, qui seront ensuite attachés à des roles et des applications';

CREATE SEQUENCE utilisateurs.t_profils_id_profil_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE utilisateurs.t_profils_id_profil_seq OWNED BY utilisateurs.t_profils.id_profil;

ALTER TABLE ONLY utilisateurs.t_profils
    ADD CONSTRAINT pk_t_profils PRIMARY KEY (id_profil);

