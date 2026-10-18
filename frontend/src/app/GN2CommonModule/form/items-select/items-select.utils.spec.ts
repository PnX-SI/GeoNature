import { UntypedFormControl, Validators } from '@angular/forms';
import { selectSingleItem } from './items-select.utils';

describe('selectSingleItem', () => {
  const requiredControl = (value: any = null) => new UntypedFormControl(value, Validators.required);

  it('selects the only item of a required empty control', () => {
    const control = requiredControl();
    selectSingleItem([{ id_dataset: 5 }], control, false, 'id_dataset');
    expect(control.value).toBe(5);
  });

  it('wraps the value in an array in multiselect mode', () => {
    const control = requiredControl();
    selectSingleItem([{ id_dataset: 5 }], control, true, 'id_dataset');
    expect(control.value).toEqual([5]);
  });

  it('does nothing if the control is not required', () => {
    const control = new UntypedFormControl(null);
    selectSingleItem([{ id_dataset: 5 }], control, false, 'id_dataset');
    expect(control.value).toBeNull();
  });

  it('does nothing if the control already has a value', () => {
    const control = requiredControl(2);
    selectSingleItem([{ id_dataset: 5 }], control, false, 'id_dataset');
    expect(control.value).toBe(2);
  });

  it('does nothing if there are several items or none', () => {
    const control = requiredControl();
    selectSingleItem([{ id_dataset: 1 }, { id_dataset: 2 }], control, false, 'id_dataset');
    selectSingleItem([], control, false, 'id_dataset');
    selectSingleItem(undefined, control, false, 'id_dataset');
    expect(control.value).toBeNull();
  });
});
