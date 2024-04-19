import { Component, OnInit, ViewChild } from '@angular/core';
import { FormControl, Validators } from '@angular/forms';
import { FieldMapping } from '@geonature/modules/imports/models/mapping.model';

import { FieldMappingService } from '@geonature/modules/imports/services/mappings/field-mapping.service';
import { ConfigService } from '@geonature/services/config.service';
import { finalize, skip } from 'rxjs/operators';
import { ImportProcessService } from '../../import-process.service';
import { Cruved, toBooleanCruved } from '@geonature/modules/imports/models/cruved.model';
import { CruvedStoreService } from '@geonature_common/service/cruved-store.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { ImportDataService } from '@geonature/modules/imports/services/data.service';
import { CommonService } from '@geonature_common/service/common.service';
import { Subscription } from 'rxjs';

@Component({
  selector: 'pnx-mapping-selection',
  templateUrl: './mapping-selection.component.html',
  styleUrls: ['./mapping-selection.component.scss'],
})
export class MappingSelectionComponent implements OnInit {
  public userFieldMappings: Array<FieldMapping> = [];
  public fieldMappingForm: FormControl;
  public createOrRenameMappingForm = new FormControl(null, [Validators.required]); // form to add a new mapping

  public cruved: Cruved;

  private fieldMappingSub: Subscription;

  public renameMappingFormVisible: boolean = false;
  public deleteMappingFormVisible: boolean = false;

  @ViewChild('deleteConfirmModal') deleteConfirmModal;

  constructor(
    private _fm: FieldMappingService,
    private config: ConfigService,
    private _importProcessService: ImportProcessService,
    private _importDataService: ImportDataService,
    public cruvedStore: CruvedStoreService,
    private _modalService: NgbModal,
    private _commonService: CommonService
  ) {
    this.cruved = toBooleanCruved(this.cruvedStore.cruved.IMPORT.module_objects.MAPPING.cruved);
    this.fieldMappingForm = this._fm.mappingSelectionFormControl;
  }

  completionStatus() {
    return this._fm.mappingCompletionStatus();
  }

  ngOnInit() {
    this._fm.data.subscribe(({ fieldMappings, targetFields, sourceFields }) => {
      if (!fieldMappings) return;
      this.userFieldMappings = fieldMappings;
    });
    this.fieldMappingSub = this.fieldMappingForm.valueChanges
      .pipe(
        // skip first empty value to avoid reseting the field form if importData as mapping:
        skip(this._importProcessService.getImportData().fieldmapping === null ? 0 : 1)
      )
      .subscribe((mapping: FieldMapping) => {
        this.onNewMappingSelected(mapping);
      });
  }

  ngOnDestroy() {
    this.fieldMappingSub.unsubscribe();
  }

  /**
   * Callback when a new mapping is selected
   *
   * @param {FieldMapping} mapping - the selected mapping
   */
  onNewMappingSelected(mapping: FieldMapping = null): void {
    // this.hideCreateOrRenameMappingForm();
    this._fm.currentFieldMapping.next(mapping);
  }

  // hideCreateOrRenameMappingForm() {
  // this.createOrRenameMappingForm.reset();
  // }
  toggleRenameMappingForm(valueToggle: boolean = null) {
    if (!this.fieldMappingForm.value?.label) {
      this._commonService.translateToaster('error', 'Import.FieldMapping.SelectMapping');
    } else {
      this.renameMappingFormVisible =
        valueToggle !== null ? valueToggle : !this.renameMappingFormVisible;
      if (this.renameMappingFormVisible) {
        this.createOrRenameMappingForm.setValue(this.fieldMappingForm.value.label);
      }
    }
  }

  isMappingSelected(): boolean {
    return this.fieldMappingForm.value != null;
  }

  openDeleteModal() {
    if (!this.fieldMappingForm.value?.label) {
      this._commonService.translateToaster('error', 'Import.FieldMapping.SelectMapping');
    } else {
      this.toggleRenameMappingForm(false);
      this.toggleDeleteModal(true);
      this._modalService.open(this.deleteConfirmModal);
    }
  }

  toggleDeleteModal(valueToggle: boolean = null) {
    this.deleteMappingFormVisible =
      valueToggle !== null ? valueToggle : !this.deleteMappingFormVisible;
  }

  renameMapping(): void {
    this._importDataService
      .renameFieldMapping(this.fieldMappingForm.value.id, this.createOrRenameMappingForm.value)
      .pipe(
        finalize(() => {
          this.renameMappingFormVisible = false;
        })
      )
      .subscribe((mapping: FieldMapping) => {
        let index = this.userFieldMappings.findIndex((m: FieldMapping) => m.id == mapping.id);
        this.fieldMappingForm.setValue(mapping);
        this.userFieldMappings[index] = mapping;
      });
  }

  deleteMapping() {
    // this.spinner = true;
    let mapping_id = this.fieldMappingForm.value.id;
    this._importDataService
      .deleteFieldMapping(mapping_id)
      .pipe()
      .subscribe(
        () => {
          this._commonService.translateToaster('success', 'Import.FieldMapping.MappingDeleted', {
            label: this.fieldMappingForm.value.label,
          });
          this.fieldMappingForm.setValue(null, { emitEvent: false });
          this.userFieldMappings = this.userFieldMappings
            .filter((mapping) => {
              return mapping.id !== mapping_id;
            })
            .sort((a, b) => a.label.localeCompare(b.label));
          // this.spinner = false;
        },
        () => {
          // this.spinner = false;
        }
      );
  }
}
