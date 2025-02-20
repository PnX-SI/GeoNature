CREATE FUNCTION gn_sensitivity.calculate_cd_diffusion_level(cd_nomenclature_diffusion_level character varying, cd_nomenclature_sensitivity character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF cd_nomenclature_diffusion_level IS NULL 
    THEN RETURN
    CASE 
      WHEN cd_nomenclature_sensitivity = '0' THEN '5'
      WHEN cd_nomenclature_sensitivity = '1' THEN '1'
      WHEN cd_nomenclature_sensitivity = '2' THEN '2'
      WHEN cd_nomenclature_sensitivity = '3' THEN '3'
      WHEN cd_nomenclature_sensitivity = '4' THEN '4'
    END;
  ELSE 
    RETURN cd_nomenclature_diffusion_level;
  END IF;
END;
$$;
CREATE FUNCTION gn_sensitivity.fct_tri_delete_id_sensitivity_synthese() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE gn_synthese.synthese AS s
    SET id_nomenclature_sensitivity = gn_synthese.get_default_nomenclature_value('SENSIBILITE'::character varying)
    FROM OLD AS deleted_rows
    WHERE s.unique_id_sinp = deleted_rows.uuid_attached_row;
    RETURN NULL;
END;
$$;
CREATE FUNCTION gn_sensitivity.fct_tri_maj_id_sensitivity_synthese() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE gn_synthese.synthese AS s
    SET id_nomenclature_sensitivity = updated_rows.id_nomenclature_sensitivity
    FROM NEW AS updated_rows
    WHERE s.unique_id_sinp = updated_rows.uuid_attached_row;
    RETURN NULL;
END;
$$;
CREATE FUNCTION gn_sensitivity.get_id_nomenclature_sensitivity(my_date_obs date, my_cd_ref integer, my_geom public.geometry, my_criterias jsonb) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE
    AS $$
        DECLARE
            sensitivity integer;
        BEGIN
            -- Paramètres durée, zone géographique, période de l'observation et critères biologique
            SELECT INTO sensitivity r.id_nomenclature_sensitivity
            FROM gn_sensitivity.t_sensitivity_rules_cd_ref r
            JOIN ref_nomenclatures.t_nomenclatures n ON n.id_nomenclature = r.id_nomenclature_sensitivity
            LEFT OUTER JOIN gn_sensitivity.cor_sensitivity_area USING(id_sensitivity)
            LEFT OUTER JOIN ref_geo.l_areas a USING(id_area)
            LEFT OUTER JOIN gn_sensitivity.cor_sensitivity_criteria c USING(id_sensitivity)
            WHERE
                ( -- taxon
                    my_cd_ref = r.cd_ref
                ) AND ( -- zone géographique de validité
                    a.geom IS NULL -- pas de restriction géographique à la validité de la règle
                    OR
                    st_intersects(my_geom, a.geom)
                ) AND ( -- période de validité
                    to_char(my_date_obs, 'MMDD') between to_char(r.date_min, 'MMDD') and to_char(r.date_max, 'MMDD')
                ) AND ( -- durée de validité
                    (date_part('year', CURRENT_TIMESTAMP) - r.sensitivity_duration) <= date_part('year', my_date_obs)
                ) AND ( -- critère
                    c.id_criteria IS NULL -- règle sans restriction de critère
                    OR
                    -- Note: no need to check criteria type, as we use id_nomenclature which can not conflict
                    c.id_criteria IN (SELECT value::int FROM jsonb_each_text(my_criterias))
                )
            ORDER BY n.cd_nomenclature DESC;

            IF sensitivity IS NULL THEN
                sensitivity := (SELECT ref_nomenclatures.get_id_nomenclature('SENSIBILITE'::text, '0'::text));
            END IF;

            return sensitivity;
        END;
        $$;

ALTER FUNCTION gn_sensitivity.get_id_nomenclature_sensitivity(my_date_obs date, my_cd_ref integer, my_geom public.geometry, my_criterias jsonb) OWNER TO geonatadmin;

SET default_tablespace = '';

SET default_table_access_method = heap;

CREATE TABLE gn_sensitivity.cor_sensitivity_area (
    id_sensitivity integer,
    id_area integer
);

ALTER TABLE gn_sensitivity.cor_sensitivity_area OWNER TO geonatadmin;

COMMENT ON TABLE gn_sensitivity.cor_sensitivity_area IS 'Specifies where a sensitivity rule applies';

CREATE TABLE gn_sensitivity.cor_sensitivity_area_type (
    id_nomenclature_sensitivity integer,
    id_area_type integer
);

ALTER TABLE gn_sensitivity.cor_sensitivity_area_type OWNER TO geonatadmin;

CREATE TABLE gn_sensitivity.cor_sensitivity_criteria (
    id_sensitivity integer,
    id_criteria integer,
    id_type_nomenclature integer
);

ALTER TABLE gn_sensitivity.cor_sensitivity_criteria OWNER TO geonatadmin;

COMMENT ON TABLE gn_sensitivity.cor_sensitivity_criteria IS 'Specifies extra criteria for a sensitivity rule';

CREATE TABLE gn_sensitivity.t_sensitivity_rules (
    id_sensitivity integer NOT NULL,
    cd_nom integer NOT NULL,
    nom_cite character varying(1000),
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
    meta_update_date timestamp without time zone
);

ALTER TABLE gn_sensitivity.t_sensitivity_rules OWNER TO geonatadmin;

COMMENT ON TABLE gn_sensitivity.t_sensitivity_rules IS 'List of sensitivity rules per taxon. Compilation of national and regional list. If you whant to disable one ou several rules you can set false to enable.';

CREATE MATERIALIZED VIEW gn_sensitivity.t_sensitivity_rules_cd_ref AS
 WITH RECURSIVE r(cd_ref) AS (
         SELECT t.cd_ref,
            r_1.id_sensitivity,
            r_1.cd_nom,
            r_1.nom_cite,
            r_1.id_nomenclature_sensitivity,
            r_1.sensitivity_duration,
            r_1.sensitivity_territory,
            r_1.id_territory,
            COALESCE(r_1.date_min, '1900-01-01'::date) AS date_min,
            COALESCE(r_1.date_max, '1900-12-31'::date) AS date_max,
            r_1.active,
            r_1.comments,
            r_1.meta_create_date,
            r_1.meta_update_date
           FROM (gn_sensitivity.t_sensitivity_rules r_1
             JOIN taxonomie.taxref t ON ((t.cd_nom = r_1.cd_nom)))
          WHERE (r_1.active = true)
        UNION ALL
         SELECT t.cd_ref,
            r_1.id_sensitivity,
            t.cd_nom,
            r_1.nom_cite,
            r_1.id_nomenclature_sensitivity,
            r_1.sensitivity_duration,
            r_1.sensitivity_territory,
            r_1.id_territory,
            r_1.date_min,
            r_1.date_max,
            r_1.active,
            r_1.comments,
            r_1.meta_create_date,
            r_1.meta_update_date
           FROM taxonomie.taxref t,
            r r_1
          WHERE (t.cd_taxsup = r_1.cd_ref)
        )
 SELECT r.cd_ref,
    r.id_sensitivity,
    r.cd_nom,
    r.nom_cite,
    r.id_nomenclature_sensitivity,
    r.sensitivity_duration,
    r.sensitivity_territory,
    r.id_territory,
    r.date_min,
    r.date_max,
    r.active,
    r.comments,
    r.meta_create_date,
    r.meta_update_date
   FROM r
  WITH NO DATA;

ALTER MATERIALIZED VIEW gn_sensitivity.t_sensitivity_rules_cd_ref OWNER TO geonatadmin;

CREATE SEQUENCE gn_sensitivity.t_sensitivity_rules_id_sensitivity_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_sensitivity.t_sensitivity_rules_id_sensitivity_seq OWNER TO geonatadmin;

ALTER SEQUENCE gn_sensitivity.t_sensitivity_rules_id_sensitivity_seq OWNED BY gn_sensitivity.t_sensitivity_rules.id_sensitivity;

ALTER TABLE ONLY gn_sensitivity.t_sensitivity_rules ALTER COLUMN id_sensitivity SET DEFAULT nextval('gn_sensitivity.t_sensitivity_rules_id_sensitivity_seq'::regclass);

ALTER TABLE gn_sensitivity.t_sensitivity_rules
    ADD CONSTRAINT check_t_sensitivity_rules_niv_precis CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_sensitivity, 'SENSIBILITE'::character varying)) NOT VALID;

ALTER TABLE ONLY gn_sensitivity.t_sensitivity_rules
    ADD CONSTRAINT t_sensitivity_rules_pkey PRIMARY KEY (id_sensitivity);

CREATE INDEX cor_sensitivity_area_id_sensitivity_idx ON gn_sensitivity.cor_sensitivity_area USING btree (id_sensitivity);

CREATE INDEX cor_sensitivity_criteria_id_sensitivity_idx ON gn_sensitivity.cor_sensitivity_criteria USING btree (id_sensitivity);

CREATE TRIGGER tri_meta_dates_change_t_sensitivity_rules BEFORE INSERT OR UPDATE ON gn_sensitivity.t_sensitivity_rules FOR EACH ROW EXECUTE FUNCTION public.fct_trg_meta_dates_change();

ALTER TABLE ONLY gn_sensitivity.cor_sensitivity_area_type
    ADD CONSTRAINT cor_sensitivity_area_type_id_area_type_fkey FOREIGN KEY (id_area_type) REFERENCES ref_geo.bib_areas_types(id_type);

ALTER TABLE ONLY gn_sensitivity.cor_sensitivity_area_type
    ADD CONSTRAINT cor_sensitivity_area_type_id_nomenclature_sensitivity_fkey FOREIGN KEY (id_nomenclature_sensitivity) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_sensitivity.cor_sensitivity_criteria
    ADD CONSTRAINT criteria_id_criteria_fkey FOREIGN KEY (id_criteria) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_sensitivity.cor_sensitivity_criteria
    ADD CONSTRAINT criteria_id_sensitivity_fkey FOREIGN KEY (id_sensitivity) REFERENCES gn_sensitivity.t_sensitivity_rules(id_sensitivity) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_sensitivity.cor_sensitivity_criteria
    ADD CONSTRAINT criteria_id_type_nomenclature_fkey FOREIGN KEY (id_type_nomenclature) REFERENCES ref_nomenclatures.bib_nomenclatures_types(id_type);

ALTER TABLE ONLY gn_sensitivity.cor_sensitivity_area
    ADD CONSTRAINT fk_cor_sensitivity_area_id_area_fkey FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area);

ALTER TABLE ONLY gn_sensitivity.cor_sensitivity_area
    ADD CONSTRAINT fk_cor_sensitivity_area_id_sensitivity_fkey FOREIGN KEY (id_sensitivity) REFERENCES gn_sensitivity.t_sensitivity_rules(id_sensitivity) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_sensitivity.t_sensitivity_rules
    ADD CONSTRAINT fk_t_sensitivity_rules_cd_nom FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_sensitivity.t_sensitivity_rules
    ADD CONSTRAINT fk_t_sensitivity_rules_id_nomenclature_sensitivity FOREIGN KEY (id_nomenclature_sensitivity) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

