export const ModuleConfig = {
  digital_proof_validator: true,
  releve_map_zoom_level: 6,
  id_taxon_list: 500,
  default_maplist_columns: [
    { prop: "taxons", name: "Taxon" },
    { prop: "date_min", name: "Date début" },
    { prop: "observateurs", name: "Observateurs" }
  ],
  form_fields: {
    releve: {
      observers_txt: false,
      date_min: true,
      date_max: true,
      hour_min: true,
      hour_max: true,
      altitude_min: true,
      altitude_max: true,
      obs_technique: true,
      group_type: true,
      comment: true
    },
    occurrence: {
      obs_method: true,
      bio_condition: true,
      bio_status: true,
      naturalness: true,
      exist_proof: true,
      observation_status: true,
      diffusion_level: true,
      blurring: true,
      determiner: true,
      determination_method: true,
      determination_method_as_text: true,
      sample_number_proof: true,
      digital_proof: true,
      non_digital_proof: true,
      source_status: true,
      comment: true
    },
    counting: {
      life_stage: true,
      sex: true,
      obj_count: true,
      type_count: true,
      count_min: true,
      count_max: true,
      validation_status: true
    }
  }
};
