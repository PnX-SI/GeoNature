
CREATE TABLE gn_imports.bib_themes (
    id_theme integer NOT NULL,
    name_theme character varying(100) NOT NULL,
    fr_label_theme character varying(100) NOT NULL,
    eng_label_theme character varying(100),
    desc_theme character varying(1000),
    order_theme integer NOT NULL
);

CREATE SEQUENCE gn_imports.dict_themes_id_theme_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_imports.dict_themes_id_theme_seq OWNED BY gn_imports.bib_themes.id_theme;

ALTER TABLE ONLY gn_imports.bib_themes
    ADD CONSTRAINT pk_dict_themes_id_theme PRIMARY KEY (id_theme);

