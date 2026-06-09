

CREATE TABLE gn_imports.cor_import_datasets (
    id_import integer NOT NULL,
    id_dataset integer NOT NULL
);

ALTER TABLE ONLY gn_imports.cor_import_datasets
    ADD CONSTRAINT cor_import_datasets_pkey PRIMARY KEY (id_import, id_dataset);

ALTER TABLE ONLY gn_imports.cor_import_datasets
    ADD CONSTRAINT fk_cor_import_datasets_id_dataset FOREIGN KEY (id_dataset) REFERENCES gn_meta.t_datasets(id_dataset) ON DELETE CASCADE;

ALTER TABLE ONLY gn_imports.cor_import_datasets
    ADD CONSTRAINT fk_cor_import_datasets_id_import FOREIGN KEY (id_import) REFERENCES gn_imports.t_imports(id_import) ON DELETE CASCADE;


