import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { GeoJSON } from 'leaflet';
import { AppConfig } from '@geonature_config/app.config';

@Injectable()
export class DataService {
  public dataLoaded: Boolean = false;
  constructor(private _api: HttpClient) {}

  getSyntheseData(params) {
    return this._api.post<GeoJSON>(`${AppConfig.API_ENDPOINT}/synthese`, params);
  }

  getOneSyntheseObservation(id_synthese) {
    return this._api.get<GeoJSON>(`${AppConfig.API_ENDPOINT}/synthese/vsynthese/${id_synthese}`);
  }

  deleteOneSyntheseObservation(id_synthese) {
    return this._api.delete<any>(`${AppConfig.API_ENDPOINT}/synthese/synthese/${id_synthese}`);
  }
}
