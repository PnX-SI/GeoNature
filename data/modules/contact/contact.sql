SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
--SET row_security = off;


CREATE SCHEMA contact;


SET search_path = contact, pg_catalog;
SET default_with_oids = false;

------------------------
--TABLES AND SEQUENCES--
------------------------

CREATE TABLE t_obs_contact (
    id_obs_contact bigint NOT NULL,
    id_lot integer NOT NULL,
    id_nomenclature_technique_obs integer NOT NULL DEFAULT 343,
    id_numerisateur integer,
    date_min date NOT NULL,
    date_max date NOT NULL,
    heure_obs integer,
    insee character(5),
    altitude_min integer,
    altitude_max integer,
    saisie_initiale character varying(20),
    supprime boolean DEFAULT false NOT NULL,
    date_insert timestamp without time zone DEFAULT now(),
    date_update timestamp without time zone DEFAULT now(),
    contexte_obs text,
    commentaire text,
    the_geom_local public.geometry(Geometry,MYLOCALSRID),
    the_geom_3857 public.geometry(Geometry,3857),
    CONSTRAINT enforce_dims_the_geom_3857 CHECK ((public.st_ndims(the_geom_3857) = 2)),
    CONSTRAINT enforce_dims_the_geom_local CHECK ((public.st_ndims(the_geom_local) = 2)),
    CONSTRAINT enforce_srid_the_geom_3857 CHECK ((public.st_srid(the_geom_3857) = 3857)),
    CONSTRAINT enforce_srid_the_geom_local CHECK ((public.st_srid(the_geom_local) = MYLOCALSRID))
);

CREATE SEQUENCE t_obs_contact_id_obs_contact_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE t_obs_contact_id_obs_contact_seq OWNED BY t_obs_contact.id_obs_contact;
ALTER TABLE ONLY t_obs_contact ALTER COLUMN id_obs_contact SET DEFAULT nextval('t_obs_contact_id_obs_contact_seq'::regclass);
SELECT pg_catalog.setval('t_obs_contact_id_obs_contact_seq', 1, false);


CREATE TABLE t_occurrences_contact (
    id_occurrence_contact bigint NOT NULL,
    id_obs_contact bigint NOT NULL,
    id_nomenclature_meth_obs integer DEFAULT 42,
    id_nomenclature_eta_bio integer NOT NULL DEFAULT 177,
    id_nomenclature_statut_bio integer DEFAULT 30,
    id_nomenclature_naturalite integer DEFAULT 182,
    id_nomenclature_preuve_exist integer DEFAULT 91,
    id_nomenclature_statut_obs integer DEFAULT 101,
    id_nomenclature_statut_valid integer DEFAULT 347,
    id_nomenclature_niv_precis integer DEFAULT 163,
    id_valideur integer,
    determinateur character varying(255),
    methode_determination character varying(255),
    cd_nom integer,
    nom_cite character varying(255),
    v_taxref character varying(6) DEFAULT 'V9.0',
    num_prelevement_contact text,
    preuve_numerique text,
    preuve_non_numerique text,
    supprime boolean DEFAULT false NOT NULL,
    date_insert timestamp without time zone,
    date_update timestamp without time zone,
    commentaire character varying
);

CREATE SEQUENCE t_occurrences_contact_id_occurrence_contact_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE t_occurrences_contact_id_occurrence_contact_seq OWNED BY t_occurrences_contact.id_occurrence_contact;
ALTER TABLE ONLY t_occurrences_contact ALTER COLUMN id_occurrence_contact SET DEFAULT nextval('t_occurrences_contact_id_occurrence_contact_seq'::regclass);
SELECT pg_catalog.setval('t_occurrences_contact_id_occurrence_contact_seq', 1, false);


CREATE TABLE cor_stade_sexe_effectif (
    id_occurrence_contact bigint NOT NULL,
    id_nomenclature_stade_vie integer NOT NULL,
    id_nomenclature_sexe integer NOT NULL,
    id_nomenclature_obj_denbr integer NOT NULL DEFAULT 166,
    id_nomenclature_typ_denbr integer DEFAULT 107,
    denombrement_min integer,
    denombrement_max integer
);


CREATE TABLE cor_role_obs_contact (
    id_obs_contact bigint NOT NULL,
    id_role integer NOT NULL
);


---------------
--PRIMARY KEY--
---------------
ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT pk_t_occurrences_contact PRIMARY KEY (id_occurrence_contact);

ALTER TABLE ONLY t_obs_contact
    ADD CONSTRAINT pk_t_obs_contact PRIMARY KEY (id_obs_contact);

ALTER TABLE ONLY cor_stade_sexe_effectif
    ADD CONSTRAINT pk_cor_stade_sexe_effectif_contact PRIMARY KEY (id_occurrence_contact, id_nomenclature_stade_vie, id_nomenclature_sexe);

ALTER TABLE ONLY cor_role_obs_contact
    ADD CONSTRAINT pk_cor_role_obs_contact PRIMARY KEY (id_obs_contact, id_role);


---------------
--FOREIGN KEY--
---------------
ALTER TABLE ONLY t_obs_contact
    ADD CONSTRAINT fk_t_obs_contact_t_lots FOREIGN KEY (id_lot) REFERENCES meta.t_lots(id_lot) ON UPDATE CASCADE;

ALTER TABLE ONLY t_obs_contact
    ADD CONSTRAINT fk_t_obs_contact_technique_obs FOREIGN KEY (id_nomenclature_technique_obs) REFERENCES nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_obs_contact
    ADD CONSTRAINT fk_t_obs_contact_t_roles FOREIGN KEY (id_numerisateur) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;


ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT fk_t_occurrences_contact_t_obs_contact FOREIGN KEY (id_obs_contact) REFERENCES t_obs_contact(id_obs_contact) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT fk_t_occurrences_contact_t_roles FOREIGN KEY (id_valideur) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT fk_t_occurrences_contact_taxref FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT fk_t_occurrences_contact_meth_obs FOREIGN KEY (id_nomenclature_meth_obs) REFERENCES nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT fk_t_occurrences_contact_eta_bio FOREIGN KEY (id_nomenclature_eta_bio) REFERENCES nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT fk_t_occurrences_contact_statut_bio FOREIGN KEY (id_nomenclature_statut_bio) REFERENCES nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT fk_t_occurrences_contact_naturalite FOREIGN KEY (id_nomenclature_naturalite) REFERENCES nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT fk_t_occurrences_contact_preuve_exist FOREIGN KEY (id_nomenclature_preuve_exist) REFERENCES nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT fk_t_occurrences_contact_statut_obs FOREIGN KEY (id_nomenclature_statut_obs) REFERENCES nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT fk_t_occurrences_contact_statut_valid FOREIGN KEY (id_nomenclature_statut_valid) REFERENCES nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT fk_t_occurrences_contact_niv_precis FOREIGN KEY (id_nomenclature_niv_precis) REFERENCES nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;


ALTER TABLE ONLY cor_stade_sexe_effectif
    ADD CONSTRAINT fk_cor_stade_effectif_id_taxon FOREIGN KEY (id_occurrence_contact) REFERENCES t_occurrences_contact(id_occurrence_contact) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_stade_sexe_effectif
    ADD CONSTRAINT fk_cor_stade_sexe_effectif_sexe FOREIGN KEY (id_nomenclature_sexe) REFERENCES nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_stade_sexe_effectif
    ADD CONSTRAINT fk_cor_stade_sexe_effectif_stade_vie FOREIGN KEY (id_nomenclature_stade_vie) REFERENCES nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_stade_sexe_effectif
    ADD CONSTRAINT fk_cor_stade_sexe_effectif_obj_denbr FOREIGN KEY (id_nomenclature_obj_denbr) REFERENCES nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_stade_sexe_effectif
    ADD CONSTRAINT fk_cor_stade_sexe_effectif_typ_denbr FOREIGN KEY (id_nomenclature_typ_denbr) REFERENCES nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;


ALTER TABLE ONLY cor_role_obs_contact
    ADD CONSTRAINT fk_cor_role_obs_contact_t_obs_contact FOREIGN KEY (id_obs_contact) REFERENCES t_obs_contact(id_obs_contact) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_role_obs_contact
    ADD CONSTRAINT fk_cor_role_obs_contact_t_roles FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

--------------
--CONSTRAINS--
--------------
ALTER TABLE ONLY t_obs_contact
    ADD CONSTRAINT check_t_obs_contact_altitude_max CHECK (altitude_max >= altitude_min);

ALTER TABLE ONLY t_obs_contact
    ADD CONSTRAINT check_t_obs_contact_date_max CHECK (date_max >= date_min);

ALTER TABLE t_obs_contact
  ADD CONSTRAINT check_t_obs_contact_technique_obs CHECK (nomenclatures.check_type_nomenclature(id_nomenclature_technique_obs,100));


ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT check_t_occurrences_contact_cd_nom_isinbib_noms CHECK (taxonomie.check_is_inbibnoms(cd_nom));

ALTER TABLE t_occurrences_contact
  ADD CONSTRAINT check_t_obs_contact_meth_obs CHECK (nomenclatures.check_type_nomenclature(id_nomenclature_meth_obs,14));

ALTER TABLE t_occurrences_contact
  ADD CONSTRAINT check_t_occurrences_contact_eta_bio CHECK (nomenclatures.check_type_nomenclature(id_nomenclature_eta_bio,7));

ALTER TABLE t_occurrences_contact
  ADD CONSTRAINT check__occurrences_contact_statut_bio CHECK (nomenclatures.check_type_nomenclature(id_nomenclature_statut_bio,13));

ALTER TABLE t_occurrences_contact
  ADD CONSTRAINT check__occurrences_contact_naturalite CHECK (nomenclatures.check_type_nomenclature(id_nomenclature_naturalite,8));

ALTER TABLE t_occurrences_contact
  ADD CONSTRAINT check__occurrences_contact_preuve_exist CHECK (nomenclatures.check_type_nomenclature(id_nomenclature_preuve_exist,15));

ALTER TABLE t_occurrences_contact
  ADD CONSTRAINT check__occurrences_contact_statut_obs CHECK (nomenclatures.check_type_nomenclature(id_nomenclature_statut_obs,18));

ALTER TABLE t_occurrences_contact
  ADD CONSTRAINT check__occurrences_contact_statut_valid CHECK (nomenclatures.check_type_nomenclature(id_nomenclature_statut_valid,101));

ALTER TABLE t_occurrences_contact
  ADD CONSTRAINT check__occurrences_contact_niv_precis CHECK (nomenclatures.check_type_nomenclature(id_nomenclature_niv_precis,5));


ALTER TABLE cor_stade_sexe_effectif
  ADD CONSTRAINT check_t_obs_contact_stade_vie CHECK (nomenclatures.check_type_nomenclature(id_nomenclature_stade_vie,10));

ALTER TABLE cor_stade_sexe_effectif
  ADD CONSTRAINT check_t_obs_contact_sexe CHECK (nomenclatures.check_type_nomenclature(id_nomenclature_sexe,9));

ALTER TABLE cor_stade_sexe_effectif
  ADD CONSTRAINT check_t_obs_contact_obj_denbr CHECK (nomenclatures.check_type_nomenclature(id_nomenclature_obj_denbr,6));

ALTER TABLE cor_stade_sexe_effectif
  ADD CONSTRAINT check_t_obs_contact_typ_denbr CHECK (nomenclatures.check_type_nomenclature(id_nomenclature_typ_denbr,21));


----------------------
--FUNCTIONS TRIGGERS--
----------------------
CREATE OR REPLACE FUNCTION insert_occurrences_contact()
  RETURNS trigger AS
$BODY$
DECLARE
    idsensibilite integer;
BEGIN
    --calcul de la valeur de la sensibilité
    SELECT INTO idsensibilite nomenclatures.calcul_sensibilite(new.cd_nom,new.id_nomenclature_meth_obs);
    new.id_nomenclature_niv_precis = idsensibilite;
    RETURN NEW;             
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION update_occurrences_contact()
  RETURNS trigger AS
$BODY$
DECLARE
    idsensibilite integer;
BEGIN
    --calcul de la valeur de la sensibilité
    SELECT INTO idsensibilite nomenclatures.calcul_sensibilite(new.cd_nom,new.id_nomenclature_meth_obs);
    new.id_nomenclature_niv_precis = idsensibilite;
    RETURN NEW;             
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


------------
--TRIGGERS--
------------
CREATE TRIGGER tri_insert_occurrences_contact
  BEFORE INSERT
  ON t_occurrences_contact
  FOR EACH ROW
  EXECUTE PROCEDURE insert_occurrences_contact();

CREATE TRIGGER tri_update_occurrences_contact
  BEFORE INSERT
  ON t_occurrences_contact
  FOR EACH ROW
  EXECUTE PROCEDURE update_occurrences_contact();


---------
--DATAS--
---------

INSERT INTO meta.t_lots  VALUES (1, 'contact', 'Observation aléatoire de la faune, de la flore ou de la fonge', 1, 2, 2, 2, 2, true, NULL, '2017-06-01 00:00:00', '2017-06-01 00:00:00');

INSERT INTO synthese.bib_modules (id_module, name_module, desc_module, entity_module_pk_field, url_module, target, picto_module, groupe_module, actif) VALUES (1, 'contact', 'Données issues du contact aléatoire', 'contact.t_occurrences_contact.id_occurrence_contact', '/contact', NULL, NULL, 'CONTACT', true);

INSERT INTO t_obs_contact VALUES(1,1,343,1,'2017-01-01','2017-01-01',12,'05100',5,10,'web',FALSE,NULL,NULL,'exemple test',NULL,NULL);
SELECT pg_catalog.setval('t_obs_contact_id_obs_contact_seq', 2, true);

INSERT INTO t_occurrences_contact VALUES(1,1,65,177,30,182,91,101,347,163,1,'gil','gees',60612,'Lynx Boréal','V9.0','','','poil',FALSE, now(),now(),'test');