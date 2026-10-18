export interface Nomenclature {
  active: boolean;
  cd_nomenclature: string;
  definition_default: string;
  definition_fr: string;
  hierarchy: string;
  id_nomenclature: number;
  id_type: number;
  label_default: string;
  label_fr: string;
  mnemonique: string;
  statut: string;
}

/** Dataset as returned by ``/meta/datasets`` (only the attributes used by the form components) */
export interface Dataset {
  id_dataset: number;
  dataset_name: string;
  active?: boolean;
  id_acquisition_framework?: number;
  [key: string]: any;
}

/** Acquisition framework as returned by ``/meta/acquisition_frameworks`` */
export interface AcquisitionFramework {
  id_acquisition_framework: number;
  acquisition_framework_name: string;
  [key: string]: any;
}

/** Observer, member of a list of users (``/users/menu``) */
export interface Observer {
  id_role: number;
  nom_complet: string;
  nom_role?: string;
  prenom_role?: string;
  id_menu?: number;
}

/** Geographic area as returned by ``/geo/areas`` */
export interface Area {
  id_area: number;
  area_name: string;
  area_code?: string;
  id_type?: number;
  area_type?: { type_code: string; [key: string]: any };
  [key: string]: any;
}

/** Scientific name found among the taxa above a rank, with its HTML display name */
export interface HigherTaxon {
  cd_nom: number;
  cd_ref?: number;
  lb_nom?: string;
  lb_auteur?: string;
  displayName: string;
  [key: string]: any;
}
