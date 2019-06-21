CREATE OR REPLACE FUNCTION gn_sensitivity.fct_tri_maj_id_sensitivity_synthese()
  RETURNS trigger AS
$BODY$
BEGIN
    UPDATE gn_synthese.synthese SET id_nomenclature_sensitivity = NEW.id_nomenclature_sensitivity
    WHERE unique_id_sinp = NEW.uuid_attached_row;
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
    WHERE unique_id_sinp = OLD.uuid_attached_row;
    RETURN OLD;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;



-- ajout vue latest validation

CREATE VIEW gn_commons.latest_validation AS
SELECT v.*
FROM gn_commons.t_validations v
INNER JOIN (
SELECT uuid_attached_row, max(validation_date) as max_date
FROM gn_commons.t_validations
GROUP BY uuid_attached_row
) last_val
ON v.uuid_attached_row = last_val.uuid_attached_row AND v.validation_date = last_val.max_date



-- nouvelle vue pour le module validatio,
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
    t.cd_nom,
    t.cd_ref,
    t.nom_valide,
    t.lb_nom,
    t.nom_vern,
    v.id_validation,
    v.id_table_location,
    v.uuid_attached_row,
    v.id_nomenclature_valid_status,
    v.id_validator,
    v.validation_comment,
    v.validation_date,
    v.validation_auto,
    n.mnemonique,
    n.cd_nomenclature AS cd_nomenclature_validation_status,
    n.label_default
    latest_v.validation_auto
   FROM gn_synthese.synthese s
     JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
     JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
     LEFT JOIN gn_commons.t_validations v ON v.uuid_attached_row = s.unique_id_sinp
     LEFT JOIN ref_nomenclatures.t_nomenclatures n ON n.id_nomenclature = v.id_nomenclature_valid_status
     LEFT JOIN gn_commons.latest_validation latest_v ON latest.uuid_attached_row = unique_id_sinp

COMMENT ON VIEW IS 'Vue utilisée pour le module validation. Prend l''id_nomenclature dans la table synthese ainsi que toutes les colonnes de la synthese pour les filtres. On JOIN sur la vue latest_validation pour voir si la validation est auto'


-- ADD validable column in t_datasets

ALTER TABLE gn_meta.t_datasets
ADD COLUMN validable boolean DEFAULT true;

UPDATE gn_meta.t_datasets SET validable = true;

ALTER TABLE gn_meta.t_datasets
DROP COLUMN default_validity;

-- DROP FROM t_sources
ALTER TABLE gn_synthese.t_sources
DROP COLUMN validable;