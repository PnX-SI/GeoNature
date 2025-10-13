import { Injectable } from '@angular/core';
import { ConfigService } from '@geonature/services/config.service';
import { ModuleService } from '@geonature/services/module.service';
import { HttpClient } from '@angular/common/http';

import { Observable } from '@librairies/rxjs';
import { SyntheseDataPaginationItem } from '@geonature_common/form/synthese-form/synthese-data-pagination-item';
import { SyntheseDataSortItem } from '@geonature_common/form/synthese-form/synthese-data-sort-item';

enum ValidationsModule {
  SYNTHESE = 'SYNTHESE',
  VALIDATION = 'VALIDATION',
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

export interface ValidationCollection {
  items: ValidationItem[];
  // pagination defined on backend side
  total: number;
  page: number;
  per_page: number;
}
@Injectable()
export class HomeValidationsService {
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

    return this.MODULES_PREVALENCE.every((module) => this._isReadGrandedInModule(module));
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
    pagination: SyntheseDataPaginationItem,
    sort: SyntheseDataSortItem
  ): Observable<ValidationCollection> {
    return this._http.get<ValidationCollection>(`${this._config.API_ENDPOINT}/validation`, {
      params: {
        page: pagination.currentPage.toString(),
        per_page: pagination.perPage.toString(),
        sort: sort.sortOrder,
        order_by: sort.sortBy,
        format: 'json',
        fields:
          'id_synthese,nom_cite,observers,date_min,date_max,last_validation,nomenclature_valid_status.cd_nomenclature,nomenclature_valid_status.mnemonique,nomenclature_valid_status.label_default,validator',
        no_auto: true,
      },
    });
  }
}
