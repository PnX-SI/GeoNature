import { AbstractControl, Validators } from '@angular/forms';

/**
 * If there is only one item and the control is required and empty, select it
 * @param key attribute of the item written in the control
 */
export function selectSingleItem(
  items: Array<any>,
  control: AbstractControl,
  multiSelect: boolean,
  key: string
): void {
  if (
    !items ||
    items.length !== 1 ||
    !control.hasValidator(Validators.required) ||
    control.value !== null
  ) {
    return;
  }
  const value = items[0][key];
  control.patchValue(multiSelect ? [value] : value);
}
