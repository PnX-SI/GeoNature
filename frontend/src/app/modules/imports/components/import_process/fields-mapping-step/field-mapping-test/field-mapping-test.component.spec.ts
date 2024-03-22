import { ComponentFixture, TestBed } from '@angular/core/testing';

import { FieldMappingTestComponent } from './field-mapping-test.component';

describe('FieldMappingTestComponent', () => {
  let component: FieldMappingTestComponent;
  let fixture: ComponentFixture<FieldMappingTestComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ FieldMappingTestComponent ]
    })
    .compileComponents();

    fixture = TestBed.createComponent(FieldMappingTestComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
