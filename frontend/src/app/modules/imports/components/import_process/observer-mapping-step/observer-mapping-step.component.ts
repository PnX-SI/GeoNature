import { Component, OnInit, ViewEncapsulation } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { FormControl, FormGroup } from '@angular/forms';

import { ImportDataService } from '../../../services/data.service';
import { ContentMappingService } from '../../../services/mappings/content-mapping.service';
import { CommonService } from '@geonature_common/service/common.service';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { CruvedStoreService } from '@geonature_common/service/cruved-store.service';
import { Step } from '../../../models/enums.model';
import { Import } from '../../../models/import.model';
import { ImportProcessService } from '../import-process.service';
import _ from 'lodash';
import { ConfigService } from '@geonature/services/config.service';
import { HttpErrorResponse } from '@librairies/@angular/common/http';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { Observable, of } from '@librairies/rxjs';

@Component({
  selector: 'observer-mapping-step',
  styleUrls: ['observer-mapping-step.component.scss'],
  templateUrl: 'observer-mapping-step.component.html',
  encapsulation: ViewEncapsulation.None,
})
export class ObserverMappingStepComponent implements OnInit {
  public step: Step;
  public observerMappingForm = new FormGroup({});
  public importData: Import | null = null;
  public observerMapping: Record<string, any> = {};
  public originalObserverMapping: Record<string, any> = {};
  public observers: Observable<Array<any>> = of([]);
  public isLoading: boolean = true;

  constructor(
    public _cm: ContentMappingService,
    private _route: ActivatedRoute,
    public cruvedStore: CruvedStoreService,
    private importProcessService: ImportProcessService,
    public config: ConfigService,
    private _importDataService: ImportDataService,
    private _commonService: CommonService,
    private _dataFormService: DataFormService
  ) {}

  ngOnInit() {
    this.step = this._route.snapshot.data.step;
    this.importData = this.importProcessService.getImportData();
    if (!this.importData) {
      return;
    }

    this._importDataService.isObserverMappingAllowed().subscribe((isAllowed) => {
      if (!isAllowed) {
        this._commonService.translateToaster(
          'info',
          'Import.ObserverMapping.Messages.MappingNotAllowed'
        );
        this.processNextStep();
        return;
      }

      if (Object.keys(this.importData.observermapping).length != 0) {
        this.observerMapping = this.importData.observermapping;
        this.originalObserverMapping = _.cloneDeep(this.importData.observermapping);
        this.fetchAndPopulateObservers();
      } else {
        this._importDataService
          .generateUserMapping(this.importData.id_import)
          .subscribe((mapping) => {
            this.observerMapping = mapping;
            this.originalObserverMapping = _.cloneDeep(mapping);
            if (Object.keys(this.observerMapping).length === 0) {
              this._commonService.translateToaster(
                'info',
                'Import.ObserverMapping.Messages.NoObserverMapping'
              );
              this.processNextStep();
              return;
            }

            this.fetchAndPopulateObservers();
          });
      }
    });
  }

  onPreviousStep() {
    this.importProcessService.navigateToPreviousStep(this.step);
  }

  fetchAndPopulateObservers() {
    this._dataFormService.getObservers().subscribe((observers) => {
      this.observers = of(observers);
      this.populateObserverMappingFormGroup();
      this.isLoading = false;
    });
  }
  populateObserverMappingFormGroup() {
    this.observers.subscribe((observers) => {
      const id_roles_authorized = observers.map((observer) => observer.id_role);
      Object.entries(this.observerMapping).forEach(([key, value]) => {
        if (!id_roles_authorized.includes(value?.id_role)) {
          value = null;
        }
        if (this.observerMappingForm.controls[key]) {
          this.observerMappingForm.controls[key].setValue(value);
        } else {
          this.observerMappingForm.addControl(key, new FormControl(value));
        }
      });
    });
  }
  clearMapping() {
    this.observerMappingForm.reset();
  }

  resetMapping() {
    // Restore original mapping and repopulate the form
    this.observerMapping = _.cloneDeep(this.originalObserverMapping);
    this.populateObserverMappingFormGroup();
  }
  isNextStepAvailable(): boolean {
    return this.observerMappingForm.valid;
  }

  onNextStep() {
    this.importData.observermapping = this.observerMappingForm.value;
    this._importDataService.updateImport(this.importData.id_import, this.importData).subscribe(
      (importData) => {
        this.importProcessService.setImportData(importData);
        this.processNextStep();
      },
      (error: HttpErrorResponse) => {
        this._commonService.regularToaster('error', error.error.description);
      }
    );
  }

  processNextStep() {
    this.importProcessService.navigateToNextStep(this.step);
  }
}
