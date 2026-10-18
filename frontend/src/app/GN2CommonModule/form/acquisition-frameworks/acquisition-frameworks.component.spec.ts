import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Component, Input } from '@angular/core';
import { UntypedFormControl } from '@angular/forms';
import { of } from 'rxjs';
import { AcquisitionFramework } from '../../interfaces';
import { AcquisitionFrameworksComponent } from './acquisition-frameworks.component';
import { AcquisitionFrameworksSource } from './acquisition-frameworks.source';

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

describe('AcquisitionFrameworksComponent (connected)', () => {
  let fixture: ComponentFixture<AcquisitionFrameworksComponent>;
  const afs: AcquisitionFramework[] = [
    { id_acquisition_framework: 1, acquisition_framework_name: 'a' },
  ];
  const select = () => fixture.debugElement.children[0].componentInstance as ItemsSelectStub;

  beforeEach(() => {
    TestBed.configureTestingModule({
      declarations: [AcquisitionFrameworksComponent, ItemsSelectStub],
      providers: [{ provide: AcquisitionFrameworksSource, useValue: { load: () => of(afs) } }],
    });
    fixture = TestBed.createComponent(AcquisitionFrameworksComponent);
    fixture.componentInstance.parentFormControl = new UntypedFormControl(null);
  });

  it('gives the acquisition frameworks to the select, which is loading until they arrive', () => {
    fixture.detectChanges();
    expect(select().items).toEqual(afs);
    expect(select().loading).toBe(false);
    expect(select().bindLabel).toBe('acquisition_framework_name');
    expect(select().bindValue).toBe('id_acquisition_framework');
  });
});
