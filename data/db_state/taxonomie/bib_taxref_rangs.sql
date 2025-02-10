
CREATE TABLE taxonomie.bib_taxref_rangs (
    id_rang character(4) NOT NULL,
    nom_rang character varying(50) NOT NULL,
    nom_rang_en character varying(50) NOT NULL,
    tri_rang integer
);

ALTER TABLE ONLY taxonomie.bib_taxref_rangs
    ADD CONSTRAINT pk_bib_taxref_rangs PRIMARY KEY (id_rang);

