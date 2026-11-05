import { FormArray, FormControl, FormGroup } from '@angular/forms';
import { Nomenclature } from '@geonature_common/interfaces';

export interface VegetationStratum {
  id_vegetation_stratum: number | null;
  id_releve_occtax?: number;
  id_nomenclature_vegetation_stratum?: number | null;
  min_height?: number | null;
  max_height?: number | null;
  average_height?: number | null;
  percentage_cover_vegetation_stratum?: number | null;
}

export interface Counting {
  id_counting_occtax?: number | null;
  id_nomenclature_life_stage?: number | null;
  id_individual?: number | null;
  id_nomenclature_sex?: number | null;
  id_nomenclature_obj_count?: number | null;
  id_nomenclature_type_count?: number | null;
  id_nomenclature_valid_status?: number | null;
  id_nomenclature_vegetation_stratum?: number | null;
  id_nomenclature_phytosociological_abundance?: number | null;
  count_min?: number | null;
  count_max?: number | null;
  medias?: unknown[] | null;
  additional_fields?: Record<string, unknown> | null;
}

export interface TaxonReference {
  cd_nom?: number | null;
  lb_nom?: string | null;
  nom_valide?: string | null;
  regne?: string | null;
  group2_inpn?: string | null;
  group3_inpn?: string | null;
  search_name?: string;
}

export interface Occurrence {
  id_occurrence_occtax?: number | null;
  id_releve_occtax?: number | null;
  id_nomenclature_obs_technique?: number | null;
  id_nomenclature_bio_condition?: number | null;
  id_nomenclature_bio_status?: number | null;
  id_nomenclature_naturalness?: number | null;
  id_nomenclature_exist_proof?: number | null;
  id_nomenclature_behaviour?: number | null;
  id_nomenclature_observation_status?: number | null;
  id_nomenclature_blurring?: number | null;
  id_nomenclature_source_status?: number | null;
  id_nomenclature_determination_method?: number | null;
  id_nomenclature_organism_support?: number | null;
  meta_v_taxref?: unknown;
  nom_cite?: string | null;
  nom_valide?: string | null;
  cd_nom?: number | null;
  comment?: string | null;
  taxref?: TaxonReference | null;
  cor_counting_occtax?: Counting[] | null;
  additional_fields?: Record<string, unknown> | null;
  determiner?: string | null;
  sample_number_proof?: string | null;
  digital_proof?: string | null;
  non_digital_proof?: string | null;
}

export interface AdditionalFieldDefinition {
  attribut_name: string;
  type_widget: string;
  value?: unknown;
  [key: string]: unknown;
}

export interface NomenclatureResponse {
  values: Nomenclature[];
}

export interface PhytoProperties {
  t_occurrences_occtax?: Occurrence[];
  t_vegetation_stratum?: VegetationStratum[];
}

export interface PhytoData {
  releve?: {
    properties?: PhytoProperties & { id_dataset?: number | null };
  } | null;
}

export interface PhytoDataWithProperties extends PhytoData {
  releve: {
    properties: PhytoProperties & { id_dataset?: number | null };
  };
}

export interface VegetationStratumFormControls {
  id_vegetation_stratum: FormControl<number | null>;
  id_nomenclature_vegetation_stratum: FormControl<number | null>;
  min_height: FormControl<number | null>;
  max_height: FormControl<number | null>;
  average_height: FormControl<number | null>;
  percentage_cover_vegetation_stratum: FormControl<number | null>;
}

export interface CountingFormControls {
  id_counting_occtax: FormControl<number | null>;
  id_nomenclature_life_stage: FormControl<number | null>;
  id_individual: FormControl<number | null>;
  id_nomenclature_sex: FormControl<number | null>;
  id_nomenclature_obj_count: FormControl<number | null>;
  id_nomenclature_type_count: FormControl<number | null>;
  id_nomenclature_vegetation_stratum: FormControl<number | null>;
  id_nomenclature_phytosociological_abundance: FormControl<number | null>;
  count_min: FormControl<number | null>;
  count_max: FormControl<number | null>;
  medias: FormControl<unknown[] | null>;
  additional_fields: FormGroup<Record<string, FormControl<unknown>>>;
}

export interface OccurrenceFormControls {
  id_nomenclature_obs_technique: FormControl<number | null>;
  id_nomenclature_bio_condition: FormControl<number | null>;
  id_nomenclature_bio_status: FormControl<number | null>;
  id_nomenclature_naturalness: FormControl<number | null>;
  id_nomenclature_exist_proof: FormControl<number | null>;
  id_nomenclature_behaviour: FormControl<number | null>;
  id_nomenclature_observation_status: FormControl<number | null>;
  id_nomenclature_blurring: FormControl<number | null>;
  id_nomenclature_source_status: FormControl<number | null>;
  determiner: FormControl<string | null>;
  id_nomenclature_determination_method: FormControl<number | null>;
  id_nomenclature_organism_support: FormControl<number | null>;
  nom_cite: FormControl<string | null>;
  cd_nom: FormControl<number | null>;
  meta_v_taxref: FormControl<unknown>;
  sample_number_proof: FormControl<string | null>;
  digital_proof: FormControl<string | null>;
  non_digital_proof: FormControl<string | null>;
  comment: FormControl<string | null>;
  additional_fields: FormGroup<Record<string, FormControl<unknown>>>;
  cor_counting_occtax: FormArray<FormGroup<CountingFormControls>>;
}

export type VegetationStratumForm = FormGroup<VegetationStratumFormControls>;
export type CountingForm = FormGroup<CountingFormControls>;
export type OccurrenceForm = FormGroup<OccurrenceFormControls>;
