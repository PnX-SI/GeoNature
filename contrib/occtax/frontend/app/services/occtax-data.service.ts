import { Injectable } from "@angular/core";
import { HttpClient } from "@angular/common/http";
import { AppConfig } from "@geonature_config/app.config";

@Injectable()
export class OcctaxDataService {
  constructor(private _api: HttpClient) {}

  getOneReleve(id) {
    return this._api.get<any>(`${AppConfig.API_ENDPOINT}/occtax/releve/${id}`);
  }

  deleteReleve(id) {
    return this._api.delete(`${AppConfig.API_ENDPOINT}/occtax/releve/${id}`);
  }

  postOcctax(form) {
    return this._api.post(`${AppConfig.API_ENDPOINT}/occtax/releve`, form);
  }

  getOneCounting(id_counting) {
    return this._api.get<any>(
      `${AppConfig.API_ENDPOINT}/occtax/counting/${id_counting}`
    );
  }
}
