import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { isArray } from 'util';
import { AppConfig } from '@geonature_config/app.config';
import { CommonService } from '@geonature_common/service/common.service';


@Injectable()
export class DataService {

  public dataLoaded: Boolean = false;

  constructor(private _http: HttpClient, private _commonService: CommonService) { }

  buildQueryUrl(params): HttpParams {
    let queryUrl = new HttpParams();
    for (let key in params) {
      if (isArray(params[key])) {
        queryUrl = queryUrl.set(key, params[key]);
      } else {
        queryUrl = queryUrl.set(key, params[key]);
      }
    }
    return queryUrl;
  }

  getSyntheseData(params) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/validation`, {
      params: this.buildQueryUrl(params)
    });
  }

  getValidationHistory(id_synthese) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/validation/history/${id_synthese}`, {
    });
  }

  postStatus(data: any, endpoint: string) {
    const urlStatus = `${AppConfig.API_ENDPOINT}/validation/${endpoint}`;
    return this._http.post<any>(urlStatus, data);
  }

  getDefinitionData() {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/validation/definitions`);
  }

  getValidationDate(id) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/validation/date/${id}`);
  }

  getStatusNames() {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/validation/statusNames`);
  }

  getTaxonTree() {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/synthese/taxons_tree`);
  }

  getOneSyntheseObservation(id_synthese) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/synthese/vsynthese/${id_synthese}`);
  }

}
