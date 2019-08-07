import { ValidatorFn, AbstractControl } from '@angular/forms';

export function similarValidator(compared: string): ValidatorFn {
  return (control: AbstractControl): { [key: string]: any } => {
    const valeur = control.value
    const group = control.parent;
    let valid = false;
    if (group) {
      const comparedValue = group.controls[compared].value;
      valid = comparedValue == valeur ? true : false;
    }

    return valid ? null : { 'similarError': { valeur } };
  };
}