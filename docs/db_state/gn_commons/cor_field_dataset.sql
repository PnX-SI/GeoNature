
CREATE TABLE gn_commons.cor_field_dataset (
    id_field integer NOT NULL,
    id_dataset integer NOT NULL
);

ALTER TABLE ONLY gn_commons.cor_field_dataset
    ADD CONSTRAINT pk_cor_field_dataset PRIMARY KEY (id_field, id_dataset);

ALTER TABLE ONLY gn_commons.cor_field_dataset
    ADD CONSTRAINT fk_cor_field_dataset FOREIGN KEY (id_dataset) REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_commons.cor_field_dataset
    ADD CONSTRAINT fk_cor_field_dataset_field FOREIGN KEY (id_field) REFERENCES gn_commons.t_additional_fields(id_field) ON UPDATE CASCADE ON DELETE CASCADE;

