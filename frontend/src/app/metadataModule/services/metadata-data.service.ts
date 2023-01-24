import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { ConfigService } from '@geonature/services/config.service';

@Injectable({
  providedIn: 'root',
})
export class MetadataDataService {
  constructor(private _api: HttpClient, public cs: ConfigService) {}

  createAF(value) {
    return this._api.post<any>(`${this.cs.API_ENDPOINT}/meta/acquisition_framework`, value);
  }

  updateAF(id_af, value) {
    return this._api.post<any>(
      `${this.cs.API_ENDPOINT}/meta/acquisition_framework/${id_af}`,
      value
    );
  }

  createDataset(value) {
    return this._api.post<any>(`${this.cs.API_ENDPOINT}/meta/dataset`, value);
  }

  updateDataset(id_dataset, value) {
    return this._api.post<any>(`${this.cs.API_ENDPOINT}/meta/dataset/${id_dataset}`, value);
  }

  patchDataset(id_dataset, value) {
    return this._api.patch<any>(`${this.cs.API_ENDPOINT}/meta/dataset/${id_dataset}`, value);
  }
}
