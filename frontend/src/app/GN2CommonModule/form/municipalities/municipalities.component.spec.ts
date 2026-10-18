import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Component, Input, Pipe, PipeTransform } from '@angular/core';
import { UntypedFormControl } from '@angular/forms';
import { MunicipalitiesComponent } from './municipalities.component';

@Pipe({ name: 'translate' })
class TranslateStubPipe implements PipeTransform {
  transform(key: string) {
    return `translated:${key}`;
  }
}

@Component({ selector: 'pnx-areas', template: '' })
class AreasStub {
  @Input() parentFormControl;
  @Input() label;
  @Input() typeCodes;
  @Input() disabled;
  @Input() valueFieldName;
  @Input() multiSelect;
}

describe('MunicipalitiesComponent', () => {
  let fixture: ComponentFixture<MunicipalitiesComponent>;
  let component: MunicipalitiesComponent;
  const areas = () => fixture.debugElement.children[0].componentInstance as AreasStub;

  beforeEach(() => {
    TestBed.configureTestingModule({
      declarations: [MunicipalitiesComponent, AreasStub, TranslateStubPipe],
    });
    fixture = TestBed.createComponent(MunicipalitiesComponent);
    component = fixture.componentInstance;
    component.parentFormControl = new UntypedFormControl(null);
  });

  it('is an areas select limited to municipalities', () => {
    component.valueFieldName = 'area_code';
    component.multiSelect = true;
    fixture.detectChanges();
    expect(areas().typeCodes).toEqual(['COM']);
    expect(areas().valueFieldName).toBe('area_code');
    expect(areas().multiSelect).toBe(true);
    expect(areas().parentFormControl).toBe(component.parentFormControl);
  });

  it('has a default label', () => {
    fixture.detectChanges();
    expect(areas().label).toBe('translated:Geo.Municipalities');
  });

  it('uses the label it is given', () => {
    component.label = 'Communes';
    fixture.detectChanges();
    expect(areas().label).toBe('Communes');
  });
});
