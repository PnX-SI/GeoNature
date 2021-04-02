import { Injectable } from "@angular/core";
import { HttpClient, HttpParams } from "@angular/common/http";
import { isArray } from "util";
import { ConfigService } from '@geonature/utils/configModule/core';
import { CommonService } from "@geonature_common/service/common.service";

@Injectable()
export class ValidationDataService {
  public dataLoaded: Boolean = false;
  public appConfig: any;
  constructor(
    private _http: HttpClient,
    private _commonService: CommonService,
    private _configService: ConfigService,
  ) {
    this.appConfig = this._configService.getSettings();!this.appConfig 
 && console.log('this.appConfig', this.appConfig);
  }


  // TODO REMOVE : Unused
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
    return this._http.post<any>(`${this.appConfig.API_ENDPOINT}/validation`, params);
  }

  postStatus(data: any, endpoint: Array<number>) {
    const urlStatus = `${this.appConfig.API_ENDPOINT}/validation/${endpoint}`;
    return this._http.post<any>(urlStatus, data);
  }

  getDefinitionData() {
    return this._http.get<any>(
      `${this.appConfig.API_ENDPOINT}/validation/definitions`
    );
  }

  getValidationDate(uuid) {
    return this._http.get<any>(
      `${this.appConfig.API_ENDPOINT}/validation/date/${uuid}`
    );
  }

  getStatusNames() {
    return this._http.get<any>(
      `${this.appConfig.API_ENDPOINT}/validation/statusNames`
    );
  }

  getTaxonTree() {
    return this._http.get<any>(
      `${this.appConfig.API_ENDPOINT}/synthese/taxons_tree`
    );
  }

}
