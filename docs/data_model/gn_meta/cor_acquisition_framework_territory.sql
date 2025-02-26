
CREATE TABLE gn_meta.cor_acquisition_framework_territory (
    id_acquisition_framework integer NOT NULL,
    id_nomenclature_territory integer NOT NULL
);

COMMENT ON TABLE gn_meta.cor_acquisition_framework_territory IS 'A acquisition_framework must have 1 or n "territoire". Implement 1.3.10 SINP metadata standard : Cible géographique du jeu de données, ou zone géographique visée par le jeu. Défini par une valeur dans la nomenclature TerritoireValue. - OBLIGATOIRE';

ALTER TABLE gn_meta.cor_acquisition_framework_territory
    ADD CONSTRAINT check_cor_af_territory CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_territory, 'TERRITOIRE'::character varying)) NOT VALID;

ALTER TABLE ONLY gn_meta.cor_acquisition_framework_territory
    ADD CONSTRAINT pk_cor_acquisition_framework_territory PRIMARY KEY (id_acquisition_framework, id_nomenclature_territory);

ALTER TABLE ONLY gn_meta.cor_acquisition_framework_territory
    ADD CONSTRAINT fk_cor_af_territory_id_af FOREIGN KEY (id_acquisition_framework) REFERENCES gn_meta.t_acquisition_frameworks(id_acquisition_framework) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_meta.cor_acquisition_framework_territory
    ADD CONSTRAINT fk_cor_af_territory_id_nomenclature_territory FOREIGN KEY (id_nomenclature_territory) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

