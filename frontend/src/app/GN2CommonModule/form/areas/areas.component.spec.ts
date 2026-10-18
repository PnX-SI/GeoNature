import { ComponentFixture, fakeAsync, TestBed, tick } from '@angular/core/testing';
import { Component, EventEmitter, Input, Output } from '@angular/core';
import { UntypedFormControl } from '@angular/forms';
import { of, throwError } from 'rxjs';
import { AreasComponent } from './areas.component';
import { AreasSource } from './areas.source';

const area = (id_area: number) => ({ id_area, area_name: `Area ${id_area}` });

@Component({ selector: 'pnx-areas-select', template: '' })
class SelectStub {
  @Input() items;
  @Input() parentFormControl;
  @Input() label;
  @Input() class;
  @Input() multiSelect;
  @Input() clearable;
  @Input() loading;
  @Input() valueFieldName;
  @Input() compareWith;
  @Output() search = new EventEmitter<string>();
  @Output() selectionChange = new EventEmitter<any>();
}

describe('AreasComponent (connected)', () => {
  let fixture: ComponentFixture<AreasComponent>;
  let component: AreasComponent;
  let source: { load: jest.Mock };
  const select = () => fixture.debugElement.children[0].componentInstance as SelectStub;

  beforeEach(() => {
    source = { load: jest.fn().mockReturnValue(of([area(1)])) };
    TestBed.configureTestingModule({
      declarations: [AreasComponent, SelectStub],
      providers: [{ provide: AreasSource, useValue: source }],
    });
    fixture = TestBed.createComponent(AreasComponent);
    component = fixture.componentInstance;
    component.parentFormControl = new UntypedFormControl(null);
  });

  it('preloads the areas of the given types and merges the default items', () => {
    component.typeCodes = ['COM'];
    component.defaultItems = [{ id_area: 9 }];
    fixture.detectChanges();
    expect(source.load).toHaveBeenCalledWith(
      expect.objectContaining({ type_code: ['COM'], without_geom: false })
    );
    expect(select().items).toEqual([area(1), { id_area: 9 }]);
  });

  it('searches areas once the user typed at least 2 characters', fakeAsync(() => {
    fixture.detectChanges();
    source.load.mockClear();
    source.load.mockReturnValue(of([area(2)]));
    select().search.emit('p');
    tick(200);
    expect(source.load).not.toHaveBeenCalled();
    select().search.emit('par');
    tick(200);
    expect(source.load).toHaveBeenCalledWith(expect.objectContaining({ area_name: 'par' }));
    fixture.detectChanges();
    expect(select().items).toEqual([area(2)]);
    expect(select().loading).toBe(false);
  }));

  it('shows an empty list when the search fails', fakeAsync(() => {
    fixture.detectChanges();
    source.load.mockReturnValue(throwError(() => new Error('boom')));
    select().search.emit('par');
    tick(200);
    fixture.detectChanges();
    expect(select().items).toEqual([]);
  }));

  it('forwards the selection changes', () => {
    fixture.detectChanges();
    const changed = jest.fn();
    component.onSelectionChange.subscribe(changed);
    select().selectionChange.emit([{ id_area: 1 }]);
    expect(changed).toHaveBeenCalledWith([{ id_area: 1 }]);
  });
});
