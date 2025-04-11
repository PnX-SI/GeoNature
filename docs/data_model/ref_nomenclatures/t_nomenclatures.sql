
CREATE TABLE ref_nomenclatures.t_nomenclatures (
    id_nomenclature integer NOT NULL,
    id_type integer NOT NULL,
    cd_nomenclature character varying(255) NOT NULL,
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
    id_broader integer,
    hierarchy character varying(255),
    meta_create_date timestamp without time zone DEFAULT now(),
    meta_update_date timestamp without time zone,
    active boolean DEFAULT true NOT NULL
);

CREATE SEQUENCE ref_nomenclatures.t_nomenclatures_id_nomenclature_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE ref_nomenclatures.t_nomenclatures_id_nomenclature_seq OWNED BY ref_nomenclatures.t_nomenclatures.id_nomenclature;

ALTER TABLE ONLY ref_nomenclatures.t_nomenclatures
    ADD CONSTRAINT pk_t_nomenclatures PRIMARY KEY (id_nomenclature);

ALTER TABLE ONLY ref_nomenclatures.t_nomenclatures
    ADD CONSTRAINT unique_id_type_cd_nomenclature UNIQUE (id_type, cd_nomenclature);

CREATE INDEX index_t_nomenclatures_bib_nomenclatures_types_fkey ON ref_nomenclatures.t_nomenclatures USING btree (id_type);

CREATE TRIGGER tri_meta_dates_change_t_nomenclatures BEFORE INSERT OR UPDATE ON ref_nomenclatures.t_nomenclatures FOR EACH ROW EXECUTE FUNCTION public.fct_trg_meta_dates_change();

ALTER TABLE ONLY ref_nomenclatures.t_nomenclatures
    ADD CONSTRAINT fk_t_nomenclatures_id_broader FOREIGN KEY (id_broader) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY ref_nomenclatures.t_nomenclatures
    ADD CONSTRAINT fk_t_nomenclatures_id_type FOREIGN KEY (id_type) REFERENCES ref_nomenclatures.bib_nomenclatures_types(id_type) ON UPDATE CASCADE;

