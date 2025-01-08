export interface Individual {
  active?: boolean;
  cd_nom: number;
  comment: string;
  id_digitiser?: number;
  // missing digitizer
  id_individual?: number;
  id_nomenclature_sex: number;
  individual_name: string;
  meta_create_date?: Date;
  meta_update_date?: Date;
  // Get Nomenclature interface nomenclature_sex?: string;
  uuid_individual?: string;
}
