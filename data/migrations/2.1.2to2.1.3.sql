--Permet la suppression d'enregistrements en synthese sans bloquage
ALTER TABLE gn_synthese.cor_area_synthese DROP CONSTRAINT fk_cor_area_synthese_id_synthese;
ALTER TABLE gn_synthese.cor_area_synthese
  ADD CONSTRAINT fk_cor_area_synthese_id_synthese FOREIGN KEY (id_synthese)
      REFERENCES gn_synthese.synthese (id_synthese) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE;

-- Correction application différé des contraintes de check sur la nomenclature
ALTER TABLE gn_sensitivity.cor_sensitivity_synthese DROP CONSTRAINT check_synthese_sensitivity;

ALTER TABLE gn_sensitivity.cor_sensitivity_synthese
  ADD CONSTRAINT check_synthese_sensitivity CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_sensitivity, 'SENSIBILITE'::character varying)) NOT VALID;

ALTER TABLE gn_sensitivity.t_sensitivity_rules DROP CONSTRAINT check_t_sensitivity_rules_niv_precis;

ALTER TABLE gn_sensitivity.t_sensitivity_rules
  ADD CONSTRAINT check_t_sensitivity_rules_niv_precis CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_sensitivity, 'SENSIBILITE'::character varying)) NOT VALID;


-- Application des règles de sensibilités à tous les sous taxons
DROP MATERIALIZED VIEW gn_sensitivity.t_sensitivity_rules_cd_ref;

CREATE MATERIALIZED VIEW gn_sensitivity.t_sensitivity_rules_cd_ref AS
WITH RECURSIVE r(cd_ref) AS (
    SELECT t.cd_ref,
       r.id_sensitivity, r.cd_nom, r.nom_cite, r.id_nomenclature_sensitivity,
       r.sensitivity_duration, r.sensitivity_territory, r.id_territory,
       COALESCE(r.date_min, '1900-01-01'::date) AS date_min,
       COALESCE(r.date_max, '1900-12-31'::date) AS date_max,
       r.active, r.comments, r.meta_create_date, r.meta_update_date
    FROM gn_sensitivity.t_sensitivity_rules r
    JOIN taxonomie.taxref t ON t.cd_nom = r.cd_nom
    WHERE r.active = true
  UNION ALL
    SELECT t.cd_ref , r.id_sensitivity, t.cd_nom, r.nom_cite, r.id_nomenclature_sensitivity,
       r.sensitivity_duration, r.sensitivity_territory, r.id_territory, r.date_min,
       r.date_max, r.active, r.comments, r.meta_create_date, r.meta_update_date
    FROM taxonomie.taxref t, r
    WHERE cd_taxsup = r.cd_ref
)
SELECT r.*
FROM r;


--Fonction pour lister les taxons parents
CREATE OR REPLACE FUNCTION taxonomie.find_all_taxons_parents(id integer)
 RETURNS SETOF integer
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
 --Param : cd_nom d'un taxon quelque soit son rang
 --Retourne le cd_nom de tous les taxons parents sous forme d'un jeu de données utilisable comme une table
 --Usage SELECT atlas.find_all_taxons_parents(197047);
  DECLARE
    inf RECORD;
  BEGIN
  FOR inf IN
	WITH RECURSIVE parents AS (
		SELECT tx1.cd_nom,tx1.cd_sup FROM taxonomie.taxref tx1 WHERE tx1.cd_nom = id
		UNION ALL 
		SELECT tx2.cd_nom,tx2.cd_sup
			FROM parents p
			JOIN taxonomie.taxref tx2 ON tx2.cd_nom = p.cd_sup
	)
	SELECT parents.cd_nom FROM parents
	JOIN taxonomie.taxref taxref ON taxref.cd_nom = parents.cd_nom
	WHERE parents.cd_nom!=id
  LOOP
      RETURN NEXT inf.cd_nom;
  END LOOP;
  END;
$function$
;

--Fonction qui retourne le cd_nom de l'ancêtre commune le plus proche
CREATE OR REPLACE FUNCTION taxonomie.find_lowest_common_ancestor(ida integer,idb integer)
 RETURNS integer
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
  --Param : cd_nom de 2 taxons
  --Retourne le cd_nom de l'ancêtre commun le plus proche
  DECLARE
  out_cd_nom integer;
BEGIN
	SELECT INTO out_cd_nom cd_nom FROM taxonomie.taxref taxref
	JOIN taxonomie.bib_taxref_rangs rg ON rg.id_rang=taxref.id_rang
	WHERE cd_nom IN 
	(SELECT taxonomie.find_all_taxons_parents(ida) INTERSECT SELECT taxonomie.find_all_taxons_parents(idb))
	ORDER BY rg.tri_rang DESC LIMIT 1;
	RETURN out_cd_nom;
END;
$function$
;
