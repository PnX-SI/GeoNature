
CREATE TABLE gn_sensitivity.cor_sensitivity_area_type (
    id_nomenclature_sensitivity integer,
    id_area_type integer
);

ALTER TABLE ONLY gn_sensitivity.cor_sensitivity_area_type
    ADD CONSTRAINT cor_sensitivity_area_type_id_area_type_fkey FOREIGN KEY (id_area_type) REFERENCES ref_geo.bib_areas_types(id_type);

ALTER TABLE ONLY gn_sensitivity.cor_sensitivity_area_type
    ADD CONSTRAINT cor_sensitivity_area_type_id_nomenclature_sensitivity_fkey FOREIGN KEY (id_nomenclature_sensitivity) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

