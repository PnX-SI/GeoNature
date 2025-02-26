
CREATE TABLE gn_sensitivity.cor_sensitivity_area (
    id_sensitivity integer,
    id_area integer
);

COMMENT ON TABLE gn_sensitivity.cor_sensitivity_area IS 'Specifies where a sensitivity rule applies';

CREATE INDEX cor_sensitivity_area_id_sensitivity_idx ON gn_sensitivity.cor_sensitivity_area USING btree (id_sensitivity);

ALTER TABLE ONLY gn_sensitivity.cor_sensitivity_area
    ADD CONSTRAINT fk_cor_sensitivity_area_id_area_fkey FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area);

ALTER TABLE ONLY gn_sensitivity.cor_sensitivity_area
    ADD CONSTRAINT fk_cor_sensitivity_area_id_sensitivity_fkey FOREIGN KEY (id_sensitivity) REFERENCES gn_sensitivity.t_sensitivity_rules(id_sensitivity) ON UPDATE CASCADE ON DELETE CASCADE;

