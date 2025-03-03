
CREATE TABLE ref_habitats.typoref (
    cd_typo integer NOT NULL,
    cd_table character varying(255),
    lb_nom_typo character varying(100),
    nom_jeu_donnees character varying(255),
    date_creation character varying(255),
    date_mise_jour_table character varying(255),
    date_mise_jour_metadonnees character varying(255),
    auteur_typo character varying(4000),
    auteur_table character varying(4000),
    territoire character varying(4000),
    organisme character varying(255),
    langue character varying(255),
    presentation character varying(4000),
    description character varying(4000),
    origine character varying(4000),
    ref_biblio character varying(4000),
    mots_cles character varying(255),
    referencement character varying(4000),
    diffusion character varying(4000),
    derniere_modif character varying(4000),
    type_table character varying(6),
    cd_typo_entre integer,
    cd_typo_sortie integer,
    niveau_inpn character varying(255)
);

COMMENT ON TABLE ref_habitats.typoref IS 'typoref, table TYPOREF du référentiel HABREF 4.0';

CREATE SEQUENCE ref_habitats.typoref_cd_typo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE ref_habitats.typoref_cd_typo_seq OWNED BY ref_habitats.typoref.cd_typo;

ALTER TABLE ONLY ref_habitats.typoref
    ADD CONSTRAINT pk_typoref PRIMARY KEY (cd_typo);

