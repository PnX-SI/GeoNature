export const DYNAMIC_FORM_DEF = [
  {
    attribut_name: 'has_medias',
    type_widget: 'bool_checkbox',
    attribut_label: "Possède des médias",
    required: false,
    value: true
  },
  {
    type_widget: 'nomenclature',
    attribut_label: "Nature de l'objet géographique",
    attribut_name: 'id_nomenclature_geo_object_nature',
    code_nomenclature_type: 'NAT_OBJ_GEO',
    required: false
  },
  {
    type_widget: 'nomenclature',
    attribut_label: 'Comportement',
    attribut_name: 'id_nomenclature_behaviour',
    code_nomenclature_type: 'OCC_COMPORTEMENT',
    required: false
  },
  {
    type_widget: 'number',
    attribut_label: 'Précision du pointage',
    attribut_name: 'precision',
    required: false
  },
  {
    type_widget: 'text',
    attribut_label: 'Méthode de regroupement',
    attribut_name: 'grp_method',
    required: false
  },
  {
    type_widget: 'text',
    attribut_label: 'Nom du lieu',
    attribut_name: 'place_name',
    required: false
  },
  {
    type_widget: 'nomenclature',
    attribut_label: 'Type de regroupement',
    attribut_name: 'id_nomenclature_grp_typ',
    code_nomenclature_type: 'TYP_GRP',
    required: false,
    multi_select: true
  },
  {
    type_widget: 'nomenclature',
    attribut_label: "Statut d'observation",
    attribut_name: 'id_nomenclature_observation_status',
    code_nomenclature_type: 'STATUT_OBS',
    required: false,
    multi_select: true
  },
  {
    type_widget: 'nomenclature',
    attribut_label: "Technique d'observation",
    attribut_name: 'id_nomenclature_obs_technique',
    code_nomenclature_type: 'METH_OBS',
    required: false,
    multi_select: true
  },
  {
    type_widget: 'nomenclature',
    attribut_label: 'Etat biologique',
    attribut_name: 'id_nomenclature_bio_condition',
    code_nomenclature_type: 'ETA_BIO',
    required: false,
    multi_select: true
  },
  {
    type_widget: 'nomenclature',
    attribut_label: 'Statut biologique',
    attribut_name: 'id_nomenclature_bio_status',
    code_nomenclature_type: 'STATUT_BIO',
    required: false,
    multi_select: true
  },
  {
    type_widget: 'nomenclature',
    attribut_label: 'Statut biogéographique',
    attribut_name: 'id_nomenclature_biogeo_status',
    code_nomenclature_type: 'STAT_BIOGEO',
    required: false,
    multi_select: true
  },
  {
    type_widget: 'nomenclature',
    attribut_label: 'Naturalité',
    attribut_name: 'id_nomenclature_naturalness',
    code_nomenclature_type: 'NATURALITE',
    required: false,
    multi_select: true
  },
  {
    type_widget: 'nomenclature',
    attribut_label: 'Méthode de détermination',
    attribut_name: 'id_nomenclature_determination_method',
    code_nomenclature_type: 'METH_DETERMIN',
    required: false,
    multi_select: true
  },
  {
    type_widget: 'nomenclature',
    attribut_label: "Preuve d'existence",
    attribut_name: 'id_nomenclature_exist_proof',
    code_nomenclature_type: 'PREUVE_EXIST',
    required: false,
    multi_select: true
  },
  {
    type_widget: 'nomenclature',
    attribut_label: 'Niveau de diffusion',
    attribut_name: 'id_nomenclature_diffusion_level',
    code_nomenclature_type: 'NIV_PRECIS',
    required: false,
    multi_select: true
  },
  {
    type_widget: 'nomenclature',
    attribut_label: 'Statut source',
    attribut_name: 'id_nomenclature_source_status',
    code_nomenclature_type: 'STATUT_SOURCE',
    required: false,
    multi_select: true
  },
  {
    type_widget: 'nomenclature',
    attribut_label: 'Floutage',
    attribut_name: 'id_nomenclature_blurring',
    code_nomenclature_type: 'DEE_FLOU',
    required: false,
    multi_select: true
  },
  // counting
  {
    type_widget: 'nomenclature',
    attribut_label: 'Stade de vie',
    attribut_name: 'id_nomenclature_life_stage',
    code_nomenclature_type: 'STADE_VIE',
    required: false,
    multi_select: true
  },
  {
    type_widget: 'nomenclature',
    attribut_label: 'Sexe',
    attribut_name: 'id_nomenclature_sex',
    code_nomenclature_type: 'SEXE',
    required: false,
    multi_select: true
  },
  {
    type_widget: 'nomenclature',
    attribut_label: 'Objet du dénombrement',
    attribut_name: 'id_nomenclature_obj_count',
    code_nomenclature_type: 'OBJ_DENBR',
    required: false,
    multi_select: true
  },
  {
    type_widget: 'nomenclature',
    attribut_label: 'Type de dénombrement',
    attribut_name: 'id_nomenclature_type_count',
    code_nomenclature_type: 'TYP_DENBR',
    required: false,
    multi_select: true
  },
  {
    type_widget: 'nomenclature',
    attribut_label: 'Statut de validation',
    attribut_name: 'id_nomenclature_valid_status',
    code_nomenclature_type: 'STATUT_VALID',
    required: false,
    multi_select: true
  },
  {
    type_widget: 'nomenclature',
    attribut_label: "Type d'objet géographique",
    attribut_name: 'id_nomenclature_geo_object_nature',
    code_nomenclature_type: 'NAT_OBJ_GEO',
    required: false,
    multi_select: true
  },
  {
    type_widget: 'nomenclature',
    attribut_label: 'Sensibilité',
    attribut_name: 'id_nomenclature_sensitivity',
    code_nomenclature_type: 'SENSIBILITE',
    required: false,
    multi_select: true
  },
  {
    type_widget: 'nomenclature',
    attribut_label: "Type d'information géographique",
    attribut_name: 'id_nomenclature_info_geo_type',
    code_nomenclature_type: 'TYP_INF_GEO',
    required: false,
    multi_select: true
  },
  {
    type_widget: 'text',
    attribut_label: 'Preuve numérique',
    attribut_name: 'digital_proof',
    required: false
  },
  {
    type_widget: 'text',
    attribut_label: 'Référence bibliographique',
    attribut_name: 'reference_biblio',
    required: false
  },
  {
    type_widget: 'text',
    attribut_label: 'Preuve non numérique',
    attribut_name: 'non_digital_proof',
    required: false
  },
  {
    type_widget: 'observers',
    attribut_label: 'Saisie par',
    attribut_name: 'id_digitiser',
    idComponent: '1',
    required: false,
    multi_select: true
  },
  {
    type_widget: 'text',
    attribut_label: 'Commentaire (relevé)',
    attribut_name: 'comment_context',
    required: false
  },
  {
    type_widget: 'text',
    attribut_label: 'Commentaire (taxon)',
    attribut_name: 'comment_description',
    required: false
  },
  {
    type_widget: 'text',
    attribut_label: 'Déterminateur',
    attribut_name: 'determiner',
    required: false
  }
];
