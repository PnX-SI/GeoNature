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



-- Optimisation de la vue validation
DROP view gn_commons.v_synthese_validation_forwebapp;
CREATE OR REPLACE VIEW gn_commons.v_synthese_validation_forwebapp AS 
 SELECT s.id_synthese,
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



DELETE FROM gn_synthese.cor_area_synthese
WHERE id_synthese NOT IN (SELECT id_synthese FROM gn_synthese.synthese);