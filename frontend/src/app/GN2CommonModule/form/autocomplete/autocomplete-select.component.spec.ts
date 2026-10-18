import { ComponentFixture, fakeAsync, TestBed, tick } from '@angular/core/testing';
import { NO_ERRORS_SCHEMA } from '@angular/core';
import { ReactiveFormsModule, UntypedFormControl } from '@angular/forms';
import { of, throwError } from 'rxjs';
import { AutoCompleteSelectComponent } from './autocomplete-select.component';

describe('AutoCompleteSelectComponent', () => {
  let fixture: ComponentFixture<AutoCompleteSelectComponent>;
  let component: AutoCompleteSelectComponent;
  let searchFn: jest.Mock;

  const search = (term: string) => {
    let result;
    component.search(of(term)).subscribe((r) => (result = r));
    tick(400);
    return result;
  };

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [ReactiveFormsModule],
      declarations: [AutoCompleteSelectComponent],
      schemas: [NO_ERRORS_SCHEMA],
    });
    fixture = TestBed.createComponent(AutoCompleteSelectComponent);
    component = fixture.componentInstance;
    component.parentFormControl = new UntypedFormControl(null);
    searchFn = jest.fn().mockReturnValue(of([{ name: 'a' }]));
    component.searchFn = searchFn;
    fixture.detectChanges();
  });

  it('searches once the term has charNumber characters (2 by default)', fakeAsync(() => {
    expect(search('c')).toEqual([]);
    expect(searchFn).not.toHaveBeenCalled();
    expect(search('ca')).toEqual([{ name: 'a' }]);
    expect(searchFn).toHaveBeenCalledWith('ca');
    expect(component.isLoading).toBe(false);
    expect(component.noResult).toBe(false);
  }));

  it('maps the results with mapFunc', fakeAsync(() => {
    component.mapFunc = (item) => ({ ...item, name: item.name.toUpperCase() });
    expect(search('ca')).toEqual([{ name: 'A' }]);
  }));

  it('flags when there is no result', fakeAsync(() => {
    searchFn.mockReturnValue(of([]));
    search('ca');
    expect(component.noResult).toBe(true);
  }));

  it('gives an empty list when the search fails', fakeAsync(() => {
    searchFn.mockReturnValue(throwError(() => new Error('boom')));
    expect(search('ca')).toEqual([]);
    expect(component.noResult).toBe(true);
  }));

  it('emits the selected item then empties the control', () => {
    const selected = jest.fn();
    component.onChange.subscribe(selected);
    component.parentFormControl.setValue('ca');
    component.itemSelected({ item: { name: 'a' } } as any);
    expect(selected).toHaveBeenCalledWith({ item: { name: 'a' } });
    expect(component.parentFormControl.value).toBeNull();
  });

  it('emits onDelete when the control is emptied', () => {
    const deleted = jest.fn();
    component.onDelete.subscribe(deleted);
    component.parentFormControl.setValue('');
    expect(deleted).toHaveBeenCalledTimes(1);
  });
});
