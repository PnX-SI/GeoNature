
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

COMMENT ON TABLE gn_sensitivity.t_sensitivity_rules IS 'List of sensitivity rules per taxon. Compilation of national and regional list. If you whant to disable one ou several rules you can set false to enable.';

CREATE SEQUENCE gn_sensitivity.t_sensitivity_rules_id_sensitivity_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_sensitivity.t_sensitivity_rules_id_sensitivity_seq OWNED BY gn_sensitivity.t_sensitivity_rules.id_sensitivity;

ALTER TABLE gn_sensitivity.t_sensitivity_rules
    ADD CONSTRAINT check_t_sensitivity_rules_niv_precis CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_sensitivity, 'SENSIBILITE'::character varying)) NOT VALID;

ALTER TABLE ONLY gn_sensitivity.t_sensitivity_rules
    ADD CONSTRAINT t_sensitivity_rules_pkey PRIMARY KEY (id_sensitivity);

CREATE TRIGGER tri_meta_dates_change_t_sensitivity_rules BEFORE INSERT OR UPDATE ON gn_sensitivity.t_sensitivity_rules FOR EACH ROW EXECUTE FUNCTION public.fct_trg_meta_dates_change();

ALTER TABLE ONLY gn_sensitivity.t_sensitivity_rules
    ADD CONSTRAINT fk_t_sensitivity_rules_cd_nom FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_sensitivity.t_sensitivity_rules
    ADD CONSTRAINT fk_t_sensitivity_rules_id_nomenclature_sensitivity FOREIGN KEY (id_nomenclature_sensitivity) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

