
CREATE TABLE ref_habitats.cor_hab_source (
    cd_hab_lien_source integer NOT NULL,
    cd integer NOT NULL,
    type_lien character varying(7) NOT NULL,
    cd_source integer NOT NULL,
    origine character varying(5),
    date_crea text,
    date_modif text
);

COMMENT ON TABLE ref_habitats.cor_hab_source IS 'Table de corespondance entre une unité (cd_hab, cd_coresp_hab, cd_coresp_taxon) et une source - Table habref_lien_source de HABREF';

ALTER TABLE ONLY ref_habitats.cor_hab_source
    ADD CONSTRAINT pk_cor_hab_source PRIMARY KEY (cd_hab_lien_source);

ALTER TABLE ONLY ref_habitats.cor_hab_source
    ADD CONSTRAINT fk_cor_cor_hab_source_cd_source FOREIGN KEY (cd_source) REFERENCES ref_habitats.habref_sources(cd_source) ON UPDATE CASCADE ON DELETE CASCADE;

