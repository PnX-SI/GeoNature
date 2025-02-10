
CREATE TABLE gn_meta.cor_acquisition_framework_publication (
    id_acquisition_framework integer NOT NULL,
    id_publication integer NOT NULL
);

COMMENT ON TABLE gn_meta.cor_acquisition_framework_publication IS 'A acquisition framework can have 0 or n "publication". Implement 1.3.10 SINP metadata standard : Référence(s) bibliographique(s) éventuelle(s) concernant le cadre d''acquisition - RECOMMANDE';

ALTER TABLE ONLY gn_meta.cor_acquisition_framework_publication
    ADD CONSTRAINT pk_cor_acquisition_framework_publication PRIMARY KEY (id_acquisition_framework, id_publication);

ALTER TABLE ONLY gn_meta.cor_acquisition_framework_publication
    ADD CONSTRAINT fk_cor_acquisition_framework_publication_id_acquisition_framewo FOREIGN KEY (id_acquisition_framework) REFERENCES gn_meta.t_acquisition_frameworks(id_acquisition_framework) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_meta.cor_acquisition_framework_publication
    ADD CONSTRAINT fk_cor_acquisition_framework_publication_id_publication FOREIGN KEY (id_publication) REFERENCES gn_meta.sinp_datatype_publications(id_publication) ON UPDATE CASCADE ON DELETE CASCADE;

