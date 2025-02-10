
CREATE TABLE taxonomie.bdc_statut_taxons (
    id integer NOT NULL,
    id_value_text integer NOT NULL,
    cd_nom integer NOT NULL,
    cd_ref integer NOT NULL,
    rq_statut character varying(1000)
);

COMMENT ON TABLE taxonomie.bdc_statut_taxons IS 'Table d''association entre les textes et les taxons';

ALTER TABLE ONLY taxonomie.bdc_statut_taxons
    ADD CONSTRAINT bdc_statut_taxons_pkey PRIMARY KEY (id);

CREATE INDEX idx_bst_id_value_text ON taxonomie.bdc_statut_taxons USING btree (id_value_text);

ALTER TABLE ONLY taxonomie.bdc_statut_taxons
    ADD CONSTRAINT bdc_statut_taxons_cd_nom_fkey FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY taxonomie.bdc_statut_taxons
    ADD CONSTRAINT bdc_statut_taxons_id_value_text_fkey FOREIGN KEY (id_value_text) REFERENCES taxonomie.bdc_statut_cor_text_values(id_value_text) ON UPDATE CASCADE ON DELETE CASCADE;

