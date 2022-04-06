import { Injectable } from "@angular/core";
import { HttpClient } from "@angular/common/http";
import { AppConfig } from "@geonature_config/app.config";
import { ModuleService } from "@geonature/services/module.service"

@Injectable({
  providedIn: "root",
})
export class OcctaxDataService {
  private currentModule;
  constructor(
    private _api: HttpClient,
    private _moduleService : ModuleService

  ) {    
    this.currentModule = this._moduleService.currentModule;
   }

  getOneReleve(id) {
    return this._api.get<any>(`${AppConfig.API_ENDPOINT}/occtax/${this.currentModule.module_code}/releve/${id}`);
  }

  deleteReleve(id) {
    return this._api.delete(`${AppConfig.API_ENDPOINT}/occtax/${this.currentModule.module_code}/releve/${id}`);
  }

  postOcctax(form) {
    return this._api.post(`${AppConfig.API_ENDPOINT}/occtax/${this.currentModule.module_code}/releve`, form);
  }

  getOneCounting(id_counting) {
    return this._api.get<any>(
      `${AppConfig.API_ENDPOINT}/occtax/${this.currentModule.module_code}/counting/${id_counting}`
    );
  }

  createReleve(form) {
    return this._api.post(`${AppConfig.API_ENDPOINT}/occtax/${this.currentModule.module_code}/only/releve`, form);
  }

  updateReleve(id_releve, form) {
    return this._api.post(
      `${AppConfig.API_ENDPOINT}/occtax/${this.currentModule.module_code}/only/releve/${id_releve}`,
      form
    );
  }

  createOccurrence(id_releve, form) {
    return this._api.post(
      `${AppConfig.API_ENDPOINT}/occtax/${this.currentModule.module_code}/releve/${id_releve}/occurrence`,
      form
    );
  }

  updateOccurrence(id_occurrence, form) {
    return this._api.post(
      `${AppConfig.API_ENDPOINT}/occtax/${this.currentModule.module_code}/occurrence/${id_occurrence}`,
      form
    );
  }

  deleteOccurrence(id) {
    return this._api.delete(
      `${AppConfig.API_ENDPOINT}/occtax/${this.currentModule.module_code}/occurrence/${id}`
    );
  }

}
