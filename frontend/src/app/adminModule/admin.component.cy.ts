import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { AdminComponent } from './admin.component';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { AppModule } from '@geonature/app.module';

describe('AdminComponent', () => {

  it('show component', () => {
    
    cy.mount(AdminComponent, {
      componentProperties: {},
      imports: [],
      declarations: [],
      providers: [],
    });
  });
});
