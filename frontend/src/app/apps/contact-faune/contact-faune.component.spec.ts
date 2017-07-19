import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { ContactFauneComponent } from './contact-faune.component';

describe('ContactFauneComponent', () => {
  let component: ContactFauneComponent;
  let fixture: ComponentFixture<ContactFauneComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ ContactFauneComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(ContactFauneComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should be created', () => {
    expect(component).toBeTruthy();
  });
});
