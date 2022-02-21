import { Injectable } from "@angular/core";
import { HttpClient, HttpParams } from "@angular/common/http";
import { AppConfig } from "@geonature_config/app.config";
import { CommonService } from "@geonature_common/service/common.service";
import {Nomenclature} from "@geonature_common/interfaces";

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

}
