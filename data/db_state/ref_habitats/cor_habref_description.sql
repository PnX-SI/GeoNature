
CREATE TABLE ref_habitats.cor_habref_description (
    cd_hab_description integer NOT NULL,
    cd_hab integer NOT NULL,
    cd_hab_field integer NOT NULL,
    cd_typo integer,
    lb_code character varying(50),
    lb_hab_field character varying(200),
    valeurs text
);

COMMENT ON TABLE ref_habitats.cor_habref_description IS 'Table de correspondance entre un habitat et les champs additionnels décrit dans la table typoref_fields - Table habref_description de HABREF';

ALTER TABLE ONLY ref_habitats.cor_habref_description
    ADD CONSTRAINT pk_cor_habref_description PRIMARY KEY (cd_hab_description);

ALTER TABLE ONLY ref_habitats.cor_habref_description
    ADD CONSTRAINT fk_cor_habref_description_cd_hab FOREIGN KEY (cd_hab) REFERENCES ref_habitats.habref(cd_hab) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY ref_habitats.cor_habref_description
    ADD CONSTRAINT fk_cor_habref_description_cd_hab_field FOREIGN KEY (cd_hab_field) REFERENCES ref_habitats.typoref_fields(cd_hab_field) ON UPDATE CASCADE ON DELETE CASCADE;

