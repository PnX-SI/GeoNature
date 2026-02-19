import { Injectable } from '@angular/core';
import { ConfigService } from '@geonature/services/config.service';
import { ModuleService } from '@geonature/services/module.service';

@Injectable({
  providedIn: 'root',
})
export class OcctaxConfigService {
  constructor(public moduleService: ModuleService, public config: ConfigService) {}

  get moduleConf() {
    const code = this.moduleService.currentModule?.module_code;
    return (code && (this.config as any)[code]) || this.config.OCCTAX;
  }
}
