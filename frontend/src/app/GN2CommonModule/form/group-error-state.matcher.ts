import { UntypedFormControl, FormGroupDirective, NgForm } from '@angular/forms';
import { ErrorStateMatcher } from '@angular/material/core';

/**
 * Error state of a Material field that also depends on errors of the parent form group
 * (cross-field validators such as a min greater than a max).
 *
 * @example
 * altitudeMatcher = new GroupErrorStateMatcher('invalidAlt');
 * <input matInput [errorStateMatcher]="altitudeMatcher" ...>
 */
export class GroupErrorStateMatcher implements ErrorStateMatcher {
  private groupErrors: string[];

  constructor(...groupErrors: string[]) {
    this.groupErrors = groupErrors;
  }

  isErrorState(
    control: UntypedFormControl | null,
    form: FormGroupDirective | NgForm | null
  ): boolean {
    if (!control) {
      return false;
    }
    const groupError = this.groupErrors.some((error) => !!control.parent?.hasError(error));
    return groupError || (control.invalid && (control.dirty || control.touched));
  }
}
