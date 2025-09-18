import { Injectable } from '@angular/core';
import {
  AbstractControl,
  ValidatorFn,
  UntypedFormGroup,
  UntypedFormControl,
  FormControl,
  Validators,
  ValidationErrors,
} from '@angular/forms';
import { Subscription, Observable, forkJoin } from 'rxjs';
import { distinctUntilChanged, map, filter, pairwise, tap, startWith } from 'rxjs/operators';

@Injectable()
export class FormService {
  constructor() {}

  dateValidator(dateMinControl: AbstractControl, dateMaxControl: AbstractControl): ValidatorFn {
    return (formGroup: UntypedFormGroup): { [key: string]: boolean } => {
      const dateMin = dateMinControl.value;
      const dateMax = dateMaxControl.value;
      if (dateMin && dateMax) {
        const formatedDateMin = new Date(dateMin.year, dateMin.month - 1, dateMin.day);
        const formatedDateMax = new Date(dateMax.year, dateMax.month - 1, dateMax.day);
        if (formatedDateMax < formatedDateMin) {
          return {
            invalidDate: true,
          };
        } else {
          return null;
        }
      }
      return null;
    };
  }

  /**
   * Check that controlMin is < to controlMax
   * @param minControl
   * @param maxControl
   * @param validatorKeyName: name of the validator
   */
  minMaxValidator(
    minControl: AbstractControl,
    maxControl: AbstractControl,
    validatorKeyName: string
  ): ValidatorFn {
    return (formGroup: UntypedFormGroup): { [key: string]: boolean } => {
      const altMin = minControl.value;
      const altMax = maxControl.value;
      if (altMin && altMax && altMin > altMax) {
        return {
          [validatorKeyName]: true,
        };
      } else {
        return null;
      }
    };
  }

  hourAndDateValidator(
    dateMinControl: AbstractControl,
    dateMaxControl: AbstractControl,
    hourMinControl: AbstractControl,
    hourMaxControl: AbstractControl
  ) {
    return (formGroup: UntypedFormGroup): { [key: string]: boolean } => {
      const invalidHour = this.invalidHour(
        dateMinControl,
        dateMaxControl,
        hourMinControl,
        hourMaxControl
      );
      return invalidHour
        ? {
            invalidHour: true,
          }
        : null;
    };
  }

  invalidHour(
    dateMinControl: AbstractControl,
    dateMaxControl: AbstractControl,
    hourMinControl: AbstractControl,
    hourMaxControl: AbstractControl
  ) {
    const hourMin = hourMinControl.value;
    const hourMax = hourMaxControl.value;
    const dateMin = dateMinControl.value;
    const dateMax = dateMaxControl.value;

    // if hour min et pas hour max => set error
    if (hourMin && !hourMax) {
      return true;
      // if hour min et hour max => check validity
    } else if (dateMin && dateMax && hourMin && hourMax) {
      const formatedHourMin = hourMin.split(':').map((h) => parseInt(h));
      const formatedHourMax = hourMax.split(':').map((h) => parseInt(h));
      // Date month are initialized with month index ... 0 = janvier SO -1 .
      const formatedDateMin = new Date(dateMin.year, dateMin.month - 1, dateMin.day);
      const formatedDateMax = new Date(dateMax.year, dateMax.month - 1, dateMax.day);

      if (dateMin && dateMax) {
        formatedDateMin.setHours(formatedHourMin[0], formatedHourMin[1]);
        formatedDateMax.setHours(formatedHourMax[0], formatedHourMax[1]);
      }

      return formatedDateMin > formatedDateMax;
    }
    return null;
  }

  taxonValidator(taxControl: AbstractControl) {
    const currentTaxon = taxControl.value;
    if (!currentTaxon) {
      return null;
    } else if (!currentTaxon.cd_nom && !currentTaxon.search_name) {
      return {
        invalidTaxon: true,
      };
    } else {
      return null;
    }
  }

  searchLocally(searchPatern, data) {
    const savedData = data;
    let filteredData = [];
    filteredData = savedData.filter((el) => {
      const isIn = el.label_default.toUpperCase().indexOf(searchPatern.toUpperCase());
      return isIn !== -1;
    });
    return filteredData;
  }

  synchronizeMax(formGroup, minControlName, maxControlName) {
    const minControl = formGroup.get(minControlName);
    const maxControl = formGroup.get(maxControlName);

    if (maxControl.pristine) {
      maxControl.setValue(minControl.value);
    }
  }

  synchronizeMin(formGroup, minControlName, maxControlName) {
    const minControl = formGroup.get(minControlName);
    const maxControl = formGroup.get(maxControlName);

    if (minControl.pristine) {
      minControl.setValue(maxControl.value);
    }
  }
  /**
   * Validator function that checks if the reference control is not null, then the current control must not be null.
   *
   * @param {string[]} referenceControlNames - The name of the control in the same form group that holds the reference value.
   * @return {ValidatorFn} A validator function
   */

  /**
   * Validator function that checks if all of reference controls are not null, then the current control must not be null.
   *
   * @param {string[]} referenceControlNames - The names of the controls in the same form group that holds the reference value.
   * @param {AbstractControl} currentControl - The control to be validated.
   * @return {boolean} True if the validation is successful, false otherwise.
   */
  areAllRefControlsNotNull(
    referenceControlNames: string[],
    currentControl: AbstractControl
  ): boolean {
    let validation: boolean = true;
    referenceControlNames.forEach((referenceControlName) => {
      const referenceControl = currentControl.parent.get(referenceControlName);

      // Throw an error if the reference control is null or undefined
      if (referenceControl == null) throw Error('Reference formControl is null or undefined');

      // Check if the reference control value is null or undefined
      const refValueIsNullOrUndefined =
        referenceControl.value == null || referenceControl.value == undefined;
      // Check if the current control value is null or undefined
      const currentControlValueIsNullOrUndefined =
        currentControl.value == null || currentControl.value == undefined;

      // Return the validation result.
      // Return a validation error if the reference control is not null or undefined and the current control is null
      validation =
        validation && (!refValueIsNullOrUndefined || !currentControlValueIsNullOrUndefined);
    });
    return validation;
  }

  /**
   * Checks if any of the reference controls are not null.
   *
   * @param {string[]} referenceControlNames - The names of the controls in the same form group that holds the reference value.
   * @param {AbstractControl} currentControl - The control to be validated.
   * @return {boolean} True if any of the reference controls is not null, false otherwise.
   */
  areAnyRefControlsNotNull(
    referenceControlNames: string[],
    currentControl: AbstractControl
  ): boolean {
    let result = false;
    if (referenceControlNames.length === 0) return true;
    referenceControlNames.forEach((referenceControlName) => {
      const referenceControl = currentControl.parent.get(referenceControlName);

      // Throw an error if the reference control is null or undefined
      if (referenceControl == null) throw Error('Reference formControl is null or undefined');

      if (referenceControl.value !== null && referenceControl.value !== undefined) {
        result = true;
      }
    });
    return result;
  }

  /**
   * Generates a validator function that requires the current control if any of the reference controls is not null.
   *
   * @param {string[]} referenceControlNames - The name of the control in the same form group that holds the reference value.
   * @return {ValidatorFn} The validator function.
   */
  RequiredIfControlIsNotNullValidator(
    referenceControlNames: string[],
    entityControls: string[]
  ): ValidatorFn {
    return (currentControl: AbstractControl): ValidationErrors | null => {
      if (!this.areAnyRefControlsNotNull(entityControls, currentControl)) {
        return null;
      }
      return this.areAllRefControlsNotNull(referenceControlNames, currentControl)
        ? Validators.required(currentControl)
        : null;
    };
  }
  /**
   * Generates a validator function that makes the current control not required if any of the reference controls is not null.
   *
   * @param {string[]} referenceControlNames - The name of the control in the same form group that holds the reference value.
   * @return {ValidatorFn} The validator function.
   */
  NotRequiredIfControlIsNotNullValidator(
    referenceControlNames: string[],
    entityControls: string[]
  ): ValidatorFn {
    return (currentControl: AbstractControl): ValidationErrors | null => {
      if (!this.areAnyRefControlsNotNull(entityControls, currentControl)) {
        return null;
      }
      return this.areAnyRefControlsNotNull(referenceControlNames, currentControl)
        ? null
        : Validators.required(currentControl);
    };
  }

  NotRequiredIfNoOther(entityControls: string[]): ValidatorFn {
    return (currentControl: AbstractControl): ValidationErrors | null => {
      return this.areAnyRefControlsNotNull(entityControls, currentControl)
        ? Validators.required(currentControl)
        : null;
    };
  }

  uuidValidator(): ValidatorFn {
    return (control: AbstractControl): ValidationErrors | null => {
      const value = control.value;

      if (!value) {
        return null; // Ne pas valider si le champ est vide (laissons required s'en charger)
      }

      const uuidRegex =
        /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

      return uuidRegex.test(value) ? null : { invalidUuid: true };
    };
  }
}
