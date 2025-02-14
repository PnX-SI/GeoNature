
CREATE TABLE gn_meta.cor_dataset_territory (
    id_dataset integer NOT NULL,
    id_nomenclature_territory integer NOT NULL,
    territory_desc text
);

COMMENT ON TABLE gn_meta.cor_dataset_territory IS 'A dataset must have 1 or n "territoire". Implement 1.3.10 SINP metadata standard : Cible géographique du jeu de données, ou zone géographique visée par le jeu. Défini par une valeur dans la nomenclature TerritoireValue. - OBLIGATOIRE';

COMMENT ON COLUMN gn_meta.cor_dataset_territory.territory_desc IS 'Correspondance standard SINP = precisionGeographique : Précisions sur le territoire visé - FACULTATIF';

ALTER TABLE gn_meta.cor_dataset_territory
    ADD CONSTRAINT check_cor_dataset_territory CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_territory, 'TERRITOIRE'::character varying)) NOT VALID;

ALTER TABLE ONLY gn_meta.cor_dataset_territory
    ADD CONSTRAINT pk_cor_dataset_territory PRIMARY KEY (id_dataset, id_nomenclature_territory);

ALTER TABLE ONLY gn_meta.cor_dataset_territory
    ADD CONSTRAINT fk_cor_dataset_territory_id_dataset FOREIGN KEY (id_dataset) REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_meta.cor_dataset_territory
    ADD CONSTRAINT fk_cor_dataset_territory_id_nomenclature_territory FOREIGN KEY (id_nomenclature_territory) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

