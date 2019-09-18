import { ValidatorFn, AbstractControl, FormGroup } from '@angular/forms';

export function similarValidator(pass: string, passConfirm: string): ValidatorFn {
  return (control: FormGroup): { [key: string]: any } => {
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
    return control.value.length >= arrayLenght ? null : { arrayMinLengthError: true };
  };
}
