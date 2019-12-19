import { distinctUntilChanged } from 'rxjs/operators';
import { Injectable } from '@angular/core';
import { FormControl, FormGroup, Validators, AbstractControl } from '@angular/forms';
import { arrayMinLengthValidator } from '@geonature/services/validators/validators';

@Injectable()
export class DynamicFormService {
  constructor() {}

  toFormGroup(formsDef: Array<any>) {
    const group: any = {};
    formsDef.forEach(form => {
      group[form.attribut_name] = this.createControl(form);
    });
    return new FormGroup(group);
  }

  createControl(formDef): AbstractControl {
    let value = formDef.value || null;
    const validators = [];

    if (formDef.type_widget === 'checkbox') {
      value = value || new Array();
      if (formDef.required) {
        validators.push(arrayMinLengthValidator(1));
      }
    } else {
      if (formDef.required) {
        validators.push(Validators.required);
      }
      if (formDef.max_length && formDef.max_length > 0) {
        validators.push(Validators.maxLength(formDef.max_length));
      }

      // contraintes min et max pour "number"
      if (formDef.type_widget === 'number') {
        const cond_min = typeof formDef.min === 'number' &&  !( (typeof formDef.max === 'number') && formDef.min > formDef.max);
        const cond_max = typeof formDef.max === 'number' &&  !( (typeof formDef.min === 'number') && formDef.min > formDef.max);

        if (cond_min) {
          validators.push(Validators.min(formDef.min));
        }

        if (cond_max) {
          validators.push(Validators.max(formDef.max));
        }
      }

    }

    return new FormControl({ value: value, disabled: formDef.disabled}, validators);
  }

  addNewControl(formDef, formGroup: FormGroup) {
    formGroup.addControl(formDef.attribut_name, this.createControl(formDef));
  }
}
