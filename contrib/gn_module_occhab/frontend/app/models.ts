export interface CRUVED {
  C: boolean;
  R: boolean;
  U: boolean;
  V: boolean;
  E: boolean;
  D: boolean;
}

export interface AdditionalData {
  [key: string]: any;
}

export interface OccurenceHabitat {
  additional_data?: AdditionalData;
}

export interface Station {
  id_station?: number;
  id_dataset?: number;
  habitats: Array<OccurenceHabitat>;
  cruved: CRUVED;
    dataset?: Dataset;
  additional_data?: AdditionalData;

}
export interface AcquistionFramework {
  opened: boolean;
}
export interface Dataset {
  acquisition_framework: AcquistionFramework;
}
export interface StationFeature {
  id?: number;
  type: 'Feature';
  geometry: {
    type: string;
    coordinates: [number, number];
  };
  properties: Station;
}

export interface StationFeatureCollection {
  type: 'FeatureCollection';
  features: Array<StationFeature>;
}
