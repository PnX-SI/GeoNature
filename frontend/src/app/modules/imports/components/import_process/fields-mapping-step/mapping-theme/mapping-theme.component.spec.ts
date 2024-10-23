import { ComponentFixture, TestBed } from '@angular/core/testing';

import { MappingThemeComponent } from './mapping-theme.component';

describe('MappingThemeComponent', () => {
  let component: MappingThemeComponent;
  let fixture: ComponentFixture<MappingThemeComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [MappingThemeComponent],
    }).compileComponents();

    fixture = TestBed.createComponent(MappingThemeComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
