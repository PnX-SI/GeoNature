import { Component, Input, OnInit } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { Field } from '@geonature/modules/imports/models/mapping.model';

@Component({
  selector: 'pnx-mapping-theme',
  templateUrl: './mapping-theme.component.html',
  styleUrls: ['./mapping-theme.component.scss'],
})
export class MappingThemeComponent implements OnInit {
  @Input() fieldsData: Field[];
  @Input() themeLabel: string;
  @Input() sourceFields: any;
  @Input() mappingFormControl: FormGroup;

  ngOnInit() {
    console.log(this.sourceFields);
    console.log('HAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA');
  }
}
