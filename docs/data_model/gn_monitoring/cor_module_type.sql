
CREATE TABLE gn_monitoring.cor_module_type (
    id_type_site integer NOT NULL,
    id_module integer NOT NULL
);

ALTER TABLE ONLY gn_monitoring.cor_module_type
    ADD CONSTRAINT pk_cor_module_type PRIMARY KEY (id_type_site, id_module);

ALTER TABLE ONLY gn_monitoring.cor_module_type
    ADD CONSTRAINT fk_cor_module_type_id_module FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules(id_module) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_monitoring.cor_module_type
    ADD CONSTRAINT fk_cor_module_type_id_nomenclature FOREIGN KEY (id_type_site) REFERENCES gn_monitoring.bib_type_site(id_nomenclature_type_site) ON UPDATE CASCADE ON DELETE CASCADE;

