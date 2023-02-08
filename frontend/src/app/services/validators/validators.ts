import { ValidatorFn, AbstractControl, UntypedFormGroup } from '@angular/forms';

export function similarValidator(pass: string, passConfirm: string): ValidatorFn {
  return (control: UntypedFormGroup): { [key: string]: any } => {
    const passControl = control.get(pass);
    const confirPassControl = control.get(passConfirm);
    if (passControl && confirPassControl && passControl.value === confirPassControl.value) {
      return null;
    }
    return { similarError: true };
  };
}

export function arrayMinLengthValidator(arrayLenght): ValidatorFn {
  return (control: AbstractControl): { [key: string]: any } => {
    if (!control.value) {
      return { arrayMinLengthError: true };
    }
    return control.value.length >= arrayLenght ? null : { arrayMinLengthError: true };
  };
}

export function isObjectValidator(): ValidatorFn {
  return (control: AbstractControl): { [key: string]: any } => {
    return typeof control.value === 'object' && control.value != null
      ? null
      : { isObjectError: true };
  };
}
