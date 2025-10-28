import { Component, OnInit, TemplateRef, ViewChild, ViewEncapsulation } from '@angular/core';
import { Router, ActivatedRoute } from '@angular/router';
import { Validators } from '@angular/forms';
import { FormControl, FormGroup, FormBuilder } from '@angular/forms';

import { Observable, of } from 'rxjs';
import { forkJoin } from 'rxjs/observable/forkJoin';
import { concatMap, finalize } from 'rxjs/operators';

import { ImportDataService } from '../../../services/data.service';
import { ContentMappingService } from '../../../services/mappings/content-mapping.service';
import { CommonService } from '@geonature_common/service/common.service';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { CruvedStoreService } from '@geonature_common/service/cruved-store.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { ContentMapping, ContentMappingValues } from '../../../models/mapping.model';
import { Step } from '../../../models/enums.model';
import { Import, ImportValues, Nomenclature } from '../../../models/import.model';
import { ImportProcessService } from '../import-process.service';
import _ from 'lodash';
import { ModalData } from '@geonature/modules/imports/models/modal-data.model';
import { ConfigService } from '@geonature/services/config.service';
import { HttpErrorResponse } from '@librairies/@angular/common/http';
import { DataFormService } from '@geonature_common/form/data-form.service';

@Component({
  selector: 'observer-mapping-step',
  styleUrls: ['observer-mapping-step.component.scss'],
  templateUrl: 'observer-mapping-step.component.html',
  encapsulation: ViewEncapsulation.None,
})
export class ObserverMappingStepComponent implements OnInit {
  public step: Step;
  public observerMappingForm = new FormGroup({});
  public importData: Import;

  // public

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

    this.populateObserverMappingFormGroup();
  }

  onPreviousStep() {
    this.importProcessService.navigateToPreviousStep(this.step);
  }

  populateObserverMappingFormGroup() {
    const observerMapping: Record<string, any> = this.importData.observermapping;
    this._dataFormService.getObservers().subscribe((observers) => {
      const id_roles_authorized = observers.map((observer) => observer.id_role);
      Object.entries(observerMapping).forEach(([key, value]) => {
        if (!id_roles_authorized.includes(value.id_role)) {
          value = null;
        }
        this.observerMappingForm.addControl(key, new FormControl(value, Validators.required));
      });
    });
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
