
CREATE TABLE ref_habitats.autocomplete_habitat (
    cd_hab integer NOT NULL,
    cd_typo integer NOT NULL,
    lb_code character varying(50),
    lb_nom_typo character varying(100) NOT NULL,
    search_name character varying(1000) NOT NULL
);

ALTER TABLE ONLY ref_habitats.autocomplete_habitat
    ADD CONSTRAINT pk_autocomplete_habitat PRIMARY KEY (cd_hab);

