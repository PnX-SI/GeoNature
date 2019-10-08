SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;


CREATE SCHEMA gn_meta;

SET search_path = gn_meta, pg_catalog;

SET default_with_oids = false;


----------
--TABLES--
----------

-- CREATE TABLE sinp_datatype_actors (
--     id_actor integer NOT NULL,
--     actor_organism character varying(255),
--     actor_fullname character varying(255),
--     actor_mail character varying(255)
-- );
-- COMMENT ON TABLE sinp_datatype_actors IS 'Define a SINP datatype Types::ActeurType.';
-- COMMENT ON COLUMN sinp_datatype_actors.id_actor IS 'Internal value for primary and foreign keys';
-- COMMENT ON COLUMN sinp_datatype_actors.actor_organism IS 'Correspondance standard SINP = organisme :Exemple : Muséum National d''Histoire Naturelle (MNHN) - OBLIGATOIRE CONDITIONNEL : il DOIT être rempli si nomPrenom n''est pas rempli';
-- COMMENT ON COLUMN sinp_datatype_actors.actor_fullname IS 'Correspondance standard SINP = nomPrenom : Nom et prénom de la personne à contacter. (Sous la forme NOM Prénom) - OBLIGATOIRE CONDITIONNEL : il DOIT être rempli si organisme n''est pas rempli';
-- COMMENT ON COLUMN sinp_datatype_actors.actor_mail IS 'Correspondance standard SINP = mail : Adresse mail de contact - RECOMMANDE.';
-- CREATE SEQUENCE sinp_datatype_actors_id_actor_seq
--     START WITH 1
--     INCREMENT BY 1
--     NO MINVALUE
--     NO MAXVALUE
--     CACHE 1;
-- ALTER SEQUENCE sinp_datatype_actors_id_actor_seq OWNED BY sinp_datatype_actors.id_actor;
-- ALTER TABLE ONLY sinp_datatype_actors ALTER COLUMN id_actor SET DEFAULT nextval('sinp_datatype_actors_id_actor_seq'::regclass);


CREATE TABLE sinp_datatype_protocols (
    id_protocol integer NOT NULL,
    unique_protocol_id uuid NOT NULL DEFAULT public.uuid_generate_v4(),
    protocol_name character varying(255) NOT NULL,
    protocol_desc text,
    id_nomenclature_protocol_type integer NOT NULL,
    protocol_url character varying(255)
);
COMMENT ON TABLE sinp_datatype_protocols IS 'Define a SINP datatype Types::ProtocoleType.';
COMMENT ON COLUMN sinp_datatype_protocols.id_protocol IS 'Internal value for primary and foreign keys';
COMMENT ON COLUMN sinp_datatype_protocols.unique_protocol_id IS 'Internal value to reference external protocol id value';
COMMENT ON COLUMN sinp_datatype_protocols.protocol_name IS 'Correspondance standard SINP = libelle :Libellé du protocole : donne le nom du protocole en quelques mots - OBLIGATOIRE';
COMMENT ON COLUMN sinp_datatype_protocols.protocol_desc IS 'Correspondance standard SINP = description : Description du protocole : décrit le contenu du protocole - FACULTATIF.';
COMMENT ON COLUMN sinp_datatype_protocols.id_nomenclature_protocol_type IS 'Correspondance standard SINP = typeProtocole : Type du protocole, tel que défini dans la nomenclature TypeProtocoleValue - OBLIGATOIRE';
COMMENT ON COLUMN sinp_datatype_protocols.protocol_url IS 'Correspondance standard SINP = uRL : URL d''accès à un document permettant de décrire le protocole - RECOMMANDE.';
CREATE SEQUENCE sinp_datatype_protocols_id_protocol_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE sinp_datatype_protocols_id_protocol_seq OWNED BY sinp_datatype_protocols.id_protocol;
ALTER TABLE ONLY sinp_datatype_protocols ALTER COLUMN id_protocol SET DEFAULT nextval('sinp_datatype_protocols_id_protocol_seq'::regclass);


CREATE TABLE sinp_datatype_publications (
    id_publication integer NOT NULL,
    unique_publication_id uuid NOT NULL DEFAULT public.uuid_generate_v4(),
    publication_reference text NOT NULL,
    publication_url text
);
COMMENT ON TABLE sinp_datatype_publications IS 'Define a SINP datatype Concepts::Publication.';
COMMENT ON COLUMN sinp_datatype_publications.id_publication IS 'Internal value for primary and foreign keys';
COMMENT ON COLUMN sinp_datatype_publications.unique_publication_id IS 'Internal value to reference external publication id value';
COMMENT ON COLUMN sinp_datatype_publications.publication_reference IS 'Correspondance standard SINP = referencePublication : Référence complète de la publication suivant la nomenclature ISO 690 - OBLIGATOIRE';
COMMENT ON COLUMN sinp_datatype_publications.publication_url IS 'Correspondance standard SINP = URLPublication : Adresse à laquelle trouver la publication - RECOMMANDE.';
CREATE SEQUENCE sinp_datatype_publications_id_publication_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE sinp_datatype_publications_id_publication_seq OWNED BY sinp_datatype_publications.id_publication;
ALTER TABLE ONLY sinp_datatype_publications ALTER COLUMN id_publication SET DEFAULT nextval('sinp_datatype_publications_id_publication_seq'::regclass);

CREATE TABLE t_acquisition_frameworks (
    id_acquisition_framework integer NOT NULL,
    unique_acquisition_framework_id uuid NOT NULL DEFAULT public.uuid_generate_v4(),
    acquisition_framework_name character varying(255) NOT NULL,
    acquisition_framework_desc text NOT NULL,
    id_nomenclature_territorial_level integer DEFAULT ref_nomenclatures.get_default_nomenclature_value('NIVEAU_TERRITORIAL'),
    territory_desc text,
    keywords text,
    id_nomenclature_financing_type integer DEFAULT ref_nomenclatures.get_default_nomenclature_value('TYPE_FINANCEMENT'),
    target_description text,
    ecologic_or_geologic_target text,
    acquisition_framework_parent_id integer,
    is_parent boolean,
    acquisition_framework_start_date date NOT NULL,
    acquisition_framework_end_date date,
    meta_create_date timestamp without time zone NOT NULL,
    meta_update_date timestamp without time zone
);
COMMENT ON TABLE t_acquisition_frameworks IS 'Define a acquisition framework that embed datasets. Implement 1.3.8 SINP metadata standard';
COMMENT ON COLUMN t_acquisition_frameworks.id_acquisition_framework IS 'Internal value for primary and foreign keys';
COMMENT ON COLUMN t_acquisition_frameworks.unique_acquisition_framework_id IS 'Correspondance standard SINP = identifiantCadre';
COMMENT ON COLUMN t_acquisition_frameworks.acquisition_framework_name IS 'Correspondance standard SINP = libelle';
COMMENT ON COLUMN t_acquisition_frameworks.acquisition_framework_desc IS 'Correspondance standard SINP = description';
COMMENT ON COLUMN t_acquisition_frameworks.id_nomenclature_territorial_level IS 'Correspondance standard SINP = niveauTerritorial';
COMMENT ON COLUMN t_acquisition_frameworks.keywords IS 'Correspondance standard SINP = motCle : Mot(s)-clé(s) représentatifs du cadre d''acquisition, séparés par des virgules - FACULTATIF';
COMMENT ON COLUMN t_acquisition_frameworks.id_nomenclature_financing_type IS 'Correspondance standard SINP = typeFinancement : Type de financement pour le cadre d''acquisition, tel que défini dans la nomenclature TypeFinancementValue - RECOMMANDE';
COMMENT ON COLUMN t_acquisition_frameworks.target_description IS 'Correspondance standard SINP = descriptionCible : Description de la cible taxonomique ou géologique pour le cadre d''acquisition. (ex : pteridophyta) - RECOMMANDE';
COMMENT ON COLUMN t_acquisition_frameworks.ecologic_or_geologic_target IS 'Correspondance standard SINP = cibleEcologiqueOuGeologique : Cet attribut sera composé de CD_NOM de TAXREF, séparés par des points virgules, s''il s''agit de taxons, ou de CD_HAB de HABREF, séparés par des points virgules, s''il s''agit d''habitats. - FACULTATIF';
COMMENT ON COLUMN t_acquisition_frameworks.acquisition_framework_parent_id IS 'Correspondance standard SINP = idMetaCadreParent : Indique, par le biais de l''existence d''un identifiant unique de métacadre parent, si le cadre d''acquisition ici présent est contenu dans un autre cadre d''acquisition. S''il y un cadre parent, c''est son identifiant qui doit être renseigné ici. - RECOMMANDE';
COMMENT ON COLUMN t_acquisition_frameworks.is_parent IS 'Correspondance standard SINP = estMetaCadre : Indique si ce dispositif est un métacadre, et donc s''il contient d''autres cadres d''acquisition. Cet attribut est un booléen : 0 pour false (n''est pas un métacadre), 1 pour true (est un métacadre) - OBLIGATOIRE.';
COMMENT ON COLUMN t_acquisition_frameworks.acquisition_framework_start_date IS 'Correspondance standard SINP = ReferenceTemporelle:dateLancement : Date de lancement du cadre d''acquisition - OBLIGATOIRE.';
COMMENT ON COLUMN t_acquisition_frameworks.acquisition_framework_end_date IS 'Correspondance standard SINP = ReferenceTemporelle:dateCloture : Date de clôture du cadre d''acquisition. Si elle n''est pas remplie, on considère que le cadre est toujours en activité. - RECOMMANDE';
COMMENT ON COLUMN t_acquisition_frameworks.meta_create_date IS 'Correspondance standard SINP = dateCreationMtd : Date de création de la fiche de métadonnées du cadre d''acquisition. - OBLIGATOIRE';
COMMENT ON COLUMN t_acquisition_frameworks.meta_update_date IS 'Correspondance standard SINP = dateMiseAJourMtd : Date de mise à jour de la fiche de métadonnées du cadre d''acquisition. - FACULTATIF';
CREATE SEQUENCE t_acquisition_frameworks_id_acquisition_framework_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE t_acquisition_frameworks_id_acquisition_framework_seq OWNED BY t_acquisition_frameworks.id_acquisition_framework;
ALTER TABLE ONLY t_acquisition_frameworks ALTER COLUMN id_acquisition_framework SET DEFAULT nextval('t_acquisition_frameworks_id_acquisition_framework_seq'::regclass);


CREATE TABLE cor_acquisition_framework_voletsinp (
    id_acquisition_framework integer NOT NULL,
    id_nomenclature_voletsinp integer NOT NULL
);
COMMENT ON TABLE cor_acquisition_framework_voletsinp IS 'A acquisition framework can have 0 or n "voletSINP". Implement 1.3.8 SINP metadata standard : Volet du SINP concerné par le dispositif de collecte, tel que défini dans la nomenclature voletSINPValue - FACULTATIF';


CREATE TABLE cor_acquisition_framework_objectif (
    id_acquisition_framework integer NOT NULL,
    id_nomenclature_objectif integer NOT NULL
);
COMMENT ON TABLE cor_acquisition_framework_objectif IS 'A acquisition framework can have 1 or n "objectif". Implement 1.3.8 SINP metadata standard : Objectif du cadre d''acquisition, tel que défini par la nomenclature TypeDispositifValue - OBLIGATOIRE';


CREATE TABLE cor_acquisition_framework_actor (
    id_cafa integer NOT NULL,
    id_acquisition_framework integer NOT NULL,
    id_role integer,
    id_organism integer,
    id_nomenclature_actor_role integer NOT NULL
);
COMMENT ON TABLE cor_acquisition_framework_actor IS 'A acquisition framework must have a principal actor "acteurPrincipal" and can have 0 or n other actor "acteurAutre". Implement 1.3.8 SINP metadata standard : Contact principal pour le cadre d''acquisition (Règle : RoleActeur prendra la valeur 1) - OBLIGATOIRE. Autres contacts pour le cadre d''acquisition (exemples : maître d''oeuvre, d''ouvrage...).- RECOMMANDE';
COMMENT ON COLUMN cor_acquisition_framework_actor.id_nomenclature_actor_role IS 'Correspondance standard SINP = roleActeur : Rôle de l''acteur tel que défini dans la nomenclature RoleActeurValue - OBLIGATOIRE';
CREATE SEQUENCE cor_acquisition_framework_actor_id_cafa_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE cor_acquisition_framework_actor_id_cafa_seq OWNED BY cor_acquisition_framework_actor.id_cafa;
ALTER TABLE ONLY cor_acquisition_framework_actor ALTER COLUMN id_cafa SET DEFAULT nextval('cor_acquisition_framework_actor_id_cafa_seq'::regclass);


CREATE TABLE cor_acquisition_framework_publication (
    id_acquisition_framework integer NOT NULL,
    id_publication integer NOT NULL
);
COMMENT ON TABLE cor_acquisition_framework_publication IS 'A acquisition framework can have 0 or n "publication". Implement 1.3.8 SINP metadata standard : Référence(s) bibliographique(s) éventuelle(s) concernant le cadre d''acquisition - RECOMMANDE';


CREATE TABLE t_datasets (
    id_dataset integer NOT NULL,
    unique_dataset_id uuid NOT NULL DEFAULT public.uuid_generate_v4(),
    id_acquisition_framework integer NOT NULL,
    dataset_name character varying(255) NOT NULL,
    dataset_shortname character varying(255) NOT NULL,
    dataset_desc text NOT NULL,
    id_nomenclature_data_type integer NOT NULL DEFAULT ref_nomenclatures.get_default_nomenclature_value('DATA_TYP'),
    keywords text,
    marine_domain boolean NOT NULL,
    terrestrial_domain boolean NOT NULL,
    id_nomenclature_dataset_objectif integer NOT NULL DEFAULT ref_nomenclatures.get_default_nomenclature_value('JDD_OBJECTIFS'),
    bbox_west real,
    bbox_east real,
    bbox_south real,
    bbox_north real,
    id_nomenclature_collecting_method integer NOT NULL DEFAULT ref_nomenclatures.get_default_nomenclature_value('METHO_RECUEIL'),
    id_nomenclature_data_origin integer NOT NULL DEFAULT ref_nomenclatures.get_default_nomenclature_value('DS_PUBLIQUE'),
    id_nomenclature_source_status integer NOT NULL DEFAULT ref_nomenclatures.get_default_nomenclature_value('STATUT_SOURCE'),
    id_nomenclature_resource_type integer NOT NULL DEFAULT ref_nomenclatures.get_default_nomenclature_value('RESOURCE_TYP'),
    active boolean NOT NULL DEFAULT TRUE,
    validable boolean DEFAULT TRUE,
    meta_create_date timestamp without time zone NOT NULL,
    meta_update_date timestamp without time zone
);
COMMENT ON TABLE t_datasets IS 'A dataset is a dataset or a survey and each observation is attached to a dataset. A lot allows to qualify datas to which it is attached (producer, owner, manager, gestionnaire, financer, public data yes/no). A dataset can be attached to a program. GeoNature V2 backoffice allows to manage datasets.';
COMMENT ON COLUMN t_datasets.id_dataset IS 'Internal value for primary and foreign keys.';
COMMENT ON COLUMN t_datasets.unique_dataset_id IS 'Correspondance standard SINP = identifiantJdd : Identifiant unique du jeu de données sous la forme d''un UUID. Il devra être sous la forme d''un UUID - OBLIGATOIRE';
COMMENT ON COLUMN t_datasets.id_acquisition_framework IS ' Internal value for foreign keys with t_acquisition_frameworks table';
COMMENT ON COLUMN t_datasets.dataset_name IS 'Correspondance standard SINP = libelle : Nom du jeu de données (150 caractères) - OBLIGATOIRE';
COMMENT ON COLUMN t_datasets.dataset_shortname IS 'Correspondance standard SINP = libelleCourt : Libellé court (30 caractères) du jeu de données - OBLIGATOIRE';
COMMENT ON COLUMN t_datasets.dataset_desc IS 'Correspondance standard SINP = description : Description du jeu de données - OBLIGATOIRE';
COMMENT ON COLUMN t_datasets.id_nomenclature_data_type IS 'Correspondance standard SINP = typeDonnees : Type de données du jeu de données tel que défini dans la nomenclature TypeDonneesValue - OBLIGATOIRE';
COMMENT ON COLUMN t_datasets.keywords IS 'Correspondance standard SINP = motCle : Mot(s)-clé(s) représentatifs du jeu de données, séparés par des virgules - FACULTATIF';
COMMENT ON COLUMN t_datasets.marine_domain IS 'Correspondance standard SINP = domaineMarin : Indique si le jeu de données concerne le domaine marin - OBLIGATOIRE';
COMMENT ON COLUMN t_datasets.terrestrial_domain IS 'Correspondance standard SINP = domaineTerrestre : Indique si le jeu de données concerne le domaine terrestre - OBLIGATOIRE';
COMMENT ON COLUMN t_datasets.id_nomenclature_dataset_objectif IS 'Correspondance standard SINP = objectifJdd : Objectif du jeu de données tel que défini par la nomenclature ObjectifJeuDonneesValue - OBLIGATOIRE';
COMMENT ON COLUMN t_datasets.bbox_west IS 'Correspondance standard SINP = empriseGeographique::borneOuest : Point le plus à l''ouest de la zone géographique délimitant le jeu de données - FACULTATIF';
COMMENT ON COLUMN t_datasets.bbox_east IS 'Correspondance standard SINP = empriseGeographique::borneEst : Point le plus à l''est de la zone géographique délimitant le jeu de données - FACULTATIF';
COMMENT ON COLUMN t_datasets.bbox_south IS 'Correspondance standard SINP = empriseGeographique::borneSud : Point le plus au sud de la zone géographique délimitant le jeu de données - FACULTATIF';
COMMENT ON COLUMN t_datasets.bbox_north IS 'Correspondance standard SINP = empriseGeographique::borneNord : Point le plus au nord de la zone géographique délimitant le jeu de données - FACULTATIF';
COMMENT ON COLUMN t_datasets.id_nomenclature_collecting_method IS 'Correspondance standard SINP = methodeRecueil : Méthode de recueil des données : Ensemble de techniques, savoir-faire et outils mobilisés pour collecter des données - RECOMMANDE';
COMMENT ON COLUMN t_datasets.id_nomenclature_data_origin IS 'Public, privée, etc... Dans le standard SINP cette information se situe au niveau de chaque occurrence de taxon. On considère ici qu''elle doit être homoogène pour un même jeu de données - OBLIGATOIRE';
COMMENT ON COLUMN t_datasets.id_nomenclature_source_status IS 'Terrain, littérature, etc... Dans le standard SINP cette information se situe au niveau de chaque occurrence de taxon. On considère ici qu''elle doit être homoogène pour un même jeu de données - OBLIGATOIRE';
COMMENT ON COLUMN t_datasets.id_nomenclature_resource_type IS 'jeu de données ou série de jeu de données. Dans le standard SINP cette information se situe au niveau de chaque occurrence de taxon. On considère ici qu''elle doit être homoogène pour un même jeu de données - OBLIGATOIRE';
COMMENT ON COLUMN t_datasets.meta_create_date IS 'Correspondance standard SINP = dateCreation : Date de création de la fiche de métadonnées du jeu de données, format AAAA-MM-JJ - OBLIGATOIRE';
COMMENT ON COLUMN t_datasets.meta_update_date IS 'Correspondance standard SINP = dateRevision : Date de révision du jeu de données ou de sa fiche de métadonnées. Il est fortement recommandé de remplir cet attribut si une révision de la fiche ou du jeu de données a été effectuées, format AAAA-MM-JJ - RECOMMANDE';
CREATE SEQUENCE t_datasets_id_dataset_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE t_datasets_id_dataset_seq OWNED BY t_datasets.id_dataset;
ALTER TABLE ONLY t_datasets ALTER COLUMN id_dataset SET DEFAULT nextval('t_datasets_id_dataset_seq'::regclass);


CREATE TABLE cor_dataset_actor (
    id_cda integer NOT NULL,
    id_dataset integer NOT NULL,
    id_role integer,
    id_organism integer,
    id_nomenclature_actor_role integer NOT NULL
);
COMMENT ON TABLE cor_dataset_actor IS 'A dataset must have 1 or n actor ""pointContactJdd"". Implement 1.3.8 SINP metadata standard : Point de contact principal pour les données du jeu de données, et autres éventuels contacts (fournisseur ou producteur). (Règle : Un contact au moins devra avoir roleActeur à 1 - Les autres types possibles pour roleActeur sont 5 et 6 (fournisseur et producteur)) - OBLIGATOIRE';
COMMENT ON COLUMN cor_dataset_actor.id_nomenclature_actor_role IS 'Correspondance standard SINP = roleActeur : Rôle de l''acteur tel que défini dans la nomenclature RoleActeurValue - OBLIGATOIRE';
CREATE SEQUENCE cor_dataset_actor_id_cda_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE cor_dataset_actor_id_cda_seq OWNED BY cor_dataset_actor.id_cda;
ALTER TABLE ONLY cor_dataset_actor ALTER COLUMN id_cda SET DEFAULT nextval('cor_dataset_actor_id_cda_seq'::regclass);

CREATE TABLE cor_dataset_territory (
    id_dataset integer NOT NULL,
    id_nomenclature_territory integer NOT NULL,
    territory_desc text
);
COMMENT ON TABLE cor_dataset_territory IS 'A dataset must have 1 or n "territoire". Implement 1.3.8 SINP metadata standard : Cible géographique du jeu de données, ou zone géographique visée par le jeu. Défini par une valeur dans la nomenclature TerritoireValue. - OBLIGATOIRE';
COMMENT ON COLUMN cor_dataset_territory.territory_desc IS 'Correspondance standard SINP = precisionGeographique : Précisions sur le territoire visé - FACULTATIF';


CREATE TABLE cor_dataset_protocol (
    id_dataset integer NOT NULL,
    id_protocol integer NOT NULL
);
COMMENT ON TABLE cor_dataset_protocol IS 'A dataset can have 0 or n "protocole". Implement 1.3.8 SINP metadata standard : Protocole(s) rattaché(s) au jeu de données (protocole de synthèse et/ou de collecte). On se rapportera au type "Protocole Type". - RECOMMANDE';


----------------
--PRIMARY KEYS--
----------------
-- ALTER TABLE ONLY sinp_datatype_actors
--     ADD CONSTRAINT pk_sinp_datatype_actors PRIMARY KEY (id_actor);

ALTER TABLE ONLY sinp_datatype_protocols
    ADD CONSTRAINT pk_sinp_datatype_protocols PRIMARY KEY (id_protocol);

ALTER TABLE ONLY sinp_datatype_publications
    ADD CONSTRAINT pk_sinp_datatype_publications PRIMARY KEY (id_publication);

ALTER TABLE ONLY t_acquisition_frameworks
    ADD CONSTRAINT pk_t_acquisition_frameworks PRIMARY KEY (id_acquisition_framework);

ALTER TABLE ONLY cor_acquisition_framework_voletsinp
    ADD CONSTRAINT pk_cor_acquisition_framework_voletsinp PRIMARY KEY (id_acquisition_framework, id_nomenclature_voletsinp);

ALTER TABLE ONLY cor_acquisition_framework_objectif
    ADD CONSTRAINT pk_cor_acquisition_framework_objectif PRIMARY KEY (id_acquisition_framework, id_nomenclature_objectif);

ALTER TABLE ONLY cor_acquisition_framework_actor
    ADD CONSTRAINT pk_cor_acquisition_framework_actor PRIMARY KEY (id_cafa);

ALTER TABLE ONLY cor_acquisition_framework_actor
    ADD CONSTRAINT check_id_role_not_group CHECK (NOT gn_commons.role_is_group(id_role));

ALTER TABLE ONLY cor_acquisition_framework_publication
    ADD CONSTRAINT pk_cor_acquisition_framework_publication PRIMARY KEY (id_acquisition_framework, id_publication);


ALTER TABLE ONLY t_datasets
    ADD CONSTRAINT pk_t_datasets PRIMARY KEY (id_dataset);

ALTER TABLE ONLY cor_dataset_actor
    ADD CONSTRAINT pk_cor_dataset_actor PRIMARY KEY (id_cda);

ALTER TABLE ONLY cor_dataset_actor
    ADD CONSTRAINT check_id_role_not_group CHECK (NOT gn_commons.role_is_group(id_role));

ALTER TABLE ONLY cor_dataset_territory
    ADD CONSTRAINT pk_cor_dataset_territory PRIMARY KEY (id_dataset, id_nomenclature_territory);


ALTER TABLE ONLY cor_dataset_protocol
    ADD CONSTRAINT pk_cor_dataset_protocol PRIMARY KEY (id_dataset, id_protocol);

----------------
--FOREIGN KEYS--
----------------

ALTER TABLE ONLY cor_acquisition_framework_voletsinp
    ADD CONSTRAINT fk_cor_acquisition_framework_voletsinp_id_acquisition_framework FOREIGN KEY (id_acquisition_framework) REFERENCES t_acquisition_frameworks(id_acquisition_framework) ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE ONLY cor_acquisition_framework_voletsinp
    ADD CONSTRAINT fk_cor_acquisition_framework_voletsinp_id_nomenclature_voletsinp FOREIGN KEY (id_nomenclature_voletsinp) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;


ALTER TABLE ONLY cor_acquisition_framework_objectif
    ADD CONSTRAINT fk_cor_acquisition_framework_objectif_id_acquisition_framework FOREIGN KEY (id_acquisition_framework) REFERENCES t_acquisition_frameworks(id_acquisition_framework) ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE ONLY cor_acquisition_framework_objectif
    ADD CONSTRAINT fk_cor_acquisition_framework_objectif_id_nomenclature_objectif FOREIGN KEY (id_nomenclature_objectif) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;


ALTER TABLE ONLY cor_acquisition_framework_actor
    ADD CONSTRAINT fk_cor_acquisition_framework_actor_id_acquisition_framework FOREIGN KEY (id_acquisition_framework) REFERENCES t_acquisition_frameworks(id_acquisition_framework) ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE ONLY cor_acquisition_framework_actor
    ADD CONSTRAINT fk_cor_acquisition_framework_actor_id_role FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE ONLY cor_acquisition_framework_actor
    ADD CONSTRAINT fk_cor_acquisition_framework_actor_id_organism FOREIGN KEY (id_organism) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE ONLY cor_acquisition_framework_actor
    ADD CONSTRAINT fk_cor_acquisition_framework_actor_id_nomenclature_actor_role FOREIGN KEY (id_nomenclature_actor_role) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;


ALTER TABLE ONLY cor_acquisition_framework_publication
    ADD CONSTRAINT fk_cor_acquisition_framework_publication_id_acquisition_framework FOREIGN KEY (id_acquisition_framework) REFERENCES t_acquisition_frameworks(id_acquisition_framework) ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE ONLY cor_acquisition_framework_publication
    ADD CONSTRAINT fk_cor_acquisition_framework_publication_id_publication FOREIGN KEY (id_publication) REFERENCES sinp_datatype_publications(id_publication) ON UPDATE CASCADE ON DELETE NO ACTION;


ALTER TABLE ONLY t_datasets
    ADD CONSTRAINT fk_t_datasets_t_acquisition_frameworks FOREIGN KEY (id_acquisition_framework) REFERENCES t_acquisition_frameworks(id_acquisition_framework) ON UPDATE CASCADE;

ALTER TABLE ONLY t_datasets
    ADD CONSTRAINT fk_t_datasets_resource_type FOREIGN KEY (id_nomenclature_resource_type) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_datasets
    ADD CONSTRAINT fk_t_datasets_data_type FOREIGN KEY (id_nomenclature_data_type) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_datasets
    ADD CONSTRAINT fk_t_datasets_objectif FOREIGN KEY (id_nomenclature_dataset_objectif) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_datasets
    ADD CONSTRAINT fk_t_datasets_collecting_method FOREIGN KEY (id_nomenclature_collecting_method) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_datasets
    ADD CONSTRAINT fk_t_datasets_data_origin FOREIGN KEY (id_nomenclature_data_origin) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_datasets
    ADD CONSTRAINT fk_t_datasets_source_status FOREIGN KEY (id_nomenclature_source_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;


ALTER TABLE ONLY cor_dataset_actor
    ADD CONSTRAINT fk_cor_dataset_actor_id_dataset FOREIGN KEY (id_dataset) REFERENCES t_datasets(id_dataset) ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE ONLY cor_dataset_actor
    ADD CONSTRAINT fk_dataset_actor_id_role FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE ONLY cor_dataset_actor
    ADD CONSTRAINT fk_dataset_actor_id_organism FOREIGN KEY (id_organism) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE ONLY cor_dataset_actor
    ADD CONSTRAINT fk_cor_dataset_actor_id_nomenclature_actor_role FOREIGN KEY (id_nomenclature_actor_role) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_dataset_territory
    ADD CONSTRAINT fk_cor_dataset_territory_id_dataset FOREIGN KEY (id_dataset) REFERENCES t_datasets(id_dataset) ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE ONLY cor_dataset_territory
    ADD CONSTRAINT fk_cor_dataset_territory_id_nomenclature_territory FOREIGN KEY (id_nomenclature_territory) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_dataset_protocol
    ADD CONSTRAINT fk_cor_dataset_protocol_id_dataset FOREIGN KEY (id_dataset) REFERENCES t_datasets(id_dataset) ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE ONLY cor_dataset_protocol
    ADD CONSTRAINT fk_cor_dataset_protocol_id_protocol FOREIGN KEY (id_protocol) REFERENCES sinp_datatype_protocols(id_protocol) ON UPDATE CASCADE ON DELETE NO ACTION;



------------
--TRIGGERS--
------------
CREATE TRIGGER tri_meta_dates_change_t_datasets
  BEFORE INSERT OR UPDATE
  ON t_datasets
  FOR EACH ROW
  EXECUTE PROCEDURE public.fct_trg_meta_dates_change();

CREATE TRIGGER tri_meta_dates_change_t_acquisition_frameworks
  BEFORE INSERT OR UPDATE
  ON t_acquisition_frameworks
  FOR EACH ROW
  EXECUTE PROCEDURE public.fct_trg_meta_dates_change();


--------------
--CONSTRAINS--
--------------
ALTER TABLE t_datasets
  ADD CONSTRAINT check_t_datasets_resource_type CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_resource_type,'RESOURCE_TYP')) NOT VALID;

ALTER TABLE t_datasets
  ADD CONSTRAINT check_t_datasets_data_type CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_data_type,'DATA_TYP')) NOT VALID;

ALTER TABLE t_datasets
  ADD CONSTRAINT check_t_datasets_objectif CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_dataset_objectif,'JDD_OBJECTIFS')) NOT VALID;

ALTER TABLE t_datasets
  ADD CONSTRAINT check_t_datasets_collecting_method CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_collecting_method,'METHO_RECUEIL')) NOT VALID;

ALTER TABLE t_datasets
  ADD CONSTRAINT check_t_datasets_data_origin CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_data_origin,'DS_PUBLIQUE')) NOT VALID;

ALTER TABLE t_datasets
  ADD CONSTRAINT check_t_datasets_source_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_source_status,'STATUT_SOURCE')) NOT VALID;


ALTER TABLE t_acquisition_frameworks
  ADD CONSTRAINT check_t_acquisition_frameworks_territorial_level CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_territorial_level,'NIVEAU_TERRITORIAL')) NOT VALID;

ALTER TABLE t_acquisition_frameworks
  ADD CONSTRAINT check_t_acquisition_financing_type CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_financing_type,'TYPE_FINANCEMENT')) NOT VALID;


ALTER TABLE cor_acquisition_framework_voletsinp
  ADD CONSTRAINT check_cor_acquisition_framework_voletsinp CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_voletsinp,'VOLET_SINP')) NOT VALID;


ALTER TABLE cor_acquisition_framework_objectif
  ADD CONSTRAINT check_cor_acquisition_framework_objectif CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_objectif,'CA_OBJECTIFS')) NOT VALID;


ALTER TABLE cor_acquisition_framework_actor
  ADD CONSTRAINT check_cor_acquisition_framework_actor CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_actor_role,'ROLE_ACTEUR')) NOT VALID;

ALTER TABLE cor_acquisition_framework_actor
  ADD CONSTRAINT check_is_actor_in_cor_acquisition_framework_actor CHECK (id_role IS NOT NULL OR id_organism IS NOT NULL);

ALTER TABLE cor_acquisition_framework_actor
  ADD CONSTRAINT check_is_unique_cor_acquisition_framework_actor_role UNIQUE(id_acquisition_framework, id_role, id_nomenclature_actor_role);

ALTER TABLE cor_acquisition_framework_actor
  ADD CONSTRAINT check_is_unique_cor_acquisition_framework_actor_organism UNIQUE(id_acquisition_framework, id_organism, id_nomenclature_actor_role);


ALTER TABLE sinp_datatype_protocols
  ADD CONSTRAINT check_sinp_datatype_protocol_type CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_protocol_type,'TYPE_PROTOCOLE')) NOT VALID;


ALTER TABLE cor_dataset_actor
  ADD CONSTRAINT check_cor_dataset_actor CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_actor_role,'ROLE_ACTEUR')) NOT VALID;

ALTER TABLE cor_dataset_actor
  ADD CONSTRAINT check_is_actor_in_cor_dataset_actor CHECK (id_role IS NOT NULL OR id_organism IS NOT NULL);

ALTER TABLE cor_dataset_territory
  ADD CONSTRAINT check_cor_dataset_territory CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_territory,'TERRITOIRE')) NOT VALID;

ALTER TABLE cor_dataset_actor
  ADD CONSTRAINT check_is_unique_cor_dataset_actor_role UNIQUE(id_dataset, id_role, id_nomenclature_actor_role);

ALTER TABLE cor_dataset_actor
  ADD CONSTRAINT check_is_unique_cor_dataset_actor_organism UNIQUE(id_dataset, id_organism, id_nomenclature_actor_role);


---------
--INDEX--
---------


CREATE INDEX i_t_datasets_id_acquisition_framework
  ON gn_meta.t_datasets
  USING btree
  (id_acquisition_framework);

--------
--VIEW--
--------
CREATE OR REPLACE VIEW v_acquisition_frameworks_protocols AS
	SELECT d.id_acquisition_framework, cdp.id_protocol
	FROM gn_meta.t_acquisition_frameworks taf
	JOIN gn_meta.t_datasets d ON d.id_acquisition_framework = taf.id_acquisition_framework
	JOIN gn_meta.cor_dataset_protocol cdp ON cdp.id_dataset = d.id_dataset;


CREATE OR REPLACE VIEW v_acquisition_frameworks_territories AS
	SELECT d.id_acquisition_framework, cdt.id_nomenclature_territory, cdt.territory_desc
	FROM gn_meta.t_acquisition_frameworks taf
	JOIN gn_meta.t_datasets d ON d.id_acquisition_framework = taf.id_acquisition_framework
	JOIN gn_meta.cor_dataset_territory cdt ON cdt.id_dataset = d.id_dataset;




-------------
-- DATAS ----
-------------

INSERT INTO gn_commons.t_modules(module_code, module_label, module_picto, module_desc, module_path, module_target, active_frontend, active_backend, module_doc_url) VALUES
('METADATA', 'Metadonnées', 'fa-book', 'Module de gestion des métadonnées', 'metadata', '_self', TRUE, TRUE, 'https://geonature.readthedocs.io/fr/latest/user-manual.html#metadonnees')
;

-----------------------
--LINK WITH T_MODULES--
-----------------------
--Created here because gn_meta uses gn_commons (see above) and must be created after gn_commons
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

