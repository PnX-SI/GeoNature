SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

CREATE SCHEMA nomenclatures;

SET search_path = nomenclatures, pg_catalog;

-------------
--FUNCTIONS--
-------------
CREATE FUNCTION check_type_nomenclature(id integer, id_type integer) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
--Function that checks if an id_nomenclature matches with wanted nomenclature type
  BEGIN
    IF id IN(SELECT id_nomenclature FROM nomenclatures.t_nomenclatures WHERE id_type_nomenclature = id_type ) THEN
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
      JOIN nomenclatures.t_nomenclatures n ON n.id_nomenclature = ctn.id_nomenclature 
      WHERE n.id_type_nomenclature = idtype
      AND group2_inpn = mygroup;
  END IF;

  IF myregne IS NOT NULL THEN
    SELECT INTO theregne DISTINCT regne 
    FROM taxonomie.cor_taxref_nomenclature ctn
    JOIN nomenclatures.t_nomenclatures n ON n.id_nomenclature = ctn.id_nomenclature 
    WHERE n.id_type_nomenclature = idtype
    AND regne = myregne;
  END IF;

  IF theregne IS NOT NULL THEN 
    IF thegroup IS NOT NULL THEN
      FOR r IN 
        SELECT DISTINCT ctn.id_nomenclature
        FROM taxonomie.cor_taxref_nomenclature ctn
        JOIN nomenclatures.t_nomenclatures n ON n.id_nomenclature = ctn.id_nomenclature 
        WHERE n.id_type_nomenclature = idtype
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
        JOIN nomenclatures.t_nomenclatures n ON n.id_nomenclature = ctn.id_nomenclature 
        WHERE n.id_type_nomenclature = idtype
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
      JOIN nomenclatures.t_nomenclatures n ON n.id_nomenclature = ctn.id_nomenclature 
      WHERE n.id_type_nomenclature = idtype
    LOOP
      RETURN NEXT r;
    END LOOP;
    RETURN;
  END IF;
END;
$$;


CREATE OR REPLACE FUNCTION calcul_sensibilite(
    cdnom integer,
    idnomenclature integer)
  RETURNS integer AS
$BODY$
  --Function to return id_nomenclature depending on observation sensibility
  --USAGE : SELECT nomenclatures.calcul_sensibilite(240,21);
  DECLARE
  idsensibilite integer;
  BEGIN
    SELECT max(id_nomenclature_niv_precis) INTO idsensibilite 
    FROM nomenclatures.cor_taxref_sensibilite
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
CREATE TABLE bib_types_nomenclatures (
    id_type_nomenclature integer NOT NULL,
    mnemonique character varying(255) NOT NULL,
    libelle_type_nomenclature character varying(255),
    definition_type_nomenclature text,
    source_type_nomenclature character varying(50),
    statut_type_nomenclature character varying(20),
    date_create timestamp without time zone DEFAULT now(),
    date_update timestamp without time zone DEFAULT now()
);
COMMENT ON TABLE bib_types_nomenclatures IS 'Description of the SINP nomenclatures list.';

CREATE TABLE t_nomenclatures (
    id_nomenclature integer NOT NULL,
    id_type_nomenclature integer,
    cd_nomenclature character varying(255) NOT NULL,
    mnemonique character varying(255) NOT NULL,
    libelle_nomenclature character varying(255),
    definition_nomenclature text,
    source_nomenclature character varying(50),
    statut_nomenclature character varying(20),
    id_parent integer,
    hierarchie character varying(255),
    date_create timestamp without time zone DEFAULT now(),
    date_update timestamp without time zone,
    actif boolean NOT NULL DEFAULT true
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
    type_relation character varying(250) NOT NULL
);

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
ALTER TABLE ONLY cor_nomenclatures_relations
    ADD CONSTRAINT cor_nomenclatures_relations_pkey PRIMARY KEY (id_nomenclature_l, id_nomenclature_r, type_relation);

ALTER TABLE ONLY bib_types_nomenclatures
    ADD CONSTRAINT bib_types_nomenclatures_pkey PRIMARY KEY (id_type_nomenclature);

ALTER TABLE ONLY t_nomenclatures
    ADD CONSTRAINT t_nomenclatures_pkey PRIMARY KEY (id_nomenclature);

ALTER TABLE ONLY cor_taxref_nomenclature
    ADD CONSTRAINT pk_cor_taxref_nomenclature PRIMARY KEY (id_nomenclature, regne, group2_inpn);

ALTER TABLE ONLY cor_taxref_sensibilite
    ADD CONSTRAINT pk_cor_taxref_sensibilite PRIMARY KEY (cd_nom, id_nomenclature_niv_precis, id_nomenclature);


---------------
--FOREIGN KEY--
---------------
ALTER TABLE ONLY cor_nomenclatures_relations
    ADD CONSTRAINT fk_cor_nomenclatures_relations_id_nomenclature_l FOREIGN KEY (id_nomenclature_l) REFERENCES t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY cor_nomenclatures_relations
    ADD CONSTRAINT fk_cor_nomenclatures_relations_id_nomenclature_r FOREIGN KEY (id_nomenclature_r) REFERENCES t_nomenclatures(id_nomenclature);


ALTER TABLE ONLY t_nomenclatures
    ADD CONSTRAINT fk_t_nomenclatures_id_parent FOREIGN KEY (id_parent) REFERENCES t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY t_nomenclatures
    ADD CONSTRAINT fk_t_nomenclatures_id_type_nomenclature FOREIGN KEY (id_type_nomenclature) REFERENCES bib_types_nomenclatures(id_type_nomenclature) ON UPDATE CASCADE;


ALTER TABLE ONLY cor_taxref_nomenclature
    ADD CONSTRAINT fk_cor_taxref_nomenclature_id_nomenclature FOREIGN KEY (id_nomenclature) REFERENCES nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;


ALTER TABLE ONLY cor_taxref_sensibilite
    ADD CONSTRAINT fk_cor_taxref_sensibilite_cd_nom FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_taxref_sensibilite
    ADD CONSTRAINT fk_cor_taxref_sensibilite_niv_precis FOREIGN KEY (id_nomenclature_niv_precis) REFERENCES nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_taxref_sensibilite
    ADD CONSTRAINT fk_cor_taxref_sensibilite_id_nomenclature FOREIGN KEY (id_nomenclature) REFERENCES nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;


--------------
--CONSTRAINS--
--------------
ALTER TABLE ONLY cor_taxref_nomenclature
    ADD CONSTRAINT check_cor_taxref_nomenclature_isgroup2inpn CHECK (taxonomie.check_is_group2inpn(group2_inpn::text) OR group2_inpn::text = 'all'::text);

ALTER TABLE ONLY cor_taxref_nomenclature
    ADD CONSTRAINT check_cor_taxref_nomenclature_isregne CHECK (taxonomie.check_is_regne(regne::text) OR regne::text = 'all'::text);


ALTER TABLE ONLY cor_taxref_sensibilite
    ADD CONSTRAINT check_cor_taxref_sensibilite_niv_precis CHECK (check_type_nomenclature(id_nomenclature_niv_precis,5));


---------
--INDEX--
---------
CREATE INDEX fki_t_nomenclatures_bib_types_nomenclatures_fkey ON t_nomenclatures USING btree (id_type_nomenclature);


---------
--VIEWS--
---------
CREATE OR REPLACE VIEW v_nomenclature_taxonomie AS 
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
  FROM nomenclatures.t_nomenclatures n
    JOIN nomenclatures.bib_types_nomenclatures tn ON tn.id_type_nomenclature = n.id_type_nomenclature
    JOIN nomenclatures.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_parent <> 0
  ORDER BY tn.id_type_nomenclature, ctn.regne, ctn.group2_inpn, n.id_nomenclature;

CREATE OR REPLACE VIEW v_technique_obs AS(
SELECT ctn.regne,ctn.group2_inpn, n.id_nomenclature, n.mnemonique, n.libelle_nomenclature, n.definition_nomenclature, n.id_parent, n.hierarchie
FROM nomenclatures.t_nomenclatures n
LEFT JOIN nomenclatures.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
WHERE n.id_type_nomenclature = 100
AND n.id_parent != 0
);
--USAGE :
--SELECT * FROM nomenclatures.v_technique_obs WHERE group2_inpn = 'Oiseaux';
--SELECT * FROM nomenclatures.v_technique_obs WHERE regne = 'Plantae';

CREATE OR REPLACE VIEW v_eta_bio AS 
  SELECT 
    n.id_nomenclature,
    n.mnemonique,
    n.libelle_nomenclature,
    n.definition_nomenclature,
    n.id_parent,
    n.hierarchie
  FROM nomenclatures.t_nomenclatures n
  WHERE n.id_type_nomenclature = 7 
  AND n.id_parent <> 0
  AND n.actif = true;
  
CREATE OR REPLACE VIEW v_stade_vie AS 
SELECT 
    ctn.regne,
    ctn.group2_inpn, 
    n.id_nomenclature, 
    n.mnemonique, 
    n.libelle_nomenclature, 
    n.definition_nomenclature, 
    n.id_parent, 
    n.hierarchie
FROM nomenclatures.t_nomenclatures n
LEFT JOIN nomenclatures.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
WHERE n.id_type_nomenclature = 10
AND n.id_parent != 0
AND n.actif = true;
--USAGE : 
--SELECT * FROM nomenclatures.v_stade_vie WHERE (regne = 'Animalia' OR regne = 'all') AND (group2_inpn = 'Amphibiens' OR group2_inpn = 'all');

CREATE OR REPLACE VIEW v_sexe AS 
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.libelle_nomenclature,
    n.definition_nomenclature,
    n.id_parent,
    n.hierarchie
   FROM nomenclatures.t_nomenclatures n
     LEFT JOIN nomenclatures.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_type_nomenclature = 9
  AND n.id_parent <> 0
  AND n.actif = true;
--USAGE : 
--SELECT * FROM nomenclatures.v_sexe WHERE (regne = 'Animalia' OR regne = 'all') AND (group2_inpn = 'Amphibiens' OR group2_inpn = 'all');

CREATE OR REPLACE VIEW v_objet_denbr AS 
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.libelle_nomenclature,
    n.definition_nomenclature,
    n.id_parent,
    n.hierarchie
   FROM nomenclatures.t_nomenclatures n
     LEFT JOIN nomenclatures.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_type_nomenclature = 6
  AND n.id_parent <> 0
  AND n.actif = true;
--USAGE : 
--SELECT * FROM nomenclatures.v_objet_denbr WHERE (regne = 'Animalia' OR regne = 'all') AND (group2_inpn = 'Amphibiens' OR group2_inpn = 'all');

CREATE OR REPLACE VIEW v_type_denbr AS 
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.libelle_nomenclature,
    n.definition_nomenclature,
    n.id_parent,
    n.hierarchie
   FROM nomenclatures.t_nomenclatures n
     LEFT JOIN nomenclatures.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_type_nomenclature = 21
  AND n.id_parent <> 0
  AND n.actif = true;
--USAGE : 
--SELECT * FROM nomenclatures.v_type_denbr WHERE (regne = 'Animalia' OR regne = 'all') AND (group2_inpn = 'Amphibiens' OR group2_inpn = 'all');

CREATE OR REPLACE VIEW v_meth_obs AS 
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.libelle_nomenclature,
    n.definition_nomenclature,
    n.id_parent,
    n.hierarchie
   FROM nomenclatures.t_nomenclatures n
     LEFT JOIN nomenclatures.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_type_nomenclature = 14
  AND n.id_parent <> 0
  AND n.actif = true;
--USAGE : 
--SELECT * FROM nomenclatures.v_meth_obs WHERE (regne = 'Animalia' OR regne = 'all') AND (group2_inpn = 'Amphibiens' OR group2_inpn = 'all');

CREATE OR REPLACE VIEW v_statut_bio AS 
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.libelle_nomenclature,
    n.definition_nomenclature,
    n.id_parent,
    n.hierarchie
   FROM nomenclatures.t_nomenclatures n
     LEFT JOIN nomenclatures.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_type_nomenclature = 13
  AND n.id_parent <> 0
  AND n.actif = true;
--USAGE : 
--SELECT * FROM nomenclatures.v_statut_bio WHERE (regne = 'Animalia' OR regne = 'all') AND (group2_inpn = 'Amphibiens' OR group2_inpn = 'all');

CREATE OR REPLACE VIEW v_naturalite AS 
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.libelle_nomenclature,
    n.definition_nomenclature,
    n.id_parent,
    n.hierarchie
   FROM nomenclatures.t_nomenclatures n
     LEFT JOIN nomenclatures.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_type_nomenclature = 8
  AND n.id_parent <> 0
  AND n.actif = true;
--USAGE : 
--SELECT * FROM nomenclatures.v_naturalite WHERE (regne = 'Animalia' OR regne = 'all');

CREATE OR REPLACE VIEW v_preuve_exist AS 
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.libelle_nomenclature,
    n.definition_nomenclature,
    n.id_parent,
    n.hierarchie
   FROM nomenclatures.t_nomenclatures n
     LEFT JOIN nomenclatures.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_type_nomenclature = 15 
  AND n.id_parent <> 0
  AND n.actif = true;
--USAGE : 
--SELECT * FROM nomenclatures.v_preuve_exist;

CREATE OR REPLACE VIEW v_statut_obs AS 
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.libelle_nomenclature,
    n.definition_nomenclature,
    n.id_parent,
    n.hierarchie
   FROM nomenclatures.t_nomenclatures n
     LEFT JOIN nomenclatures.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_type_nomenclature = 18 
  AND n.id_parent <> 0
  AND n.actif = true;
--USAGE : 
--SELECT * FROM nomenclatures.v_statut_obs;

CREATE OR REPLACE VIEW v_statut_valid AS 
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.libelle_nomenclature,
    n.definition_nomenclature,
    n.id_parent,
    n.hierarchie
   FROM nomenclatures.t_nomenclatures n
     LEFT JOIN nomenclatures.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_type_nomenclature = 101 
  AND n.id_parent <> 0
  AND n.actif = true;
--USAGE : 
--SELECT * FROM nomenclatures.v_statut_valid;

CREATE OR REPLACE VIEW v_niv_precis AS 
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.libelle_nomenclature,
    n.definition_nomenclature,
    n.id_parent,
    n.hierarchie
   FROM nomenclatures.t_nomenclatures n
     LEFT JOIN nomenclatures.cor_taxref_nomenclature ctn ON ctn.id_nomenclature = n.id_nomenclature
  WHERE n.id_type_nomenclature = 5
  AND n.id_parent <> 0
  AND n.actif = true;
--USAGE : 
--SELECT * FROM nomenclatures.v_statut_valid;
