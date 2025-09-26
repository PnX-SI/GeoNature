
\restrict IHD2qzd74QfDZH2pmIcrXSmUpeY8XpK0mxMllzBwbemKffAao1QuAzcTEzVaZWM

CREATE TABLE taxonomie.bib_taxref_statuts (
    id_statut character(1) NOT NULL,
    nom_statut character varying(50) NOT NULL
);

ALTER TABLE ONLY taxonomie.bib_taxref_statuts
    ADD CONSTRAINT pk_bib_taxref_statuts PRIMARY KEY (id_statut);

\unrestrict IHD2qzd74QfDZH2pmIcrXSmUpeY8XpK0mxMllzBwbemKffAao1QuAzcTEzVaZWM

