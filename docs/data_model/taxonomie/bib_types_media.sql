
\restrict bnagXZmfdfgkpVh4NpKnu2sbboCpQToMKGenrAscACX2x2P47alSG9RQhPkFGfo

CREATE TABLE taxonomie.bib_types_media (
    id_type integer NOT NULL,
    nom_type_media character varying(100) NOT NULL,
    desc_type_media text
);

ALTER TABLE ONLY taxonomie.bib_types_media
    ADD CONSTRAINT id PRIMARY KEY (id_type);

\unrestrict bnagXZmfdfgkpVh4NpKnu2sbboCpQToMKGenrAscACX2x2P47alSG9RQhPkFGfo

