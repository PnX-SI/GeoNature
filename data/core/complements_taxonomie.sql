SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = taxonomie, pg_catalog;


----------------------
--MATERIALIZED VIEWS--
----------------------
--Vue materialisée permettant d'améliorer fortement les performances des contraintes check sur les champ filtres 'regne' et 'group2_inpn'
CREATE MATERIALIZED VIEW vm_regne AS (SELECT DISTINCT regne FROM taxref);
CREATE MATERIALIZED VIEW vm_group2_inpn AS (SELECT DISTINCT group2_inpn FROM taxref);


-------------
--FUNCTIONS--
-------------
CREATE OR REPLACE FUNCTION check_is_inbibnoms(cdnom integer)
  RETURNS boolean AS
$BODY$
--fonction permettant de vérifier si un texte proposé correspond à un group2_inpn dans la table taxref
  BEGIN
    IF cdnom IN(SELECT cd_nom FROM bib_noms) THEN
      RETURN true;
    ELSE
      RETURN false;
    END IF;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;


CREATE OR REPLACE FUNCTION check_is_group2inpn(mygroup text)
  RETURNS boolean AS
$BODY$
--fonction permettant de vérifier si un texte proposé correspond à un group2_inpn dans la table taxref
  BEGIN
    IF mygroup IN(SELECT group2_inpn FROM vm_group2_inpn) OR mygroup IS NULL THEN
      RETURN true;
    ELSE
      RETURN false;
    END IF;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;


CREATE OR REPLACE FUNCTION check_is_regne(myregne text)
  RETURNS boolean AS
$BODY$
--fonction permettant de vérifier si un texte proposé correspond à un regne dans la table taxref
  BEGIN
    IF myregne IN(SELECT regne FROM vm_regne) OR myregne IS NULL THEN
      return true;
    ELSE
      RETURN false;
    END IF;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;


CREATE OR REPLACE FUNCTION find_group2inpn(id integer)
  RETURNS text AS
$BODY$
--fonction permettant de renvoyer le group2_inpn d'un taxon à partir de son cd_nom
  DECLARE group2 character varying(255);
  BEGIN
    SELECT INTO group2 group2_inpn FROM taxref WHERE cd_nom = id;
    return group2;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

CREATE OR REPLACE FUNCTION calcul_sensibilite(
    cdnom integer,
    idnomenclature integer)
  RETURNS integer AS
$BODY$
  --fonction permettant de renvoyer l'id nomenclature correspondant à la sensibilité de l'observation
  --USAGE : SELECT taxonomie.calcul_sensibilite(240,21);
  DECLARE
  idsensibilite integer;
  BEGIN
    SELECT max(id_nomenclature_niv_precis) INTO idsensibilite 
    FROM taxonomie.cor_taxref_sensibilite
    WHERE cd_nom = cdnom
    AND (id_nomenclature = idnomenclature OR id_nomenclature = 0);
  IF idsensibilite IS NULL THEN
    idsensibilite = 163;  
  END IF;
  RETURN idsensibilite;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;




----------
--TABLES--
----------
CREATE TABLE cor_taxref_nomenclature
(
  id_nomenclature integer NOT NULL,
  regne character varying(255) NOT NULL,
  group2_inpn character varying(255) NOT NULL,
  date_create timestamp without time zone DEFAULT now(),
  date_update timestamp without time zone
);


CREATE TABLE cor_taxref_sensibilite
(
  cd_nom integer NOT NULL,
  id_nomenclature_niv_precis integer NOT NULL,
  id_nomenclature integer NOT NULL,
  duree_sensibilite integer NOT NULL,
  territoire_sensibilite character varying(50),
  date_create timestamp without time zone DEFAULT now(),
  date_update timestamp without time zone
);


---------------
--PRIMARY KEY--
---------------
ALTER TABLE ONLY cor_taxref_nomenclature
    ADD CONSTRAINT pk_cor_taxref_nomenclature PRIMARY KEY (id_nomenclature, regne, group2_inpn);

ALTER TABLE ONLY cor_taxref_sensibilite
    ADD CONSTRAINT pk_cor_taxref_sensibilite PRIMARY KEY (cd_nom, id_nomenclature_niv_precis, id_nomenclature);


---------------
--FOREIGN KEY--
---------------
ALTER TABLE ONLY cor_taxref_nomenclature
    ADD CONSTRAINT fk_cor_taxref_nomenclature_id_nomenclature FOREIGN KEY (id_nomenclature) REFERENCES meta.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;


ALTER TABLE ONLY cor_taxref_sensibilite
    ADD CONSTRAINT fk_cor_taxref_sensibilite_cd_nom FOREIGN KEY (cd_nom) REFERENCES taxref(cd_nom) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_taxref_sensibilite
    ADD CONSTRAINT fk_cor_taxref_sensibilite_niv_precis FOREIGN KEY (id_nomenclature_niv_precis) REFERENCES meta.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_taxref_sensibilite
    ADD CONSTRAINT fk_cor_taxref_sensibilite_id_nomenclature FOREIGN KEY (id_nomenclature) REFERENCES meta.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;


--------------
--CONSTRAINS--
--------------
ALTER TABLE ONLY cor_taxref_nomenclature
    ADD CONSTRAINT check_cor_taxref_nomenclature_isgroup2inpn CHECK (check_is_group2inpn(group2_inpn::text) OR group2_inpn::text = 'all'::text);

ALTER TABLE ONLY cor_taxref_nomenclature
    ADD CONSTRAINT check_cor_taxref_nomenclature_isregne CHECK (check_is_regne(regne::text) OR regne::text = 'all'::text);


ALTER TABLE ONLY cor_taxref_sensibilite
    ADD CONSTRAINT check_cor_taxref_sensibilite_niv_precis CHECK (meta.check_type_nomenclature(id_nomenclature_niv_precis,5));


---------
--VIEWS--
---------

CREATE OR REPLACE VIEW meta.v_nomenclature_taxonomie AS 
  SELECT tn.id_type_nomenclature,
    tn.libelle_type_nomenclature,
    tn.definition_type_nomenclature,
    ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.libelle_nomenclature,
    n.definition_nomenclature,
    n.id_parent,
    n.hierarchie
  FROM meta.t_nomenclatures n
    JOIN meta.bib_types_nomenclatures tn ON tn.id_type_nomenclature = n.id_type_nomenclature
    JOIN taxonomie.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_parent <> 0
  ORDER BY tn.id_type_nomenclature, ctn.regne, ctn.group2_inpn, n.id_nomenclature;