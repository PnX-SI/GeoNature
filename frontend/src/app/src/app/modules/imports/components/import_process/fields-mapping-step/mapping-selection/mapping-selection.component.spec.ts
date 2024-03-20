import { ComponentFixture, TestBed } from '@angular/core/testing';

import { MappingSelectionComponent } from './mapping-selection.component';

describe('MappingSelectionComponent', () => {
  let component: MappingSelectionComponent;
  let fixture: ComponentFixture<MappingSelectionComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ MappingSelectionComponent ]
    })
    .compileComponents();

    fixture = TestBed.createComponent(MappingSelectionComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
