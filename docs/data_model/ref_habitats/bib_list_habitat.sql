
CREATE TABLE ref_habitats.bib_list_habitat (
    id_list integer NOT NULL,
    list_name character varying(255) NOT NULL
);

COMMENT ON TABLE ref_habitats.bib_list_habitat IS 'Table des listes des habitats';

CREATE SEQUENCE ref_habitats.bib_list_habitat_id_list_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE ref_habitats.bib_list_habitat_id_list_seq OWNED BY ref_habitats.bib_list_habitat.id_list;

ALTER TABLE ONLY ref_habitats.bib_list_habitat
    ADD CONSTRAINT pk_bib_list_habitat PRIMARY KEY (id_list);

