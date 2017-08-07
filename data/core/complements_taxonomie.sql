CREATE OR REPLACE FUNCTION taxonomie.check_is_inbibnoms(cdnom integer)
  RETURNS boolean AS
$BODY$
--fonction permettant de vérifier si un texte proposé correspond à un group2_inpn dans la table taxref
  BEGIN
    IF cdnom IN(SELECT cd_nom FROM taxonomie.bib_noms) THEN
      RETURN true;
    ELSE
      RETURN false;
    END IF;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

--Vue materialisée permettant d'améliorer fortement les performances des contraintes check sur les champ filtres 'regne' et 'group2_inpn'  

CREATE MATERIALIZED VIEW taxonomie.vm_regne AS (SELECT DISTINCT regne FROM taxonomie.taxref);
CREATE MATERIALIZED VIEW taxonomie.vm_group2_inpn AS (SELECT DISTINCT group2_inpn FROM taxonomie.taxref);

CREATE OR REPLACE FUNCTION taxonomie.check_is_group2inpn(mygroup text)
  RETURNS boolean AS
$BODY$
--fonction permettant de vérifier si un texte proposé correspond à un group2_inpn dans la table taxref
  BEGIN
    IF mygroup IN(SELECT group2_inpn FROM taxonomie.vm_group2_inpn) OR mygroup IS NULL THEN
      RETURN true;
    ELSE
      RETURN false;
    END IF;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;


CREATE OR REPLACE FUNCTION taxonomie.check_is_regne(myregne text)
  RETURNS boolean AS
$BODY$
--fonction permettant de vérifier si un texte proposé correspond à un regne dans la table taxref
  BEGIN
    IF myregne IN(SELECT regne FROM taxonomie.vm_regne) OR myregne IS NULL THEN
      return true;
    ELSE
      RETURN false;
    END IF;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;


CREATE OR REPLACE FUNCTION taxonomie.find_group2inpn(id integer)
  RETURNS text AS
$BODY$
--fonction permettant de renvoyer le group2_inpn d'un taxon à partir de son cd_nom
  DECLARE group2 character varying(255);
  BEGIN
    SELECT INTO group2 group2_inpn FROM taxonomie.taxref WHERE cd_nom = id;
    return group2;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;


CREATE TABLE taxonomie.cor_taxref_nomenclature
(
  id_nomenclature integer NOT NULL,
  regne character varying(255) NOT NULL,
  group2_inpn character varying(255) NOT NULL,
  date_create timestamp without time zone DEFAULT now(),
  date_update timestamp without time zone,
  CONSTRAINT cor_taxref_nomenclature_pkey PRIMARY KEY (id_nomenclature, regne, group2_inpn),
  CONSTRAINT cor_taxref_nomenclature_id_nomenclature_fkey FOREIGN KEY (id_nomenclature)
      REFERENCES meta.t_nomenclatures (id_nomenclature) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION,
  CONSTRAINT cor_taxref_nomenclature_isgroup2inpn_check CHECK (taxonomie.check_is_group2inpn(group2_inpn::text) OR group2_inpn::text = 'all'::text),
  CONSTRAINT cor_taxref_nomenclature_isregne_check CHECK (taxonomie.check_is_regne(regne::text) OR regne::text = 'all'::text)
)
WITH (
  OIDS=FALSE
);

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