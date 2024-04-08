import { ComponentFixture, TestBed } from '@angular/core/testing';

import { FieldMappingModalComponent } from './field-mapping-modal.component';

describe('FieldMappingModalComponent', () => {
  let component: FieldMappingModalComponent;
  let fixture: ComponentFixture<FieldMappingModalComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ FieldMappingModalComponent ]
    })
    .compileComponents();

    fixture = TestBed.createComponent(FieldMappingModalComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
