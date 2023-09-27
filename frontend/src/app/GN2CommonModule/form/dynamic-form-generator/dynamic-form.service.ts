import { Injectable } from '@angular/core';
import {
  UntypedFormControl,
  UntypedFormGroup,
  UntypedFormBuilder,
  Validators,
  AbstractControl,
  ValidatorFn,
} from '@angular/forms';
import {
  arrayMinLengthValidator,
  isObjectValidator,
} from '@geonature/services/validators/validators';
import { MediaService } from '@geonature_common/service/media.service';

@Injectable()
export class DynamicFormService {
  constructor(private _mediaService: MediaService, private _formBuilder: UntypedFormBuilder) {}

  initFormGroup() {
    return this._formBuilder.group({});
  }

  toFormGroup(formsDef: Array<any>) {
    // TODO: this method seem not used. Remove it ?
    const group: any = {};
    formsDef.forEach((form) => {
      group[form.attribut_name] = this.createControl(form);
    });
    return new UntypedFormGroup(group);
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

      // Constraint pattern for the "text"
      if (formDef.type_widget === 'text') {
        if (typeof formDef.pattern == 'string') {
          try {
            new RegExp(formDef.pattern);
            validators.push(Validators.pattern(formDef.pattern));
          } catch (e) {}
        }
      }

      if (formDef.type_widget === 'taxonomy' && formDef.required) {
        validators.push(isObjectValidator());
      }
    }

    control.setValidators(validators);

    if (formDef.disabled) {
      control.disable();
    }

    control.updateValueAndValidity();
  }

  createControl(formDef): AbstractControl {
    const formControl = new UntypedFormControl();
    const value = formDef.value || null;
    const defaultValue = parseFloat(value) ? parseFloat(value) : value;
    this.setControl(formControl, formDef, defaultValue);
    return formControl;
  }
  addNewControl(formDef, formGroup: UntypedFormGroup) {
    //Mise en fonction des valeurs des dynamic-form ex: "hidden: "({value}) => value.monChamps != 'maValeur'""
    for (const keyParam of Object.keys(formDef)) {
      const func = this.toFunction(formDef[keyParam]);
      if (func) {
        formDef[keyParam] = func;
      }
    }

    if (formDef.type_widget !== 'html') {
      let control = this.createControl(formDef);
      if (formDef.disable) {
        control.disable();
      }
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
    const formDefinitions = Object.keys(formDefinitionsDict).map((key) => ({
      ...formDefinitionsDict[key],
      attribut_name: key,
      meta,
    }));

    return formDefinitions;
  }

  /**
   * Converti s en function js
   *
   *
   * @param s chaine de caractere
   */
  toFunction(s_in) {
    //En cas de tableau de fonction, on les joint (utile pour fonction complexe)
    let s = Array.isArray(s_in) ? s_in.join('\n') : s_in;
    if (!(typeof s == 'string')) {
      return;
    }

    const tests = ['(', ')', '{', '}', '=>'];

    if (!tests.every((test) => s.includes(test))) {
      return;
    }

    let func;

    try {
      func = eval(s);
    } catch (error) {
      console.error(`Erreur dans la définition de la fonction ${error}`);
    }

    return func;
  }
}
