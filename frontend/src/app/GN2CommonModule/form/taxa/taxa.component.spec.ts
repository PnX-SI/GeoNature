import { ComponentFixture, fakeAsync, TestBed, tick } from '@angular/core/testing';
import { Component, EventEmitter, Input, Output } from '@angular/core';
import { UntypedFormControl } from '@angular/forms';
import { of } from 'rxjs';
import { TaxaComponent } from './taxa.component';
import { TaxaSource } from './taxa.source';

@Component({ selector: 'pnx-taxa-select', template: '' })
class SelectStub {
  @Input() items;
  @Input() parentFormControl;
  @Input() label;
  @Input() class;
  @Input() loading;
  @Input() valueFieldName;
  @Input() compareWith;
  @Output() search = new EventEmitter<string>();
  @Output() selectionChange = new EventEmitter<any>();
}

describe('TaxaComponent (connected)', () => {
  let fixture: ComponentFixture<TaxaComponent>;
  let component: TaxaComponent;
  let source: { load: jest.Mock };
  const select = () => fixture.debugElement.children[0].componentInstance as SelectStub;

  beforeEach(() => {
    source = { load: jest.fn().mockReturnValue(of([{ cd_nom: 3 }])) };
    TestBed.configureTestingModule({
      declarations: [TaxaComponent, SelectStub],
      providers: [{ provide: TaxaSource, useValue: source }],
    });
    fixture = TestBed.createComponent(TaxaComponent);
    component = fixture.componentInstance;
    component.parentFormControl = new UntypedFormControl([]);
  });

  it('starts with the default items without calling the API', () => {
    component.defaultItems = [{ cd_nom: 1 }];
    fixture.detectChanges();
    expect(select().items).toEqual([{ cd_nom: 1 }]);
    expect(source.load).not.toHaveBeenCalled();
  });

  it('searches taxa of the given rank once the user typed at least 2 characters', fakeAsync(() => {
    component.rank = 'FM';
    fixture.detectChanges();
    select().search.emit('c');
    tick(200);
    expect(source.load).not.toHaveBeenCalled();
    select().search.emit('can');
    tick(200);
    expect(source.load).toHaveBeenCalledWith({ rank: 'FM', term: 'can' });
    fixture.detectChanges();
    expect(select().items).toEqual([{ cd_nom: 3 }]);
  }));

  it('forwards the selection changes', () => {
    fixture.detectChanges();
    const changed = jest.fn();
    component.onSelectionChange.subscribe(changed);
    select().selectionChange.emit([{ cd_nom: 3 }]);
    expect(changed).toHaveBeenCalledWith([{ cd_nom: 3 }]);
  });
});
