import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { MunicipalitiesComponent } from './municipalities.component';

describe('MunicipalitiesComponent', () => {
  let component: MunicipalitiesComponent;
  let fixture: ComponentFixture<MunicipalitiesComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [MunicipalitiesComponent],
    }).compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(MunicipalitiesComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
