import { Injectable } from "@angular/core";
import { HttpClient, HttpHeaders, HttpParams } from "@angular/common/http";
import { AppConfig } from "@geonature_config/app.config";
import { CommonService } from "@geonature_common/service/common.service";
import { Nomenclature } from "@geonature_common/interfaces";

@Injectable()
export class ValidationDataService {
  public dataLoaded: Boolean = false;

  constructor(
    private _http: HttpClient,
    private _commonService: CommonService
  ) { }



  getSyntheseData(params) {
    return this._http.post<any>(`${AppConfig.API_ENDPOINT}/validation`, params);
  }

  postStatus(data: any, endpoint: Array<number>) {
    const urlStatus = `${AppConfig.API_ENDPOINT}/validation/${endpoint}`;
    return this._http.post<Nomenclature>(urlStatus, data);
  }

  getValidationDate(uuid) {
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/validation/date/${uuid}`
    );
  }

  getStatusNames() {
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/validation/statusNames`
    );
  }

  getTaxonTree() {
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/synthese/taxons_tree`
    );
  }

  getReports(params) {
    return this._http.get(
      `${AppConfig.API_ENDPOINT}/synthese/reports?${params}`
    )
  }

  createReport(params) {
    return this._http.put(`${AppConfig.API_ENDPOINT}/synthese/reports`,
      params, {
      headers: new HttpHeaders().set('Content-Type', 'application/json')
    });
  }

  deleteReport(id) {
    return this._http.delete(`${AppConfig.API_ENDPOINT}/synthese/reports/${id}`)
  }
}
