
CREATE TABLE taxonomie.bdc_statut_values (
    id_value integer NOT NULL,
    code_statut character varying(50) NOT NULL,
    label_statut character varying(250)
);

COMMENT ON TABLE taxonomie.bdc_statut_values IS 'Table contenant la liste des valeurs possible pour les textes';

CREATE SEQUENCE taxonomie.bdc_statut_values_id_value_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE taxonomie.bdc_statut_values_id_value_seq OWNED BY taxonomie.bdc_statut_values.id_value;

ALTER TABLE ONLY taxonomie.bdc_statut_values
    ADD CONSTRAINT bdc_statut_values_pkey PRIMARY KEY (id_value);

