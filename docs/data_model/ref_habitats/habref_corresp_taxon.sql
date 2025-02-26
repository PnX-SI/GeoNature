
CREATE TABLE ref_habitats.habref_corresp_taxon (
    cd_corresp_tax integer NOT NULL,
    cd_hab_entre integer NOT NULL,
    cd_nom integer,
    cd_type_relation integer,
    lb_condition character varying(1000),
    lb_remarques character varying(4000),
    nom_cite character varying(500),
    validite boolean,
    date_crea text,
    date_modif text
);

COMMENT ON TABLE ref_habitats.habref_corresp_taxon IS 'Table de corespondances entres les habitats les taxon (table taxref)';

ALTER TABLE ONLY ref_habitats.habref_corresp_taxon
    ADD CONSTRAINT pk_habref_corresp_taxon PRIMARY KEY (cd_corresp_tax);

ALTER TABLE ONLY ref_habitats.habref_corresp_taxon
    ADD CONSTRAINT fk_habref_corresp_tax_cd_hab_entre FOREIGN KEY (cd_hab_entre) REFERENCES ref_habitats.habref(cd_hab) ON UPDATE CASCADE;

ALTER TABLE ONLY ref_habitats.habref_corresp_taxon
    ADD CONSTRAINT fk_habref_corresp_tax_cd_typ_rel FOREIGN KEY (cd_type_relation) REFERENCES ref_habitats.bib_habref_typo_rel(cd_type_rel) ON UPDATE CASCADE;

