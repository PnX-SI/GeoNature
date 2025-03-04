
CREATE TABLE gn_synthese.cor_area_synthese (
    id_synthese integer NOT NULL,
    id_area integer NOT NULL
);

ALTER TABLE ONLY gn_synthese.cor_area_synthese
    ADD CONSTRAINT pk_cor_area_synthese PRIMARY KEY (id_synthese, id_area);

CREATE INDEX i_cor_area_synthese_id_area ON gn_synthese.cor_area_synthese USING btree (id_area);

ALTER TABLE ONLY gn_synthese.cor_area_synthese
    ADD CONSTRAINT fk_cor_area_synthese_id_area FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_synthese.cor_area_synthese
    ADD CONSTRAINT fk_cor_area_synthese_id_synthese FOREIGN KEY (id_synthese) REFERENCES gn_synthese.synthese(id_synthese) ON UPDATE CASCADE ON DELETE CASCADE;

