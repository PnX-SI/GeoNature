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
CREATE OR REPLACE FUNCTION get_default_nomenclature_value(myidtype integer, myidorganism integer DEFAULT 0) RETURNS integer
IMMUTABLE
LANGUAGE plpgsql
AS $$
--Function that return the default nomenclature id with wanteds nomenclature type, organism id 
--Return -1 if nothing matche with given parameters
  DECLARE
    thenomenclatureid integer;
  BEGIN
      SELECT INTO thenomenclatureid id_nomenclature
      FROM ref_nomenclatures.defaults_nomenclatures_value 
      WHERE id_type = myidtype 
      AND (id_organism = myidorganism OR id_organism = 0)
      ORDER BY id_organism DESC LIMIT 1;
    IF (thenomenclatureid IS NOT NULL) THEN
      RETURN thenomenclatureid;
    END IF;
    RETURN -1;
  END;
$$;

CREATE OR REPLACE FUNCTION check_nomenclature_type(id integer , myidtype integer) returns boolean
IMMUTABLE
LANGUAGE plpgsql
AS $$
--Function that checks if an id_nomenclature matches with wanted nomenclature type
  BEGIN
    IF (id IN (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE id_type = myidtype )
        OR id IS NULL) THEN
      RETURN true;
    ELSE
	    RAISE EXCEPTION 'Error : id_nomenclature and id_type didn''t match. Use nomenclature with corresponding type (id_type). See ref_nomenclatures.t_nomenclatures.id_type.';
    END IF;
    RETURN false;
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
  --Function to return id_nomenclature depending on observation sensitivity
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


CREATE OR REPLACE FUNCTION get_cd_nomenclature(
    myidnomenclature integer)
  RETURNS character varying AS
$BODY$
--Function which return the cd_nomenclature from an id_type and an id_nomenclature
DECLARE thecdnomenclature character varying;
  BEGIN
SELECT INTO thecdnomenclature cd_nomenclature
FROM ref_nomenclatures.t_nomenclatures n
WHERE myidnomenclature = n.id_nomenclature;
return thecdnomenclature;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

CREATE OR REPLACE FUNCTION get_id_nomenclature(
    myidtype integer,
    mycdnomenclature character varying)
  RETURNS character varying AS
$BODY$
--Function which return the cd_nomenclature from an id_type and an id_nomenclature
DECLARE theidnomenclature character varying;
  BEGIN
SELECT INTO theidnomenclature id_nomenclature
FROM ref_nomenclatures.t_nomenclatures n
WHERE myidtype = n.id_type AND mycdnomenclature = n.cd_nomenclature;
return theidnomenclature;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

CREATE OR REPLACE FUNCTION get_nomenclature_label(
    myidnomenclature integer,
    mylanguage character varying
    )
  RETURNS character varying AS
$BODY$
--Function which return the label from the id_nomenclature and the language
DECLARE 
	labelfield character varying;
	thelabel character varying;
  BEGIN
  labelfield = 'label_'||mylanguage;
  EXECUTE format( ' SELECT  %s
  FROM ref_nomenclatures.t_nomenclatures n
  WHERE id_nomenclature = %s',labelfield, myidnomenclature  )INTO thelabel;
return thelabel;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;


----------
--TABLES--
----------
CREATE TABLE bib_nomenclatures_types (
    id_type integer NOT NULL,
    mnemonique character varying(255),
    label_default character varying(255),
    definition_default text,
    label_fr character varying(255),
    definition_fr text,
    label_en character varying(255),
    definition_en text,
    label_es character varying(255),
    definition_es text,
    label_de character varying(255),
    definition_de text,
    label_it character varying(255),
    definition_it text,
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
    mnemonique character varying(255),
    label_default character varying(255),
    definition_default text,
    label_fr character varying(255),
    definition_fr text,
    label_en character varying(255),
    definition_en text,
    label_es character varying(255),
    definition_es text,
    label_de character varying(255),
    definition_de text,
    label_it character varying(255),
    definition_it text,
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


CREATE TABLE defaults_nomenclatures_value (
    id_type integer NOT NULL,
    id_organism integer NOT NULL,
    id_nomenclature integer NOT NULL
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

ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT pk_defaults_nomenclatures_value PRIMARY KEY (id_type, id_organism);


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


ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT fk_defaults_nomenclatures_value_id_type FOREIGN KEY (id_type) REFERENCES bib_nomenclatures_types(id_type) ON UPDATE CASCADE;

ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT fk_defaults_nomenclatures_value_id_organism FOREIGN KEY (id_organism) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT fk_defaults_nomenclatures_value_id_nomenclature FOREIGN KEY (id_nomenclature) REFERENCES t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;


--------------
--CONSTRAINS--
--------------
ALTER TABLE ONLY cor_taxref_nomenclature
    ADD CONSTRAINT check_cor_taxref_nomenclature_isgroup2inpn CHECK (taxonomie.check_is_group2inpn(group2_inpn::text) OR group2_inpn::text = 'all'::text);

ALTER TABLE ONLY cor_taxref_nomenclature
    ADD CONSTRAINT check_cor_taxref_nomenclature_isregne CHECK (taxonomie.check_is_regne(regne::text) OR regne::text = 'all'::text);


ALTER TABLE ONLY cor_taxref_sensitivity
    ADD CONSTRAINT check_cor_taxref_sensitivity_niv_precis CHECK (check_nomenclature_type(id_nomenclature_niv_precis,5));


ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT check_defaults_nomenclatures_value_is_nomenclature_in_type CHECK (check_nomenclature_type(id_nomenclature, id_type));

---------
--INDEX--
---------
CREATE INDEX index_t_nomenclatures_bib_nomenclatures_types_fkey ON t_nomenclatures USING btree (id_type);


---------
--VIEWS--
---------
CREATE OR REPLACE VIEW v_nomenclature_taxonomie AS 
  SELECT tn.id_type,
    tn.label_default AS type_label,
    tn.definition_default AS type_definition,
    tn.label_fr AS type_label_fr,
    tn.definition_fr AS type_definition_fr,
    tn.label_en AS type_label_en,
    tn.definition_en AS type_definition_en,
    tn.label_es AS type_label_es,
    tn.definition_es AS type_definition_es,
    tn.label_de AS type_label_de,
    tn.definition_de AS type_definition_de,
    tn.label_it AS type_label_it,
    tn.definition_it AS type_definition_it,
    ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.label_default AS nomenclature_label,
    n.definition_default AS nomenclature_definition,
    n.label_fr AS nomenclature_label_fr,
    n.definition_fr AS nomenclature_definition_fr,
    n.label_en AS nomenclature_label_en,
    n.definition_en AS nomenclature_definition_en,
    n.label_es AS nomenclature_label_es,
    n.definition_es AS nomenclature_definition_es,
    n.label_de AS nomenclature_label_de,
    n.definition_de AS nomenclature_definition_de,
    n.label_it AS nomenclature_label_it,
    n.definition_it AS nomenclature_definition_it,
    n.id_broader,
    n.hierarchy
  FROM ref_nomenclatures.t_nomenclatures n
    JOIN ref_nomenclatures.bib_nomenclatures_types tn ON tn.id_type = n.id_type
    JOIN ref_nomenclatures.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.active = true
  ORDER BY tn.id_type, ctn.regne, ctn.group2_inpn, n.id_nomenclature;

CREATE OR REPLACE VIEW v_technique_obs AS(
SELECT ctn.regne,ctn.group2_inpn, n.id_nomenclature, n.mnemonique, n.label_default AS label, n.definition_default AS definition, n.id_broader, n.hierarchy
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
    n.label_default AS label,
    n.definition_default AS definition,
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
    n.label_default AS label, 
    n.definition_default AS definition, 
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
    n.label_default AS label,
    n.definition_default AS definition,
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
    n.label_default AS label,
    n.definition_default AS definition,
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
    n.label_default AS label,
    n.definition_default AS definition,
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
    n.label_default AS label,
    n.definition_default AS definition,
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
    n.label_default AS label,
    n.definition_default AS definition,
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
    n.label_default AS label,
    n.definition_default AS definition,
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
    n.label_default AS label,
    n.definition_default AS definition,
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
    n.label_default AS label,
    n.definition_default AS definition,
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
    n.label_default AS label,
    n.definition_default AS definition,
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
    n.label_default AS label,
    n.definition_default AS definition,
    n.id_broader,
    n.hierarchy
   FROM ref_nomenclatures.t_nomenclatures n
     LEFT JOIN ref_nomenclatures.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_type = 5
  AND n.active = true;
--USAGE : 
--SELECT * FROM ref_nomenclatures.v_niv_precis;

CREATE OR REPLACE VIEW v_resource_typ AS 
 SELECT
    n.id_nomenclature,
    n.mnemonique,
    n.label_default AS label,
    n.definition_default AS definition,
    n.id_broader,
    n.hierarchy
  FROM ref_nomenclatures.t_nomenclatures n
  WHERE n.id_type = 102
  AND n.active = true;
--USAGE : 
--SELECT * FROM ref_nomenclatures.v_resource_typ;

CREATE OR REPLACE VIEW v_data_typ AS 
 SELECT
    n.id_nomenclature,
    n.mnemonique,
    n.label_default AS label,
    n.definition_default AS definition,
    n.id_broader,
    n.hierarchy
   FROM ref_nomenclatures.t_nomenclatures n
   WHERE n.id_type = 103
  AND n.active = true;
--USAGE : 
--SELECT * FROM ref_nomenclatures.v_data_typ;

CREATE OR REPLACE VIEW v_sampling_plan_typ AS 
 SELECT 
    n.id_nomenclature,
    n.mnemonique,
    n.label_default AS label,
    n.definition_default AS definition,
    n.id_broader,
    n.hierarchy
   FROM ref_nomenclatures.t_nomenclatures n
   WHERE n.id_type = 104
  AND n.active = true;
--USAGE : 
--SELECT * FROM ref_nomenclatures.v_sampling_plan_typ;

CREATE OR REPLACE VIEW v_sampling_units_typ AS 
 SELECT
    n.id_nomenclature,
    n.mnemonique,
    n.label_default AS label,
    n.definition_default AS definition,
    n.id_broader,
    n.hierarchy
  FROM ref_nomenclatures.t_nomenclatures n
  WHERE n.id_type = 105
  AND n.active = true;
--USAGE : 
--SELECT * FROM ref_nomenclatures.v_sampling_units_typ;

CREATE OR REPLACE VIEW v_meth_determin AS 
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.label_default AS label,
    n.definition_default AS definition,
    n.id_broader,
    n.hierarchy
   FROM ref_nomenclatures.t_nomenclatures n
     LEFT JOIN ref_nomenclatures.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_type = 106
  AND n.active = true;
--USAGE : 
--SELECT * FROM ref_nomenclatures.v_meth_determin;

------------
--TRIGGERS--
------------
CREATE TRIGGER tri_meta_dates_change_bib_nomenclatures_types
  BEFORE INSERT OR UPDATE
  ON bib_nomenclatures_types
  FOR EACH ROW
  EXECUTE PROCEDURE public.fct_trg_meta_dates_change();
  
CREATE TRIGGER tri_meta_dates_change_cor_taxref_nomenclature
  BEFORE INSERT OR UPDATE
  ON cor_taxref_nomenclature
  FOR EACH ROW
  EXECUTE PROCEDURE public.fct_trg_meta_dates_change();
  
CREATE TRIGGER tri_meta_dates_change_cor_taxref_sensitivity
  BEFORE INSERT OR UPDATE
  ON cor_taxref_sensitivity
  FOR EACH ROW
  EXECUTE PROCEDURE public.fct_trg_meta_dates_change();
  
CREATE TRIGGER tri_meta_dates_change_t_nomenclatures
  BEFORE INSERT OR UPDATE
  ON t_nomenclatures
  FOR EACH ROW
  EXECUTE PROCEDURE public.fct_trg_meta_dates_change();
