import { Component, OnInit, ViewChild } from '@angular/core';
import { ImportDataService } from '../../../services/data.service';
import { FieldMappingService } from '@geonature/modules/imports/services/mappings/field-mapping.service';
import { FieldMappingModalComponent } from './field-mapping-modal/field-mapping-modal.component';
import { Cruved, toBooleanCruved } from '@geonature/modules/imports/models/cruved.model';
import { Step } from '@geonature/modules/imports/models/enums.model';
import { ActivatedRoute } from '@angular/router';
import { ImportProcessService } from '../import-process.service';
import { CruvedStoreService } from '@geonature_common/service/cruved-store.service';
import { concatMap, finalize, first, flatMap, skip, take } from 'rxjs/operators';
import { Observable, Subscription, of } from 'rxjs';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { Import } from '@geonature/modules/imports/models/import.model';
import {
  ContentMapping,
  FieldMappingValues,
} from '@geonature/modules/imports/models/mapping.model';
import { ConfigService } from '@geonature/services/config.service';
import { FormControl } from '@angular/forms';

@Component({
  selector: 'pnx-fields-mapping-step',
  templateUrl: './fields-mapping-step.component.html',
  styleUrls: ['./fields-mapping-step.component.scss'],
})
export class FieldsMappingStepComponent implements OnInit {
  @ViewChild('saveMappingModal') saveMappingModal;
  public targetFields;
  public sourceFields: Array<string> = [];
  public isReady: boolean = false;
  public cruved: Cruved;
  public importData: Import;
  public updateAvailable: boolean = false;
  public step: Step;
  public modalCreateMappingForm = new FormControl('');

  constructor(
    public _fieldMappingService: FieldMappingService,
    private _route: ActivatedRoute,
    private importProcessService: ImportProcessService,
    private _cruvedStore: CruvedStoreService,
    private _importDataService: ImportDataService,
    private _modalService: NgbModal,
    private _configService: ConfigService
  ) {}

  ngOnInit() {
    this._fieldMappingService.retrieveData();
    this.importData = this.importProcessService.getImportData();
    this._fieldMappingService.data
      .pipe(skip(1), take(1)) // First value is either null or the value from the last import so we skip it, and we don't need to get it multiple times
      .subscribe(({ fieldMappings, targetFields, sourceFields }) => {
        if (!fieldMappings) return;
        this._fieldMappingService.parseData({ fieldMappings, targetFields, sourceFields });
        this.targetFields = this._fieldMappingService.getTargetFieldsData();
        this.sourceFields = this._fieldMappingService.getSourceFieldsData();
        this._fieldMappingService.initForm();
        this._fieldMappingService.populateMappingForm();
        if (this.importData.fieldmapping) {
          this._fieldMappingService.fillFormWithMapping(this.importData.fieldmapping, false);
        }
        this.isReady = true;
      });
    this.step = this._route.snapshot.data.step;
    this.cruved = toBooleanCruved(this._cruvedStore.cruved.IMPORT.module_objects.MAPPING.cruved);
  }

  /**
   * Unsubscribe from
   */
  ngOnDestroy() {
    this._fieldMappingService.destroySubscription();
  }

  /**
   * Count the number of invalid controls
   * in an entity FormGroup
   */
  invalidEntityControls(entityFormLabel: string) {
    let result: number = 0;
    this.targetFields
      .find(({ entity }) => entity.label === entityFormLabel)
      .themes.forEach(({ fields }) => {
        fields.forEach((field) => {
          let control = this._fieldMappingService.mappingFormGroup.controls[field.name_field];
          result += control.status === 'INVALID' ? 1 : 0;
        });
      });
    return result;
  }

  onNextStep() {
    if (!this._fieldMappingService.mappingFormGroup?.valid) {
      return;
    }
    let mappingValue = this._fieldMappingService.currentFieldMapping.value;
    if (
      this._fieldMappingService.mappingFormGroup.dirty &&
      (this.cruved.C || (mappingValue && mappingValue.cruved.U && !mappingValue.public)) //
    ) {
      if (mappingValue && !mappingValue.public) {
        this.updateAvailable = true;
        this.modalCreateMappingForm.setValue(mappingValue.label);
      } else {
        this.updateAvailable = false;
        this.modalCreateMappingForm.setValue('');
      }
      console.log(this.updateAvailable, this.modalCreateMappingForm.value);
      this._modalService.open(this.saveMappingModal, { size: 'lg' });
    } else {
      // this.spinner = true;
      this.processNextStep();
    }
  }

  getFieldMappingValues(): FieldMappingValues {
    let values: FieldMappingValues = {};
    for (let [key, value] of Object.entries(this._fieldMappingService.mappingFormGroup.value)) {
      if (value != null) {
        values[key] = Array.isArray(value) ? value : (value as string);
      }
    }
    return values;
  }

  onSaveData(loadImport = false): Observable<Import> {
    const formgroup = this._fieldMappingService.mappingFormGroup;
    const mappingSelected = this._fieldMappingService.currentFieldMapping !== null;
    return of(this.importProcessService.getImportData()).pipe(
      concatMap((importData: Import) => {
        if (mappingSelected || formgroup.dirty) {
          return this._importDataService.setImportFieldMapping(
            importData.id_import,
            this.getFieldMappingValues()
          );
        } else {
          return of(importData);
        }
      }),
      concatMap((importData: Import) => {
        if (!importData.loaded && loadImport) {
          return this._importDataService.loadImport(importData.id_import);
        } else {
          return of(importData);
        }
      }),
      concatMap((importData: Import) => {
        if (
          (mappingSelected || formgroup.dirty) &&
          !this._configService.IMPORT.ALLOW_VALUE_MAPPING
        ) {
          return this._importDataService
            .getContentMapping(this._configService.IMPORT.DEFAULT_VALUE_MAPPING_ID)
            .pipe(
              flatMap((mapping: ContentMapping) => {
                return this._importDataService.setImportContentMapping(
                  importData.id_import,
                  mapping.values
                );
              })
            );
        } else {
          return of(importData);
        }
      })
    );
  }
  processNextStep() {
    this.onSaveData(true).subscribe((importData: Import) => {
      this.importProcessService.setImportData(importData);
      this.importProcessService.navigateToNextStep(this.step);
    });
  }

  onPreviousStep() {
    this.importProcessService.navigateToPreviousStep(this.step);
  }

  isNextStepAvailable() {
    if (this.targetFields !== undefined) {
      for (let entity of this.targetFields) {
        if (this.invalidEntityControls(entity.entity.label) > 0) {
          return false;
        }
      }
      return true;
    }

    return false;
  }

  createMapping() {
    // this.spinner = true;
    this._importDataService
      .createFieldMapping(this.modalCreateMappingForm.value, this.getFieldMappingValues())
      .pipe()
      .subscribe(
        () => {
          this.processNextStep();
        },
        () => {
          // this.spinner = false;
        }
      );
  }
  updateMapping() {
    // this.spinner = true;
    let name = '';
    if (
      this.modalCreateMappingForm.value !=
      this._fieldMappingService.mappingSelectionFormControl.value.label
    ) {
      name = this.modalCreateMappingForm.value;
    }
    this._importDataService
      .updateFieldMapping(
        this._fieldMappingService.mappingSelectionFormControl.value.id,
        this.getFieldMappingValues(),
        name
      )
      .pipe()
      .subscribe(
        () => {
          this.processNextStep();
        },
        () => {
          // this.spinner = false;
        }
      );
  }
}
