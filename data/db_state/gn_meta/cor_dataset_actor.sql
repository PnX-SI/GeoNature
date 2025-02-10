
CREATE TABLE gn_meta.cor_dataset_actor (
    id_cda integer NOT NULL,
    id_dataset integer NOT NULL,
    id_role integer,
    id_organism integer,
    id_nomenclature_actor_role integer NOT NULL,
    CONSTRAINT check_id_role_not_group CHECK ((NOT gn_commons.role_is_group(id_role))),
    CONSTRAINT check_is_actor_in_cor_dataset_actor CHECK (((id_role IS NOT NULL) OR (id_organism IS NOT NULL)))
);

COMMENT ON TABLE gn_meta.cor_dataset_actor IS 'A dataset must have 1 or n actor ""pointContactJdd"". Implement 1.3.10 SINP metadata standard : Point de contact principal pour les données du jeu de données, et autres éventuels contacts (fournisseur ou producteur). (Règle : Un contact au moins devra avoir roleActeur à 1 - Les autres types possibles pour roleActeur sont 5 et 6 (fournisseur et producteur)) - OBLIGATOIRE';

COMMENT ON COLUMN gn_meta.cor_dataset_actor.id_nomenclature_actor_role IS 'Correspondance standard SINP = roleActeur : Rôle de l''acteur tel que défini dans la nomenclature RoleActeurValue - OBLIGATOIRE';

CREATE SEQUENCE gn_meta.cor_dataset_actor_id_cda_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_meta.cor_dataset_actor_id_cda_seq OWNED BY gn_meta.cor_dataset_actor.id_cda;

ALTER TABLE gn_meta.cor_dataset_actor
    ADD CONSTRAINT check_cor_dataset_actor CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_actor_role, 'ROLE_ACTEUR'::character varying)) NOT VALID;

ALTER TABLE ONLY gn_meta.cor_dataset_actor
    ADD CONSTRAINT check_is_unique_cor_dataset_actor_organism UNIQUE (id_dataset, id_organism, id_nomenclature_actor_role);

ALTER TABLE ONLY gn_meta.cor_dataset_actor
    ADD CONSTRAINT check_is_unique_cor_dataset_actor_role UNIQUE (id_dataset, id_role, id_nomenclature_actor_role);

ALTER TABLE ONLY gn_meta.cor_dataset_actor
    ADD CONSTRAINT pk_cor_dataset_actor PRIMARY KEY (id_cda);

ALTER TABLE ONLY gn_meta.cor_dataset_actor
    ADD CONSTRAINT fk_cor_dataset_actor_id_dataset FOREIGN KEY (id_dataset) REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_meta.cor_dataset_actor
    ADD CONSTRAINT fk_cor_dataset_actor_id_nomenclature_actor_role FOREIGN KEY (id_nomenclature_actor_role) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_meta.cor_dataset_actor
    ADD CONSTRAINT fk_dataset_actor_id_organism FOREIGN KEY (id_organism) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_meta.cor_dataset_actor
    ADD CONSTRAINT fk_dataset_actor_id_role FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;

