
CREATE TABLE ref_habitats.cor_list_habitat (
    id_cor_list integer NOT NULL,
    id_list integer NOT NULL,
    cd_hab integer NOT NULL
);

COMMENT ON TABLE ref_habitats.cor_list_habitat IS 'Habitat de chaque liste';

CREATE SEQUENCE ref_habitats.cor_list_habitat_id_cor_list_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE ref_habitats.cor_list_habitat_id_cor_list_seq OWNED BY ref_habitats.cor_list_habitat.id_cor_list;

ALTER TABLE ONLY ref_habitats.cor_list_habitat
    ADD CONSTRAINT pk_cor_list_habitat PRIMARY KEY (id_cor_list);

ALTER TABLE ONLY ref_habitats.cor_list_habitat
    ADD CONSTRAINT unique_cor_list_habitat UNIQUE (id_list, cd_hab);

ALTER TABLE ONLY ref_habitats.cor_list_habitat
    ADD CONSTRAINT fk_cor_list_habitat_cd_hab FOREIGN KEY (cd_hab) REFERENCES ref_habitats.habref(cd_hab) ON UPDATE CASCADE;

ALTER TABLE ONLY ref_habitats.cor_list_habitat
    ADD CONSTRAINT fk_cor_list_habitat_id_list FOREIGN KEY (id_list) REFERENCES ref_habitats.bib_list_habitat(id_list) ON UPDATE CASCADE;

