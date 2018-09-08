import { Injectable } from '@angular/core';
import { FormControl, FormArray, FormGroup, Validators, AbstractControl } from '@angular/forms';

@Injectable()
export class DynamicFormService {
  constructor() { }

  toFormGroup(formsDef: Array<any>) {
    let group: any = {};
    formsDef.forEach(form => {
      group[form.nom_attribut] = this.createControl(form);
    });
    return new FormGroup(group);
  }

  createControl(formDef): AbstractControl {
    let abstractForm;
    if (formDef.type_widget === 'checkbox') {
      abstractForm = formDef.obligatoire
        ? new FormControl([], Validators.required)
        : new FormControl([]);
    } else {
      abstractForm = formDef.obligatoire
        ? new FormControl(formDef.value || null, Validators.required)
        : new FormControl(formDef.value || null);
    }
    return abstractForm;
  }

  addNewControl(formDef, formGroup: FormGroup) {
    formGroup.addControl(formDef.attribut_name, this.createControl(formDef));
  }
}
