import { Injectable } from '@angular/core';
import { ConfigService } from '@geonature/services/config.service';
import { ModuleService } from '@geonature/services/module.service';

enum ValidationsModule {
  SYNTHESE = 'SYNTHESE',
  VALIDATION = 'VALIDATION',
}

@Injectable()
export class HomeValidationsService {
  readonly MODULES_PREVALENCE = [ValidationsModule.SYNTHESE, ValidationsModule.VALIDATION];
  constructor(
    private _config: ConfigService,
    private _moduleService: ModuleService
  ) {}

  private _isValidationsAllowedInModule(module: ValidationsModule): boolean {
    return this._moduleService.getModule(module)?.cruved['R'] != undefined;
  }
  private _isValidationsAvailableInModule(module: ValidationsModule): boolean {
    return this._config.SYNTHESE.DISCUSSION_MODULES.includes(module);
  }

  private _getUrl(module: ValidationsModule, id: number): Array<string> {
    switch (module) {
      case ValidationsModule.SYNTHESE:
        return ['/synthese', 'occurrence', id.toString(), 'discussion'];
      case ValidationsModule.VALIDATION:
        return ['/validation', 'occurrence', id.toString(), 'discussion'];
    }
  }

  get isAvailable(): boolean {
    for (const module of this.MODULES_PREVALENCE) {
      if (this._isValidationsAllowedInModule(module)) {
        if (this._isValidationsAvailableInModule(module)) {
          return this._config.HOME.DISPLAY_LATEST_VALIDATIONS;
        }
      }
    }
    return false;
  }

  computeValidationsRedirectionUrl(id: number): Array<string> {
    for (const module of this.MODULES_PREVALENCE) {
      if (this._isValidationsAllowedInModule(module)) {
        if (this._isValidationsAvailableInModule(module)) {
          return this._getUrl(module, id);
        }
      }
    }
    return [];
  }
}
