import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { ConfigService } from '@geonature/services/config.service';

@Injectable()
export class OccHabDataService {
  constructor(
    private _http: HttpClient,
    private _gnDataService: DataFormService,
    public config: ConfigService
  ) {}

  postStation(data) {
    return this._http.post(`${this.config.API_ENDPOINT}/occhab/station`, data);
  }

  getStations(params?) {
    let queryString: HttpParams = new HttpParams();
    for (let key in params) {
      if (params[key]) {
        queryString = queryString.set(key, params[key]);
      }
    }
    return this._http.get<any>(`${this.config.API_ENDPOINT}/occhab/stations`, {
      params: queryString,
    });
  }

  getOneStation(idStation) {
    return this._http.get<any>(`${this.config.API_ENDPOINT}/occhab/station/${idStation}`);
  }

  deleteOneStation(idStation) {
    return this._http.delete<any>(`${this.config.API_ENDPOINT}/occhab/station/${idStation}`);
  }

  exportStations(export_format, idsStation?: Array<number>) {
    const sub = this._http.post(
      `${this.config.API_ENDPOINT}/occhab/export_stations/${export_format}`,
      { idsStation: idsStation },
      {
        observe: 'events',
        responseType: 'blob',
        reportProgress: true,
      }
    );
    this._gnDataService.subscribeAndDownload(sub, 'export_hab', export_format);
  }
}
