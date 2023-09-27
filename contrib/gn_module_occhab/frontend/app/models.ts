export interface CRUVED {
  C: boolean;
  R: boolean;
  U: boolean;
  V: boolean;
  E: boolean;
  D: boolean;
}

export interface OccurenceHabitat {}

export interface Station {
  id_station?: number;
  habitats: Array<OccurenceHabitat>;
  cruved: CRUVED;
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
