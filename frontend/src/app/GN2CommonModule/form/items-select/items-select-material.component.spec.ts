import { Component } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { FormsModule, ReactiveFormsModule, UntypedFormControl, Validators } from '@angular/forms';
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
import { ItemsSelectComponent } from './items-select.component';

@Component({
  template: `
    <pnx-items-select
      designStyle="material"
      [items]="items"
      [parentFormControl]="control"
      bindLabel="name"
      [optionTemplate]="option"
    ></pnx-items-select>
    <ng-template
      #option
      let-item
    >
      <b>{{ item.name }}!</b>
    </ng-template>
  `,
})
class HostComponent {
  items = [{ id: 1, name: 'One' }];
  control = new UntypedFormControl(null);
}

describe('ItemsSelectComponent (material design)', () => {
  let fixture: ComponentFixture<ItemsSelectComponent>;
  let component: ItemsSelectComponent;
  let loader: HarnessLoader;
  let control: UntypedFormControl;

  const items = [
    { id: 1, name: 'Alpha' },
    { id: 2, name: 'Bravo' },
    { id: 3, name: 'Charlie' },
  ];

  const select = () => loader.getHarness(MatSelectHarness);
  const optionTexts = async () => {
    const s = await select();
    return Promise.all((await s.getOptions()).map((o) => o.getText()));
  };

  /** Create the component. `multiSelect` cannot change once the select is rendered */
  const create = (inputs: Partial<ItemsSelectComponent> = {}) => {
    fixture = TestBed.createComponent(ItemsSelectComponent);
    component = fixture.componentInstance;
    control = new UntypedFormControl(null);
    component.parentFormControl = control;
    const all = {
      designStyle: 'material',
      items,
      bindLabel: 'name',
      bindValue: 'id',
      label: 'Letters',
      ...inputs,
    };
    Object.entries(all).forEach(([name, value]) => fixture.componentRef.setInput(name, value));
    fixture.detectChanges();
    loader = TestbedHarnessEnvironment.loader(fixture);
  };

  beforeEach(() => {
    TestBed.configureTestingModule({
      declarations: [ItemsSelectComponent, HostComponent],
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
      ],
    });
    create();
  });

  it('renders a material select, not an ng-select', () => {
    expect(fixture.nativeElement.querySelector('mat-select')).not.toBeNull();
    expect(fixture.nativeElement.querySelector('ng-select')).toBeNull();
  });

  it('displays the label', () => {
    expect(fixture.nativeElement.querySelector('mat-label').textContent).toBe('Letters');
  });

  it('lists the items by their bindLabel', async () => {
    await (await select()).open();
    expect(await optionTexts()).toEqual(['Alpha', 'Bravo', 'Charlie']);
  });

  it('writes the bindValue of the picked item in the control', async () => {
    await (await select()).clickOptions({ text: 'Bravo' });
    expect(control.value).toBe(2);
  });

  it('displays the selected item of the control', async () => {
    control.setValue(3);
    expect(await (await select()).getValueText()).toBe('Charlie');
  });

  it('writes the whole item without bindValue', async () => {
    fixture.componentRef.setInput('bindValue', null);
    fixture.detectChanges();
    await (await select()).clickOptions({ text: 'Alpha' });
    expect(control.value).toBe(items[0]);
  });

  it('compares items with compareWith when the whole item is written', async () => {
    fixture.componentRef.setInput('bindValue', null);
    fixture.componentRef.setInput('compareWith', (item, selected) => item.id === selected.id);
    fixture.detectChanges();
    control.setValue({ id: 2 });
    expect(await (await select()).getValueText()).toBe('Bravo');
  });

  it('selects several items in multiselect mode', async () => {
    create({ multiSelect: true });
    const s = await select();
    await s.clickOptions({ text: 'Alpha' });
    await s.clickOptions({ text: 'Charlie' });
    expect(control.value).toEqual([1, 3]);
  });

  describe('search', () => {
    it('filters the items on their label, ignoring case', async () => {
      await (await select()).open();
      component.searchChanged('RAV');
      fixture.detectChanges();
      expect(await optionTexts()).toEqual(['Bravo']);
    });

    it('shows a message when nothing matches', async () => {
      await (await select()).open();
      component.searchChanged('zzz');
      fixture.detectChanges();
      expect(await optionTexts()).toEqual(['Aucun élément trouvé']);
    });

    it('keeps the selected items in the list so the select keeps their label', async () => {
      control.setValue(1);
      component.searchChanged('charlie');
      expect(component.filteredItems.map((i) => i.name)).toEqual(['Alpha', 'Charlie']);
    });

    it('is reset when the panel closes', async () => {
      const s = await select();
      await s.open();
      component.searchChanged('alp');
      await s.close();
      expect(component.search).toBe('');
    });

    it('has no search box when not searchable', async () => {
      fixture.componentRef.setInput('searchable', false);
      fixture.detectChanges();
      await (await select()).open();
      expect(document.querySelector('[data-qa="items-select-search"]')).toBeNull();
    });
  });

  describe('clear button', () => {
    const clearButton = () => fixture.nativeElement.querySelector('[data-qa="items-select-clear"]');

    it('is hidden without value', () => {
      expect(clearButton()).toBeNull();
    });

    it('empties the control', () => {
      control.setValue(2);
      fixture.detectChanges();
      clearButton().click();
      expect(control.value).toBeNull();
    });

    it('empties a multiselect to an empty list', () => {
      create({ multiSelect: true });
      control.setValue([1, 2]);
      fixture.detectChanges();
      clearButton().click();
      expect(control.value).toEqual([]);
    });

    it('is hidden when not clearable', () => {
      fixture.componentRef.setInput('clearable', false);
      control.setValue(2);
      fixture.detectChanges();
      expect(clearButton()).toBeNull();
    });
  });

  it('shows a spinner while loading', () => {
    expect(fixture.nativeElement.querySelector('mat-spinner')).toBeNull();
    fixture.componentRef.setInput('loading', true);
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('mat-spinner')).not.toBeNull();
  });

  it('is required when the control is', () => {
    expect(component.required).toBe(false);
    control.addValidators(Validators.required);
    expect(component.required).toBe(true);
  });

  it('sets the qa attributes on the select', () => {
    fixture.componentRef.setInput('dataQa', 'my-select');
    fixture.componentRef.setInput('qaTest', 'my-test');
    fixture.detectChanges();
    const el: HTMLElement = fixture.nativeElement.querySelector('mat-select');
    expect(el.getAttribute('data-qa')).toBe('my-select');
    expect(el.getAttribute('qa-test')).toBe('my-test');
  });

  it('auto-selects the only item of a required empty control', () => {
    control.addValidators(Validators.required);
    fixture.componentRef.setInput('autoSelectKey', 'id');
    fixture.componentRef.setInput('items', [items[1]]);
    fixture.detectChanges();
    expect(control.value).toBe(2);
  });

  it('displays the options with the given template', async () => {
    const host = TestBed.createComponent(HostComponent);
    host.detectChanges();
    const hostLoader = TestbedHarnessEnvironment.loader(host);
    const s = await hostLoader.getHarness(MatSelectHarness);
    await s.open();
    expect(await (await s.getOptions())[0].getText()).toBe('One!');
  });
});
