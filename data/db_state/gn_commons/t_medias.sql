
CREATE TABLE gn_commons.t_medias (
    id_media integer NOT NULL,
    unique_id_media uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_nomenclature_media_type integer NOT NULL,
    id_table_location integer NOT NULL,
    uuid_attached_row uuid,
    title_fr character varying(255),
    title_en character varying(255),
    title_it character varying(255),
    title_es character varying(255),
    title_de character varying(255),
    media_url character varying(255),
    media_path character varying(255),
    author character varying(100),
    description_fr text,
    description_en text,
    description_it text,
    description_es text,
    description_de text,
    is_public boolean DEFAULT true NOT NULL,
    meta_create_date timestamp without time zone DEFAULT now(),
    meta_update_date timestamp without time zone DEFAULT now()
);

COMMENT ON COLUMN gn_commons.t_medias.id_nomenclature_media_type IS 'Correspondance nomenclature GEONATURE = TYPE_MEDIA (117)';

CREATE SEQUENCE gn_commons.t_medias_id_media_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_commons.t_medias_id_media_seq OWNED BY gn_commons.t_medias.id_media;

ALTER TABLE gn_commons.t_medias
    ADD CONSTRAINT check_t_medias_media_type CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_media_type, 'TYPE_MEDIA'::character varying)) NOT VALID;

ALTER TABLE ONLY gn_commons.t_medias
    ADD CONSTRAINT pk_t_medias PRIMARY KEY (id_media);

CREATE TRIGGER tri_log_changes_t_medias AFTER INSERT OR DELETE OR UPDATE ON gn_commons.t_medias FOR EACH ROW EXECUTE FUNCTION gn_commons.fct_trg_log_changes();

CREATE TRIGGER tri_meta_dates_change_t_medias BEFORE INSERT OR UPDATE ON gn_commons.t_medias FOR EACH ROW EXECUTE FUNCTION public.fct_trg_meta_dates_change();

ALTER TABLE ONLY gn_commons.t_medias
    ADD CONSTRAINT fk_t_medias_bib_tables_location FOREIGN KEY (id_table_location) REFERENCES gn_commons.bib_tables_location(id_table_location) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_commons.t_medias
    ADD CONSTRAINT fk_t_medias_media_type FOREIGN KEY (id_nomenclature_media_type) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

