SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

CREATE SCHEMA ref_nomenclatures;

SET search_path = ref_nomenclatures, pg_catalog;

-------------
--FUNCTIONS--
-------------
CREATE FUNCTION check_nomenclature_type(id integer, myidtype integer) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
--Function that checks if an id_nomenclature matches with wanted nomenclature type
  BEGIN
    IF id IN(SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE id_type = myidtype ) THEN
      return true;
    ELSE
      RETURN false;
    END IF;
  END;
$$;


CREATE FUNCTION get_filtered_nomenclature(idtype integer, myregne character varying, mygroup character varying) RETURNS SETOF integer
    LANGUAGE plpgsql IMMUTABLE
    AS $$
--Function that returns a list of id_nomenclature depending on regne and/or group2_inpn sent with parameters.
  DECLARE
    thegroup character varying(255);
    theregne character varying(255);
    r integer;

BEGIN
  thegroup = NULL;
  theregne = NULL;

  IF mygroup IS NOT NULL THEN
      SELECT INTO thegroup DISTINCT group2_inpn 
      FROM taxonomie.cor_taxref_nomenclature ctn
      JOIN ref_nomenclatures.t_nomenclatures n ON n.id_nomenclature = ctn.id_nomenclature 
      WHERE n.id_type = idtype
      AND group2_inpn = mygroup;
  END IF;

  IF myregne IS NOT NULL THEN
    SELECT INTO theregne DISTINCT regne 
    FROM taxonomie.cor_taxref_nomenclature ctn
    JOIN ref_nomenclatures.t_nomenclatures n ON n.id_nomenclature = ctn.id_nomenclature 
    WHERE n.id_type = idtype
    AND regne = myregne;
  END IF;

  IF theregne IS NOT NULL THEN 
    IF thegroup IS NOT NULL THEN
      FOR r IN 
        SELECT DISTINCT ctn.id_nomenclature
        FROM taxonomie.cor_taxref_nomenclature ctn
        JOIN ref_nomenclatures.t_nomenclatures n ON n.id_nomenclature = ctn.id_nomenclature 
        WHERE n.id_type = idtype
        AND regne = theregne
        AND group2_inpn = mygroup
      LOOP
        RETURN NEXT r;
      END LOOP;
      RETURN;
    ELSE
      FOR r IN 
        SELECT DISTINCT ctn.id_nomenclature
        FROM taxonomie.cor_taxref_nomenclature ctn
        JOIN ref_nomenclatures.t_nomenclatures n ON n.id_nomenclature = ctn.id_nomenclature 
        WHERE n.id_type = idtype
        AND regne = theregne
      LOOP
        RETURN NEXT r;
      END LOOP;
      RETURN;
    END IF;
  ELSE
    FOR r IN 
      SELECT DISTINCT ctn.id_nomenclature
      FROM taxonomie.cor_taxref_nomenclature ctn
      JOIN ref_nomenclatures.t_nomenclatures n ON n.id_nomenclature = ctn.id_nomenclature 
      WHERE n.id_type = idtype
    LOOP
      RETURN NEXT r;
    END LOOP;
    RETURN;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION calculate_sensitivity(
    mycdnom integer,
    mynomenclatureid integer)
  RETURNS integer AS
$BODY$
  --Function to return id_nomenclature depending on observation sensibility
  --USAGE : SELECT ref_nomenclatures.calculate_sensitivity(240,21);
  DECLARE
  sensitivityid integer;
  BEGIN
    SELECT max(id_nomenclature_niv_precis) INTO sensitivityid 
    FROM ref_nomenclatures.cor_taxref_sensitivity
    WHERE cd_nom = mycdnom
    AND (id_nomenclature = mynomenclatureid OR id_nomenclature = 0);
  IF sensitivityid IS NULL THEN
    sensitivityid = 163;  
  END IF;
  RETURN sensitivityid;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;


----------
--TABLES--
----------
CREATE TABLE bib_nomenclatures_types (
    id_type integer NOT NULL,
    mnemonique character varying(255) NOT NULL,
    label_fr character varying(255),
    definition_fr text,
    source character varying(50),
    statut character varying(20),
    meta_create_date timestamp without time zone DEFAULT now(),
    meta_update_date timestamp without time zone DEFAULT now()
);
COMMENT ON TABLE bib_nomenclatures_types IS 'Description of the SINP nomenclatures list.';

CREATE TABLE t_nomenclatures (
    id_nomenclature integer NOT NULL,
    id_type integer,
    cd_nomenclature character varying(255) NOT NULL,
    mnemonique character varying(255) NOT NULL,
    label_fr character varying(255),
    definition_fr text,
    source character varying(50),
    statut character varying(20),
    id_broader integer,
    hierarchy character varying(255),
    meta_create_date timestamp without time zone DEFAULT now(),
    meta_update_date timestamp without time zone,
    active boolean NOT NULL DEFAULT true
);
CREATE SEQUENCE t_nomenclatures_id_nomenclature_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE t_nomenclatures_id_nomenclature_seq OWNED BY t_nomenclatures.id_nomenclature;
ALTER TABLE ONLY t_nomenclatures ALTER COLUMN id_nomenclature SET DEFAULT nextval('t_nomenclatures_id_nomenclature_seq'::regclass);

CREATE TABLE cor_nomenclatures_relations (
    id_nomenclature_l integer NOT NULL,
    id_nomenclature_r integer NOT NULL,
    relation_type character varying(250) NOT NULL
);

CREATE TABLE cor_taxref_nomenclature
(
  id_nomenclature integer NOT NULL,
  regne character varying(255) NOT NULL,
  group2_inpn character varying(255) NOT NULL,
  meta_create_date timestamp without time zone DEFAULT now(),
  meta_update_date timestamp without time zone
);


CREATE TABLE cor_taxref_sensitivity
(
  cd_nom integer NOT NULL,
  id_nomenclature_niv_precis integer NOT NULL,
  id_nomenclature integer NOT NULL,
  sensitivity_duration integer NOT NULL,
  sensitivity_territory character varying(50),
  meta_create_date timestamp without time zone DEFAULT now(),
  meta_update_date timestamp without time zone
);
---------------
--PRIMARY KEY--
---------------
ALTER TABLE ONLY cor_nomenclatures_relations
    ADD CONSTRAINT pk_cor_nomenclatures_relations PRIMARY KEY (id_nomenclature_l, id_nomenclature_r, relation_type);

ALTER TABLE ONLY bib_nomenclatures_types
    ADD CONSTRAINT pk_bib_nomenclatures_types PRIMARY KEY (id_type);

ALTER TABLE ONLY t_nomenclatures
    ADD CONSTRAINT pk_t_nomenclatures PRIMARY KEY (id_nomenclature);

ALTER TABLE ONLY cor_taxref_nomenclature
    ADD CONSTRAINT pk_cor_taxref_nomenclature PRIMARY KEY (id_nomenclature, regne, group2_inpn);

ALTER TABLE ONLY cor_taxref_sensitivity
    ADD CONSTRAINT pk_cor_taxref_sensitivity PRIMARY KEY (cd_nom, id_nomenclature_niv_precis, id_nomenclature);


---------------
--FOREIGN KEY--
---------------
ALTER TABLE ONLY cor_nomenclatures_relations
    ADD CONSTRAINT fk_cor_nomenclatures_relations_id_nomenclature_l FOREIGN KEY (id_nomenclature_l) REFERENCES t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY cor_nomenclatures_relations
    ADD CONSTRAINT fk_cor_nomenclatures_relations_id_nomenclature_r FOREIGN KEY (id_nomenclature_r) REFERENCES t_nomenclatures(id_nomenclature);


ALTER TABLE ONLY t_nomenclatures
    ADD CONSTRAINT fk_t_nomenclatures_id_broader FOREIGN KEY (id_broader) REFERENCES t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY t_nomenclatures
    ADD CONSTRAINT fk_t_nomenclatures_id_type FOREIGN KEY (id_type) REFERENCES bib_nomenclatures_types(id_type) ON UPDATE CASCADE;


ALTER TABLE ONLY cor_taxref_nomenclature
    ADD CONSTRAINT fk_cor_taxref_nomenclature_id_nomenclature FOREIGN KEY (id_nomenclature) REFERENCES t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;


ALTER TABLE ONLY cor_taxref_sensitivity
    ADD CONSTRAINT fk_cor_taxref_sensitivity_cd_nom FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_taxref_sensitivity
    ADD CONSTRAINT fk_cor_taxref_sensitivity_niv_precis FOREIGN KEY (id_nomenclature_niv_precis) REFERENCES t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_taxref_sensitivity
    ADD CONSTRAINT fk_cor_taxref_sensitivity_id_nomenclature FOREIGN KEY (id_nomenclature) REFERENCES t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;


--------------
--CONSTRAINS--
--------------
ALTER TABLE ONLY cor_taxref_nomenclature
    ADD CONSTRAINT check_cor_taxref_nomenclature_isgroup2inpn CHECK (taxonomie.check_is_group2inpn(group2_inpn::text) OR group2_inpn::text = 'all'::text);

ALTER TABLE ONLY cor_taxref_nomenclature
    ADD CONSTRAINT check_cor_taxref_nomenclature_isregne CHECK (taxonomie.check_is_regne(regne::text) OR regne::text = 'all'::text);


ALTER TABLE ONLY cor_taxref_sensitivity
    ADD CONSTRAINT check_cor_taxref_sensitivity_niv_precis CHECK (check_nomenclature_type(id_nomenclature_niv_precis,5));


---------
--INDEX--
---------
CREATE INDEX fki_t_nomenclatures_bib_nomenclatures_types_fkey ON t_nomenclatures USING btree (id_type);


---------
--VIEWS--
---------
CREATE OR REPLACE VIEW v_nomenclature_taxonomie AS 
  SELECT tn.id_type,
    tn.label_fr AS type_nomenclature_label_fr,
    tn.definition_fr AS type_nomenclature_definition_fr,
    ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.label_fr AS nomenclature_label_fr,
    n.definition_fr AS nomenclature_definition_fr,
    n.id_broader,
    n.hierarchy
  FROM ref_nomenclatures.t_nomenclatures n
    JOIN ref_nomenclatures.bib_nomenclatures_types tn ON tn.id_type = n.id_type
    JOIN ref_nomenclatures.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  ORDER BY tn.id_type, ctn.regne, ctn.group2_inpn, n.id_nomenclature;

CREATE OR REPLACE VIEW v_technique_obs AS(
SELECT ctn.regne,ctn.group2_inpn, n.id_nomenclature, n.mnemonique, n.label_fr, n.definition_fr, n.id_broader, n.hierarchy
FROM ref_nomenclatures.t_nomenclatures n
LEFT JOIN ref_nomenclatures.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
WHERE n.id_type = 100
);
--USAGE :
--SELECT * FROM ref_nomenclatures.v_technique_obs WHERE group2_inpn = 'Oiseaux';
--SELECT * FROM ref_nomenclatures.v_technique_obs WHERE regne = 'Plantae';

CREATE OR REPLACE VIEW v_eta_bio AS 
  SELECT 
    n.id_nomenclature,
    n.mnemonique,
    n.label_fr,
    n.definition_fr,
    n.id_broader,
    n.hierarchy
  FROM ref_nomenclatures.t_nomenclatures n
  WHERE n.id_type = 7 
  AND n.active = true;
  
CREATE OR REPLACE VIEW v_stade_vie AS 
SELECT 
    ctn.regne,
    ctn.group2_inpn, 
    n.id_nomenclature, 
    n.mnemonique, 
    n.label_fr, 
    n.definition_fr, 
    n.id_broader, 
    n.hierarchy
FROM ref_nomenclatures.t_nomenclatures n
LEFT JOIN ref_nomenclatures.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
WHERE n.id_type = 10
AND n.active = true;
--USAGE : 
--SELECT * FROM ref_nomenclatures.v_stade_vie WHERE (regne = 'Animalia' OR regne = 'all') AND (group2_inpn = 'Amphibiens' OR group2_inpn = 'all');

CREATE OR REPLACE VIEW v_sexe AS 
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.label_fr,
    n.definition_fr,
    n.id_broader,
    n.hierarchy
   FROM ref_nomenclatures.t_nomenclatures n
     LEFT JOIN ref_nomenclatures.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_type = 9
  AND n.active = true;
--USAGE : 
--SELECT * FROM ref_nomenclatures.v_sexe WHERE (regne = 'Animalia' OR regne = 'all') AND (group2_inpn = 'Amphibiens' OR group2_inpn = 'all');

CREATE OR REPLACE VIEW v_objet_denbr AS 
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.label_fr,
    n.definition_fr,
    n.id_broader,
    n.hierarchy
   FROM ref_nomenclatures.t_nomenclatures n
     LEFT JOIN ref_nomenclatures.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_type = 6
  AND n.active = true;
--USAGE : 
--SELECT * FROM ref_nomenclatures.v_objet_denbr WHERE (regne = 'Animalia' OR regne = 'all') AND (group2_inpn = 'Amphibiens' OR group2_inpn = 'all');

CREATE OR REPLACE VIEW v_type_denbr AS 
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.label_fr,
    n.definition_fr,
    n.id_broader,
    n.hierarchy
   FROM ref_nomenclatures.t_nomenclatures n
     LEFT JOIN ref_nomenclatures.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_type = 21
  AND n.active = true;
--USAGE : 
--SELECT * FROM ref_nomenclatures.v_type_denbr WHERE (regne = 'Animalia' OR regne = 'all') AND (group2_inpn = 'Amphibiens' OR group2_inpn = 'all');

CREATE OR REPLACE VIEW v_meth_obs AS 
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.label_fr,
    n.definition_fr,
    n.id_broader,
    n.hierarchy
   FROM ref_nomenclatures.t_nomenclatures n
     LEFT JOIN ref_nomenclatures.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_type = 14
  AND n.active = true;
--USAGE : 
--SELECT * FROM ref_nomenclatures.v_meth_obs WHERE (regne = 'Animalia' OR regne = 'all') AND (group2_inpn = 'Amphibiens' OR group2_inpn = 'all');

CREATE OR REPLACE VIEW v_statut_bio AS 
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.label_fr,
    n.definition_fr,
    n.id_broader,
    n.hierarchy
   FROM ref_nomenclatures.t_nomenclatures n
     LEFT JOIN ref_nomenclatures.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_type = 13
  AND n.active = true;
--USAGE : 
--SELECT * FROM ref_nomenclatures.v_statut_bio WHERE (regne = 'Animalia' OR regne = 'all') AND (group2_inpn = 'Amphibiens' OR group2_inpn = 'all');

CREATE OR REPLACE VIEW v_naturalite AS 
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.label_fr,
    n.definition_fr,
    n.id_broader,
    n.hierarchy
   FROM ref_nomenclatures.t_nomenclatures n
     LEFT JOIN ref_nomenclatures.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_type = 8
  AND n.active = true;
--USAGE : 
--SELECT * FROM ref_nomenclatures.v_naturalite WHERE (regne = 'Animalia' OR regne = 'all');

CREATE OR REPLACE VIEW v_preuve_exist AS 
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.label_fr,
    n.definition_fr,
    n.id_broader,
    n.hierarchy
   FROM ref_nomenclatures.t_nomenclatures n
     LEFT JOIN ref_nomenclatures.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_type = 15 
  AND n.active = true;
--USAGE : 
--SELECT * FROM ref_nomenclatures.v_preuve_exist;

CREATE OR REPLACE VIEW v_statut_obs AS 
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.label_fr,
    n.definition_fr,
    n.id_broader,
    n.hierarchy
   FROM ref_nomenclatures.t_nomenclatures n
     LEFT JOIN ref_nomenclatures.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_type = 18 
  AND n.active = true;
--USAGE : 
--SELECT * FROM ref_nomenclatures.v_statut_obs;

CREATE OR REPLACE VIEW v_statut_valid AS 
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.label_fr,
    n.definition_fr,
    n.id_broader,
    n.hierarchy
   FROM ref_nomenclatures.t_nomenclatures n
     LEFT JOIN ref_nomenclatures.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_type = 101 
  AND n.active = true;
--USAGE : 
--SELECT * FROM ref_nomenclatures.v_statut_valid;

CREATE OR REPLACE VIEW v_niv_precis AS 
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.label_fr,
    n.definition_fr,
    n.id_broader,
    n.hierarchy
   FROM ref_nomenclatures.t_nomenclatures n
     LEFT JOIN ref_nomenclatures.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_type = 5
  AND n.active = true;
--USAGE : 
--SELECT * FROM ref_nomenclatures.v_statut_valid;
