
CREATE TABLE ref_habitats.cor_habref_terr_statut (
    cd_hab_ter integer NOT NULL,
    cd_hab integer NOT NULL,
    cd_sig_terr character varying(20) NOT NULL,
    cd_statut_presence character varying(1),
    date_crea text,
    date_modif text
);

COMMENT ON TABLE ref_habitats.cor_habref_terr_statut IS 'Table de descritpion des champs additionnels de chaque typologie.';

ALTER TABLE ONLY ref_habitats.cor_habref_terr_statut
    ADD CONSTRAINT pk_cor_habref_terr_statut PRIMARY KEY (cd_hab_ter);

ALTER TABLE ONLY ref_habitats.cor_habref_terr_statut
    ADD CONSTRAINT fk_cor_habref_terr_statut_cd_hab FOREIGN KEY (cd_hab) REFERENCES ref_habitats.habref(cd_hab) ON UPDATE CASCADE;

ALTER TABLE ONLY ref_habitats.cor_habref_terr_statut
    ADD CONSTRAINT fk_cor_habref_terr_statut_cd_statut_presence FOREIGN KEY (cd_statut_presence) REFERENCES ref_habitats.bib_habref_statuts(statut) ON UPDATE CASCADE;

