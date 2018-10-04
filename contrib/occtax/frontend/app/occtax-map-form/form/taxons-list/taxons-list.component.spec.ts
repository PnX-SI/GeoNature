import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { TaxonsListComponent } from './taxons-list.component';

describe('TaxonsListComponent', () => {
  let component: TaxonsListComponent;
  let fixture: ComponentFixture<TaxonsListComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ TaxonsListComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(TaxonsListComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should be created', () => {
    expect(component).toBeTruthy();
  });
});
