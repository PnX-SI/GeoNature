import { Injectable } from "@angular/core";
import { HttpClient } from "@angular/common/http";
import { ModuleService } from "@geonature/services/module.service";
import { ConfigService } from "@geonature/services/config.service";

@Injectable({
  providedIn: "root",
})
export class OcctaxDataService {
  public currentModule;
  public moduleConfig;
  constructor(
    private _api: HttpClient,
    private _moduleService: ModuleService,
    public config: ConfigService,
  ) {
    this.currentModule = this._moduleService.currentModule;

    this.moduleConfig =
      this.currentModule.module_code == "OCCTAX"
        ? this.config["OCCTAX"]["DEFAULT"]
        : this.config["OCCTAX"][this.currentModule.module_code];
  }

  getOneReleve(id) {
    return this._api.get<any>(
      `${this.config.API_ENDPOINT}/occtax/${this.currentModule.module_code}/releve/${id}`,
    );
  }

  deleteReleve(id) {
    return this._api.delete(
      `${this.config.API_ENDPOINT}/occtax/${this.currentModule.module_code}/releve/${id}`,
    );
  }

  postOcctax(form) {
    return this._api.post(
      `${this.config.API_ENDPOINT}/occtax/${this.currentModule.module_code}/releve`,
      form,
    );
  }

  getOneCounting(id_counting) {
    return this._api.get<any>(
      `${this.config.API_ENDPOINT}/occtax/${this.currentModule.module_code}/counting/${id_counting}`,
    );
  }

  createReleve(form) {
    return this._api.post(
      `${this.config.API_ENDPOINT}/occtax/${this.currentModule.module_code}/only/releve`,
      form,
    );
  }

  updateReleve(id_releve, form) {
    return this._api.post(
      `${this.config.API_ENDPOINT}/occtax/${this.currentModule.module_code}/only/releve/${id_releve}`,
      form,
    );
  }

  createOccurrence(id_releve, form) {
    return this._api.post(
      `${this.config.API_ENDPOINT}/occtax/${this.currentModule.module_code}/releve/${id_releve}/occurrence`,
      form,
    );
  }

  updateOccurrence(id_occurrence, form) {
    return this._api.post(
      `${this.config.API_ENDPOINT}/occtax/${this.currentModule.module_code}/occurrence/${id_occurrence}`,
      form,
    );
  }

  deleteOccurrence(id) {
    return this._api.delete(
      `${this.config.API_ENDPOINT}/occtax/${this.currentModule.module_code}/occurrence/${id}`,
    );
  }
}
