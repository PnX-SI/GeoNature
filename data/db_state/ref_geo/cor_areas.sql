
CREATE TABLE ref_geo.cor_areas (
    id_area_group integer,
    id_area integer
);

COMMENT ON TABLE ref_geo.cor_areas IS 'Table de correspondance entre les éléments lineaires et les éléments de zonage. Non remplie par défaut';

CREATE INDEX ref_geo_cor_areas_id_area ON ref_geo.cor_areas USING btree (id_area);

CREATE INDEX ref_geo_cor_areas_id_area_group ON ref_geo.cor_areas USING btree (id_area_group);

ALTER TABLE ONLY ref_geo.cor_areas
    ADD CONSTRAINT fk_ref_geo_cor_areas_id_area FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY ref_geo.cor_areas
    ADD CONSTRAINT fk_ref_geo_cor_areas_id_area_group FOREIGN KEY (id_area_group) REFERENCES ref_geo.l_areas(id_area) ON UPDATE CASCADE ON DELETE CASCADE;

