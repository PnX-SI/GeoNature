import { Injectable } from '@angular/core';
import { Resolve, ActivatedRouteSnapshot, RouterStateSnapshot, Router } from '@angular/router';
import { HttpErrorResponse } from '@angular/common/http';

import { Observable, EMPTY, of } from 'rxjs';
import { catchError, concatMap } from 'rxjs/operators';

import { CommonService } from "@geonature_common/service/common.service";

import { ImportProcessService } from './import-process.service';
import { Import } from "../../models/import.model";
import { Step } from "../../models/enums.model";
import { DataService } from "../../services/data.service";
import { ConfigService } from '@geonature/services/config.service';

@Injectable()
export class ImportProcessResolver implements Resolve<Import>{
  constructor(
    private router: Router,
    private ds: DataService,
    private commonService: CommonService,
    private importProcessService: ImportProcessService,
    public config: ConfigService
  ) { }

  resolve(route: ActivatedRouteSnapshot,
          state: RouterStateSnapshot): Import | Observable<Import> {
    let step: Step = route.data.step;
    if (step == Step.Upload && route.params.id_import === undefined) {
      // creating new import
      this.importProcessService.setImportData(null);
    } else {
      let importId: number = Number(route.params.id_import);
      let importData: Import = this.importProcessService.getImportData();
      if (importData === null || importData.id_import != importId) {
        // the service as no import yet, or the import id has changed
        return this.ds.getOneImport(importId).pipe(
          // typically 404 not found or 403 forbidden, we redirect to import list
          catchError((error: HttpErrorResponse) => {
            this.commonService.regularToaster("error", error.error.description);
            this.router.navigate([this.config.IMPORT.MODULE_URL]);
            return EMPTY;
          }),
          concatMap((importData: Import) => {
            this.importProcessService.setImportData(importData);
            if (this.importProcessService.getLastAvailableStep() < step) {
              this.commonService.regularToaster("info", "Vous avez été redirigé vers la dernière étape validée.");
              this.importProcessService.navigateToLastStep();
              return EMPTY;
            } else {
              return of(importData);
            }
          }),
        );
      } else {
        // previous import is still valid
        if (this.importProcessService.getLastAvailableStep() < step) {
          // this step is not available yet
          // note: this check is here and not in guard as we need resolved importData
          return EMPTY;
        } else {
          return importData;
        }
      }
    }
  }
}
