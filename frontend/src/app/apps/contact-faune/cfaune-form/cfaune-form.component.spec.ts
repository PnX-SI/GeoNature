import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { CfauneFormComponent } from './cfaune-form.component';

describe('CfauneFormComponent', () => {
  let component: CfauneFormComponent;
  let fixture: ComponentFixture<CfauneFormComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ CfauneFormComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(CfauneFormComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should be created', () => {
    expect(component).toBeTruthy();
  });
});
