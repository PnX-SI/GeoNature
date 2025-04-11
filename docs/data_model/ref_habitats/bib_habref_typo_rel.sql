
CREATE TABLE ref_habitats.bib_habref_typo_rel (
    cd_type_rel integer NOT NULL,
    lb_type_rel character varying(200),
    lb_rel character varying(1000),
    corresp_hab boolean,
    corresp_esp boolean,
    corresp_syn boolean,
    date_crea text,
    date_modif text
);

COMMENT ON TABLE ref_habitats.bib_habref_typo_rel IS 'Bibliothèque des types de relations entre habitats - Table habref_typo_rel de HABREF';

ALTER TABLE ONLY ref_habitats.bib_habref_typo_rel
    ADD CONSTRAINT pk_bib_habref_typo_rel PRIMARY KEY (cd_type_rel);

