
CREATE TABLE gn_meta.cor_acquisition_framework_voletsinp (
    id_acquisition_framework integer NOT NULL,
    id_nomenclature_voletsinp integer NOT NULL
);

COMMENT ON TABLE gn_meta.cor_acquisition_framework_voletsinp IS 'A acquisition framework can have 0 or n "voletSINP". Implement 1.3.10 SINP metadata standard : Volet du SINP concerné par le dispositif de collecte, tel que défini dans la nomenclature voletSINPValue - FACULTATIF';

ALTER TABLE gn_meta.cor_acquisition_framework_voletsinp
    ADD CONSTRAINT check_cor_acquisition_framework_voletsinp CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_voletsinp, 'VOLET_SINP'::character varying)) NOT VALID;

ALTER TABLE ONLY gn_meta.cor_acquisition_framework_voletsinp
    ADD CONSTRAINT pk_cor_acquisition_framework_voletsinp PRIMARY KEY (id_acquisition_framework, id_nomenclature_voletsinp);

ALTER TABLE ONLY gn_meta.cor_acquisition_framework_voletsinp
    ADD CONSTRAINT fk_cor_acquisition_framework_voletsinp_id_acquisition_framework FOREIGN KEY (id_acquisition_framework) REFERENCES gn_meta.t_acquisition_frameworks(id_acquisition_framework) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_meta.cor_acquisition_framework_voletsinp
    ADD CONSTRAINT fk_cor_acquisition_framework_voletsinp_id_nomenclature_voletsin FOREIGN KEY (id_nomenclature_voletsinp) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

