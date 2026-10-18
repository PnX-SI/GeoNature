import { ComponentFixture, TestBed } from '@angular/core/testing';
import { FormsModule, ReactiveFormsModule, UntypedFormControl } from '@angular/forms';
import { HarnessLoader } from '@angular/cdk/testing';
import { TestbedHarnessEnvironment } from '@angular/cdk/testing/testbed';
import { NoopAnimationsModule } from '@angular/platform-browser/animations';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSelectModule } from '@angular/material/select';
import { MatSelectHarness } from '@angular/material/select/testing';
import { MatTooltipModule } from '@angular/material/tooltip';
import { AreasSelectComponent } from './areas-select.component';

describe('AreasSelectComponent (material design)', () => {
  let fixture: ComponentFixture<AreasSelectComponent>;
  let component: AreasSelectComponent;
  let loader: HarnessLoader;
  let control: UntypedFormControl;

  const alpes = { id_area: 1, area_name: 'Alpes' };
  const vosges = { id_area: 2, area_name: 'Vosges' };

  const select = () => loader.getHarness(MatSelectHarness);
  const optionTexts = async () =>
    Promise.all((await (await select()).getOptions()).map((o) => o.getText()));

  const create = (inputs: Partial<AreasSelectComponent> = {}) => {
    fixture = TestBed.createComponent(AreasSelectComponent);
    component = fixture.componentInstance;
    control = new UntypedFormControl(null);
    component.parentFormControl = control;
    const all = { items: [alpes, vosges], label: 'Zones', ...inputs };
    Object.entries(all).forEach(([name, value]) => fixture.componentRef.setInput(name, value));
    fixture.detectChanges();
    loader = TestbedHarnessEnvironment.loader(fixture);
  };

  beforeEach(() => {
    TestBed.configureTestingModule({
      declarations: [AreasSelectComponent],
      imports: [
        FormsModule,
        ReactiveFormsModule,
        NoopAnimationsModule,
        MatButtonModule,
        MatFormFieldModule,
        MatIconModule,
        MatInputModule,
        MatProgressSpinnerModule,
        MatSelectModule,
        MatTooltipModule,
      ],
    });
    create();
  });

  it('is the default design', () => {
    expect(fixture.nativeElement.querySelector('mat-select')).not.toBeNull();
    expect(fixture.nativeElement.querySelector('ng-select')).toBeNull();
  });

  it('writes the id of the selected area', async () => {
    await (await select()).clickOptions({ text: 'Vosges' });
    expect(control.value).toBe(2);
  });

  it('writes the whole area without valueFieldName', async () => {
    create({ valueFieldName: null });
    await (await select()).clickOptions({ text: 'Vosges' });
    expect(control.value).toEqual(vosges);
  });

  it('emits the selected areas', async () => {
    create({ multiSelect: true });
    const changed = jest.fn();
    component.selectionChange.subscribe(changed);
    const s = await select();
    await s.clickOptions({ text: 'Alpes' });
    await s.clickOptions({ text: 'Vosges' });
    expect(control.value).toEqual([1, 2]);
    expect(changed).toHaveBeenLastCalledWith([alpes, vosges]);
  });

  it('emits the term typed in the search box', async () => {
    const searched = jest.fn();
    component.search.subscribe(searched);
    component.ngOnInit();
    await (await select()).open();
    component.termChanged('alp');
    expect(searched).toHaveBeenCalledWith('alp');
  });

  it('keeps the selected area in the options when the search result changes', async () => {
    create({ multiSelect: true });
    await (await select()).clickOptions({ text: 'Alpes' });
    fixture.componentRef.setInput('items', [vosges]);
    fixture.detectChanges();
    expect(await optionTexts()).toEqual(['Alpes', 'Vosges']);
  });

  it('shows the selected area of an update form', async () => {
    create({ items: [alpes, vosges] });
    control.setValue(2);
    fixture.detectChanges();
    expect(await (await select()).getValueText()).toBe('Vosges');
  });

  it('clears the selection', async () => {
    control.setValue(2);
    fixture.detectChanges();
    fixture.nativeElement.querySelector('[data-qa="areas-select-clear"]').click();
    expect(control.value).toBeNull();
  });
});
