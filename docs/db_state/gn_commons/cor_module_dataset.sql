
CREATE TABLE gn_commons.cor_module_dataset (
    id_module integer NOT NULL,
    id_dataset integer NOT NULL
);

COMMENT ON TABLE gn_commons.cor_module_dataset IS 'Define which datasets can be used in modules';

ALTER TABLE ONLY gn_commons.cor_module_dataset
    ADD CONSTRAINT pk_cor_module_dataset PRIMARY KEY (id_module, id_dataset);

ALTER TABLE ONLY gn_commons.cor_module_dataset
    ADD CONSTRAINT fk_cor_module_dataset_id_dataset FOREIGN KEY (id_dataset) REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_commons.cor_module_dataset
    ADD CONSTRAINT fk_cor_module_dataset_id_module FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules(id_module) ON UPDATE CASCADE ON DELETE CASCADE;

