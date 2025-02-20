
CREATE TABLE ref_nomenclatures.cor_nomenclatures_relations (
    id_nomenclature_l integer NOT NULL,
    id_nomenclature_r integer NOT NULL,
    relation_type character varying(250) NOT NULL
);

ALTER TABLE ONLY ref_nomenclatures.cor_nomenclatures_relations
    ADD CONSTRAINT pk_cor_nomenclatures_relations PRIMARY KEY (id_nomenclature_l, id_nomenclature_r, relation_type);

ALTER TABLE ONLY ref_nomenclatures.cor_nomenclatures_relations
    ADD CONSTRAINT fk_cor_nomenclatures_relations_id_nomenclature_l FOREIGN KEY (id_nomenclature_l) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY ref_nomenclatures.cor_nomenclatures_relations
    ADD CONSTRAINT fk_cor_nomenclatures_relations_id_nomenclature_r FOREIGN KEY (id_nomenclature_r) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

