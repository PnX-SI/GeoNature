
CREATE TABLE taxonomie.bib_attributs (
    id_attribut integer DEFAULT nextval('taxonomie.bib_attributs_id_attribut_seq'::regclass) NOT NULL,
    nom_attribut character varying(255) NOT NULL,
    label_attribut character varying(50) NOT NULL,
    liste_valeur_attribut text,
    obligatoire boolean DEFAULT false NOT NULL,
    desc_attribut text,
    type_attribut character varying(50),
    type_widget character varying(50),
    regne character varying(20),
    group2_inpn character varying(255),
    id_theme integer NOT NULL,
    ordre integer
);

ALTER TABLE ONLY taxonomie.bib_attributs
    ADD CONSTRAINT pk_bib_attributs PRIMARY KEY (id_attribut);

ALTER TABLE ONLY taxonomie.bib_attributs
    ADD CONSTRAINT unique_bib_attributs_nom_attribut UNIQUE (nom_attribut);

ALTER TABLE ONLY taxonomie.bib_attributs
    ADD CONSTRAINT bib_attributs_id_theme_fkey FOREIGN KEY (id_theme) REFERENCES taxonomie.bib_themes(id_theme);

