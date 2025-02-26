
CREATE TABLE ref_nomenclatures.cor_application_nomenclature (
    id_nomenclature integer NOT NULL,
    id_application integer NOT NULL
);

COMMENT ON TABLE ref_nomenclatures.cor_application_nomenclature IS 'Allow to create specific list per module for one nomenclature.';

ALTER TABLE ONLY ref_nomenclatures.cor_application_nomenclature
    ADD CONSTRAINT pk_cor_application_nomenclature PRIMARY KEY (id_nomenclature, id_application);

ALTER TABLE ONLY ref_nomenclatures.cor_application_nomenclature
    ADD CONSTRAINT fk_cor_application_nomenclature_id_application FOREIGN KEY (id_application) REFERENCES utilisateurs.t_applications(id_application) ON UPDATE CASCADE;

ALTER TABLE ONLY ref_nomenclatures.cor_application_nomenclature
    ADD CONSTRAINT fk_cor_application_nomenclature_id_nomenclature FOREIGN KEY (id_nomenclature) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

