import { distinctUntilChanged } from 'rxjs/operators';
import { Injectable } from '@angular/core';
import { FormControl, FormGroup, Validators, AbstractControl } from '@angular/forms';
import { arrayMinLengthValidator, isObjectValidator } from '@geonature/services/validators/validators';

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

  setControl(control:AbstractControl, formDef, value=null) {
    if(![null, undefined].includes(value)) {
      console.log('yarglou', value)
      control.setValue(value)
      console.log(control.value)
    }

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

      if (formDef.type_widget === 'taxonomy' && formDef.required) {
        validators.push(isObjectValidator());
      }
    }
    control.setValidators(validators);
    if(formDef.disabled) {
      console.log('dis', formDef.attribut_name)
      control.disable();
    } else {
      control.enable();
    }
  }

  createControl(formDef): AbstractControl {
    const formControl = new FormControl();
    let value = formDef.value || null;
    console.log('Create control', formDef.attribut_name, value)
    this.setControl(formControl, formDef, value);
    return formControl;

  }

  addNewControl(formDef, formGroup: FormGroup) {
    formGroup.addControl(formDef.attribut_name, this.createControl(formDef));
  }

}
