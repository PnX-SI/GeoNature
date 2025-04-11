import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Nomenclature } from '@geonature_common/interfaces';
import { ConfigService } from '@geonature/services/config.service';

@Injectable()
export class ValidationDataService {
  public dataLoaded: Boolean = false;

  constructor(
    private _http: HttpClient,
    public config: ConfigService
  ) {}

  getSyntheseData(params) {
    return this._http.post<any>(`${this.config.API_ENDPOINT}/validation`, params);
  }

  postStatus(data: any, endpoint: Array<number>) {
    const urlStatus = `${this.config.API_ENDPOINT}/validation/${endpoint}`;
    return this._http.post<Nomenclature>(urlStatus, data);
  }

  getValidationDate(uuid) {
    return this._http.get<any>(`${this.config.API_ENDPOINT}/validation/date/${uuid}`);
  }

  getStatusNames() {
    return this._http.get<any>(`${this.config.API_ENDPOINT}/validation/statusNames`);
  }

  getTaxonTree() {
    return this._http.get<any>(`${this.config.API_ENDPOINT}/synthese/taxons_tree`);
  }

  getReports(params) {
    return this._http.get(`${this.config.API_ENDPOINT}/synthese/reports?${params}`);
  }

  createReport(params) {
    return this._http.put(`${this.config.API_ENDPOINT}/synthese/reports`, params, {
      headers: new HttpHeaders().set('Content-Type', 'application/json'),
    });
  }

  deleteReport(id) {
    return this._http.delete(`${this.config.API_ENDPOINT}/synthese/reports/${id}`);
  }
}
