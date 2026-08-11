export interface Publication {
  id_publication: number;
  publication_reference: string;
  publication_url?: string;
  id_nomenclature_type_publication?: string;
  description_publication?: string;
  digitiser?: {
    id_role: number;
    nom_role: string;
  };
}
