import { Injectable } from "@angular/core";
import { HttpClient } from "@angular/common/http";
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
}
