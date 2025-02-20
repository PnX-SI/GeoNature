
CREATE TABLE taxonomie.bib_themes (
    id_theme integer NOT NULL,
    nom_theme character varying(20),
    desc_theme character varying(255),
    ordre integer
);

CREATE SEQUENCE taxonomie.bib_themes_id_theme_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE taxonomie.bib_themes_id_theme_seq OWNED BY taxonomie.bib_themes.id_theme;

ALTER TABLE ONLY taxonomie.bib_themes
    ADD CONSTRAINT bib_themes_pkey PRIMARY KEY (id_theme);

ALTER TABLE ONLY taxonomie.bib_themes
    ADD CONSTRAINT unique_bib_themes_nom_theme UNIQUE (nom_theme);

