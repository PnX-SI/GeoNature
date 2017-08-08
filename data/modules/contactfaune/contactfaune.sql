SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
--SET row_security = off;


CREATE SCHEMA contactfaune;


SET search_path = contactfaune, pg_catalog;
SET default_with_oids = false;

------------------------
--TABLES AND SEQUENCES--
------------------------
CREATE TABLE cor_role_releve_cfaune (
    id_releve_cfaune bigint NOT NULL,
    id_role integer NOT NULL
);


CREATE TABLE cor_stade_sexe_effectif (
    id_occurrence_cfaune bigint NOT NULL,
    id_nomenclature_stade_vie integer NOT NULL,
    id_nomenclature_sexe integer NOT NULL,
    id_nomenclature_obj_denbr integer NOT NULL DEFAULT 166,
    id_nomenclature_typ_denbr integer DEFAULT 107,
    denombrement_min integer,
    denombrement_max integer
);


CREATE TABLE t_releves_cfaune (
    id_releve_cfaune bigint NOT NULL,
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

CREATE SEQUENCE t_releves_cfaune_id_releve_cfaune_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE t_releves_cfaune_id_releve_cfaune_seq OWNED BY t_releves_cfaune.id_releve_cfaune;
ALTER TABLE ONLY t_releves_cfaune ALTER COLUMN id_releve_cfaune SET DEFAULT nextval('t_releves_cfaune_id_releve_cfaune_seq'::regclass);
SELECT pg_catalog.setval('t_releves_cfaune_id_releve_cfaune_seq', 1, false);


CREATE TABLE t_occurrences_cfaune (
    id_occurrence_cfaune bigint NOT NULL,
    id_releve_cfaune bigint NOT NULL,
    id_nomenclature_meth_obs integer DEFAULT 42,
    id_nomenclature_eta_bio integer NOT NULL DEFAULT 177,
    id_nomenclature_statut_bio integer DEFAULT 30,
    id_nomenclature_naturalite integer DEFAULT 182,
    id_nomenclature_preuve_exist integer DEFAULT 91,
    id_nomenclature_statut_obs integer DEFAULT 101,
    id_nomenclature_statut_valid integer DEFAULT 347,
    id_valideur integer,
    determinateur character varying(255),
    methode_determination character varying(255),
    cd_nom integer,
    nom_cite character varying(255),
    v_taxref character varying(6) DEFAULT 'V9.0',
    num_prelevement_cfaune text,
    preuve_numerique text,
    preuve_non_numerique text,

    supprime boolean DEFAULT false NOT NULL,
    date_insert timestamp without time zone,
    date_update timestamp without time zone,
    commentaire character varying
);

CREATE SEQUENCE t_occurrences_cfaune_id_occurrence_cfaune_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE t_occurrences_cfaune_id_occurrence_cfaune_seq OWNED BY t_occurrences_cfaune.id_occurrence_cfaune;
ALTER TABLE ONLY t_occurrences_cfaune ALTER COLUMN id_occurrence_cfaune SET DEFAULT nextval('t_occurrences_cfaune_id_occurrence_cfaune_seq'::regclass);
SELECT pg_catalog.setval('t_occurrences_cfaune_id_occurrence_cfaune_seq', 1, false);


---------------
--PRIMARY KEY--
---------------
ALTER TABLE ONLY t_occurrences_cfaune
    ADD CONSTRAINT pk_t_occurrences_cfaune PRIMARY KEY (id_occurrence_cfaune);

ALTER TABLE ONLY t_releves_cfaune
    ADD CONSTRAINT pk_t_releves_cfaune PRIMARY KEY (id_releve_cfaune);

ALTER TABLE ONLY cor_stade_sexe_effectif
    ADD CONSTRAINT pk_cor_stade_sexe_effectif_cfaune PRIMARY KEY (id_occurrence_cfaune, id_nomenclature_stade_vie, id_nomenclature_sexe);

ALTER TABLE ONLY cor_role_releve_cfaune
    ADD CONSTRAINT pk_cor_role_releve_cfaune PRIMARY KEY (id_releve_cfaune, id_role);


---------------
--FOREIGN KEY--
---------------
ALTER TABLE ONLY t_releves_cfaune
    ADD CONSTRAINT fk_t_releves_cfaune_t_lots FOREIGN KEY (id_lot) REFERENCES meta.t_lots(id_lot) ON UPDATE CASCADE;

ALTER TABLE ONLY t_releves_cfaune
    ADD CONSTRAINT fk_t_releves_cfaune_technique_obs FOREIGN KEY (id_nomenclature_technique_obs) REFERENCES meta.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_releves_cfaune
    ADD CONSTRAINT fk_t_releves_cfaune_t_roles FOREIGN KEY (id_numerisateur) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;


ALTER TABLE ONLY t_occurrences_cfaune
    ADD CONSTRAINT fk_t_occurrences_cfaune_t_releves_cfaune FOREIGN KEY (id_releve_cfaune) REFERENCES t_releves_cfaune(id_releve_cfaune) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY t_occurrences_cfaune
    ADD CONSTRAINT fk_t_occurrences_cfaune_t_roles FOREIGN KEY (id_valideur) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_cfaune
    ADD CONSTRAINT fk_t_occurrences_cfaune_taxref FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_cfaune
    ADD CONSTRAINT fk_t_occurrences_cfaune_meth_obs FOREIGN KEY (id_nomenclature_meth_obs) REFERENCES meta.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_cfaune
    ADD CONSTRAINT fk_t_occurrences_cfaune_eta_bio FOREIGN KEY (id_nomenclature_eta_bio) REFERENCES meta.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_cfaune
    ADD CONSTRAINT fk_t_occurrences_cfaune_statut_bio FOREIGN KEY (id_nomenclature_statut_bio) REFERENCES meta.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_cfaune
    ADD CONSTRAINT fk_t_occurrences_cfaune_naturalite FOREIGN KEY (id_nomenclature_naturalite) REFERENCES meta.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_cfaune
    ADD CONSTRAINT fk_t_occurrences_cfaune_preuve_exist FOREIGN KEY (id_nomenclature_preuve_exist) REFERENCES meta.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_cfaune
    ADD CONSTRAINT fk_t_occurrences_cfaune_statut_obs FOREIGN KEY (id_nomenclature_statut_obs) REFERENCES meta.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_cfaune
    ADD CONSTRAINT fk_t_occurrences_cfaune_statut_valid FOREIGN KEY (id_nomenclature_statut_valid) REFERENCES meta.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;


ALTER TABLE ONLY cor_stade_sexe_effectif
    ADD CONSTRAINT fk_cor_stade_effectif_id_taxon FOREIGN KEY (id_occurrence_cfaune) REFERENCES t_occurrences_cfaune(id_occurrence_cfaune) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_stade_sexe_effectif
    ADD CONSTRAINT fk_cor_stade_sexe_effectif_sexe FOREIGN KEY (id_nomenclature_sexe) REFERENCES meta.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_stade_sexe_effectif
    ADD CONSTRAINT fk_cor_stade_sexe_effectif_stade_vie FOREIGN KEY (id_nomenclature_stade_vie) REFERENCES meta.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_stade_sexe_effectif
    ADD CONSTRAINT fk_cor_stade_sexe_effectif_obj_denbr FOREIGN KEY (id_nomenclature_obj_denbr) REFERENCES meta.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_stade_sexe_effectif
    ADD CONSTRAINT fk_cor_stade_sexe_effectif_typ_denbr FOREIGN KEY (id_nomenclature_typ_denbr) REFERENCES meta.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;


ALTER TABLE ONLY cor_role_releve_cfaune
    ADD CONSTRAINT fk_cor_role_releve_cfaune_t_releves_cfaune FOREIGN KEY (id_releve_cfaune) REFERENCES t_releves_cfaune(id_releve_cfaune) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_role_releve_cfaune
    ADD CONSTRAINT fk_cor_role_releve_cfaune_t_roles FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

--------------
--CONSTRAINS--
--------------
ALTER TABLE ONLY t_releves_cfaune
    ADD CONSTRAINT check_t_releves_cfaune_altitude_max CHECK (altitude_max >= altitude_min);

ALTER TABLE ONLY t_releves_cfaune
    ADD CONSTRAINT check_t_releves_cfaune_date_max CHECK (date_max >= date_min);

ALTER TABLE t_releves_cfaune
  ADD CONSTRAINT check_t_releves_cfaune_technique_obs CHECK (meta.check_type_nomenclature(id_nomenclature_technique_obs,100));


ALTER TABLE ONLY t_occurrences_cfaune
    ADD CONSTRAINT check_t_occurrences_cfaune_cd_nom_isinbib_noms CHECK (taxonomie.check_is_inbibnoms(cd_nom));

ALTER TABLE t_occurrences_cfaune
  ADD CONSTRAINT check_t_releves_cfaune_meth_obs CHECK (meta.check_type_nomenclature(id_nomenclature_meth_obs,14));

ALTER TABLE t_occurrences_cfaune
  ADD CONSTRAINT check_t_occurrences_cfaune_eta_bio CHECK (meta.check_type_nomenclature(id_nomenclature_eta_bio,7));

ALTER TABLE t_occurrences_cfaune
  ADD CONSTRAINT check__occurrences_cfaune_statut_bio CHECK (meta.check_type_nomenclature(id_nomenclature_statut_bio,13));

ALTER TABLE t_occurrences_cfaune
  ADD CONSTRAINT check__occurrences_cfaune_naturalite CHECK (meta.check_type_nomenclature(id_nomenclature_naturalite,8));

ALTER TABLE t_occurrences_cfaune
  ADD CONSTRAINT check__occurrences_cfaune_preuve_exist CHECK (meta.check_type_nomenclature(id_nomenclature_preuve_exist,15));

ALTER TABLE t_occurrences_cfaune
  ADD CONSTRAINT check__occurrences_cfaune_statut_obs CHECK (meta.check_type_nomenclature(id_nomenclature_statut_obs,18));

ALTER TABLE t_occurrences_cfaune
  ADD CONSTRAINT check__occurrences_cfaune_statut_valid CHECK (meta.check_type_nomenclature(id_nomenclature_statut_valid,101));


ALTER TABLE cor_stade_sexe_effectif
  ADD CONSTRAINT check_t_releves_cfaune_stade_vie CHECK (meta.check_type_nomenclature(id_nomenclature_stade_vie,10));

ALTER TABLE cor_stade_sexe_effectif
  ADD CONSTRAINT check_t_releves_cfaune_sexe CHECK (meta.check_type_nomenclature(id_nomenclature_sexe,9));

ALTER TABLE cor_stade_sexe_effectif
  ADD CONSTRAINT check_t_releves_cfaune_obj_denbr CHECK (meta.check_type_nomenclature(id_nomenclature_obj_denbr,6));

ALTER TABLE cor_stade_sexe_effectif
  ADD CONSTRAINT check_t_releves_cfaune_typ_denbr CHECK (meta.check_type_nomenclature(id_nomenclature_typ_denbr,21));


---------
--VIEWS--
---------
CREATE OR REPLACE VIEW contactfaune.v_technique_obs AS(
SELECT ctn.regne,ctn.group2_inpn, n.id_nomenclature, n.mnemonique, n.libelle_nomenclature, n.definition_nomenclature, n.id_parent, n.hierarchie
FROM meta.t_nomenclatures n
LEFT JOIN taxonomie.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
WHERE n.id_type_nomenclature = 100
AND n.id_parent != 0
);
--USAGE :
--SELECT * FROM contactfaune.v_technique_obs WHERE group2_inpn = 'Oiseaux';
--SELECT * FROM contactfaune.v_technique_obs WHERE regne = 'Plantae';

CREATE OR REPLACE VIEW contactfaune.v_eta_bio AS 
  SELECT 
    n.id_nomenclature,
    n.mnemonique,
    n.libelle_nomenclature,
    n.definition_nomenclature,
    n.id_parent,
    n.hierarchie
  FROM meta.t_nomenclatures n
  WHERE n.id_type_nomenclature = 7 
  AND n.id_parent <> 0
  AND n.actif = true;
CREATE OR REPLACE VIEW contactfaune.v_stade_vie AS 
SELECT 
    ctn.regne,
    ctn.group2_inpn, 
    n.id_nomenclature, 
    n.mnemonique, 
    n.libelle_nomenclature, 
    n.definition_nomenclature, 
    n.id_parent, 
    n.hierarchie
FROM meta.t_nomenclatures n
LEFT JOIN taxonomie.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
WHERE n.id_type_nomenclature = 10
AND n.id_parent != 0
AND n.actif = true;
--USAGE : 
--SELECT * FROM contactfaune.v_stade_vie WHERE (regne = 'Animalia' OR regne = 'all') AND (group2_inpn = 'Amphibiens' OR group2_inpn = 'all');

CREATE OR REPLACE VIEW contactfaune.v_sexe AS 
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.libelle_nomenclature,
    n.definition_nomenclature,
    n.id_parent,
    n.hierarchie
   FROM meta.t_nomenclatures n
     LEFT JOIN taxonomie.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_type_nomenclature = 9
  AND n.id_parent <> 0
  AND n.actif = true;
--USAGE : 
--SELECT * FROM contactfaune.v_sexe WHERE (regne = 'Animalia' OR regne = 'all') AND (group2_inpn = 'Amphibiens' OR group2_inpn = 'all');

CREATE OR REPLACE VIEW contactfaune.v_objet_denbr AS 
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.libelle_nomenclature,
    n.definition_nomenclature,
    n.id_parent,
    n.hierarchie
   FROM meta.t_nomenclatures n
     LEFT JOIN taxonomie.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_type_nomenclature = 6
  AND n.id_parent <> 0
  AND n.actif = true;
--USAGE : 
--SELECT * FROM contactfaune.v_objet_denbr WHERE (regne = 'Animalia' OR regne = 'all') AND (group2_inpn = 'Amphibiens' OR group2_inpn = 'all');

CREATE OR REPLACE VIEW contactfaune.v_type_denbr AS 
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.libelle_nomenclature,
    n.definition_nomenclature,
    n.id_parent,
    n.hierarchie
   FROM meta.t_nomenclatures n
     LEFT JOIN taxonomie.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_type_nomenclature = 21
  AND n.id_parent <> 0
  AND n.actif = true;
--USAGE : 
--SELECT * FROM contactfaune.v_type_denbr WHERE (regne = 'Animalia' OR regne = 'all') AND (group2_inpn = 'Amphibiens' OR group2_inpn = 'all');

CREATE OR REPLACE VIEW contactfaune.v_meth_obs AS 
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.libelle_nomenclature,
    n.definition_nomenclature,
    n.id_parent,
    n.hierarchie
   FROM meta.t_nomenclatures n
     LEFT JOIN taxonomie.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_type_nomenclature = 14
  AND n.id_parent <> 0
  AND n.actif = true;
--USAGE : 
--SELECT * FROM contactfaune.v_meth_obs WHERE (regne = 'Animalia' OR regne = 'all') AND (group2_inpn = 'Amphibiens' OR group2_inpn = 'all');

CREATE OR REPLACE VIEW contactfaune.v_statut_bio AS 
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.libelle_nomenclature,
    n.definition_nomenclature,
    n.id_parent,
    n.hierarchie
   FROM meta.t_nomenclatures n
     LEFT JOIN taxonomie.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_type_nomenclature = 13
  AND n.id_parent <> 0
  AND n.actif = true;
--USAGE : 
--SELECT * FROM contactfaune.v_statut_bio WHERE (regne = 'Animalia' OR regne = 'all') AND (group2_inpn = 'Amphibiens' OR group2_inpn = 'all');

CREATE OR REPLACE VIEW contactfaune.v_naturalite AS 
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.libelle_nomenclature,
    n.definition_nomenclature,
    n.id_parent,
    n.hierarchie
   FROM meta.t_nomenclatures n
     LEFT JOIN taxonomie.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_type_nomenclature = 8
  AND n.id_parent <> 0
  AND n.actif = true;
--USAGE : 
--SELECT * FROM contactfaune.v_naturalite WHERE (regne = 'Animalia' OR regne = 'all');

CREATE OR REPLACE VIEW contactfaune.v_preuve_exist AS 
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.libelle_nomenclature,
    n.definition_nomenclature,
    n.id_parent,
    n.hierarchie
   FROM meta.t_nomenclatures n
     LEFT JOIN taxonomie.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_type_nomenclature = 15 
  AND n.id_parent <> 0
  AND n.actif = true;
--USAGE : 
--SELECT * FROM contactfaune.v_preuve_exist;

CREATE OR REPLACE VIEW contactfaune.v_statut_obs AS 
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.libelle_nomenclature,
    n.definition_nomenclature,
    n.id_parent,
    n.hierarchie
   FROM meta.t_nomenclatures n
     LEFT JOIN taxonomie.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_type_nomenclature = 18 
  AND n.id_parent <> 0
  AND n.actif = true;
--USAGE : 
--SELECT * FROM contactfaune.v_statut_obs;

CREATE OR REPLACE VIEW contactfaune.v_statut_valid AS 
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.libelle_nomenclature,
    n.definition_nomenclature,
    n.id_parent,
    n.hierarchie
   FROM meta.t_nomenclatures n
     LEFT JOIN taxonomie.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_type_nomenclature = 101 
  AND n.id_parent <> 0
  AND n.actif = true;
--USAGE : 
--SELECT * FROM contactfaune.v_statut_valid;
  

---------
--DATAS--
---------

INSERT INTO meta.t_lots  VALUES (1, 'contactfaune', 'Observation aléatoire de la faune vertébrés', 1, 2, 2, 2, 2, true, NULL, '2017-06-01 00:00:00', '2017-06-01 00:00:00');

INSERT INTO synthese.bib_modules (id_module, name_module, desc_module, entity_module_pk_field, url_module, target, picto_module, groupe_module, actif) VALUES (1, 'contact faune', 'Données issues du contact faune', 'contactfaune.t_occurrences_cfaune.id_occurrence_cfaune', '/cfaune', NULL, NULL, 'FAUNE', true);

INSERT INTO t_releves_cfaune VALUES(1,1,343,1,'2017-01-01','2017-01-01',12,'05100',5,10,'web',FALSE,NULL,NULL,'exemple test',NULL,NULL);
SELECT pg_catalog.setval('t_releves_cfaune_id_releve_cfaune_seq', 2, true);