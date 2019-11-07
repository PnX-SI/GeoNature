import { Injectable } from "@angular/core";
import { HttpClient, HttpParams } from "@angular/common/http";
import { AppConfig } from "@geonature_config/app.config";
import { ModuleConfig } from "../module.config";

@Injectable()
export class OccHabDataService {
  constructor(private _http: HttpClient) {}

  postStation(data) {
    return this._http.post(
      `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/station`,
      data
    );
  }

  getStations(params?) {
    let queryString: HttpParams = new HttpParams();
    for (let key in params) {
      if (params[key]) {
        queryString = queryString.set(key, params[key]);
      }
    }
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/stations`,
      { params: queryString }
    );
  }

  getOneStation(id_station) {
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/station/${id_station}`
    );
  }
}
