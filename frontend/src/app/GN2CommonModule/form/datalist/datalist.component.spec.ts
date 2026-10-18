import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Component, Input } from '@angular/core';
import { UntypedFormControl } from '@angular/forms';
import { of } from 'rxjs';
import { DatalistComponent } from './datalist.component';
import { DataFormService } from '../data-form.service';

@Component({ selector: 'pnx-datalist-select', template: '' })
class SelectStub {
  @Input() values;
  @Input() parentFormControl;
  @Input() label;
  @Input() designStyle;
  @Input() keyLabel;
  @Input() keyValue;
  @Input() keyTitle;
  @Input() multiple;
  @Input() required;
  @Input() definition;
  @Input() filters;
  @Input() orderBy;
  @Input() default;
  @Input() nullDefault;
}

describe('DatalistComponent (connected)', () => {
  let fixture: ComponentFixture<DatalistComponent>;
  let component: DatalistComponent;
  let dataFormService: { getDataList: jest.Mock };
  const select = () => fixture.debugElement.children[0].componentInstance as SelectStub;

  beforeEach(() => {
    dataFormService = { getDataList: jest.fn().mockReturnValue(of({ data: ['x', 'y'] })) };
    TestBed.configureTestingModule({
      declarations: [DatalistComponent, SelectStub],
      providers: [{ provide: DataFormService, useValue: dataFormService }],
    });
    fixture = TestBed.createComponent(DatalistComponent);
    component = fixture.componentInstance;
    component.parentFormControl = new UntypedFormControl(null);
  });

  it('gives the values input to the select without calling the API', () => {
    component.values = [{ label: 'A', value: 'a' }];
    component.api = 'ignored';
    fixture.detectChanges();
    expect(dataFormService.getDataList).not.toHaveBeenCalled();
    expect(select().values).toEqual([{ label: 'A', value: 'a' }]);
  });

  it('fetches the values from the API and follows dataPath', () => {
    component.api = 'my/api';
    component.application = 'GeoNature';
    component.params = { orderby: 'x' };
    component.dataPath = 'data';
    fixture.detectChanges();
    expect(dataFormService.getDataList).toHaveBeenCalledWith(
      'my/api',
      'GeoNature',
      { orderby: 'x' },
      undefined
    );
    expect(select().values).toEqual([
      { label: 'x', value: 'x' },
      { label: 'y', value: 'y' },
    ]);
  });

  it('defaults the design style to material even if undefined is given', () => {
    component.designStyle = undefined;
    fixture.detectChanges();
    expect(select().designStyle).toBe('material');
  });

  it('forwards the display inputs to the select', () => {
    component.values = [];
    component.keyLabel = 'name';
    component.multiple = true;
    component.required = true;
    component.label = 'Choices';
    fixture.detectChanges();
    expect(select().keyLabel).toBe('name');
    expect(select().multiple).toBe(true);
    expect(select().required).toBe(true);
    expect(select().label).toBe('Choices');
    expect(select().parentFormControl).toBe(component.parentFormControl);
  });
});
