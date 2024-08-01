import { ComponentFixture, TestBed } from '@angular/core/testing';

import { MappingEntityComponent } from './mapping-entity.component';

describe('MappingEntityComponent', () => {
  let component: MappingEntityComponent;
  let fixture: ComponentFixture<MappingEntityComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [MappingEntityComponent],
    }).compileComponents();

    fixture = TestBed.createComponent(MappingEntityComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
