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


-- Ne plus considérer les géométries parfaitement limitrophes comme intersectantes
CREATE OR REPLACE FUNCTION gn_synthese.fct_trig_insert_in_cor_area_synthese()
  RETURNS trigger AS
$BODY$
  DECLARE
  id_area_loop integer;
  geom_change boolean;
  BEGIN
  geom_change = false;
  IF(TG_OP = 'UPDATE') THEN
	SELECT INTO geom_change NOT public.ST_EQUALS(OLD.the_geom_local, NEW.the_geom_local);
  END IF;

  IF (geom_change) THEN
	DELETE FROM gn_synthese.cor_area_synthese WHERE id_synthese = NEW.id_synthese;
  END IF;

  -- intersection avec toutes les areas et écriture dans cor_area_synthese
    IF (TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND geom_change )) THEN
      INSERT INTO gn_synthese.cor_area_synthese SELECT
	      s.id_synthese AS id_synthese,
        a.id_area AS id_area
        FROM ref_geo.l_areas a
        JOIN gn_synthese.synthese s 
        	ON public.ST_INTERSECTS(s.the_geom_local, a.geom)  AND NOT public.ST_TOUCHES(s.the_geom_local,a.geom)
        WHERE s.id_synthese = NEW.id_synthese AND a.enable IS true;
    END IF;
  RETURN NULL;
  END;
  $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- Correction sur les données antérieures
DELETE FROM gn_synthese.cor_area_synthese cas
USING gn_synthese.synthese s , ref_geo.l_areas a
WHERE cas.id_synthese = s.id_synthese AND a.id_area = cas.id_area
AND public.ST_TOUCHES(s.the_geom_local,a.geom);
