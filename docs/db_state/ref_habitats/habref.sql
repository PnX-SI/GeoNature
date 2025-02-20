
CREATE TABLE ref_habitats.habref (
    cd_hab integer NOT NULL,
    fg_validite character varying(20) NOT NULL,
    cd_typo integer NOT NULL,
    lb_code character varying(50),
    lb_hab_fr character varying(500),
    lb_hab_fr_complet character varying(500),
    lb_hab_en character varying(500),
    lb_auteur character varying(500),
    niveau integer,
    lb_niveau character varying(100),
    cd_hab_sup integer,
    path_cd_hab character varying(2000),
    france character varying(5),
    lb_description character varying(4000)
);

COMMENT ON TABLE ref_habitats.habref IS 'habref, table HABREF référentiel HABREF 4.0 INPN';

ALTER TABLE ONLY ref_habitats.habref
    ADD CONSTRAINT pk_habref PRIMARY KEY (cd_hab);

ALTER TABLE ONLY ref_habitats.habref
    ADD CONSTRAINT fk_typoref FOREIGN KEY (cd_typo) REFERENCES ref_habitats.typoref(cd_typo) ON UPDATE CASCADE;

