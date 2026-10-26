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
    id_nomenclature_vegetation_stratum?: number | null;
    id_nomenclature_phytosociological_abundance?: number | null;
    [key: string]: any;
}

export interface Occurrence {
    id_occurrence_occtax?: number | null;
    nom_cite?: string | null;
    nom_valide?: string | null;
    comment?: string | null;
    id_releve_occtax?: number;
    taxref?: {
        cd_nom?: number | null;
        lb_nom?: string | null;
        nom_valide?: string | null;
        regne?: string | null;
        group2_inpn?: string | null;
        group3_inpn?: string | null;
        [key: string]: any;
    } | null;
    cor_counting_occtax?: Counting[] | null;
    [key: string]: any;
}