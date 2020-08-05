
-- vue validation de gn_commons necessitant le schéma synthese
CREATE OR REPLACE VIEW gn_commons.v_synthese_validation_forwebapp AS
SELECT  s.id_synthese,
    s.unique_id_sinp,
    s.unique_id_sinp_grp,
    s.id_source,
    s.entity_source_pk_value,
    s.count_min,
    s.count_max,
    s.nom_cite,
    s.meta_v_taxref,
    s.sample_number_proof,
    s.digital_proof,
    s.non_digital_proof,
    s.altitude_min,
    s.altitude_max,
    s.the_geom_4326,
    s.date_min,
    s.date_max,
    s.validator,
    s.observers,
    s.id_digitiser,
    s.determiner,
    s.comment_context,
    s.comment_description,
    s.meta_validation_date,
    s.meta_create_date,
    s.meta_update_date,
    s.last_action,
    d.id_dataset,
    d.dataset_name,
    d.id_acquisition_framework,
    s.id_nomenclature_geo_object_nature,
    s.id_nomenclature_info_geo_type,
    s.id_nomenclature_grp_typ,
    s.id_nomenclature_obs_meth,
    s.id_nomenclature_obs_technique,
    s.id_nomenclature_bio_status,
    s.id_nomenclature_bio_condition,
    s.id_nomenclature_naturalness,
    s.id_nomenclature_exist_proof,
    s.id_nomenclature_diffusion_level,
    s.id_nomenclature_life_stage,
    s.id_nomenclature_sex,
    s.id_nomenclature_obj_count,
    s.id_nomenclature_type_count,
    s.id_nomenclature_sensitivity,
    s.id_nomenclature_observation_status,
    s.id_nomenclature_blurring,
    s.id_nomenclature_source_status,
    s.id_nomenclature_valid_status,
    s.reference_biblio,
    t.cd_nom,
    t.cd_ref,
    t.nom_valide,
    t.lb_nom,
    t.nom_vern,
    n.mnemonique,
    n.cd_nomenclature AS cd_nomenclature_validation_status,
    n.label_default,
    v.validation_auto,
    v.validation_date,
    ST_asgeojson(s.the_geom_4326) as geojson
   FROM gn_synthese.synthese s
    JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
    JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
    LEFT JOIN ref_nomenclatures.t_nomenclatures n ON n.id_nomenclature = s.id_nomenclature_valid_status
    LEFT JOIN LATERAL (
        SELECT v.validation_auto, v.validation_date
        FROM gn_commons.t_validations v
        WHERE v.uuid_attached_row = s.unique_id_sinp
        ORDER BY v.validation_date DESC
        LIMIT 1
    ) v ON true
  WHERE d.validable = true AND NOT s.unique_id_sinp IS NULL;

COMMENT ON VIEW gn_commons.v_synthese_validation_forwebapp  IS 'Vue utilisée pour le module validation. Prend l''id_nomenclature dans la table synthese ainsi que toutes les colonnes de la synthese pour les filtres. On JOIN sur la vue latest_validation pour voir si la validation est auto';


CREATE TABLE gn_commons.t_medias_temp
(
  id_media integer NOT NULL,
  unique_id_media uuid NOT NULL DEFAULT public.uuid_generate_v4(),
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
  is_public boolean NOT NULL DEFAULT true
);
COMMENT ON COLUMN gn_commons.t_medias_temp.id_nomenclature_media_type IS 'Table temporaire des medias';

CREATE SEQUENCE gn_commons.t_medias_temp_id_media_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE gn_commons.t_medias_temp_id_media_seq OWNED BY gn_commons.t_medias_temp.id_media;
ALTER TABLE ONLY gn_commons.t_medias_temp ALTER COLUMN id_media SET DEFAULT nextval('gn_commons.t_medias_temp_id_media_seq'::regclass);
SELECT pg_catalog.setval('gn_commons.t_medias_temp_id_media_seq', 1, false);

ALTER TABLE ONLY gn_commons.t_medias_temp
    ADD CONSTRAINT pk_t_medias_temp PRIMARY KEY (id_media);

ALTER TABLE ONLY gn_commons.t_medias_temp
    ADD CONSTRAINT fk_t_medias_temp_media_type FOREIGN KEY (id_nomenclature_media_type) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_commons.t_medias_temp
  ADD CONSTRAINT fk_t_medias_temp_bib_tables_location FOREIGN KEY (id_table_location) REFERENCES gn_commons.bib_tables_location (id_table_location) ON UPDATE CASCADE;


