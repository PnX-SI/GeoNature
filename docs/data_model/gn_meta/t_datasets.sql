
CREATE TABLE gn_meta.t_datasets (
    id_dataset integer NOT NULL,
    unique_dataset_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_acquisition_framework integer NOT NULL,
    dataset_name character varying(255) NOT NULL,
    dataset_shortname character varying(255) NOT NULL,
    dataset_desc text NOT NULL,
    id_nomenclature_data_type integer DEFAULT ref_nomenclatures.get_default_nomenclature_value('DATA_TYP'::character varying) NOT NULL,
    keywords text,
    marine_domain boolean NOT NULL,
    terrestrial_domain boolean NOT NULL,
    id_nomenclature_dataset_objectif integer DEFAULT ref_nomenclatures.get_default_nomenclature_value('JDD_OBJECTIFS'::character varying) NOT NULL,
    bbox_west real,
    bbox_east real,
    bbox_south real,
    bbox_north real,
    id_nomenclature_collecting_method integer DEFAULT ref_nomenclatures.get_default_nomenclature_value('METHO_RECUEIL'::character varying) NOT NULL,
    id_nomenclature_data_origin integer DEFAULT ref_nomenclatures.get_default_nomenclature_value('DS_PUBLIQUE'::character varying) NOT NULL,
    id_nomenclature_source_status integer DEFAULT ref_nomenclatures.get_default_nomenclature_value('STATUT_SOURCE'::character varying) NOT NULL,
    id_nomenclature_resource_type integer DEFAULT ref_nomenclatures.get_default_nomenclature_value('RESOURCE_TYP'::character varying) NOT NULL,
    active boolean DEFAULT true NOT NULL,
    validable boolean DEFAULT true,
    id_digitizer integer,
    id_taxa_list integer,
    meta_create_date timestamp without time zone NOT NULL,
    meta_update_date timestamp without time zone
);

COMMENT ON TABLE gn_meta.t_datasets IS 'A dataset is a dataset or a survey and each observation is attached to a dataset. A lot allows to qualify datas to which it is attached (producer, owner, manager, gestionnaire, financer, public data yes/no). A dataset can be attached to a program. GeoNature V2 backoffice allows to manage datasets.';

COMMENT ON COLUMN gn_meta.t_datasets.id_dataset IS 'Internal value for primary and foreign keys.';

COMMENT ON COLUMN gn_meta.t_datasets.unique_dataset_id IS 'Correspondance standard SINP = identifiantJdd : Identifiant unique du jeu de données sous la forme d''un UUID. Il devra être sous la forme d''un UUID - OBLIGATOIRE';

COMMENT ON COLUMN gn_meta.t_datasets.id_acquisition_framework IS ' Internal value for foreign keys with t_acquisition_frameworks table';

COMMENT ON COLUMN gn_meta.t_datasets.dataset_name IS 'Correspondance standard SINP = libelle : Nom du jeu de données (150 caractères) - OBLIGATOIRE';

COMMENT ON COLUMN gn_meta.t_datasets.dataset_shortname IS 'Correspondance standard SINP = libelleCourt : Libellé court (30 caractères) du jeu de données - OBLIGATOIRE';

COMMENT ON COLUMN gn_meta.t_datasets.dataset_desc IS 'Correspondance standard SINP = description : Description du jeu de données - OBLIGATOIRE';

COMMENT ON COLUMN gn_meta.t_datasets.id_nomenclature_data_type IS 'Correspondance standard SINP = typeDonnees : Type de données du jeu de données tel que défini dans la nomenclature TypeDonneesValue - OBLIGATOIRE';

COMMENT ON COLUMN gn_meta.t_datasets.keywords IS 'Correspondance standard SINP = motCle : Mot(s)-clé(s) représentatifs du jeu de données, séparés par des virgules - FACULTATIF';

COMMENT ON COLUMN gn_meta.t_datasets.marine_domain IS 'Correspondance standard SINP = domaineMarin : Indique si le jeu de données concerne le domaine marin - OBLIGATOIRE';

COMMENT ON COLUMN gn_meta.t_datasets.terrestrial_domain IS 'Correspondance standard SINP = domaineTerrestre : Indique si le jeu de données concerne le domaine terrestre - OBLIGATOIRE';

COMMENT ON COLUMN gn_meta.t_datasets.id_nomenclature_dataset_objectif IS 'Correspondance standard SINP = objectifJdd : Objectif du jeu de données tel que défini par la nomenclature ObjectifJeuDonneesValue - OBLIGATOIRE';

COMMENT ON COLUMN gn_meta.t_datasets.bbox_west IS 'Correspondance standard SINP = empriseGeographique::borneOuest : Point le plus à l''ouest de la zone géographique délimitant le jeu de données - FACULTATIF';

COMMENT ON COLUMN gn_meta.t_datasets.bbox_east IS 'Correspondance standard SINP = empriseGeographique::borneEst : Point le plus à l''est de la zone géographique délimitant le jeu de données - FACULTATIF';

COMMENT ON COLUMN gn_meta.t_datasets.bbox_south IS 'Correspondance standard SINP = empriseGeographique::borneSud : Point le plus au sud de la zone géographique délimitant le jeu de données - FACULTATIF';

COMMENT ON COLUMN gn_meta.t_datasets.bbox_north IS 'Correspondance standard SINP = empriseGeographique::borneNord : Point le plus au nord de la zone géographique délimitant le jeu de données - FACULTATIF';

COMMENT ON COLUMN gn_meta.t_datasets.id_nomenclature_collecting_method IS 'Correspondance standard SINP = methodeRecueil : Méthode de recueil des données : Ensemble de techniques, savoir-faire et outils mobilisés pour collecter des données - RECOMMANDE';

COMMENT ON COLUMN gn_meta.t_datasets.id_nomenclature_data_origin IS 'Public, privée, etc... Dans le standard SINP cette information se situe au niveau de chaque occurrence de taxon. On considère ici qu''elle doit être homoogène pour un même jeu de données - OBLIGATOIRE';

COMMENT ON COLUMN gn_meta.t_datasets.id_nomenclature_source_status IS 'Terrain, littérature, etc... Dans le standard SINP cette information se situe au niveau de chaque occurrence de taxon. On considère ici qu''elle doit être homoogène pour un même jeu de données - OBLIGATOIRE';

COMMENT ON COLUMN gn_meta.t_datasets.id_nomenclature_resource_type IS 'jeu de données ou série de jeu de données. Dans le standard SINP cette information se situe au niveau de chaque occurrence de taxon. On considère ici qu''elle doit être homoogène pour un même jeu de données - OBLIGATOIRE';

COMMENT ON COLUMN gn_meta.t_datasets.meta_create_date IS 'Correspondance standard SINP = dateCreation : Date de création de la fiche de métadonnées du jeu de données, format AAAA-MM-JJ - OBLIGATOIRE';

COMMENT ON COLUMN gn_meta.t_datasets.meta_update_date IS 'Identifiant de la liste de taxon associé au JDD. FK: taxonomie.bib_liste';

CREATE SEQUENCE gn_meta.t_datasets_id_dataset_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_meta.t_datasets_id_dataset_seq OWNED BY gn_meta.t_datasets.id_dataset;

ALTER TABLE gn_meta.t_datasets
    ADD CONSTRAINT check_t_datasets_collecting_method CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_collecting_method, 'METHO_RECUEIL'::character varying)) NOT VALID;

ALTER TABLE gn_meta.t_datasets
    ADD CONSTRAINT check_t_datasets_data_origin CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_data_origin, 'DS_PUBLIQUE'::character varying)) NOT VALID;

ALTER TABLE gn_meta.t_datasets
    ADD CONSTRAINT check_t_datasets_data_type CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_data_type, 'DATA_TYP'::character varying)) NOT VALID;

ALTER TABLE gn_meta.t_datasets
    ADD CONSTRAINT check_t_datasets_objectif CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_dataset_objectif, 'JDD_OBJECTIFS'::character varying)) NOT VALID;

ALTER TABLE gn_meta.t_datasets
    ADD CONSTRAINT check_t_datasets_resource_type CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_resource_type, 'RESOURCE_TYP'::character varying)) NOT VALID;

ALTER TABLE gn_meta.t_datasets
    ADD CONSTRAINT check_t_datasets_source_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_source_status, 'STATUT_SOURCE'::character varying)) NOT VALID;

ALTER TABLE ONLY gn_meta.t_datasets
    ADD CONSTRAINT pk_t_datasets PRIMARY KEY (id_dataset);

ALTER TABLE ONLY gn_meta.t_datasets
    ADD CONSTRAINT unique_dataset_uuid UNIQUE (unique_dataset_id);

CREATE INDEX i_t_datasets_id_acquisition_framework ON gn_meta.t_datasets USING btree (id_acquisition_framework);

CREATE UNIQUE INDEX i_unique_t_datasets_unique_id ON gn_meta.t_datasets USING btree (unique_dataset_id);

CREATE TRIGGER tri_meta_dates_change_t_datasets BEFORE INSERT OR UPDATE ON gn_meta.t_datasets FOR EACH ROW EXECUTE FUNCTION public.fct_trg_meta_dates_change();

ALTER TABLE ONLY gn_meta.t_datasets
    ADD CONSTRAINT fk_t_datasets_collecting_method FOREIGN KEY (id_nomenclature_collecting_method) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_meta.t_datasets
    ADD CONSTRAINT fk_t_datasets_data_origin FOREIGN KEY (id_nomenclature_data_origin) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_meta.t_datasets
    ADD CONSTRAINT fk_t_datasets_data_type FOREIGN KEY (id_nomenclature_data_type) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_meta.t_datasets
    ADD CONSTRAINT fk_t_datasets_id_digitizer FOREIGN KEY (id_digitizer) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_meta.t_datasets
    ADD CONSTRAINT fk_t_datasets_objectif FOREIGN KEY (id_nomenclature_dataset_objectif) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_meta.t_datasets
    ADD CONSTRAINT fk_t_datasets_resource_type FOREIGN KEY (id_nomenclature_resource_type) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_meta.t_datasets
    ADD CONSTRAINT fk_t_datasets_source_status FOREIGN KEY (id_nomenclature_source_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_meta.t_datasets
    ADD CONSTRAINT fk_t_datasets_t_acquisition_frameworks FOREIGN KEY (id_acquisition_framework) REFERENCES gn_meta.t_acquisition_frameworks(id_acquisition_framework) ON UPDATE CASCADE;

