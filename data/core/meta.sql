SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;


CREATE SCHEMA gn_meta;

SET search_path = gn_meta, pg_catalog;

SET default_with_oids = false;

-------------
--FUNCTIONS--
-------------
CREATE OR REPLACE FUNCTION get_default_parameter(myparamname text, myidorganisme int)
  RETURNS text AS
$BODY$
    DECLARE
        theparamvalue text; 
-- Function that allows to get value of a parameter depending on his name and organism
-- USAGE : SELECT gn_meta.get_default_parameter('taxref_version',NULL);
-- OR      SELECT gn_meta.get_default_parameter('uuid_url_value', 1);
  BEGIN
    IF myidorganisme IS NOT NULL THEN
      SELECT INTO theparamvalue parameter_value FROM gn_meta.t_parameters WHERE parameter_name = myparamname AND id_organism = myidorganisme LIMIT 1;
    ELSE
      SELECT INTO theparamvalue parameter_value FROM gn_meta.t_parameters WHERE parameter_name = myparamname LIMIT 1;
    END IF;
    RETURN theparamvalue;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;


----------
--TABLES--
----------
CREATE TABLE t_parameters (
    id_parameter integer NOT NULL,
    id_organism integer,
    parameter_name character varying(100) NOT NULL,
    parameter_desc text,
    parameter_value text NOT NULL,
    parameter_extra_value character varying(255)
);
COMMENT ON TABLE t_parameters IS 'Allow to manage content configuration depending on organism or not (CRUD depending on privileges).';


CREATE TABLE sinp_datatype_actors (
    id_actor integer NOT NULL,
    actor_organism character varying(255),
    actor_fullname character varying(255),
    actor_mail character varying(255)
);
COMMENT ON TABLE sinp_datatype_actors IS 'Define a SINP datatype Types::ActeurType.';
COMMENT ON COLUMN sinp_datatype_actors.id_actor IS 'Internal value for primary and foreign keys';
COMMENT ON COLUMN sinp_datatype_actors.actor_organism IS 'Correspondance standard SINP = organisme :Exemple : Muséum National d''Histoire Naturelle (MNHN) - OBLIGATOIRE CONDITIONNEL : il DOIT être rempli si nomPrenom n''est pas rempli';
COMMENT ON COLUMN sinp_datatype_actors.actor_fullname IS 'Correspondance standard SINP = nomPrenom : Nom et prénom de la personne à contacter. (Sous la forme NOM Prénom) - OBLIGATOIRE CONDITIONNEL : il DOIT être rempli si organisme n''est pas rempli';
COMMENT ON COLUMN sinp_datatype_actors.actor_mail IS 'Correspondance standard SINP = mail : Adresse mail de contact - RECOMMANDE.';

CREATE TABLE sinp_datatype_protocols (
    id_protocol integer NOT NULL,
    protocol_name character varying(255) NOT NULL,
    protocol_desc character varying(255),
    id_nomenclature_protocol_type integer NOT NULL,
    protocol_url character varying(255)
);
COMMENT ON TABLE sinp_datatype_protocols IS 'Define a SINP datatype Types::ProtocoleType.';
COMMENT ON COLUMN sinp_datatype_protocols.id_protocol IS 'Internal value for primary and foreign keys';
COMMENT ON COLUMN sinp_datatype_protocols.protocol_name IS 'Correspondance standard SINP = libelle :Libellé du protocole : donne le nom du protocole en quelques mots - OBLIGATOIRE';
COMMENT ON COLUMN sinp_datatype_protocols.protocol_desc IS 'Correspondance standard SINP = description : Description du protocole : décrit le contenu du protocole - FACULTATIF.';
COMMENT ON COLUMN sinp_datatype_protocols.id_nomenclature_protocol_type IS 'Correspondance standard SINP = typeProtocole : Type du protocole, tel que défini dans la nomenclature TypeProtocoleValue - OBLIGATOIRE';
COMMENT ON COLUMN sinp_datatype_protocols.protocol_url IS 'Correspondance standard SINP = uRL : URL d''accès à un document permettant de décrire le protocole - RECOMMANDE.';


CREATE TABLE sinp_datatype_publications (
    id_publication integer NOT NULL,
    publication_reference text NOT NULL,
    publication_url text
);
COMMENT ON TABLE sinp_datatype_publications IS 'Define a SINP datatype Concepts::Publication.';
COMMENT ON COLUMN sinp_datatype_publications.id_publication IS 'Internal value for primary and foreign keys';
COMMENT ON COLUMN sinp_datatype_publications.publication_reference IS 'Correspondance standard SINP = referencePublication : Référence complète de la publication suivant la nomenclature ISO 690 - OBLIGATOIRE';
COMMENT ON COLUMN sinp_datatype_publications.protocol_url IS 'Correspondance standard SINP = URLPublication : Adresse à laquelle trouver la publication - RECOMMANDE.';


CREATE TABLE t_acquisition_frameworks (
    id_acquisition_framework integer NOT NULL,
    unique_acquisition_framework_id uuid NOT NULL DEFAULT public.uuid_generate_v4(),
    acquisition_framework_name character varying(255) NOT NULL,
    acquisition_framework_desc text NOT NULL,
    id_nomenclature_territorial_level integer,
    territory_desc text,
    keywords text,
    id_nomenclature_financing_type integer,
    target_description text,
    ecologic_or_geologic_target text,
    acquisition_framework_parent_id integer,
    is_parent integer,
    acquisition_framework_start_date date NOT NULL,
    acquisition_framework_end_date date,
    meta_create_date timestamp without time zon NOT NULL,
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


CREATE TABLE cor_acquisition_framework_territory (
    id_acquisition_framework integer NOT NULL,
    id_nomenclature_territory integer NOT NULL,
    territory_desc text,
);
COMMENT ON TABLE cor_acquisition_framework_territory IS 'A acquisition framework can have 1 or n "territoire". Implement 1.3.8 SINP metadata standard : Territoire(s) visé(s) par le cadre d''acquisition, tel(s) que défini(s) par la nomenclature TerritoireValue - OBLIGATOIRE';
COMMENT ON COLUMN cor_acquisition_framework_territory.territory_desc IS 'Correspondance standard SINP = precisionGeographique : Précisions sur le territoire visé - FACULTATIF';


CREATE TABLE cor_acquisition_framework_actor (
    id_acquisition_framework integer NOT NULL,
    id_actor integer NOT NULL,
    id_nomenclature_actor_role integer NOT NULL
);
COMMENT ON TABLE cor_acquisition_framework_actor IS 'A acquisition framework must have a principal actor "acteurPrincipal" and can have 0 or n other actor "acteurAutre". Implement 1.3.8 SINP metadata standard : Contact principal pour le cadre d''acquisition (Règle : RoleActeur prendra la valeur 1) - OBLIGATOIRE. Autres contacts pour le cadre d''acquisition (exemples : maître d''oeuvre, d''ouvrage...).- RECOMMANDE';
COMMENT ON COLUMN cor_acquisition_framework_actor.id_nomenclature_actor_role IS 'Correspondance standard SINP = roleActeur : Rôle de l''acteur tel que défini dans la nomenclature RoleActeurValue - OBLIGATOIRE';


CREATE TABLE cor_acquisition_framework_publication (
    id_acquisition_framework integer NOT NULL,
    id_publication integer NOT NULL
);
COMMENT ON TABLE cor_acquisition_framework_publication IS 'A acquisition framework can have 0 or n "publication". Implement 1.3.8 SINP metadata standard : Référence(s) bibliographique(s) éventuelle(s) concernant le cadre d''acquisition - RECOMMANDE';


CREATE TABLE cor_acquisition_framework_protocol (
    id_acquisition_framework integer NOT NULL,
    id_protocol integer NOT NULL
);
COMMENT ON TABLE cor_acquisition_framework_protocol IS 'A acquisition framework can have 0 or n "protocole". Implement 1.3.8 SINP metadata standard : Protocole(s) éventuel(s) pour le cadre d''acquisition et/ou sa fiche de métadonnées. Contient le type "ProtocoleType" autant de fois que nécessaire - RECOMMANDE';


CREATE TABLE cor_role_privilege_entity (
    id_role integer NOT NULL,
    id_privilege integer NOT NULL,
    entity_name character varying(255) NOT NULL
);
COMMENT ON TABLE cor_role_privilege_entity IS 'Allow to manage privileges of a group or user on entities (tables) into backoffice (CRUD depending on privileges).';


CREATE TABLE cor_role_dataset_application (
    id_role integer NOT NULL,
    id_dataset integer NOT NULL,
    id_application integer NOT NULL
);
COMMENT ON TABLE cor_role_dataset_application IS 'Allow to identify for each GeoNature module (1 module = 1 application in UsersHub) among which dataset connected user can create observations. Reminder : A dataset is a dataset or a survey and each observation is attached to a dataset. GeoNature V2 backoffice allows to manage datasets.';


CREATE TABLE t_datasets (
    id_dataset integer NOT NULL,
    dataset_name character varying(255),
    dataset_desc text,
    id_program integer NOT NULL,
    id_organism_owner integer NOT NULL,
    id_organism_producer integer NOT NULL,
    id_organism_administrator integer NOT NULL,
    id_organism_funder integer NOT NULL,
    public_data boolean DEFAULT true NOT NULL,
    default_validity boolean,
    id_nomenclature_resource_type integer NOT NULL DEFAULT 351,
    id_nomenclature_data_type integer NOT NULL DEFAULT 353,
    ecologic_group  character varying(50),
    id_nomenclature_sampling_plan_type integer NOT NULL,
    id_nomenclature_sampling_units_type integer NOT NULL,
    meta_create_date timestamp without time zone,
    meta_update_date timestamp without time zone
);
COMMENT ON TABLE t_datasets IS 'A dataset is a dataset or a survey and each observation is attached to a dataset. A lot allows to qualify datas to which it is attached (producer, owner, manager, gestionnaire, financer, public data yes/no). A dataset can be attached to a program. GeoNature V2 backoffice allows to manage datasets.';


CREATE TABLE t_programs (
    id_program integer NOT NULL,
    program_name character varying(255),
    program_desc text,
    active boolean
);
COMMENT ON TABLE t_programs IS 'Programs are general objects that can embed datasets and/or protocols. Example : ATBI, raptors, action national plan, etc... GeoNature V2 backoffice allows to manage datasets.';


----------------
--PRIMARY KEYS--
----------------
ALTER TABLE ONLY t_parameters
    ADD CONSTRAINT pk_t_parameters PRIMARY KEY (id_parameter);

ALTER TABLE ONLY sinp_datatype_actors
    ADD CONSTRAINT pk_sinp_datatype_actors PRIMARY KEY (id_actor);

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

ALTER TABLE ONLY cor_acquisition_framework_territory
    ADD CONSTRAINT pk_cor_acquisition_framework_territory PRIMARY KEY (id_acquisition_framework, id_nomenclature_territory);

ALTER TABLE ONLY cor_acquisition_framework_actor
    ADD CONSTRAINT pk_cor_acquisition_framework_actor PRIMARY KEY (id_acquisition_framework, id_actor, id_nomenclature_actor_role);

ALTER TABLE ONLY cor_acquisition_framework_publication
    ADD CONSTRAINT pk_cor_acquisition_framework_publication PRIMARY KEY (id_acquisition_framework, id_publication);

ALTER TABLE ONLY cor_acquisition_framework_protocol
    ADD CONSTRAINT pk_cor_acquisition_framework_protocol PRIMARY KEY (id_acquisition_framework, id_protocol);

ALTER TABLE ONLY cor_role_privilege_entity
    ADD CONSTRAINT pk_cor_role_privilege_entity PRIMARY KEY (id_role, id_privilege, entity_name);

ALTER TABLE ONLY cor_role_dataset_application
    ADD CONSTRAINT pk_cor_role_dataset_application PRIMARY KEY (id_role, id_dataset, id_application);

ALTER TABLE ONLY t_datasets
    ADD CONSTRAINT pk_t_datasets PRIMARY KEY (id_dataset);

ALTER TABLE ONLY t_programs
    ADD CONSTRAINT pk_t_programs PRIMARY KEY (id_program);


----------------
--FOREIGN KEYS--
----------------
ALTER TABLE ONLY t_parameters
    ADD CONSTRAINT fk_t_parameters_bib_organismes FOREIGN KEY (id_organism) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE ON DELETE NO ACTION;


ALTER TABLE ONLY cor_acquisition_framework_voletsinp
    ADD CONSTRAINT fk_cor_acquisition_framework_voletsinp_id_acquisition_framework FOREIGN KEY (id_acquisition_framework) REFERENCES t_acquisition_frameworks(id_acquisition_framework) ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE ONLY cor_acquisition_framework_voletsinp
    ADD CONSTRAINT fk_cor_acquisition_framework_voletsinp_id_nomenclature_voletsinp FOREIGN KEY (id_nomenclature_voletsinp) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;


ALTER TABLE ONLY cor_acquisition_framework_objectif
    ADD CONSTRAINT fk_cor_acquisition_framework_objectif_id_acquisition_framework FOREIGN KEY (id_acquisition_framework) REFERENCES t_acquisition_frameworks(id_acquisition_framework) ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE ONLY cor_acquisition_framework_objectif
    ADD CONSTRAINT fk_cor_acquisition_framework_objectif_id_nomenclature_objectif FOREIGN KEY (id_nomenclature_objectif) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;


ALTER TABLE ONLY cor_acquisition_framework_territory
    ADD CONSTRAINT fk_cor_acquisition_framework_territory_id_acquisition_framework FOREIGN KEY (id_acquisition_framework) REFERENCES t_acquisition_frameworks(id_acquisition_framework) ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE ONLY cor_acquisition_framework_territory
    ADD CONSTRAINT fk_cor_acquisition_framework_territory_id_nomenclature_territory FOREIGN KEY (id_nomenclature_territory) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;


ALTER TABLE ONLY cor_acquisition_framework_actor
    ADD CONSTRAINT fk_cor_acquisition_framework_actor_id_acquisition_framework FOREIGN KEY (id_acquisition_framework) REFERENCES t_acquisition_frameworks(id_acquisition_framework) ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE ONLY cor_acquisition_framework_actor
    ADD CONSTRAINT fk_cor_acquisition_framework_actor_id_actor FOREIGN KEY (id_actor) REFERENCES sinp_datatype_actors(id_actor) ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE ONLY cor_acquisition_framework_actor
    ADD CONSTRAINT fk_cor_acquisition_framework_actor_id_nomenclature_actor_role FOREIGN KEY (id_nomenclature_actor_role) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;


ALTER TABLE ONLY cor_acquisition_framework_publication
    ADD CONSTRAINT fk_cor_acquisition_framework_publication_id_acquisition_framework FOREIGN KEY (id_acquisition_framework) REFERENCES t_acquisition_frameworks(id_acquisition_framework) ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE ONLY cor_acquisition_framework_publication
    ADD CONSTRAINT fk_cor_acquisition_framework_publication_id_publication FOREIGN KEY (id_publication) REFERENCES sinp_datatype_publications(id_publication) ON UPDATE CASCADE ON DELETE NO ACTION;


ALTER TABLE ONLY cor_acquisition_framework_protocol
    ADD CONSTRAINT fk_cor_acquisition_framework_protocol_id_acquisition_framework FOREIGN KEY (id_acquisition_framework) REFERENCES t_acquisition_frameworks(id_acquisition_framework) ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE ONLY cor_acquisition_framework_protocol
    ADD CONSTRAINT fk_cor_acquisition_framework_protocol_id_publication FOREIGN KEY (id_protocol) REFERENCES sinp_datatype_protocols(id_protocol) ON UPDATE CASCADE ON DELETE NO ACTION;


ALTER TABLE ONLY cor_role_privilege_entity
    ADD CONSTRAINT fk_cor_role_droit_application_id_privilege FOREIGN KEY (id_privilege) REFERENCES utilisateurs.bib_droits(id_droit) ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE ONLY cor_role_privilege_entity
    ADD CONSTRAINT fk_cor_role_privilege_entity_t_roles FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE NO ACTION;


ALTER TABLE ONLY cor_role_dataset_application
    ADD CONSTRAINT fk_cor_role_droit_application_id_role FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE ONLY cor_role_dataset_application
    ADD CONSTRAINT fk_cor_role_dataset_application_id_application FOREIGN KEY (id_application) REFERENCES utilisateurs.t_applications(id_application) ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE ONLY cor_role_dataset_application
    ADD CONSTRAINT fk_cor_role_dataset_application_id_privilege FOREIGN KEY (id_dataset) REFERENCES t_datasets(id_dataset) ON UPDATE CASCADE ON DELETE NO ACTION;


ALTER TABLE ONLY t_datasets
    ADD CONSTRAINT fk_t_datasets_financeur FOREIGN KEY (id_organism_funder) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY t_datasets
    ADD CONSTRAINT fk_t_datasets_gestionnaire FOREIGN KEY (id_organism_administrator) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY t_datasets
    ADD CONSTRAINT fk_t_datasets_producteur FOREIGN KEY (id_organism_producer) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY t_datasets
    ADD CONSTRAINT fk_t_datasets_proprietaire FOREIGN KEY (id_organism_owner) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY t_datasets
    ADD CONSTRAINT fk_t_datasets_t_programs FOREIGN KEY (id_program) REFERENCES t_programs(id_program) ON UPDATE CASCADE;

ALTER TABLE ONLY t_datasets
    ADD CONSTRAINT fk_t_datasets_resource_type FOREIGN KEY (id_nomenclature_resource_type) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_datasets
    ADD CONSTRAINT fk_t_datasets_data_type FOREIGN KEY (id_nomenclature_data_type) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_datasets
    ADD CONSTRAINT fk_t_datasets_sampling_plan_type FOREIGN KEY (id_nomenclature_sampling_plan_type) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_datasets
    ADD CONSTRAINT fk_t_datasets_sampling_units_type FOREIGN KEY (id_nomenclature_sampling_units_type) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;



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
  ADD CONSTRAINT check_t_datasets_resource_type CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_resource_type,102));

ALTER TABLE t_datasets
  ADD CONSTRAINT check_t_datasets_data_type CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_data_type,103));

ALTER TABLE t_datasets
  ADD CONSTRAINT check_t_datasets_sampling_plan_type CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_sampling_plan_type,104));

ALTER TABLE t_datasets
  ADD CONSTRAINT check_t_datasets_sampling_units_type CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_sampling_units_type,105));

ALTER TABLE t_datasets
  ADD CONSTRAINT check_t_datasets_sampling_units_type CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_sampling_units_type,105));


ALTER TABLE t_acquisition_frameworks
  ADD CONSTRAINT check_t_acquisition_frameworks_territorial_level CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_territorial_level,107));

ALTER TABLE t_acquisition_frameworks
  ADD CONSTRAINT check_t_acquisition_financing_type CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_financing_type,111));


ALTER TABLE cor_acquisition_framework_voletsinp
  ADD CONSTRAINT check_cor_acquisition_framework_voletsinp CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_voletsinp,113));


ALTER TABLE cor_acquisition_framework_objectif
  ADD CONSTRAINT check_cor_acquisition_framework_objectif CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_objectif,108));


ALTER TABLE cor_acquisition_framework_territory
  ADD CONSTRAINT check_cor_acquisition_framework_territory CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_territory,110));


ALTER TABLE cor_acquisition_framework_objectif
  ADD CONSTRAINT check_cor_acquisition_framework_objectif CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_objectif,108));


ALTER TABLE cor_acquisition_framework_actor
  ADD CONSTRAINT check_cor_acquisition_framework_actor CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_actor_role,109));


ALTER TABLE sinp_datatype_protocols
  ADD CONSTRAINT check_sinp_datatype_protocol_type CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_protocol_type,112));


---------------
--SAMPLE DATA--
---------------
INSERT INTO t_programs VALUES (1, 'contact', 'programme contact aléatoire de la faune, de la flore ou de la fonge', true);
INSERT INTO t_programs VALUES (2, 'test', 'test', false);

INSERT INTO t_parameters (id_parameter, id_organism, parameter_name, parameter_desc, parameter_value, parameter_extra_value) VALUES
(1,NULL,'taxref_version','Version du référentiel taxonomique','Taxref V9.0',NULL)
,(2,2,'uuid_url_value','Valeur de l''identifiant unique SINP pour l''organisme Parc national des Ecrins','http://ecrins-parcnational.fr/data/',NULL)
,(3,1,'uuid_url_value','Valeur de l''identifiant unique SINP pour l''organisme Parc nationaux de France','http://parcnational.fr/data/',NULL)
,(4,NULL,'local_srid','Valeur du SRID local','2154',NULL)
,(5,NULL,'annee_ref_commune', 'Annéee du référentiel géographique des communes utilisé', '2017', NULL);

--TODO : insert sample data in "t_acquisition_frameworks" and is correlation TABLE
--TESTING instal_db.sh