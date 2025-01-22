import { Component, OnInit, TemplateRef, ViewChild } from '@angular/core';
import { ImportDataService } from '../../../services/data.service';
import { FieldMappingService } from '@geonature/modules/imports/services/mappings/field-mapping.service';
import { Cruved, toBooleanCruved } from '@geonature/modules/imports/models/cruved.model';
import { Step } from '@geonature/modules/imports/models/enums.model';
import { ActivatedRoute } from '@angular/router';
import { ImportProcessService } from '../import-process.service';
import { CruvedStoreService } from '@geonature_common/service/cruved-store.service';
import { concatMap, flatMap, skip, take } from 'rxjs/operators';
import { Observable, of } from 'rxjs';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { Import } from '@geonature/modules/imports/models/import.model';
import {
  ContentMapping,
  FieldMappingValues,
} from '@geonature/modules/imports/models/mapping.model';
import { ConfigService } from '@geonature/services/config.service';
import { FormControl } from '@angular/forms';
import { AuthService } from '@geonature/components/auth/auth.service';
import { ModalData } from '@geonature/modules/imports/models/modal-data.model';

@Component({
  selector: 'pnx-fields-mapping-step',
  templateUrl: './fields-mapping-step.component.html',
  styleUrls: ['./fields-mapping-step.component.scss'],
})
export class FieldsMappingStepComponent implements OnInit {
  @ViewChild('saveMappingModal') saveMappingModal;
  @ViewChild('editModal') editModal: TemplateRef<any>;
  public targetFields;
  public sourceFields: Array<string> = [];
  public isReady: boolean = false;
  public cruved: Cruved;
  public importData: Import;
  public updateAvailable: boolean = false;
  public step: Step;
  public modalCreateMappingForm = new FormControl('');
  public defaultValueFormDefs: any = {};
  public modalData:ModalData;
  constructor(
    public _fieldMappingService: FieldMappingService,
    private _route: ActivatedRoute,
    private importProcessService: ImportProcessService,
    private _cruvedStore: CruvedStoreService,
    private _importDataService: ImportDataService,
    private _modalService: NgbModal,
    private _configService: ConfigService,
    private _authService: AuthService
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
        this.defaultValueFormDefs = this._fieldMappingService.getDefaultValueFormDefs();
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
          if (control === undefined) return; // FIXME control is undefined when a new import is made after an other one without reload the page
          result += control.status === 'INVALID' ? 1 : 0;
        });
      });
    return result;
  }

  onNextStep() {
    if (!this._fieldMappingService.mappingFormGroup?.valid) {
      return;
    }

    // Mapping stored data
    let mappingValue = this._fieldMappingService.currentFieldMapping.value;
    // is mapping update right for the current user is at admin level
    const hasAdminUpdateMappingRight =
      this._cruvedStore.cruved.IMPORT.module_objects.MAPPING.cruved.U > 2;
    const hasOwnMappingUpdateRight =
      this._cruvedStore.cruved.IMPORT.module_objects.MAPPING.cruved.U > 0;
    //
    const currentUser = this._authService.getCurrentUser();

    if (this._fieldMappingService.mappingFormGroup.dirty && this.cruved.C) {
      if (mappingValue) {
        const intersectMappingOwnerUser = mappingValue['owners'].filter((x) =>
          x.identifiant == currentUser.user_login ? mappingValue['owners'] : false
        );

        if (
          mappingValue.public &&
          (hasAdminUpdateMappingRight ||
            (hasOwnMappingUpdateRight && intersectMappingOwnerUser.length > 0))
        ) {
          this.updateAvailable = true;
          this.modalCreateMappingForm.setValue(mappingValue.label);
        } else if (!mappingValue.public) {
          this.updateAvailable = true;
          this.modalCreateMappingForm.setValue(mappingValue.label);
        } else {
          this.updateAvailable = false;
        }
      } else {
        console.log(4);
        this.updateAvailable = false;
      }
      this._modalService.open(this.saveMappingModal, { size: 'lg' });
    } else {
      this.processNextStep();
    }
  }

  getFieldMappingValues(): FieldMappingValues {
    const values: FieldMappingValues = {};
    this._fieldMappingService
      .flattenTargetFieldData(this.targetFields)
      .forEach(({ name_field }) => {
        const column_src = this._fieldMappingService.mappingFormGroup.get(name_field)?.value;
        const default_value = this._fieldMappingService.mappingFormGroup.get(
          `${name_field}_default_value`
        )?.value;
        if (column_src || default_value) {
          values[name_field] = {
            column_src: column_src || undefined,
            default_value: this._fieldMappingService.getFieldDefaultValue(
              name_field,
              default_value
            ),
          };
        }
      });
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

  getMappedTargetFields(): Number {
    return this._fieldMappingService.getMappedTargetFields().length;
  }

  getUnmappedFieldsLength(): Number {
    return this._fieldMappingService.getUnmappedFieldsLength();
  }

  getUnmappedFields() {
    return this._fieldMappingService.getUnmappedFields();
  }

  checkBeforeNextStep(){
      if (this.importData?.fieldmapping) {
         this.openModal(this.editModal);
          return;
        }
        else{
          this.onNextStep();
        }
    }

    openModal(editModal: TemplateRef<any>) {
      this.modalData = {
        title: 'Modification',
        bodyMessage: 'Des modifications ont été apportées à la correspondances des champs. L\'ancienne correspondance des champs sera supprimée',
        additionalMessage: 'Etes-vous sur de continuer ?',
        cancelButtonText: 'Annuler',
        confirmButtonText: 'Confirmer',
        confirmButtonColor: 'warn',
        headerDataQa: 'import-modal-edit',
        confirmButtonDataQa: 'modal-edit-validate',
      };  
      this._modalService.open(editModal);
    }

    handleModalAction(event: { confirmed: boolean; actionType: string; data?: any }) {
      if (event.confirmed) {
        if (event.actionType === 'edit') {
          this.onNextStep();
        }
      }
    }
  
}
