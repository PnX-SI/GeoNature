
CREATE TABLE ref_nomenclatures.defaults_nomenclatures_value (
    mnemonique_type character varying(255) NOT NULL,
    id_organism integer NOT NULL,
    id_nomenclature integer NOT NULL
);

ALTER TABLE ref_nomenclatures.defaults_nomenclatures_value
    ADD CONSTRAINT check_defaults_nomenclatures_value_is_nomenclature_in_type CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature, mnemonique_type)) NOT VALID;

ALTER TABLE ONLY ref_nomenclatures.defaults_nomenclatures_value
    ADD CONSTRAINT pk_defaults_nomenclatures_value PRIMARY KEY (mnemonique_type, id_organism);

ALTER TABLE ONLY ref_nomenclatures.defaults_nomenclatures_value
    ADD CONSTRAINT fk_defaults_nomenclatures_value_id_nomenclature FOREIGN KEY (id_nomenclature) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY ref_nomenclatures.defaults_nomenclatures_value
    ADD CONSTRAINT fk_defaults_nomenclatures_value_id_organism FOREIGN KEY (id_organism) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY ref_nomenclatures.defaults_nomenclatures_value
    ADD CONSTRAINT fk_defaults_nomenclatures_value_mnemonique_type FOREIGN KEY (mnemonique_type) REFERENCES ref_nomenclatures.bib_nomenclatures_types(mnemonique) ON UPDATE CASCADE;

