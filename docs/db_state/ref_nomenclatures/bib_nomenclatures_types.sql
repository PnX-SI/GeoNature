
CREATE TABLE ref_nomenclatures.bib_nomenclatures_types (
    id_type integer NOT NULL,
    mnemonique character varying(255),
    label_default character varying(255) NOT NULL,
    definition_default text,
    label_fr character varying(255) NOT NULL,
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

COMMENT ON TABLE ref_nomenclatures.bib_nomenclatures_types IS 'Types of nomenclature (SINP, CAMPanule, GeoNature...)';

CREATE SEQUENCE ref_nomenclatures.bib_nomenclatures_types_id_type_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE ref_nomenclatures.bib_nomenclatures_types_id_type_seq OWNED BY ref_nomenclatures.bib_nomenclatures_types.id_type;

ALTER TABLE ONLY ref_nomenclatures.bib_nomenclatures_types
    ADD CONSTRAINT pk_bib_nomenclatures_types PRIMARY KEY (id_type);

ALTER TABLE ONLY ref_nomenclatures.bib_nomenclatures_types
    ADD CONSTRAINT unique_bib_nomenclatures_types_mnemonique UNIQUE (mnemonique);

CREATE TRIGGER tri_meta_dates_change_bib_nomenclatures_types BEFORE INSERT OR UPDATE ON ref_nomenclatures.bib_nomenclatures_types FOR EACH ROW EXECUTE FUNCTION public.fct_trg_meta_dates_change();

