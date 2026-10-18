import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Component, EventEmitter, Input, Output } from '@angular/core';
import { UntypedFormControl } from '@angular/forms';
import { of } from 'rxjs';
import { TaxonomyComponent } from './taxonomy.component';
import { DataFormService } from '../data-form.service';
import { ConfigService } from '@geonature/services/config.service';

@Component({ selector: 'pnx-taxonomy-select', template: '' })
class SelectStub {
  @Input() parentFormControl;
  @Input() label;
  @Input() searchFn;
  @Input() charNumber;
  @Input() displayedLabel;
  @Input() displayAdvancedFilters;
  @Input() regnesAndGroup;
  @Output() onChange = new EventEmitter();
  @Output() onDelete = new EventEmitter();
  refreshAllInput = jest.fn();
}

describe('TaxonomyComponent (connected)', () => {
  let fixture: ComponentFixture<TaxonomyComponent>;
  let component: TaxonomyComponent;
  let dataFormService: {
    getTaxhubAPI: jest.Mock;
    autocompleteTaxon: jest.Mock;
    getRegneAndGroup2Inpn: jest.Mock;
  };
  const select = () => fixture.debugElement.children[0].componentInstance as SelectStub;

  beforeEach(() => {
    dataFormService = {
      getTaxhubAPI: jest.fn().mockReturnValue('http://th/api'),
      autocompleteTaxon: jest.fn().mockReturnValue(of([{ cd_nom: 1 }])),
      getRegneAndGroup2Inpn: jest.fn().mockReturnValue(of({ Animalia: ['Mammifères'] })),
    };
    TestBed.configureTestingModule({
      declarations: [TaxonomyComponent, SelectStub],
      providers: [
        { provide: DataFormService, useValue: dataFormService },
        { provide: ConfigService, useValue: {} },
      ],
    });
    fixture = TestBed.createComponent(TaxonomyComponent);
    component = fixture.componentInstance;
    component.parentFormControl = new UntypedFormControl(null);
    component.charNumber = 3;
  });

  it('searches taxa in the TaxHub API of the taxa list, with the limit and the filters', () => {
    component.idList = '100';
    component.listLength = 10;
    fixture.detectChanges();
    component.searchFn('can', { regne: 'Animalia', group2_inpn: null }).subscribe();
    expect(dataFormService.autocompleteTaxon).toHaveBeenCalledWith(
      'http://th/api/taxref/allnamebylist/100',
      'can',
      { regne: 'Animalia', group2_inpn: null, limit: '10' }
    );
  });

  it('keeps the endpoint it is given', () => {
    component.apiEndPoint = 'http://other/api';
    fixture.detectChanges();
    expect(component.apiEndPoint).toBe('http://other/api');
  });

  it('updates the endpoint when the list changes', () => {
    fixture.detectChanges();
    component.ngOnChanges({ idList: { currentValue: '7' } });
    expect(component.apiEndPoint).toBe('http://th/api/taxref/allnamebylist/7');
  });

  it('loads the regnes and groups only with the advanced filters', () => {
    fixture.detectChanges();
    expect(dataFormService.getRegneAndGroup2Inpn).not.toHaveBeenCalled();
  });

  it('gives the regnes and groups to the select with the advanced filters', () => {
    component.displayAdvancedFilters = true;
    fixture.detectChanges();
    expect(select().regnesAndGroup).toEqual({ Animalia: ['Mammifères'] });
  });

  it('forwards the events of the select', () => {
    fixture.detectChanges();
    const changed = jest.fn();
    const deleted = jest.fn();
    component.onChange.subscribe(changed);
    component.onDelete.subscribe(deleted);
    select().onChange.emit({ item: 1 });
    select().onDelete.emit();
    expect(changed).toHaveBeenCalledWith({ item: 1 });
    expect(deleted).toHaveBeenCalled();
  });

  it('resets the control by itself when the select component is not found', () => {
    fixture.detectChanges();
    component.parentFormControl.setValue('can');
    component.refreshAllInput();
    expect(component.parentFormControl.value).toBeNull();
  });
});
