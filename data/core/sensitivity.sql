
CREATE SCHEMA IF NOT EXISTS gn_sensitivity;

-- DROP TABLE gn_sensitivity.t_sensitivity_rules;

CREATE TABLE gn_sensitivity.t_sensitivity_rules
(
  id_sensitivity serial NOT NULL,
  cd_nom integer NOT NULL,
  nom_cite  character varying(1000),
  id_nomenclature_sensitivity integer NOT NULL,
  sensitivity_duration integer NOT NULL,
  sensitivity_territory character varying(1000),
  id_territory character varying(50),
  date_min date,
  date_max date,
  source character varying(250),
  active boolean DEFAULT true,
  comments character varying(500),
  meta_create_date timestamp without time zone DEFAULT now(),
  meta_update_date timestamp without time zone,
  CONSTRAINT t_sensitivity_rules_pkey PRIMARY KEY (id_sensitivity),
  CONSTRAINT fk_t_sensitivity_rules_cd_nom FOREIGN KEY (cd_nom)
      REFERENCES taxonomie.taxref (cd_nom) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION,
  CONSTRAINT fk_t_sensitivity_rules_id_nomenclature_sensitivity FOREIGN KEY (id_nomenclature_sensitivity)
      REFERENCES ref_nomenclatures.t_nomenclatures (id_nomenclature) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION,
  CONSTRAINT check_t_sensitivity_rules_niv_precis CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_sensitivity, 'SENSIBILITE'::character varying))
);
COMMENT ON TABLE gn_sensitivity.t_sensitivity_rules
  IS 'List of sensitivity rules per taxon. Compilation of national and regional list. If you whant to disable one ou several rules you can set false to enable.';

-- Trigger: tri_meta_dates_change_t_sensitivity_rules on gn_sensitivity.t_sensitivity_rules

-- DROP TRIGGER tri_meta_dates_change_t_sensitivity_rules ON gn_sensitivity.t_sensitivity_rules;

CREATE TRIGGER tri_meta_dates_change_t_sensitivity_rules
  BEFORE INSERT OR UPDATE
  ON gn_sensitivity.t_sensitivity_rules
  FOR EACH ROW
  EXECUTE PROCEDURE public.fct_trg_meta_dates_change();


-- DROP TABLE gn_sensitivity.t_sensitivity_rules_area;

CREATE TABLE gn_sensitivity.cor_sensitivity_area
(
  id_sensitivity integer,
  id_area integer,
  CONSTRAINT fk_cor_sensitivity_area_id_area_fkey FOREIGN KEY (id_area)
      REFERENCES ref_geo.l_areas (id_area) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk_cor_sensitivity_area_id_sensitivity_fkey FOREIGN KEY (id_sensitivity)
      REFERENCES gn_sensitivity.t_sensitivity_rules (id_sensitivity) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
);

COMMENT ON TABLE gn_sensitivity.cor_sensitivity_area
  IS 'Specifies where a sensitivity rule applies';


 -- lien avec la nomenclature
CREATE TABLE gn_sensitivity.cor_sensitivity_criteria (
  id_sensitivity integer,
  id_criteria integer,
  id_type_nomenclature integer,
  CONSTRAINT criteria_id_type_nomenclature_fkey FOREIGN KEY (id_type_nomenclature)
      REFERENCES ref_nomenclatures.bib_nomenclatures_types (id_type) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT criteria_id_criteria_fkey FOREIGN KEY (id_criteria)
      REFERENCES ref_nomenclatures.t_nomenclatures (id_nomenclature) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT criteria_id_sensitivity_fkey FOREIGN KEY (id_sensitivity)
      REFERENCES gn_sensitivity.t_sensitivity_rules (id_sensitivity) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
);

COMMENT ON TABLE gn_sensitivity.cor_sensitivity_criteria
  IS 'Specifies extra criteria for a sensitivity rule';


-- DROP TABLE gn_sensitivity.cor_sensitivity_area_type;

CREATE TABLE gn_sensitivity.cor_sensitivity_area_type
(
  id_nomenclature_sensitivity integer,
  id_area_type integer,
  CONSTRAINT cor_sensitivity_area_type_id_area_type_fkey FOREIGN KEY (id_area_type)
      REFERENCES ref_geo.bib_areas_types (id_type) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT cor_sensitivity_area_type_id_nomenclature_sensitivity_fkey FOREIGN KEY (id_nomenclature_sensitivity)
      REFERENCES ref_nomenclatures.t_nomenclatures (id_nomenclature) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
);

--Dégradation en fonction du niveau de sensibilité
INSERT INTO gn_sensitivity.cor_sensitivity_area_type VALUES
(ref_nomenclatures.get_id_nomenclature('SENSIBILITE', '1'), ref_geo.get_id_area_type('COM')),
(ref_nomenclatures.get_id_nomenclature('SENSIBILITE', '2'), ref_geo.get_id_area_type('M10')),
(ref_nomenclatures.get_id_nomenclature('SENSIBILITE', '3'), ref_geo.get_id_area_type('DEP'));



--- Fonction calcul de la sensibilité

CREATE OR REPLACE FUNCTION gn_sensitivity.get_id_nomenclature_sensitivity(
	my_date_obs date,
	my_cd_ref int,
	my_geom geometry,
	my_criterias jsonb
)
RETURNS integer AS
$BODY$
DECLARE niv_precis integer;
BEGIN

    -- Paramètres critères biologiques
    -- S'il existe un critère pour ce taxon
    IF EXISTS (
        SELECT 1
        FROM gn_sensitivity.t_sensitivity_rules s
        JOIN gn_sensitivity.cor_sensitivity_criteria c USING(id_sensitivity)
        WHERE taxonomie.find_cdref(cd_nom) = my_cd_ref
            AND active = TRUE
    ) THEN
        -- Si le critère est remplis
        niv_precis := (
            SELECT DISTINCT id_nomenclature_sensitivity
            FROM gn_sensitivity.t_sensitivity_rules s
            JOIN gn_sensitivity.cor_sensitivity_criteria c USING(id_sensitivity)
            JOIN (SELECT * FROM jsonb_each_text(my_criterias)) a
            ON c.id_criteria = a.value::int
            WHERE taxonomie.find_cdref(cd_nom) = my_cd_ref
                AND active = TRUE
            LIMIT 1
        );

        IF niv_precis IS NULL THEN
            niv_precis := (SELECT ref_nomenclatures.get_id_nomenclature('SENSIBILITE'::text, '0'::text));
        END IF;

        return niv_precis;
    END IF;

    -- Paramètres durée, zone géographique, période de l'observation
	SELECT INTO niv_precis s.id_nomenclature_sensitivity
	FROM (
		SELECT taxonomie.find_cdref(cd_nom) cd_ref , s.*, l.geom
		FROM gn_sensitivity.t_sensitivity_rules s
		LEFT OUTER JOIN gn_sensitivity.cor_sensitivity_area  USING(id_sensitivity)
		LEFT OUTER JOIN ref_geo.l_areas l USING(id_area)
		WHERE s.active=true
	)s
	WHERE my_cd_ref = s.cd_ref
		AND (st_intersects(st_transform(my_geom, 2154), s.geom) OR s.geom IS NULL) -- paramètre géographique
		AND (-- paramètre période
			(to_char(my_date_obs, 'MMDD') between to_char(s.date_min, 'MMDD') and to_char(s.date_max, 'MMDD') )
			OR
			(date_min IS NULL)
		)
		AND ( -- paramètre duré de validité de la règle
			(date_part('year', CURRENT_TIMESTAMP) - sensitivity_duration) <= date_part('year', my_date_obs)
		);

	IF niv_precis IS NULL THEN
		niv_precis := (SELECT ref_nomenclatures.get_id_nomenclature('SENSIBILITE', '0'));
	END IF;


	return niv_precis;

END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

-- Table permettant de stocker la sensibilité d'une donnée issue de la synthèse
CREATE TABLE gn_sensitivity.cor_sensitivity_synthese  (
    uuid_attached_row uuid NOT NULL,
    id_nomenclature_sensitivity int NOT NULL,
    computation_auto BOOLEAN NOT NULL DEFAULT (TRUE),
    id_digitizer integer,
    sensitivity_comment text,
    meta_create_date timestamp,
    meta_update_date timestamp,
    CONSTRAINT cor_sensitivity_synthese_pk PRIMARY KEY (uuid_attached_row, id_nomenclature_sensitivity),
    CONSTRAINT cor_sensitivity_synthese_id_nomenclature_sensitivity_fkey FOREIGN KEY (id_nomenclature_sensitivity)
      REFERENCES ref_nomenclatures.t_nomenclatures (id_nomenclature) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT check_synthese_sensitivity 
        CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_sensitivity, 'SENSIBILITE'::character varying)) NOT VALID
);


CREATE OR REPLACE FUNCTION gn_sensitivity.fct_tri_maj_id_sensitivity_synthese()
  RETURNS trigger AS
$BODY$
BEGIN
    UPDATE gn_synthese.synthese SET id_nomenclature_sensitivity = NEW.id_nomenclature_sensitivity
    WHERE id_synthese = NEW.id_synthese;
    RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION gn_sensitivity.fct_tri_delete_id_sensitivity_synthese()
  RETURNS trigger AS
$BODY$
BEGIN
    UPDATE gn_synthese.synthese SET id_nomenclature_sensitivity = gn_synthese.get_default_nomenclature_value('SENSIBILITE'::character varying)
    WHERE id_synthese = OLD.id_synthese;
    RETURN OLD;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


CREATE TRIGGER tri_maj_id_sensitivity_synthese
  AFTER INSERT OR UPDATE
  ON gn_sensitivity.cor_sensitivity_synthese
  FOR EACH ROW
  EXECUTE PROCEDURE gn_sensitivity.fct_tri_maj_id_sensitivity_synthese();

  
CREATE TRIGGER tri_delete_id_sensitivity_synthese
  AFTER DELETE
  ON gn_sensitivity.cor_sensitivity_synthese
  FOR EACH ROW
  EXECUTE PROCEDURE gn_sensitivity.fct_tri_delete_id_sensitivity_synthese();

CREATE TRIGGER tri_meta_dates_change_cor_sensitivity_synthese
  BEFORE INSERT OR UPDATE
  ON  gn_sensitivity.cor_sensitivity_synthese
  FOR EACH ROW
  EXECUTE PROCEDURE public.fct_trg_meta_dates_change();

