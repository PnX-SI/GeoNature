import { Component, forwardRef, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import {
  AbstractControl,
  ControlValueAccessor,
  FormGroup,
  NG_VALUE_ACCESSOR,
  ReactiveFormsModule,
} from '@angular/forms';
import { FieldMappingService } from '@geonature/modules/imports/services/mappings/field-mapping.service';
import { NgSelectModule } from '@ng-select/ng-select';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { DynamicFormWrapperComponent } from './dynamic-form-wrapper/dynamic-form-wrapper.component';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';
import {
  FieldMappingItem,
  FieldMappingItemCSVValue,
} from '@geonature/modules/imports/models/mapping.model';
import { BibField } from './bibfield';
import { ConfigService } from '@geonature/services/config.service';

// ////////////////////////////////////////////////////
// control value accessor
// ////////////////////////////////////////////////////

enum InputStackState {
  INPUT_FILE = 'input_file',
  CONSTANT = 'constant',
}

// ////////////////////////////////////////////////////
// Value type
// ////////////////////////////////////////////////////

const CUSTOM_CONTROL_VALUE_ACCESSOR: any = {
  provide: NG_VALUE_ACCESSOR,
  useExisting: forwardRef(() => FieldMappingInputComponent),
  multi: true,
};

@Component({
  standalone: true,
  selector: 'pnx-fieldmapping-input',
  templateUrl: './fieldmapping-input.component.html',
  styleUrls: ['./fieldmapping-input.component.scss'],
  imports: [
    CommonModule,
    ReactiveFormsModule,
    NgSelectModule,
    GN2CommonModule,
    DynamicFormWrapperComponent,
    NgbModule,
  ],
  providers: [CUSTOM_CONTROL_VALUE_ACCESSOR],
})
export class FieldMappingInputComponent implements ControlValueAccessor {
  constructor(
    public fm: FieldMappingService,
    private _configService: ConfigService
  ) {}

  // ////////////////////////////////////////////////////
  // Entity data
  // ////////////////////////////////////////////////////
  @Input() entity;

  // ////////////////////////////////////////////////////
  // control value accessor
  // ////////////////////////////////////////////////////
  @Input()
  value: FieldMappingItem | null = null;
  writeValue(value: FieldMappingItem | null): void {
    // TODO : fix this
    if (value == null && this.value != null) {
      return;
    }
    if (this.value == value) {
      return;
    }
    this.value = value;
    this.updateComponentState();
  }

  onChanged: Function = () => {};
  registerOnChange(fn: Function) {
    this.onChanged = fn;
  }

  onTouched: Function = () => {};
  registerOnTouched(fn: Function) {
    this.onTouched = fn;
  }

  // ////////////////////////////////////////////////////
  // Value selector
  // ////////////////////////////////////////////////////

  updateValue() {
    if (this._csvColumn) {
      this.value = {
        column_src: this._csvColumn,
      };
    } else if (this.constantValue != null) {
      this.value = {
        constant_value: this.constantValue,
      };
    } else {
      this.value = null;
    }
  }

  updateComponentState() {
    if (this._csvColumn != this.value?.column_src) {
      this.csvColumn = this.value?.column_src;
    }
    if (this.constantValue != this.value?.constant_value) {
      this.constantValue = this.value?.constant_value;
    }

    if (this._csvColumn) {
      this.inputState = InputStackState.INPUT_FILE;
    } else if (this.constantValue != null) {
      this.inputState = InputStackState.CONSTANT;
    }
  }

  // //////////////////////////////////////////////////////////////////////////
  // CSV Selector
  // //////////////////////////////////////////////////////////////////////////

  @Input()
  csvColumnNames: Array<string> = [];

  _csvColumn: FieldMappingItemCSVValue | null = null;

  get csvColumn(): FieldMappingItemCSVValue | null {
    return this._csvColumn;
  }

  set csvColumn(csvColumn: FieldMappingItemCSVValue | null) {
    if (this._csvColumn == csvColumn) {
      return;
    }

    this._csvColumn = csvColumn;

    if (this.csvColumn) {
      this.constantValue = null;
      if (!this._isColumnValid(this.csvColumn)) {
        this._csvColumn = null;
      }
    }
    this.updateValue();
    this.onChanged(this.value);
    this.onTouched(true);
  }

  _isColumnValid(csvColumn: FieldMappingItemCSVValue): boolean {
    if (typeof csvColumn == 'boolean') {
      return true;
    }
    return Array.isArray(csvColumn)
      ? csvColumn.every((column) => this.csvColumnNames.includes(column))
      : this.csvColumnNames.includes(csvColumn);
  }

  // //////////////////////////////////////////////////////////////////////////
  // Constant value Selector
  // //////////////////////////////////////////////////////////////////////////

  constantValue: string | boolean | null = null;

  constantValueEdited(constantValue: string | boolean | null) {
    if (this.constantValue === constantValue) {
      return;
    }

    this.constantValue = constantValue;
    if (this.constantValue != null) {
      this._csvColumn = null;
    }
    this.updateValue();
    this.onChanged(this.value);
    this.onTouched(true);
  }

  // ////////////////////////////////////////////////////
  // Fields
  // ////////////////////////////////////////////////////
  @Input()
  siblings: Array<BibField> = [];

  @Input()
  set field(field: BibField) {
    this._field = field;
    if (this._field.name_field === 'unique_id_sinp_generate') {
      this.constantValue = this._configService.IMPORT.DEFAULT_GENERATE_MISSING_UUID;
      this.updateValue();
    }
  }
  get field(): BibField {
    return this._field;
  }

  _field: BibField = {
    autogenerated: false,
    comment: '',
    desc_field: '',
    eng_label: '',
    fr_label: '',
    id_field: 0,
    mandatory: false,
    name_field: '',
    multi: false,
    type_field: '',
    type_field_params: null,
  };

  // ////////////////////////////////////////////////////
  // Form
  // ////////////////////////////////////////////////////
  get formGroup(): FormGroup {
    return this.fm.mappingFormGroup;
  }

  get formControl(): AbstractControl {
    return this.formGroup.controls[this.field.name_field];
  }

  // ////////////////////////////////////////////////////
  // SINPGenerateAlert
  // ////////////////////////////////////////////////////

  get sinpGenerate(): boolean {
    return this.constantValue === true;
  }

  set sinpGenerate(value: boolean) {
    this.constantValueEdited(value);
  }

  get shouldDisplaySINPGenerateAlert(): boolean {
    return this._field.name_field === 'unique_id_sinp_generate' && !this.sinpGenerate;
  }

  // //////////////////////////////////////////////////////////////////////////
  // Field label
  // //////////////////////////////////////////////////////////////////////////

  _getFieldsLabel(labels: string[]): string[] {
    return labels.map((label) => {
      return this.siblings.find((field) => field.name_field === label)?.fr_label;
    });
  }

  get optionalFieldLabels(): string[] {
    return this._getFieldsLabel(this._field.optional_conditions);
  }

  get mandatoryFieldLabels(): string[] {
    return this._getFieldsLabel(this._field.mandatory_conditions);
  }

  // ////////////////////////////////////////////////////
  // Input Stack state
  // ////////////////////////////////////////////////////

  // expose to html
  InputStackState = InputStackState;

  inputState: InputStackState = InputStackState.INPUT_FILE;

  switchInputType() {
    if (this.inputState == InputStackState.INPUT_FILE) {
      this.inputState = InputStackState.CONSTANT;
      this.csvColumn = null;
    } else if (this.inputState == InputStackState.CONSTANT) {
      this.inputState = InputStackState.INPUT_FILE;
      this.constantValue = null;
    } else {
      // Should never beNever reached
      this.constantValue = null;
      this.inputState = InputStackState.INPUT_FILE;
    }
  }
}
