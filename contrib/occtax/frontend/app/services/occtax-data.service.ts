import { Injectable } from "@angular/core";
import { HttpClient } from "@angular/common/http";
import { ConfigService } from '@geonature/utils/configModule/core';

@Injectable({
  providedIn: "root",
})
export class OcctaxDataService {

  public appConfig = this._configService().getSettings();

  constructor(
    private _api: HttpClient,
    private _configService: ConfigService,
  ) {
    this.appConfig = this._configService.getSettings();!this.appConfig 
 && console.log('this.appConfig', this.appConfig);
  }

  getOneReleve(id) {
    return this._api.get<any>(`${this.appConfig.API_ENDPOINT}/occtax/releve/${id}`);
  }

  deleteReleve(id) {
    return this._api.delete(`${this.appConfig.API_ENDPOINT}/occtax/releve/${id}`);
  }

  postOcctax(form) {
    return this._api.post(`${this.appConfig.API_ENDPOINT}/occtax/releve`, form);
  }

  getOneCounting(id_counting) {
    return this._api.get<any>(
      `${this.appConfig.API_ENDPOINT}/occtax/counting/${id_counting}`
    );
  }

  createReleve(form) {
    return this._api.post(`${this.appConfig.API_ENDPOINT}/occtax/only/releve`, form);
  }

  updateReleve(id_releve, form) {
    return this._api.post(
      `${this.appConfig.API_ENDPOINT}/occtax/only/releve/${id_releve}`,
      form
    );
  }

  createOccurrence(id_releve, form) {
    return this._api.post(
      `${this.appConfig.API_ENDPOINT}/occtax/releve/${id_releve}/occurrence`,
      form
    );
  }

  updateOccurrence(id_occurrence, form) {
    return this._api.post(
      `${this.appConfig.API_ENDPOINT}/occtax/occurrence/${id_occurrence}`,
      form
    );
  }

  deleteOccurrence(id) {
    return this._api.delete(
      `${this.appConfig.API_ENDPOINT}/occtax/occurrence/${id}`
    );
  }
}
