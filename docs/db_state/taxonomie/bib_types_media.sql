
CREATE TABLE taxonomie.bib_types_media (
    id_type integer NOT NULL,
    nom_type_media character varying(100) NOT NULL,
    desc_type_media text
);

ALTER TABLE ONLY taxonomie.bib_types_media
    ADD CONSTRAINT id PRIMARY KEY (id_type);

