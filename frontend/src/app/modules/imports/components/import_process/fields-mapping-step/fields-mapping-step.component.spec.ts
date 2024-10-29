import { ComponentFixture, TestBed } from '@angular/core/testing';

import { FieldsMappingStepComponent } from './fields-mapping-step.component';

describe('FieldMappingStepComponent', () => {
  let component: FieldsMappingStepComponent;
  let fixture: ComponentFixture<FieldsMappingStepComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [FieldsMappingStepComponent],
    }).compileComponents();

    fixture = TestBed.createComponent(FieldsMappingStepComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
