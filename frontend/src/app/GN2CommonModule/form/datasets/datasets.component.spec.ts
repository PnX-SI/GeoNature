import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Component, Input } from '@angular/core';
import { UntypedFormControl } from '@angular/forms';
import { of } from 'rxjs';
import { Dataset } from '../../interfaces';
import { ConfigService } from '@geonature/services/config.service';
import { DatasetsComponent } from './datasets.component';
import { DatasetsSource } from './datasets.source';

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

describe('DatasetsComponent (connected)', () => {
  let fixture: ComponentFixture<DatasetsComponent>;
  let component: DatasetsComponent;
  let source: { load: jest.Mock };
  const datasets: Dataset[] = [{ id_dataset: 1, dataset_name: 'One' }];
  const select = () => fixture.debugElement.children[0].componentInstance as ItemsSelectStub;

  beforeEach(() => {
    source = { load: jest.fn().mockReturnValue(of(datasets)) };
    TestBed.configureTestingModule({
      declarations: [DatasetsComponent, ItemsSelectStub],
      providers: [
        { provide: DatasetsSource, useValue: source },
        { provide: ConfigService, useValue: {} },
      ],
    });
    fixture = TestBed.createComponent(DatasetsComponent);
    component = fixture.componentInstance;
    component.parentFormControl = new UntypedFormControl(null);
  });

  it('loads the active datasets and gives them to the select', () => {
    fixture.detectChanges();
    expect(source.load).toHaveBeenCalledWith({ active: true });
    expect(select().items).toEqual(datasets);
    expect(select().parentFormControl).toBe(component.parentFormControl);
    expect(select().bindLabel).toBe('dataset_name');
    expect(select().bindValue).toBe('id_dataset');
    expect(select().autoSelectKey).toBe('id_dataset');
  });

  it('passes the module filters to the source', () => {
    component.moduleCode = 'OCCTAX';
    component.creatableInModule = 'OCCHAB';
    component.displayOnlyActive = false;
    fixture.detectChanges();
    expect(source.load).toHaveBeenCalledWith({ module_code: 'OCCTAX', create: 'OCCHAB' });
  });

  it('gives the whole dataset to the control with bindAllItem', () => {
    component.bindAllItem = true;
    fixture.detectChanges();
    expect(select().bindValue).toBeNull();
  });

  it('emits valueLoaded when datasets are loaded', () => {
    const loaded = jest.fn();
    component.valueLoaded.subscribe(loaded);
    fixture.detectChanges();
    expect(loaded).toHaveBeenCalledWith({ value: datasets });
  });

  it('reloads datasets when the acquisition framework ids change', () => {
    fixture.detectChanges();
    source.load.mockClear();
    component.idAcquisitionFrameworks = [4, 5];
    fixture.detectChanges();
    expect(source.load).toHaveBeenCalledWith({ id_acquisition_frameworks: [4, 5], active: true });
  });

  it('reloads datasets when the acquisition framework id changes', () => {
    fixture.detectChanges();
    source.load.mockClear();
    component.ngOnChanges({
      idAcquisitionFramework: { currentValue: 3, previousValue: undefined, firstChange: false },
    } as any);
    expect(source.load).toHaveBeenCalledWith({ id_acquisition_framework: 3, active: true });
  });
});
