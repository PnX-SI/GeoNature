
CREATE TABLE taxonomie.bdc_statut_type (
    cd_type_statut character varying(50) NOT NULL,
    lb_type_statut character varying(250),
    regroupement_type character varying(250),
    thematique character varying(100),
    type_value character varying(100)
);

COMMENT ON TABLE taxonomie.bdc_statut_type IS 'Table des grands type de statuts';

ALTER TABLE ONLY taxonomie.bdc_statut_type
    ADD CONSTRAINT bdc_statut_type_pkey PRIMARY KEY (cd_type_statut);

