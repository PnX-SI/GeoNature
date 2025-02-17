import { Injectable } from '@angular/core';
import { ConfigService } from '@geonature/services/config.service';
import { ModuleService } from '@geonature/services/module.service';
import { HttpClient } from '@angular/common/http';

import { Observable } from '@librairies/rxjs';
import { Router } from '@librairies/@angular/router';

enum ValidationsModule {
  SYNTHESE = 'SYNTHESE',
  VALIDATION = 'VALIDATION',
}

export interface SortingItem {
  sort: 'asc' | 'desc';
  order_by: string;
}

export interface Pagination {
  total: number;
  page: number;
  per_page: number;
}
export interface ValidationItem {
  id_synthese: number;
  date_max: string;
  date_min: string;
  observers: string;
  nomenclature_valid_status: { label_default: string; [key: string]: string };
  validator: string;
  last_validation: {
    id_validation: number;
    validation_comment: string;
    validation_date: string;
    validation_auto: string;
  };
}

export interface ValidationCollection extends Pagination {
  items: ValidationItem[];
}
@Injectable()
export class HomeValidationsService {
  static readonly DEFAULT_PAGINATION: Pagination = {
    total: 0,
    page: 1,
    per_page: 4,
  };
  readonly MODULES_PREVALENCE = [ValidationsModule.SYNTHESE, ValidationsModule.VALIDATION];
  constructor(
    private _http: HttpClient,
    private _config: ConfigService,
    private _moduleService: ModuleService
  ) {}

  // //////////////////////////////////////////////////////////////////////////
  // Modules and authorization
  // //////////////////////////////////////////////////////////////////////////

  private _isReadGrandedInModule(module: ValidationsModule): boolean {
    return this._moduleService.getModule(module)?.cruved['R'] != undefined;
  }

  get isAvailable(): boolean {
    if (!this._config.HOME.DISPLAY_LATEST_VALIDATIONS) {
      return false;
    }

    return (
      this.MODULES_PREVALENCE.every((module) =>
        this._isReadGrandedInModule(module)
      )
    );
  }

  // //////////////////////////////////////////////////////////////////////////
  // Redirection to module
  // //////////////////////////////////////////////////////////////////////////

  computeValidationsRedirectionUrl(id_synthese: number): Array<string> {
    for (const module of this.MODULES_PREVALENCE) {
      if (this._isReadGrandedInModule(module)) {
        return this._getUrl(module, id_synthese);
      }
    }
    return [];
  }
  private _getUrl(module: ValidationsModule, id_synthese: number): Array<string> {
    switch (module) {
      case ValidationsModule.SYNTHESE:
        return ['/synthese', 'occurrence', id_synthese.toString(), 'validation'];
      case ValidationsModule.VALIDATION:
        return ['/validation', 'occurrence', id_synthese.toString(), 'validation'];
    }
  }

  // //////////////////////////////////////////////////////////////////////////
  // Fetch validations
  // //////////////////////////////////////////////////////////////////////////

  public fetchValidations(
    pagination: Pagination,
    sort: SortingItem
  ): Observable<ValidationCollection> {
    return this._http.get<ValidationCollection>(`${this._config.API_ENDPOINT}/validation`, {
      params: {
        page: pagination.page.toString(),
        per_page: pagination.per_page.toString(),
        sort: sort.sort,
        order_by: sort.order_by,
        format: 'json',
        fields:
          'id_synthese,nom_cite,observers,date_min,date_max,last_validation,nomenclature_valid_status.cd_nomenclature,nomenclature_valid_status.mnemonique,nomenclature_valid_status.label_default,validator',
        no_auto: true,
      },
    });
  }
}

