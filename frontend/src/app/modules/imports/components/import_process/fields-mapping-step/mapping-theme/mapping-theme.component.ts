import { Component, Input, OnInit } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { Field } from '@geonature/modules/imports/models/mapping.model';
import { FieldMappingService } from '@geonature/modules/imports/services/mappings/field-mapping.service';

@Component({
  selector: 'pnx-mapping-theme',
  templateUrl: './mapping-theme.component.html',
  styleUrls: ['./mapping-theme.component.scss'],
})
export class MappingThemeComponent implements OnInit {
  @Input() themeData;
  @Input() sourceFields: Array<string>;

  constructor(public _fm: FieldMappingService) {}

  ngOnInit() {}

  isMapped(keySource: string) {
    return this._fm.mappingStatus('mapped', keySource);
  }
  displayAlert(field) {
    return (
      field.name_field === 'unique_id_sinp_generate' &&
      !this._fm.mappingFormGroup.get(field.name_field).value
    );
  }
  
  getFieldLabels(labels:string[]):string[]{
    return labels.map(label => {
      return this.themeData.fields.find(field => field.name_field === label)?.fr_label
    })
  }
}
