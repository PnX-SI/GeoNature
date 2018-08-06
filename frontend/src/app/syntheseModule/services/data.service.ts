import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { GeoJSON } from 'leaflet';
import { AppConfig } from '@geonature_config/app.config';
import { isArray } from 'util';

@Injectable()
export class DataService {
  public dataLoaded: Boolean = false;
  constructor(private _api: HttpClient) {}

  getSyntheseData(params) {
    console.log(params);
    let queryUrl = new HttpParams();
    for (let key in params) {
      if (isArray(params[key])) {
        queryUrl = queryUrl.append(key, params[key]);
        console.log(params[key], 'laaaaaaaaaaa');
      } else {
        console.log(params[key]);
        queryUrl = queryUrl.set(key, params[key]);
      }
    }
    return this._api.get<GeoJSON>(`${AppConfig.API_ENDPOINT}/synthese`, {
      params: queryUrl
    });
  }

  getOneSyntheseObservation(id_synthese) {
    return this._api.get<GeoJSON>(`${AppConfig.API_ENDPOINT}/synthese/vsynthese/${id_synthese}`);
  }

  deleteOneSyntheseObservation(id_synthese) {
    return this._api.delete<any>(`${AppConfig.API_ENDPOINT}/synthese/${id_synthese}`);
  }

  exportData(params) {
    return this._api.post<GeoJSON>(`${AppConfig.API_ENDPOINT}/synthese/export`, params);
  }
}
