import { Component, OnInit } from '@angular/core';
import { FormControl } from '@angular/forms';
import { FieldMapping } from '@geonature/modules/imports/models/mapping.model';

import { FieldMappingService } from '@geonature/modules/imports/services/mappings/field-mapping.service';
import { ConfigService } from '@geonature/services/config.service';
import { skip } from 'rxjs/operators';
import { ImportProcessService } from '../../import-process.service';

@Component({
  selector: 'pnx-mapping-selection',
  templateUrl: './mapping-selection.component.html',
  styleUrls: ['./mapping-selection.component.scss'],
})
export class MappingSelectionComponent implements OnInit {
  public userFieldMappings: Array<FieldMapping> = [];
  public fieldMappingForm: FormControl = new FormControl();

  constructor(
    private _fm: FieldMappingService,
    private config: ConfigService,
    private _importProcessService: ImportProcessService
  ) {}

  ngOnInit() {
    this._fm.data.subscribe(({ fieldMappings, targetFields, sourceFields }) => {
      if (!fieldMappings) return;
      this.userFieldMappings = fieldMappings;
    });
    this.fieldMappingForm.valueChanges
      .pipe(
        // skip first empty value to avoid reseting the field form if importData as mapping:
        skip(this._importProcessService.getImportData().fieldmapping === null ? 0 : 1)
      )
      .subscribe((mapping: FieldMapping) => {
        this.onNewMappingSelected(mapping);
      });
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
}
