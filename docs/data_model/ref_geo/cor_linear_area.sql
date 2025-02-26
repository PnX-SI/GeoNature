
CREATE TABLE ref_geo.cor_linear_area (
    id_linear integer,
    id_area integer
);

CREATE INDEX ref_geo_cor_linear_area_id_area ON ref_geo.cor_linear_area USING btree (id_area);

CREATE INDEX ref_geo_cor_linear_area_id_linear ON ref_geo.cor_linear_area USING btree (id_linear);

ALTER TABLE ONLY ref_geo.cor_linear_area
    ADD CONSTRAINT fk_ref_geo_cor_linear_id_area_group FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY ref_geo.cor_linear_area
    ADD CONSTRAINT fk_ref_geo_cor_linear_id_lineair_group FOREIGN KEY (id_linear) REFERENCES ref_geo.l_linears(id_linear) ON UPDATE CASCADE ON DELETE CASCADE;

