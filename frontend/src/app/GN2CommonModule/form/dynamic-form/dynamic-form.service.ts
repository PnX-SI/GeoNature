import { Injectable } from '@angular/core';
import { FormControl, FormArray, FormGroup, Validators, AbstractControl } from '@angular/forms';

@Injectable()
export class DynamicFormService {
  constructor() { }

  toFormGroup(formsDef: Array<any>) {
    const group: any = {};
    formsDef.forEach(form => {
      group[form.attribut_name] = this.createControl(form);
    });
    return new FormGroup(group);
  }

  createControl(formDef): AbstractControl {
    let abstractForm;
    if (formDef.type_widget === 'checkbox') {
      abstractForm = formDef.required
        ? new FormControl([], Validators.required)
        : new FormControl([]);
    } else {
      abstractForm = formDef.required
        ? new FormControl(formDef.value || null, Validators.required)
        : new FormControl(formDef.value || null);
    }
    return abstractForm;
  }

  addNewControl(formDef, formGroup: FormGroup) {
    formGroup.addControl(formDef.attribut_name, this.createControl(formDef));
  }
}
