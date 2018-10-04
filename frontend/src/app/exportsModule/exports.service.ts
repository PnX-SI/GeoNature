import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { AppConfig } from '../../conf/app.config';

@Injectable()
export class ExportsService {
  constructor(private _api: HttpClient) {}

  getFakeViewList() {
    return [
      {
        id_view: 1,
        view_name: 'Export au format "Standard d\'occurrences de taxons" '
      }
    ];
  }
  getViewList() {
    return this._api.get<any>(`${AppConfig.API_ENDPOINT}/export/viewList`).map(data => data.json());
  }
}
