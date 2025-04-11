
CREATE TABLE gn_meta.cor_dataset_protocol (
    id_dataset integer NOT NULL,
    id_protocol integer NOT NULL
);

COMMENT ON TABLE gn_meta.cor_dataset_protocol IS 'A dataset can have 0 or n "protocole". Implement 1.3.10 SINP metadata standard : Protocole(s) rattaché(s) au jeu de données (protocole de synthèse et/ou de collecte). On se rapportera au type "Protocole Type". - RECOMMANDE';

ALTER TABLE ONLY gn_meta.cor_dataset_protocol
    ADD CONSTRAINT pk_cor_dataset_protocol PRIMARY KEY (id_dataset, id_protocol);

ALTER TABLE ONLY gn_meta.cor_dataset_protocol
    ADD CONSTRAINT fk_cor_dataset_protocol_id_dataset FOREIGN KEY (id_dataset) REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_meta.cor_dataset_protocol
    ADD CONSTRAINT fk_cor_dataset_protocol_id_protocol FOREIGN KEY (id_protocol) REFERENCES gn_meta.sinp_datatype_protocols(id_protocol) ON UPDATE CASCADE;

