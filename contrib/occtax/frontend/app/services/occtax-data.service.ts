import { Injectable } from "@angular/core";
import { HttpClient } from "@angular/common/http";
import { AppConfig } from "@geonature_config/app.config";
import { ModuleService } from "@geonature/services/module.service"

@Injectable({
  providedIn: "root",
})
export class OcctaxDataService {
  public currentModuleCode;
  constructor(
    private _api: HttpClient,
    private _moduleService : ModuleService

  ) {
    this.currentModuleCode = this._moduleService.currentModule.module_code;
   }

  getOneReleve(id) {
    return this._api.get<any>(`${AppConfig.API_ENDPOINT}/occtax/${this.currentModuleCode}/releve/${id}`);
  }

  deleteReleve(id) {
    return this._api.delete(`${AppConfig.API_ENDPOINT}/occtax/${this.currentModuleCode}/releve/${id}`);
  }

  postOcctax(form) {
    return this._api.post(`${AppConfig.API_ENDPOINT}/occtax/${this.currentModuleCode}/releve`, form);
  }

  getOneCounting(id_counting) {
    return this._api.get<any>(
      `${AppConfig.API_ENDPOINT}/occtax/${this.currentModuleCode}/counting/${id_counting}`
    );
  }

  createReleve(form) {
    return this._api.post(`${AppConfig.API_ENDPOINT}/occtax/${this.currentModuleCode}/only/releve`, form);
  }

  updateReleve(id_releve, form) {
    return this._api.post(
      `${AppConfig.API_ENDPOINT}/occtax/${this.currentModuleCode}/only/releve/${id_releve}`,
      form
    );
  }

  createOccurrence(id_releve, form) {
    return this._api.post(
      `${AppConfig.API_ENDPOINT}/occtax/${this.currentModuleCode}/releve/${id_releve}/occurrence`,
      form
    );
  }

  updateOccurrence(id_occurrence, form) {
    return this._api.post(
      `${AppConfig.API_ENDPOINT}/occtax/${this.currentModuleCode}/occurrence/${id_occurrence}`,
      form
    );
  }

  deleteOccurrence(id) {
    return this._api.delete(
      `${AppConfig.API_ENDPOINT}/occtax/${this.currentModuleCode}/occurrence/${id}`
    );
  }

}
