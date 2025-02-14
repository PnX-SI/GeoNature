
CREATE TABLE gn_sensitivity.cor_sensitivity_criteria (
    id_sensitivity integer,
    id_criteria integer,
    id_type_nomenclature integer
);

COMMENT ON TABLE gn_sensitivity.cor_sensitivity_criteria IS 'Specifies extra criteria for a sensitivity rule';

CREATE INDEX cor_sensitivity_criteria_id_sensitivity_idx ON gn_sensitivity.cor_sensitivity_criteria USING btree (id_sensitivity);

ALTER TABLE ONLY gn_sensitivity.cor_sensitivity_criteria
    ADD CONSTRAINT criteria_id_criteria_fkey FOREIGN KEY (id_criteria) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_sensitivity.cor_sensitivity_criteria
    ADD CONSTRAINT criteria_id_sensitivity_fkey FOREIGN KEY (id_sensitivity) REFERENCES gn_sensitivity.t_sensitivity_rules(id_sensitivity) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_sensitivity.cor_sensitivity_criteria
    ADD CONSTRAINT criteria_id_type_nomenclature_fkey FOREIGN KEY (id_type_nomenclature) REFERENCES ref_nomenclatures.bib_nomenclatures_types(id_type);

