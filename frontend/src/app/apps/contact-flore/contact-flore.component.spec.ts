import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { ContactFloreComponent } from './contact-flore.component';

describe('ContactFloreComponent', () => {
  let component: ContactFloreComponent;
  let fixture: ComponentFixture<ContactFloreComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ ContactFloreComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(ContactFloreComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should be created', () => {
    expect(component).toBeTruthy();
  });
});
