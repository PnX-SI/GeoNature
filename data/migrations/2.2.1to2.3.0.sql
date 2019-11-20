--Created here because gn_meta uses gn_commons (see above) and must be created after gn_commons
CREATE TABLE gn_commons.cor_module_dataset (
    id_module integer NOT NULL,
    id_dataset integer NOT NULL,
  CONSTRAINT pk_cor_module_dataset PRIMARY KEY (id_module, id_dataset),
  CONSTRAINT fk_cor_module_dataset_id_module FOREIGN KEY (id_module)
      REFERENCES gn_commons.t_modules (id_module) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION,
  CONSTRAINT fk_cor_module_dataset_id_dataset FOREIGN KEY (id_dataset)
      REFERENCES gn_meta.t_datasets (id_dataset) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION
);
COMMENT ON TABLE gn_commons.cor_module_dataset IS 'Define wich datasets can be used in modules';

-- on met tous les JDD comme appartenant Occtax par défaut pour assurer la rétrocompatibilité

INSERT into gn_commons.cor_module_dataset(id_module, id_dataset)
SELECT
gn_commons.get_id_module_bycode('OCCTAX'), t.id_dataset
FROM gn_meta.t_datasets t
WHERE t.active = true
;

DROP view gn_commons.v_synthese_validation_forwebapp;
CREATE OR REPLACE VIEW gn_commons.v_synthese_validation_forwebapp AS
 SELECT DISTINCT ON (s.id_synthese) s.id_synthese,
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
    t.cd_nom,
    t.cd_ref,
    t.nom_valide,
    t.lb_nom,
    t.nom_vern,
    n.mnemonique,
    n.cd_nomenclature AS cd_nomenclature_validation_status,
    n.label_default,
    v.validation_auto,
    v.validation_date
   FROM gn_synthese.synthese s
     JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
     JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
     LEFT JOIN ref_nomenclatures.t_nomenclatures n ON n.id_nomenclature = s.id_nomenclature_valid_status
     LEFT JOIN gn_commons.t_validations v ON v.uuid_attached_row = s.unique_id_sinp
  WHERE d.validable = true
  ORDER BY s.id_synthese, v.validation_date DESC;

COMMENT ON VIEW gn_commons.v_synthese_validation_forwebapp  IS 'Vue utilisée pour le module validation. Prend l''id_nomenclature dans la table synthese ainsi que toutes les colonnes de la synthese pour les filtres. On JOIN sur la vue latest_validation pour voir si la validation est auto';


-- Nettoyage monitoring
DROP TABLE IF EXISTS gn_monitoring.cor_site_application;

-- gn_commons.t_modules Changement des CHARACTER(n) en CHARACTER VARYING(n)
ALTER TABLE gn_commons.t_modules ALTER COLUMN module_path TYPE CHARACTER VARYING(255);
ALTER TABLE gn_commons.t_modules ALTER COLUMN module_external_url TYPE CHARACTER VARYING(255);
ALTER TABLE gn_commons.t_modules ALTER COLUMN module_target TYPE CHARACTER VARYING(10);
