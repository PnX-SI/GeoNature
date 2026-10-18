import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Component, EventEmitter, Input, Output } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { UntypedFormControl } from '@angular/forms';
import { of } from 'rxjs';
import { AutoCompleteComponent } from './autocomplete.component';

@Component({ selector: 'pnx-autocomplete-select', template: '' })
class SelectStub {
  @Input() searchFn;
  @Input() designStyle;
  @Input() parentFormControl;
  @Input() label;
  @Input() charNumber;
  @Input() placeholder;
  @Input() keyValue;
  @Input() formatter;
  @Input() mapFunc;
  @Input() resultTemplate;
  @Output() onChange = new EventEmitter();
  @Output() onDelete = new EventEmitter();
}

describe('AutoCompleteComponent (connected)', () => {
  let fixture: ComponentFixture<AutoCompleteComponent>;
  let component: AutoCompleteComponent;
  let http: { get: jest.Mock };
  const select = () => fixture.debugElement.children[0].componentInstance as SelectStub;

  beforeEach(() => {
    http = { get: jest.fn().mockReturnValue(of([{ name: 'a' }])) };
    TestBed.configureTestingModule({
      declarations: [AutoCompleteComponent, SelectStub],
      providers: [{ provide: HttpClient, useValue: http }],
    });
    fixture = TestBed.createComponent(AutoCompleteComponent);
    component = fixture.componentInstance;
    component.parentFormControl = new UntypedFormControl(null);
    component.apiEndPoint = 'http://api/search';
    component.queryParamSearch = 'q';
    component.othersGetParams = { limit: 5 };
    component.keyValue = 'name';
    component.charNumber = 3;
    fixture.detectChanges();
  });

  it('gives the display inputs to the select', () => {
    expect(select().keyValue).toBe('name');
    expect(select().charNumber).toBe(3);
    expect(select().parentFormControl).toBe(component.parentFormControl);
  });

  it('searches the API with the term in the query string', () => {
    let result;
    select()
      .searchFn('canis')
      .subscribe((r) => (result = r));
    const [url, options] = http.get.mock.calls[0];
    expect(url).toBe('http://api/search');
    expect(options.params.toString()).toBe('q=canis&limit=5');
    expect(result).toEqual([{ name: 'a' }]);
  });

  it('forwards the events of the select', () => {
    const changed = jest.fn();
    const deleted = jest.fn();
    component.onChange.subscribe(changed);
    component.onDelete.subscribe(deleted);
    select().onChange.emit({ item: 1 });
    select().onDelete.emit();
    expect(changed).toHaveBeenCalledWith({ item: 1 });
    expect(deleted).toHaveBeenCalled();
  });

  it('uses the material design by default', () => {
    fixture.detectChanges();
    expect(fixture.debugElement.children[0].componentInstance.designStyle).toBe('material');
  });

  it('can use the bootstrap design', () => {
    component.designStyle = 'bootstrap';
    fixture.detectChanges();
    expect(fixture.debugElement.children[0].componentInstance.designStyle).toBe('bootstrap');
  });
});
