import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ReactiveFormsModule, UntypedFormControl } from '@angular/forms';
import { HarnessLoader } from '@angular/cdk/testing';
import { TestbedHarnessEnvironment } from '@angular/cdk/testing/testbed';
import { NoopAnimationsModule } from '@angular/platform-browser/animations';
import { MatAutocompleteModule } from '@angular/material/autocomplete';
import { MatAutocompleteHarness } from '@angular/material/autocomplete/testing';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { of } from 'rxjs';
import { AutoCompleteSelectComponent } from './autocomplete-select.component';

describe('AutoCompleteSelectComponent (material design)', () => {
  let fixture: ComponentFixture<AutoCompleteSelectComponent>;
  let component: AutoCompleteSelectComponent;
  let loader: HarnessLoader;
  let control: UntypedFormControl;
  let searchFn: jest.Mock;

  const results = [
    { id: 1, name: 'Alpha' },
    { id: 2, name: 'Bravo' },
  ];
  const autocomplete = () => loader.getHarness(MatAutocompleteHarness);
  const optionTexts = async () =>
    Promise.all((await (await autocomplete()).getOptions()).map((o) => o.getText()));

  beforeEach(() => {
    TestBed.configureTestingModule({
      declarations: [AutoCompleteSelectComponent],
      imports: [
        ReactiveFormsModule,
        NoopAnimationsModule,
        MatAutocompleteModule,
        MatFormFieldModule,
        MatInputModule,
        MatProgressSpinnerModule,
      ],
    });
    fixture = TestBed.createComponent(AutoCompleteSelectComponent);
    component = fixture.componentInstance;
    control = new UntypedFormControl(null);
    component.parentFormControl = control;
    searchFn = jest.fn().mockReturnValue(of(results));
    component.searchFn = searchFn;
    component.keyValue = 'name';
    component.label = 'Search';
    component.placeholder = 'Type here';
    fixture.detectChanges();
    loader = TestbedHarnessEnvironment.loader(fixture);
  });

  it('is the default design: a material autocomplete, not an ngb typeahead', () => {
    expect(fixture.nativeElement.querySelector('input[matInput]')).not.toBeNull();
    expect(fixture.nativeElement.querySelector('input[ngbTypeahead]')).toBeNull();
    expect(fixture.nativeElement.querySelector('mat-label').textContent).toBe('Search');
  });

  it('keeps the id of the input and gives it the placeholder', async () => {
    const input = fixture.nativeElement.querySelector('input');
    expect(input.id).toBe('taxonInput');
    expect(await (await autocomplete()).getValue()).toBe('');
    expect(input.placeholder).toBe('Type here');
  });

  it('lists the results of the search once enough characters are typed', async () => {
    await (await autocomplete()).enterText('alp');
    expect(searchFn).toHaveBeenCalledWith('alp');
    expect(await optionTexts()).toEqual(['Alpha', 'Bravo']);
  });

  it('does not search before charNumber characters', async () => {
    const auto = await autocomplete();
    await auto.enterText('a');
    expect(searchFn).not.toHaveBeenCalled();
    expect(await auto.isOpen()).toBe(false);
  });

  it('maps the results with mapFunc', async () => {
    component.mapFunc = (item) => ({ ...item, name: item.name.toUpperCase() });
    await (await autocomplete()).enterText('alp');
    expect(await optionTexts()).toEqual(['ALPHA', 'BRAVO']);
  });

  it('emits the picked item as a typeahead event, then empties the input', async () => {
    const picked = jest.fn();
    component.onChange.subscribe(picked);
    const auto = await autocomplete();
    await auto.enterText('alp');
    await auto.selectOption({ text: 'Bravo' });
    expect(picked).toHaveBeenCalledTimes(1);
    expect(picked.mock.calls[0][0].item).toEqual(results[1]);
    expect(typeof picked.mock.calls[0][0].preventDefault).toBe('function');
    expect(control.value).toBeNull();
    expect(await auto.getValue()).toBe('');
  });

  it('shows a message when nothing was found', async () => {
    searchFn.mockReturnValue(of([]));
    await (await autocomplete()).enterText('zzz');
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('mat-hint').textContent.trim()).toBe(
      'Aucun élement trouvé'
    );
  });

  it('displays a value of the control with the formatter', () => {
    component.formatter = (item) => item.name;
    expect(component.displayWith({ name: 'Alpha' })).toBe('Alpha');
    component.formatter = undefined;
    expect(component.displayWith('text')).toBe('text');
  });

  it('does not give an empty value to the formatter', () => {
    const formatter = jest.fn((item) => item.name);
    component.formatter = formatter;
    expect(component.displayWith(null)).toBe('');
    expect(component.displayWith(undefined)).toBe('');
    expect(formatter).not.toHaveBeenCalled();
    expect(component.displayWith(null)).toBe('');
  });
});
