--Define wich datasets can be used in modules
CREATE TABLE gn_commons.cor_module_dataset (
    id_module integer NOT NULL,
    id_dataset integer NOT NULL,
  CONSTRAINT pk_cor_module_dataset PRIMARY KEY (id_module, id_dataset),
  CONSTRAINT fk_cor_module_dataset_id_module FOREIGN KEY (id_module)
      REFERENCES gn_commons.t_modules (id_module) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION,
  CONSTRAINT fk_cor_module_dataset_id_dataset FOREIGN KEY (id_dataset)
      REFERENCES gn_meta.t_datasets (id_dataset) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION
);
COMMENT ON TABLE gn_commons.cor_module_dataset IS 'Define wich datasets can be used in modules';

--Define all active datasets as datasets module's
INSERT INTO gn_commons.cor_module_dataset (id_module, id_dataset)
SELECT gn_commons.get_id_module_bycode('OCCTAX'), id_dataset
FROM gn_meta.t_datasets
WHERE active;
