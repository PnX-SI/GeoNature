import { AbstractControl, UntypedFormGroup, ValidationErrors, ValidatorFn } from '@angular/forms';
import { ValidationErrorsId } from './validation-errors-id';

// ////////////////////////////////////////////////////////////////////////////
// Helpers
// ////////////////////////////////////////////////////////////////////////////

function buildValidationErrors(errorName: string): ValidationErrors {
  return { [errorName]: true }
}

function addErrorToControl(control: AbstractControl, validationErrorsId: ValidationErrorsId){
  control.setErrors({
    ...control.errors,
    ...buildValidationErrors(validationErrorsId)
  });
}

function removeErrorFromControl(control: AbstractControl, validationErrorsId: ValidationErrorsId){
  if(control.errors) {
    const {
      [validationErrorsId]: ignored,
      ...errors
    } = control.errors
    control.setErrors(Object.keys(errors).length ? errors : null);
  }
}

// ////////////////////////////////////////////////////////////////////////////
// Control Error
// ////////////////////////////////////////////////////////////////////////////

export function arrayMinLengthValidator(arrayLength: number): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    if (!control.value) {
      return buildValidationErrors(ValidationErrorsId.ARRAY_MIN_LENGTH_ERROR);
    }
    return control.value.length >= arrayLength ? null : buildValidationErrors(ValidationErrorsId.ARRAY_MIN_LENGTH_ERROR);
  };
}

export function isObjectValidator(): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    return typeof control.value === 'object' && control.value != null
      ? null
      : buildValidationErrors(ValidationErrorsId.IS_OBJECT_ERROR);
  };
}

// ////////////////////////////////////////////////////////////////////////////
// Group Error
// ////////////////////////////////////////////////////////////////////////////

export function similarValidator(passControlName: string, passControlConfirmName: string): ValidatorFn {
  return (group: UntypedFormGroup): ValidationErrors | null => {
    const passControl = group.get(passControlName);
    const confirmPassControl = group.get(passControlConfirmName);
    if (passControl && confirmPassControl && passControl.value === confirmPassControl.value) {
      return null;
    }
    return buildValidationErrors(ValidationErrorsId.IS_OBJECT_ERROR);
  };
}

export function minBelowMaxValidator(minControlName: string, maxControlName: string, updateControlsError: boolean = true): ValidatorFn {
  return (group: UntypedFormGroup): ValidationErrors | null => {
    const minControl = group.get(minControlName);
    const maxControl = group.get(maxControlName);
    // Ensure that controls are found
    if(!minControl || !maxControl){
      return null;
    }

    // Adjust max control errors - remove invalidCount
    if( (minControl.errors && !minControl.hasError(ValidationErrorsId.MIN_GREATER_THAN_MAX)) ){
      if(updateControlsError) {
        removeErrorFromControl(maxControl, ValidationErrorsId.MIN_GREATER_THAN_MAX);
      }
      return null;
    }

    // Adjust min control errors - remove invalidCount
    if( (maxControl.errors && !maxControl.hasError(ValidationErrorsId.MIN_GREATER_THAN_MAX)) ){
      if(updateControlsError) {
        removeErrorFromControl(minControl, ValidationErrorsId.MIN_GREATER_THAN_MAX);
      }
      return null;
    }

    // Check values
    if (Number.isInteger(minControl.value) && Number.isInteger(maxControl.value)) {
      if(minControl.value > maxControl.value){
        if(updateControlsError){
          addErrorToControl(minControl, ValidationErrorsId.MIN_GREATER_THAN_MAX);
          addErrorToControl(maxControl, ValidationErrorsId.MIN_GREATER_THAN_MAX);
        }
        return buildValidationErrors(ValidationErrorsId.MIN_GREATER_THAN_MAX);
      }
      else {
        if(updateControlsError){
          removeErrorFromControl(minControl, ValidationErrorsId.MIN_GREATER_THAN_MAX);
          removeErrorFromControl(maxControl, ValidationErrorsId.MIN_GREATER_THAN_MAX);
        }
        return null;
      }
    }
    return null;
  }
}
