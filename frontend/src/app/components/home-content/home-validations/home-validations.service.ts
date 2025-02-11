import { Injectable } from '@angular/core';
import { ConfigService } from '@geonature/services/config.service';
import { ModuleService } from '@geonature/services/module.service';
import { HttpClient } from '@angular/common/http';

import { Observable } from '@librairies/rxjs';

enum ValidationsModule {
  SYNTHESE = 'SYNTHESE',
  VALIDATION = 'VALIDATION',
}

export interface Pagination {
  total: number;
  page: number;
  per_page: number;
}
export type ValidationItem = any;

export interface ValidationCollection extends Pagination {
  items: ValidationItem[];
}
@Injectable()
export class HomeValidationsService {
  readonly MODULES_PREVALENCE = [ValidationsModule.SYNTHESE, ValidationsModule.VALIDATION];
  constructor(
    private _http: HttpClient,
    private _config: ConfigService,
    private _moduleService: ModuleService
  ) {}

  private _isValidationsAllowedInModule(module: ValidationsModule): boolean {
    return this._moduleService.getModule(module)?.cruved['R'] != undefined;
  }

  get isAvailable(): boolean {
    if (!this._config.HOME.DISPLAY_LATEST_VALIDATIONS) {
      return false;
    }
    for (const module of this.MODULES_PREVALENCE) {
      if (this._isValidationsAllowedInModule(module)) {
          return true;
      }
    }
    return false;
  }

  private _getUrl(module: ValidationsModule, id_synthese: number): Array<string> {
    switch (module) {
      case ValidationsModule.SYNTHESE:
        return ['/synthese', 'occurrence', id_synthese.toString(), 'validation'];
      case ValidationsModule.VALIDATION:
        return ['/validation', 'occurrence', id_synthese.toString(), 'validation'];
    }
  }

  computeValidationsRedirectionUrl(id_synthese: number): Array<string> {
    for (const module of this.MODULES_PREVALENCE) {
      if (this._isValidationsAllowedInModule(module)) {
          return this._getUrl(module, id_synthese);
      }
    }
    return [];
  }

  public fetchValidations(params: Record<string, string>): any {
    return this._http.get<ValidationCollection>(`${this._config.API_ENDPOINT}/validation`, {
      params: params,
    });
  }
}
