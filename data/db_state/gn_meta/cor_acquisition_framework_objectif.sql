
CREATE TABLE gn_meta.cor_acquisition_framework_objectif (
    id_acquisition_framework integer NOT NULL,
    id_nomenclature_objectif integer NOT NULL
);

COMMENT ON TABLE gn_meta.cor_acquisition_framework_objectif IS 'A acquisition framework can have 1 or n "objectif". Implement 1.3.10 SINP metadata standard : Objectif du cadre d''acquisition, tel que défini par la nomenclature TypeDispositifValue - OBLIGATOIRE';

ALTER TABLE gn_meta.cor_acquisition_framework_objectif
    ADD CONSTRAINT check_cor_acquisition_framework_objectif CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_objectif, 'CA_OBJECTIFS'::character varying)) NOT VALID;

ALTER TABLE ONLY gn_meta.cor_acquisition_framework_objectif
    ADD CONSTRAINT pk_cor_acquisition_framework_objectif PRIMARY KEY (id_acquisition_framework, id_nomenclature_objectif);

ALTER TABLE ONLY gn_meta.cor_acquisition_framework_objectif
    ADD CONSTRAINT fk_cor_acquisition_framework_objectif_id_acquisition_framework FOREIGN KEY (id_acquisition_framework) REFERENCES gn_meta.t_acquisition_frameworks(id_acquisition_framework) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_meta.cor_acquisition_framework_objectif
    ADD CONSTRAINT fk_cor_acquisition_framework_objectif_id_nomenclature_objectif FOREIGN KEY (id_nomenclature_objectif) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

