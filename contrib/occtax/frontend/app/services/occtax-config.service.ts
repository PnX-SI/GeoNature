import { Injectable } from "@angular/core";
import { ConfigService } from "@geonature/services/config.service";
import { ModuleService } from "@geonature/services/module.service";

@Injectable({
  providedIn: "root",
})
export class OcctaxConfigService {
  private confs: any = {};
  constructor(
    public moduleService: ModuleService,
    public config: ConfigService,
  ) {
    const main = { ...this.config.OCCTAX };
    try {
      Object.entries(main.additional_confs).forEach(([key, value]) => {
        this.confs[key] = value;
      });
      delete main.additional_confs;
    } catch (error) {}
    this.confs["OCCTAX"] = main;
  }

  get moduleConf() {
    const code = this.moduleService.currentModule?.module_code;
    return this.confs[code] || this.config.OCCTAX;
  }
}
