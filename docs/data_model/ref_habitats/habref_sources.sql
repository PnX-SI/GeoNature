
CREATE TABLE ref_habitats.habref_sources (
    cd_source integer NOT NULL,
    cd_doc integer,
    type_source character varying(1),
    auteur_source character varying(255),
    date_source integer,
    lb_source character varying(1000),
    lb_source_complet character varying(2000),
    titre character varying(1000),
    link character varying(1000),
    date_crea text,
    date_modif text
);

COMMENT ON TABLE ref_habitats.habref_sources IS 'Table des sources décrivant les habitats';

ALTER TABLE ONLY ref_habitats.habref_sources
    ADD CONSTRAINT pk_habref_sources PRIMARY KEY (cd_source);

