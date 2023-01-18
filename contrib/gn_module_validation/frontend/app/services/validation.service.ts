import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';

import { MapListService } from '@geonature_common/map-list/map-list.service';
import { ValidationDataService } from '../services/data.service';
import { CommonService } from '@geonature_common/service/common.service';
import { Nomenclature } from '@geonature_common/interfaces';

@Injectable()
export class ValidationService {
  constructor(
    private _mapListService: MapListService,
    private _api: ValidationDataService,
    private _commonService: CommonService
  ) {}

  postNewValidStatusAndUpdateUI(value, idSynthese: Array<number>): Observable<Nomenclature> {
    return this._api.postStatus(value, idSynthese).pipe(
      tap((newValidationStatus) => {
        this._commonService.translateToaster('success', 'Nouveau statut de validation enregistré');
        this._mapListService.tableData.forEach((obs) => {
          if (idSynthese.includes(obs.id_synthese)) {
            obs['nomenclature_valid_status'] = newValidationStatus;
            obs['validation_date'] = {
              validation_auto: false,
              validation_date: new Date(),
            };
          }
        });
      })
    );
  }
}
