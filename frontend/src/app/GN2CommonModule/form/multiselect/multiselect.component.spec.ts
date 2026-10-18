import { Component, Input } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { UntypedFormControl } from '@angular/forms';
import { MultiSelectComponent } from './multiselect.component';

@Component({ selector: 'pnx-items-select', template: '' })
class ItemsSelectStub {
  @Input() items;
  @Input() designStyle;
  @Input() parentFormControl;
  @Input() label;
  @Input() multiSelect;
  @Input() clearable;
  @Input() bindLabel;
  @Input() bindValue;
  @Input() compareWith;
}

describe('MultiSelectComponent', () => {
  let fixture: ComponentFixture<MultiSelectComponent>;
  let component: MultiSelectComponent;
  const values = [
    { id: 1, name: 'One' },
    { id: 2, name: 'Two' },
  ];
  const select = () => fixture.debugElement.children[0];

  beforeEach(() => {
    TestBed.configureTestingModule({ declarations: [MultiSelectComponent, ItemsSelectStub] });
    fixture = TestBed.createComponent(MultiSelectComponent);
    component = fixture.componentInstance;
    component.parentFormControl = new UntypedFormControl([]);
    component.values = values;
    component.keyLabel = 'name';
    component.keyValue = 'id';
    component.label = 'Numbers';
  });

  it('gives its inputs to a multiple material select', () => {
    fixture.detectChanges();
    const stub = select().componentInstance as ItemsSelectStub;
    expect(stub.designStyle).toBe('material');
    expect(stub.multiSelect).toBe(true);
    expect(stub.items).toBe(values);
    expect(stub.bindLabel).toBe('name');
    expect(stub.bindValue).toBe('id');
    expect(stub.label).toBe('Numbers');
    expect(stub.parentFormControl).toBe(component.parentFormControl);
  });

  it('gives the whole items to the control with bindAllItem', () => {
    component.bindAllItem = true;
    fixture.detectChanges();
    expect((select().componentInstance as ItemsSelectStub).bindValue).toBeNull();
  });

  it('compares whole items by label', () => {
    fixture.detectChanges();
    const compare = (select().componentInstance as ItemsSelectStub).compareWith;
    expect(compare({ name: 'One' }, { name: 'One', id: 1 })).toBe(true);
    expect(compare({ name: 'One' }, { name: 'Two' })).toBe(false);
    expect(compare({ name: 'One' }, null)).toBe(false);
  });

  it('forwards the added and removed items', () => {
    fixture.detectChanges();
    const changed = jest.fn();
    const deleted = jest.fn();
    component.onChange.subscribe(changed);
    component.onDelete.subscribe(deleted);
    select().triggerEventHandler('itemAdded', values[0]);
    select().triggerEventHandler('itemRemoved', { value: values[1] });
    expect(changed).toHaveBeenCalledWith(values[0]);
    expect(deleted).toHaveBeenCalledWith({ value: values[1] });
  });
});
