
CREATE TABLE taxonomie.bdc_statut_cor_text_area (
    id_text integer NOT NULL,
    id_area integer NOT NULL
);

ALTER TABLE ONLY taxonomie.bdc_statut_cor_text_area
    ADD CONSTRAINT bdc_statut_cor_text_area_pkey PRIMARY KEY (id_text, id_area);

ALTER TABLE ONLY taxonomie.bdc_statut_cor_text_area
    ADD CONSTRAINT fk_bdc_statut_cor_text_area_id_area FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area) ON UPDATE CASCADE;

ALTER TABLE ONLY taxonomie.bdc_statut_cor_text_area
    ADD CONSTRAINT fk_bdc_statut_cor_text_area_id_text FOREIGN KEY (id_text) REFERENCES taxonomie.bdc_statut_text(id_text) ON UPDATE CASCADE;

