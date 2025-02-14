
CREATE TABLE ref_habitats.habref_corresp_hab (
    cd_corresp_hab integer NOT NULL,
    cd_hab_entre integer NOT NULL,
    cd_hab_sortie integer,
    cd_type_relation integer,
    lb_condition character varying(1000),
    lb_remarques character varying(4000),
    validite boolean,
    cd_typo_entre integer,
    cd_typo_sortie integer,
    date_crea text,
    date_modif text,
    diffusion boolean
);

COMMENT ON TABLE ref_habitats.habref_corresp_hab IS 'Table de corespondances entres les habitats de differentes typologie';

ALTER TABLE ONLY ref_habitats.habref_corresp_hab
    ADD CONSTRAINT pk_habref_corresp_hab PRIMARY KEY (cd_corresp_hab);

ALTER TABLE ONLY ref_habitats.habref_corresp_hab
    ADD CONSTRAINT fk_habref_corresp_hab_cd_hab_entre FOREIGN KEY (cd_hab_entre) REFERENCES ref_habitats.habref(cd_hab) ON UPDATE CASCADE;

ALTER TABLE ONLY ref_habitats.habref_corresp_hab
    ADD CONSTRAINT fk_habref_corresp_hab_cd_hab_sortie FOREIGN KEY (cd_hab_sortie) REFERENCES ref_habitats.habref(cd_hab) ON UPDATE CASCADE;

ALTER TABLE ONLY ref_habitats.habref_corresp_hab
    ADD CONSTRAINT fk_habref_corresp_hab_cd_type_rel FOREIGN KEY (cd_type_relation) REFERENCES ref_habitats.bib_habref_typo_rel(cd_type_rel) ON UPDATE CASCADE;

