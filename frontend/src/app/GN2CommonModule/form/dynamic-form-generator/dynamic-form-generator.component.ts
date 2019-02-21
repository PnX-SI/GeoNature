import { Component, OnInit, Input } from '@angular/core';
import { FormGroup, FormControl } from '@angular/forms';
import { DynamicFormService } from './dynamic-form.service';

@Component({
  selector: 'pnx-dynamic-form-generator',
  templateUrl: './dynamic-form-generator.component.html',
  styleUrls: ['./dynamic-form-generator.component.scss']
})
export class GenericFormGeneratorComponent implements OnInit {
  public selectControl = new FormControl();
  @Input() formGroup: FormGroup;
  @Input() formsDefinition: Array<any>;
  @Input() selectLabel: string;
  public formsSelected = [];
  constructor(private _dynformService: DynamicFormService) {}

  ngOnInit() {
    this.selectControl.valueChanges.filter(value => value !== null).subscribe(formDef => {
      this.addFormControl(formDef);
    });
    this.formsDefinition.sort((a, b) => {
      return a.attribut_label.localeCompare(b.attribut_label);
    });
  }

  removeFormControl(i) {
    const formDef = this.formsSelected[i];
    this.formsSelected.splice(i, 1);
    this.formsDefinition.push(formDef);
    this.formGroup.removeControl(formDef.attribut_name);
    this.selectControl.setValue(null);
  }

  addFormControl(formDef) {
    this.formsSelected.push(formDef);
    this.formsDefinition = this.formsDefinition.filter(form => {
      return form.attribut_name !== formDef.attribut_name;
    });
    this._dynformService.addNewControl(formDef, this.formGroup);
  }
}
