SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;


-----------------------
--PUBLIQUES FUNCTIONS--
-----------------------
CREATE OR REPLACE FUNCTION public.fct_trg_meta_dates_change()
  RETURNS trigger AS
$BODY$
begin
        if(TG_OP = 'INSERT') THEN
                NEW.meta_create_date = NOW();
        ELSIF(TG_OP = 'UPDATE') THEN
                NEW.meta_update_date = NOW();
                if(NEW.meta_create_date IS NULL) THEN
                        NEW.meta_create_date = NOW();
                END IF;
        end IF;
        return NEW;
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

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
--fonction permettant de récupérer la valeur d'un paramètre selon son nom et l'organisme
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


---------------
--PRIMARY KEY--
---------------
ALTER TABLE ONLY t_parameters
    ADD CONSTRAINT pk_t_parameters PRIMARY KEY (id_parameter);

ALTER TABLE ONLY cor_role_privilege_entity
    ADD CONSTRAINT pk_cor_role_privilege_entity PRIMARY KEY (id_role, id_privilege, entity_name);

ALTER TABLE ONLY cor_role_dataset_application
    ADD CONSTRAINT pk_cor_role_dataset_application PRIMARY KEY (id_role, id_dataset, id_application);

ALTER TABLE ONLY t_datasets
    ADD CONSTRAINT pk_t_datasets PRIMARY KEY (id_dataset);

ALTER TABLE ONLY t_programs
    ADD CONSTRAINT pk_t_programs PRIMARY KEY (id_program);


---------------
--FOREIGN KEY--
---------------
ALTER TABLE ONLY t_parameters
    ADD CONSTRAINT fk_t_parameters_bib_organismes FOREIGN KEY (id_organism) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE ON DELETE NO ACTION;

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
    ADD CONSTRAINT fk_t_datasets_financeur FOREIGN KEY (id_organism_funder) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE NO ACTION;

ALTER TABLE ONLY t_datasets
    ADD CONSTRAINT fk_t_datasets_gestionnaire FOREIGN KEY (id_organism_administrator) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE NO ACTION;

ALTER TABLE ONLY t_datasets
    ADD CONSTRAINT fk_t_datasets_producteur FOREIGN KEY (id_organism_producer) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE NO ACTION;

ALTER TABLE ONLY t_datasets
    ADD CONSTRAINT fk_t_datasets_proprietaire FOREIGN KEY (id_organism_owner) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE NO ACTION;

ALTER TABLE ONLY t_datasets
    ADD CONSTRAINT fk_t_datasets_t_programs FOREIGN KEY (id_program) REFERENCES t_programs(id_program) ON UPDATE NO ACTION;


------------
--TRIGGERS--
------------
CREATE TRIGGER tri_meta_dates_change_t_datasets
  BEFORE INSERT OR UPDATE
  ON t_datasets
  FOR EACH ROW
  EXECUTE PROCEDURE public.fct_trg_meta_dates_change();


---------
--DATAS--
---------
INSERT INTO t_programs VALUES (1, 'contact', 'programme contact aléatoire de la faune, de la flore ou de la fonge', true);
INSERT INTO t_programs VALUES (2, 'test', 'test', false);

INSERT INTO t_parameters (id_parameter, id_organism, parameter_name, parameter_desc, parameter_value, parameter_extra_value) VALUES
(1,NULL,'taxref_version','version du référentiel taxonomique','Taxref V9.0',NULL)
,(2,2,'uuid_url_value','valeur de l''identifiant unique SINP pour l''organisme Parc national des Ecrins','http://ecrins-parcnational.fr/data/',NULL)
,(3,1,'uuid_url_value','valeur de l''identifiant unique SINP pour l''organisme Parc nationaux de France','http://parcnational.fr/data/',NULL);
,(4,1,'local_srid','valeur du srid local','2154',NULL);
