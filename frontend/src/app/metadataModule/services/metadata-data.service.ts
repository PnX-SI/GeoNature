import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { AppConfig } from '@geonature_config/app.config';

@Injectable({
  providedIn: 'root',
})
export class MetadataDataService {
  constructor(private _api: HttpClient) {}

  createAF(value) {
    return this._api.post<any>(`${AppConfig.API_ENDPOINT}/meta/acquisition_framework`, value);
  }

  updateAF(id_af, value) {
    return this._api.post<any>(
      `${AppConfig.API_ENDPOINT}/meta/acquisition_framework/${id_af}`,
      value
    );
  }

  createDataset(value) {
    return this._api.post<any>(`${AppConfig.API_ENDPOINT}/meta/dataset`, value);
  }

  updateDataset(id_dataset, value) {
    return this._api.post<any>(`${AppConfig.API_ENDPOINT}/meta/dataset/${id_dataset}`, value);
  }

  patchDataset(id_dataset, value) {
    return this._api.patch<any>(`${AppConfig.API_ENDPOINT}/meta/dataset/${id_dataset}`, value);
  }
}
