import { AbstractControl, ValidationErrors, ValidatorFn } from '@angular/forms';

export function urlValidator(accept_empty: boolean = true): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    if (!control.value && accept_empty) {
      return null;
    }
    try {
      const url = new URL(control.value);
      if (!['http:', 'https:'].includes(url.protocol)) {
        return { invalidUrl: true };
      }
      return null;
    } catch {
      return { invalidUrl: true };
    }
  };
}
