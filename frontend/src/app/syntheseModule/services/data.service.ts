import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { GeoJSON } from 'leaflet';
import { AppConfig } from '@geonature_config/app.config';

@Injectable()
export class DataService {
  public dataLoaded: Boolean = false;
  constructor(private _api: HttpClient) {}

  getSyntheseData(params) {
    return this._api.post<GeoJSON>(`${AppConfig.API_ENDPOINT}/synthese/synthese`, params);
  }
}
