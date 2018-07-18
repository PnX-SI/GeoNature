import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { NomenclatureMultiSelectComponent } from './nomenclature-multi-select.component';

describe('NomenclatureMultiSelectComponent', () => {
  let component: NomenclatureMultiSelectComponent;
  let fixture: ComponentFixture<NomenclatureMultiSelectComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ NomenclatureMultiSelectComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(NomenclatureMultiSelectComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
