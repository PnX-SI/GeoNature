import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Component, Input } from '@angular/core';
import { UntypedFormControl } from '@angular/forms';
import { of } from 'rxjs';
import { Observer } from '../../interfaces';
import { ObserversComponent } from './observers.component';
import { ObserversSource } from './observers.source';

@Component({ selector: 'pnx-items-select', template: '' })
class ItemsSelectStub {
  @Input() items;
  @Input() parentFormControl;
  @Input() label;
  @Input() class;
  @Input() multiSelect;
  @Input() clearable;
  @Input() loading;
  @Input() bindLabel;
  @Input() bindValue;
  @Input() placeholder;
  @Input() compareWith;
  @Input() appendTo;
  @Input() clearAllText;
  @Input() dataQa;
  @Input() qaTest;
  @Input() optionTemplate;
  @Input() autoSelectKey;
}

describe('ObserversComponent (connected)', () => {
  let fixture: ComponentFixture<ObserversComponent>;
  let component: ObserversComponent;
  let source: { load: jest.Mock };
  const observers: Observer[] = [{ id_role: 1, nom_complet: 'A' }];
  const select = () => fixture.debugElement.children[0].componentInstance as ItemsSelectStub;

  beforeEach(() => {
    source = { load: jest.fn().mockReturnValue(of(observers)) };
    TestBed.configureTestingModule({
      declarations: [ObserversComponent, ItemsSelectStub],
      providers: [{ provide: ObserversSource, useValue: source }],
    });
    fixture = TestBed.createComponent(ObserversComponent);
    component = fixture.componentInstance;
    component.parentFormControl = new UntypedFormControl(null);
    component.label = 'Observateurs';
  });

  it('loads all observers by default', () => {
    fixture.detectChanges();
    expect(source.load).toHaveBeenCalledWith({ idMenu: undefined, codeList: undefined });
    expect(select().items).toEqual(observers);
    expect(select().placeholder).toBe('Observateurs');
    expect(select().bindLabel).toBe('nom_complet');
    expect(select().dataQa).toBe('gn-common-form-observers-select');
  });

  it('matches observers by id_role unless a value attribute is bound', () => {
    fixture.detectChanges();
    expect(select().compareWith).toBe(component.compareWith);
  });

  it('loads the observers of a list (idList takes precedence over idMenu)', () => {
    component.idMenu = 1;
    component.idList = 9;
    fixture.detectChanges();
    expect(source.load).toHaveBeenCalledWith({ idMenu: 9, codeList: undefined });
  });

  it('loads the observers of a list from its code and refreshes the control value', () => {
    component.codeList = 'obs';
    component.parentFormControl.setValue([{ id_role: 1 }]);
    const changed = jest.fn();
    component.parentFormControl.valueChanges.subscribe(changed);
    fixture.detectChanges();
    expect(source.load).toHaveBeenCalledWith({ idMenu: undefined, codeList: 'obs' });
    expect(changed).toHaveBeenCalled();
  });

  it('uses the observers given as input without loading', () => {
    component.observers = of([{ id_role: 5, nom_complet: 'B' }]);
    fixture.detectChanges();
    expect(source.load).not.toHaveBeenCalled();
    expect(select().items).toEqual([{ id_role: 5, nom_complet: 'B' }]);
  });
});
