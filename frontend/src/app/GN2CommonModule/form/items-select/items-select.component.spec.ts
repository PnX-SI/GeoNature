import { Component, TemplateRef, ViewChild } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ReactiveFormsModule, UntypedFormControl, Validators } from '@angular/forms';
import { NgSelectModule } from '@ng-select/ng-select';
import { MatTooltipModule } from '@angular/material/tooltip';
import { ItemsSelectComponent } from './items-select.component';

@Component({
  template: `
    <pnx-items-select
      designStyle="bootstrap"
      [items]="items"
      [parentFormControl]="control"
      bindLabel="name"
      [optionTemplate]="option"
    ></pnx-items-select>
    <ng-template
      #option
      let-item
    >
      <b class="custom">{{ item.name }}!</b>
    </ng-template>
  `,
})
class HostComponent {
  items = [{ id: 1, name: 'one' }];
  control = new UntypedFormControl(null);
}

describe('ItemsSelectComponent', () => {
  let fixture: ComponentFixture<ItemsSelectComponent>;
  let control: UntypedFormControl;

  const items = [
    { id: 1, name: 'One' },
    { id: 2, name: 'Two' },
  ];

  const selected = () => fixture.nativeElement.querySelector('.ng-value-label')?.textContent.trim();
  const settle = async () => {
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();
  };

  beforeEach(() => {
    TestBed.configureTestingModule({
      declarations: [ItemsSelectComponent, HostComponent],
      imports: [ReactiveFormsModule, NgSelectModule, MatTooltipModule],
    });
    fixture = TestBed.createComponent(ItemsSelectComponent);
    control = new UntypedFormControl(null);
    fixture.componentInstance.parentFormControl = control;
    fixture.componentRef.setInput('designStyle', 'bootstrap');
    fixture.componentRef.setInput('items', items);
    fixture.componentRef.setInput('bindLabel', 'name');
    fixture.componentRef.setInput('label', 'My items');
  });

  it('displays the label', () => {
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('small').textContent).toBe('My items');
  });

  it('uses the label as placeholder unless one is given', async () => {
    await settle();
    expect(fixture.nativeElement.querySelector('.ng-placeholder').textContent).toBe('My items');
    fixture.componentRef.setInput('placeholder', 'Pick one');
    await settle();
    expect(fixture.nativeElement.querySelector('.ng-placeholder').textContent).toBe('Pick one');
  });

  it('displays the bindLabel attribute of the selected item', async () => {
    fixture.componentRef.setInput('bindValue', 'id');
    control.setValue(2);
    await settle();
    expect(selected()).toBe('Two');
  });

  it('writes the whole item without bindValue', async () => {
    fixture.componentRef.setInput('compareWith', (item, value) => item.id === value.id);
    control.setValue({ id: 1 });
    await settle();
    expect(selected()).toBe('One');
  });

  it('sets the qa attributes on the select', () => {
    fixture.componentRef.setInput('dataQa', 'my-select');
    fixture.componentRef.setInput('qaTest', 'my-test');
    fixture.detectChanges();
    const select: HTMLElement = fixture.nativeElement.querySelector('ng-select');
    expect(select.getAttribute('data-qa')).toBe('my-select');
    expect(select.getAttribute('qa-test')).toBe('my-test');
  });

  it('does not set the qa attributes by default', () => {
    fixture.detectChanges();
    const select: HTMLElement = fixture.nativeElement.querySelector('ng-select');
    expect(select.hasAttribute('data-qa')).toBe(false);
    expect(select.hasAttribute('qa-test')).toBe(false);
  });

  describe('autoSelectKey', () => {
    it('selects the only item when the control is required and empty', () => {
      control.addValidators(Validators.required);
      fixture.componentRef.setInput('autoSelectKey', 'id');
      fixture.componentRef.setInput('items', [items[0]]);
      fixture.detectChanges();
      expect(control.value).toBe(1);
    });

    it('does nothing without the input', () => {
      control.addValidators(Validators.required);
      fixture.componentRef.setInput('items', [items[0]]);
      fixture.detectChanges();
      expect(control.value).toBeNull();
    });

    it('does nothing with several items', () => {
      control.addValidators(Validators.required);
      fixture.componentRef.setInput('autoSelectKey', 'id');
      fixture.detectChanges();
      expect(control.value).toBeNull();
    });
  });

  it('displays the options with the given template', async () => {
    const host = TestBed.createComponent(HostComponent);
    host.detectChanges();
    host.nativeElement.querySelector('ng-select input').dispatchEvent(new Event('focus'));
    host.nativeElement
      .querySelector('ng-select .ng-select-container')
      .dispatchEvent(new MouseEvent('mousedown'));
    await host.whenStable();
    host.detectChanges();
    expect(
      document.querySelector('.custom')?.textContent ??
        host.nativeElement.querySelector('.custom')?.textContent
    ).toBe('one!');
  });

  it('displays the options with a tooltip and the data-qa of the item by default', async () => {
    const host = TestBed.createComponent(ItemsSelectComponent);
    host.componentInstance.parentFormControl = new UntypedFormControl(null);
    host.componentRef.setInput('designStyle', 'bootstrap');
    host.componentRef.setInput('items', items);
    host.componentRef.setInput('bindLabel', 'name');
    host.detectChanges();
    host.nativeElement
      .querySelector('.ng-select-container')
      .dispatchEvent(new MouseEvent('mousedown'));
    await host.whenStable();
    host.detectChanges();
    const option = host.nativeElement.querySelector('[data-qa="One"]');
    expect(option.textContent.trim()).toBe('One');
  });
});
