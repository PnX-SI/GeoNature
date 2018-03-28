import { Injectable } from '@angular/core';
import { FormControl, FormGroup, Validators } from '@angular/forms';

@Injectable()
export class DynamicFormService {
  constructor() {}

  toFormGroup(formsDef: Array<any>) {
    let group: any = {};
    formsDef.forEach(form => {
      group[form.key] = form.required
        ? new FormControl(form.value || '', Validators.required)
        : new FormControl(form.value || '');
    });
    return new FormGroup(group);
  }

  addNewControl(formDef, formGroup: FormGroup) {
    const formControl = formDef.required
      ? new FormControl(formDef.value || '', Validators.required)
      : new FormControl(formDef.value || '');

    formGroup.addControl(formDef.key, formControl);
  }
}
