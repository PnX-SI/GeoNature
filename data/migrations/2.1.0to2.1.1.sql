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


-- ajout du code nomenclature dans la vue validation

CREATE OR REPLACE VIEW gn_commons.v_validations_for_web_app AS 
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
    sources.name_source,
    sources.url_source,
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
    n.cd_nomenclature AS cd_nomenclature_validation_status
   FROM gn_synthese.synthese s
     JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
     JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
     JOIN gn_synthese.t_sources sources ON sources.id_source = s.id_source
     JOIN gn_commons.t_validations v ON v.uuid_attached_row = s.unique_id_sinp
     JOIN ref_nomenclatures.t_nomenclatures n ON n.id_nomenclature = v.id_nomenclature_valid_status;


CREATE OR REPLACE VIEW gn_commons.v_latest_validations_for_web_app AS 
 SELECT v1.id_synthese,
    v1.unique_id_sinp,
    v1.unique_id_sinp_grp,
    v1.id_source,
    v1.entity_source_pk_value,
    v1.count_min,
    v1.count_max,
    v1.nom_cite,
    v1.meta_v_taxref,
    v1.sample_number_proof,
    v1.digital_proof,
    v1.non_digital_proof,
    v1.altitude_min,
    v1.altitude_max,
    v1.the_geom_4326,
    v1.date_min,
    v1.date_max,
    v1.validator,
    v1.observers,
    v1.id_digitiser,
    v1.determiner,
    v1.comment_context,
    v1.comment_description,
    v1.meta_validation_date,
    v1.meta_create_date,
    v1.meta_update_date,
    v1.last_action,
    v1.id_dataset,
    v1.dataset_name,
    v1.id_acquisition_framework,
    v1.id_nomenclature_geo_object_nature,
    v1.id_nomenclature_info_geo_type,
    v1.id_nomenclature_grp_typ,
    v1.id_nomenclature_obs_meth,
    v1.id_nomenclature_obs_technique,
    v1.id_nomenclature_bio_status,
    v1.id_nomenclature_bio_condition,
    v1.id_nomenclature_naturalness,
    v1.id_nomenclature_exist_proof,
    v1.id_nomenclature_diffusion_level,
    v1.id_nomenclature_life_stage,
    v1.id_nomenclature_sex,
    v1.id_nomenclature_obj_count,
    v1.id_nomenclature_type_count,
    v1.id_nomenclature_sensitivity,
    v1.id_nomenclature_observation_status,
    v1.id_nomenclature_blurring,
    v1.id_nomenclature_source_status,
    v1.name_source,
    v1.url_source,
    v1.cd_nom,
    v1.cd_ref,
    v1.nom_valide,
    v1.lb_nom,
    v1.nom_vern,
    v1.id_validation,
    v1.id_table_location,
    v1.uuid_attached_row,
    v1.id_nomenclature_valid_status,
    v1.id_validator,
    v1.validation_comment,
    v1.validation_date,
    v1.validation_auto,
    v1.mnemonique,
    v1.cd_nomenclature_validation_status
   FROM gn_commons.v_validations_for_web_app v1
     JOIN ( SELECT v_validations_for_web_app.id_synthese,
            max(v_validations_for_web_app.validation_date) AS max
           FROM gn_commons.v_validations_for_web_app
          GROUP BY v_validations_for_web_app.id_synthese) v2 ON v1.validation_date = v2.max AND v1.id_synthese = v2.id_synthese;
