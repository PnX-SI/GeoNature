import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { GeoJSON } from 'leaflet';
import { AppConfig } from '@geonature_config/app.config';
import { isArray } from 'util';

@Injectable()
export class DataService {
  public dataLoaded: Boolean = false;
  constructor(private _api: HttpClient) {}

  buildQueryUrl(params): HttpParams {
    let queryUrl = new HttpParams();
    for (let key in params) {
      if (isArray(params[key])) {
        queryUrl = queryUrl.append(key, params[key]);
      } else {
        queryUrl = queryUrl.set(key, params[key]);
      }
    }
    return queryUrl;
  }
  getSyntheseData(params) {
    return this._api.get<GeoJSON>(`${AppConfig.API_ENDPOINT}/synthese`, {
      params: this.buildQueryUrl(params)
    });
  }

  getOneSyntheseObservation(id_synthese) {
    return this._api.get<GeoJSON>(`${AppConfig.API_ENDPOINT}/synthese/vsynthese/${id_synthese}`);
  }

  deleteOneSyntheseObservation(id_synthese) {
    return this._api.delete<any>(`${AppConfig.API_ENDPOINT}/synthese/${id_synthese}`);
  }

  exportData(params) {
    return this._api.get<GeoJSON>(`${AppConfig.API_ENDPOINT}/synthese/export`, {
      params: this.buildQueryUrl(params)
    });
  }

  getTaxonTree() {
    return this._api.get<any>(`${AppConfig.API_ENDPOINT}/synthese/taxons_tree`);
  }
}
