
CREATE TABLE taxonomie.bdc_statut_cor_text_values (
    id_value_text integer NOT NULL,
    id_value integer NOT NULL,
    id_text integer NOT NULL
);

COMMENT ON TABLE taxonomie.bdc_statut_cor_text_values IS 'Table d''association entre les textes, les taxons et la valeur';

CREATE SEQUENCE taxonomie.bdc_statut_cor_text_values_id_value_text_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE taxonomie.bdc_statut_cor_text_values_id_value_text_seq OWNED BY taxonomie.bdc_statut_cor_text_values.id_value_text;

ALTER TABLE ONLY taxonomie.bdc_statut_cor_text_values
    ADD CONSTRAINT bdc_statut_cor_text_values_pkey PRIMARY KEY (id_value_text);

CREATE INDEX idx_bsctv_id_text ON taxonomie.bdc_statut_cor_text_values USING btree (id_text);

CREATE INDEX idx_bsctv_id_value ON taxonomie.bdc_statut_cor_text_values USING btree (id_value);

ALTER TABLE ONLY taxonomie.bdc_statut_cor_text_values
    ADD CONSTRAINT tbdc_statut_cor_text_values_id_text_fkey FOREIGN KEY (id_text) REFERENCES taxonomie.bdc_statut_text(id_text) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY taxonomie.bdc_statut_cor_text_values
    ADD CONSTRAINT tbdc_statut_cor_text_values_id_value_fkey FOREIGN KEY (id_value) REFERENCES taxonomie.bdc_statut_values(id_value) ON UPDATE CASCADE ON DELETE CASCADE;

