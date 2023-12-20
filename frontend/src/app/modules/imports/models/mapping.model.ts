import { Step } from "./enums.model";
import { Cruved } from "./cruved.model";

interface Mapping {
    id: number;
    label: string;
    type: string;
    active: boolean;
    public: boolean;
    cruved: Cruved;
}

export interface FieldMappingValues {
    [propName: string]: string | string[];
}


export interface FieldMapping extends Mapping {
    values: FieldMappingValues;
}


interface ContentMappingNomenclatureValues {
    [propName: string]: string;  // source value: target cd_nomenclature
}


export interface ContentMappingValues {
    [mnemonique: string]: ContentMappingNomenclatureValues;
}

export interface ContentMapping extends Mapping {
    values: ContentMappingValues;
}
