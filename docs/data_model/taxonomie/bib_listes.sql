
CREATE TABLE taxonomie.bib_listes (
    id_liste integer NOT NULL,
    code_liste character varying(50) NOT NULL,
    nom_liste character varying(255) NOT NULL,
    desc_liste text,
    regne character varying(20),
    group2_inpn character varying(255)
);

CREATE SEQUENCE taxonomie.bib_listes_id_liste_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE taxonomie.bib_listes_id_liste_seq OWNED BY taxonomie.bib_listes.id_liste;

ALTER TABLE ONLY taxonomie.bib_listes
    ADD CONSTRAINT pk_bib_listes PRIMARY KEY (id_liste);

ALTER TABLE ONLY taxonomie.bib_listes
    ADD CONSTRAINT unique_bib_listes_code_liste UNIQUE (code_liste);

ALTER TABLE ONLY taxonomie.bib_listes
    ADD CONSTRAINT unique_bib_listes_nom_liste UNIQUE (nom_liste);

