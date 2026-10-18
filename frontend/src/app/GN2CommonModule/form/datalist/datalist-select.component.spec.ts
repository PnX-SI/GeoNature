import { ComponentFixture, TestBed } from '@angular/core/testing';
import { FormsModule, ReactiveFormsModule, UntypedFormControl } from '@angular/forms';
import { NgSelectModule } from '@ng-select/ng-select';
import { NoopAnimationsModule } from '@angular/platform-browser/animations';
import { MatChipsModule } from '@angular/material/chips';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatTooltipModule } from '@angular/material/tooltip';
import { DatalistSelectComponent } from './datalist-select.component';

describe('DatalistSelectComponent', () => {
  let fixture: ComponentFixture<DatalistSelectComponent>;
  let component: DatalistSelectComponent;
  let control: UntypedFormControl;

  const values = [
    { value: 'b', label: 'Bravo' },
    { value: 'a', label: 'Alpha' },
    { value: 'c', label: 'Charlie' },
  ];

  const setInputs = (inputs: Partial<DatalistSelectComponent>) => {
    Object.entries(inputs).forEach(([k, v]) => fixture.componentRef.setInput(k, v));
    fixture.detectChanges();
  };

  beforeEach(() => {
    TestBed.configureTestingModule({
      declarations: [DatalistSelectComponent],
      imports: [
        FormsModule,
        ReactiveFormsModule,
        NoopAnimationsModule,
        NgSelectModule,
        MatChipsModule,
        MatFormFieldModule,
        MatIconModule,
        MatInputModule,
        MatSelectModule,
        MatTooltipModule,
      ],
    });
    fixture = TestBed.createComponent(DatalistSelectComponent);
    component = fixture.componentInstance;
    control = new UntypedFormControl(null);
    component.parentFormControl = control;
  });

  it('renders nothing until values are given', () => {
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('ng-select')).toBeNull();
    setInputs({ designStyle: 'bootstrap', values });
    expect(fixture.nativeElement.querySelector('ng-select')).not.toBeNull();
  });

  it('normalizes raw values', () => {
    setInputs({ values: ['x', 'y'] });
    expect(component.filteredValues).toEqual([
      { label: 'x', value: 'x' },
      { label: 'y', value: 'y' },
    ]);
  });

  it('marks the control as touched', () => {
    setInputs({ values });
    expect(control.touched).toBe(true);
  });

  it('removes duplicated values', () => {
    setInputs({ values: [...values, { value: 'a', label: 'Alpha again' }] });
    expect(component.filteredValues.map((v) => v.value)).toEqual(['b', 'a', 'c']);
  });

  it('orders values by label', () => {
    setInputs({ values, orderBy: 'asc' });
    expect(component.filteredValues.map((v) => v.label)).toEqual(['Alpha', 'Bravo', 'Charlie']);
    setInputs({ values: [...values], orderBy: 'desc' });
    expect(component.filteredValues.map((v) => v.label)).toEqual(['Charlie', 'Bravo', 'Alpha']);
  });

  it('filters the values with the search term, ignoring case', () => {
    setInputs({ values });
    component.searchChanged('ALP');
    expect(component.filteredValues.map((v) => v.value)).toEqual(['a']);
  });

  it('keeps only the filtered keys, in the order of the filter', () => {
    setInputs({ values, filters: { value: ['c', 'a', 'zzz'] } });
    expect(component.filteredValues.map((v) => v.value)).toEqual(['c', 'a']);
  });

  it('uses the first existing key of a comma separated keyLabel', () => {
    setInputs({
      values: [
        { value: 1, name: 'N' },
        { value: 2, label: 'L' },
      ],
      keyLabel: 'label,name',
    });
    expect(component.filteredValues.map((v) => component.displayLabel(v))).toEqual(['N', 'L']);
  });

  describe('required with a single choice', () => {
    it('selects it', () => {
      setInputs({ values: [values[0]], required: true });
      expect(control.value).toBe('b');
    });

    it('selects it in an array in multiple mode', () => {
      setInputs({ values: [values[0]], required: true, multiple: true });
      expect(control.value).toEqual(['b']);
    });

    it('does not override an existing value', () => {
      control.setValue('z');
      setInputs({ values: [values[0]], required: true });
      expect(control.value).toBe('z');
    });

    it('does nothing when not required', () => {
      setInputs({ values: [values[0]] });
      expect(control.value).toBeNull();
    });
  });

  describe('nullDefault', () => {
    it('adds an empty choice when not required', () => {
      setInputs({ values, nullDefault: true });
      expect(component.filteredValues[0]).toEqual({ value: null, label: '-- Aucun --' });
    });

    it('adds nothing when required', () => {
      setInputs({ values, nullDefault: true, required: true });
      expect(component.filteredValues.length).toBe(3);
    });
  });

  describe('default', () => {
    it('is applied to an empty control when it is one of the values', () => {
      setInputs({ values, default: { value: 'c' } });
      expect(control.value).toBe('c');
    });

    it('is not applied when it is not one of the values', () => {
      setInputs({ values, default: { value: 'zzz' } });
      expect(control.value).toBeNull();
    });

    it('is not applied when the control already has a value', () => {
      control.setValue('a');
      setInputs({ values, default: { value: 'c' } });
      expect(control.value).toBe('a');
    });
  });

  it('removes a chip from the control value', () => {
    control.setValue(['a', 'b']);
    setInputs({ values, multiple: true });
    component.onToppingRemoved('a');
    expect(control.value).toEqual(['b']);
  });

  it('gives the label of a value', () => {
    setInputs({ values });
    expect(component.displayLabelFromValue('c')).toBe('Charlie');
    expect(component.displayLabelFromValue('nope')).toBeUndefined();
    expect(component.displayLabelFromValue(null)).toBe('');
  });
});
