
CREATE TABLE taxonomie.cor_nom_liste (
    id_liste integer NOT NULL,
    cd_nom integer NOT NULL
);

ALTER TABLE ONLY taxonomie.cor_nom_liste
    ADD CONSTRAINT cor_nom_liste_pkey PRIMARY KEY (cd_nom, id_liste);

ALTER TABLE ONLY taxonomie.cor_nom_liste
    ADD CONSTRAINT unique_cor_nom_liste_id_liste_cd_nom UNIQUE (id_liste, cd_nom);

ALTER TABLE ONLY taxonomie.cor_nom_liste
    ADD CONSTRAINT cor_nom_listes_bib_listes_fkey FOREIGN KEY (id_liste) REFERENCES taxonomie.bib_listes(id_liste) ON UPDATE CASCADE;

ALTER TABLE ONLY taxonomie.cor_nom_liste
    ADD CONSTRAINT cor_nom_listes_taxref_fkey FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE ON DELETE CASCADE;

