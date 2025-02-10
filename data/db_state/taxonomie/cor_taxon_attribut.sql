
CREATE TABLE taxonomie.cor_taxon_attribut (
    id_attribut integer NOT NULL,
    valeur_attribut text NOT NULL,
    cd_ref integer NOT NULL,
    CONSTRAINT check_is_cd_ref CHECK ((cd_ref = taxonomie.find_cdref(cd_ref)))
);

ALTER TABLE ONLY taxonomie.cor_taxon_attribut
    ADD CONSTRAINT cor_taxon_attribut_pkey PRIMARY KEY (id_attribut, cd_ref);

CREATE INDEX fki_cor_taxon_attribut ON taxonomie.cor_taxon_attribut USING btree (valeur_attribut);

ALTER TABLE ONLY taxonomie.cor_taxon_attribut
    ADD CONSTRAINT cor_taxon_attrib_bib_attrib_fkey FOREIGN KEY (id_attribut) REFERENCES taxonomie.bib_attributs(id_attribut);

