import { Injectable } from '@angular/core';
import {
  FormControl,
  FormGroup,
  FormBuilder,
  Validators,
  AbstractControl,
  ValidatorFn
} from '@angular/forms';
import {
  arrayMinLengthValidator,
  isObjectValidator
} from '@geonature/services/validators/validators';
import { MediaService } from '@geonature_common/service/media.service';

@Injectable()
export class DynamicFormService {
  constructor(private _mediaService: MediaService, private _formBuilder: FormBuilder) {}

  initFormGroup() {
    return this._formBuilder.group({});
  }

  toFormGroup(formsDef: Array<any>) {
    // TODO: this method seem not used. Remove it ?
    const group: any = {};
    formsDef.forEach(form => {
      group[form.attribut_name] = this.createControl(form);
    });
    return new FormGroup(group);
  }

  /** revoie la valeur d'un attribut d'une definition de formulaire (formDef)
   * si la valeur est une fonction, on renvoie la valeur evaluée avec
   *   value : les valeur de formulaire
   *   meta : des données supplémentaires, fournies par le formDef
   *   attribut_name : fourni par le formDef
   *
   * sinon, on renvoie la valeur tout simplement
   *
   */
  getFormDefValue(formDef, key, value) {
    const def = formDef[key];
    return typeof def === 'function'
      ? def({ value, meta: formDef.meta, attribut_name: formDef.attribut_name })
      : def;
  }

  setControl(control: AbstractControl, formDef, value = null) {
    if (formDef.type_widget === 'html') {
      return;
    }

    if (![null, undefined].includes(value)) {
      control.setValue(value);
    }

    const validators = [];

    if (formDef.type_widget === 'medias') {
      validators.push(this._mediaService.mediasValidator());
    } else if (formDef.type_widget === 'checkbox') {
      value = value || new Array();
      if (formDef.required) {
        validators.push(arrayMinLengthValidator(1));
      }
    } else if (formDef.type_widget === 'file') {
      if (formDef.required) {
        validators.push(isObjectValidator());
      }
    } else {
      if (formDef.required) {
        validators.push(Validators.required);
      }
      if (formDef.max_length && formDef.max_length > 0) {
        validators.push(Validators.maxLength(formDef.max_length));
      }

      // Contraints for "file" input
      if (formDef.type_widget === 'file') {
        if (formDef.sizeMax) {
          validators.push(this.fileSizeMaxValidator(formDef.sizeMax));
        }
      }

      // Contraints min and max for "number" input
      if (formDef.type_widget === 'number') {
        const cond_min =
          typeof formDef.min === 'number' &&
          !(typeof formDef.max === 'number' && formDef.min > formDef.max);
        const cond_max =
          typeof formDef.max === 'number' &&
          !(typeof formDef.min === 'number' && formDef.min > formDef.max);

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

    // Dans le html (pour pouvoir avoir required et disable avec une valeur donnée)
    if (formDef.disabled) {
      control.disable();
    }
  }

  createControl(formDef): AbstractControl {
    const formControl = new FormControl();
    const value = formDef.value || null;
    this.setControl(formControl, formDef, value);
    return formControl;
  }

  addNewControl(formDef, formGroup: FormGroup) {
    if (formDef.type_widget !== 'html') {
      let control = this.createControl(formDef);
      formGroup.addControl(formDef.attribut_name, control);
    }
  }

  fileSizeMaxValidator(sizeMax): ValidatorFn {
    return (control: AbstractControl): { [key: string]: boolean } | null => {
      const file = control.value;
      const valid = !(file && file.size) || file.size / 1000 > sizeMax;
      return !valid ? { file: true } : null;
    };
  }

  formDefinitionsdictToArray(formDefinitionsDict, meta) {
    const formDefinitions = Object.keys(formDefinitionsDict).map(key => ({
      ...formDefinitionsDict[key],
      attribut_name: key,
      meta
    }));

    return formDefinitions;
  }
}
