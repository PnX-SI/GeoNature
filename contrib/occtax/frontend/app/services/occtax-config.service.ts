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
        const additional = { ...main, ...(value as any) };
        additional.form_fields = additional.form_fields || {};
        // TODO ? less config but more explanations
        /* Object.entries(main.form_fields || {}).forEach(([key, value]) => {
          if (typeof additional.form_fields[key] == "undefined") {
            additional.form_fields[key] = value;
          }
        }); */
        this.confs[key] = additional;
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
