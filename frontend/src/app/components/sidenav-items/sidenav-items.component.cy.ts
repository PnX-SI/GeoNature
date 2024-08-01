import { SidenavItemsComponent } from './sidenav-items.component';

describe('AdminComponent', () => {

  it('show component', () => {
    
    cy.mount(SidenavItemsComponent, {
      componentProperties: {},
      imports: [],
      declarations: [],
      providers: [],
    });
  });
});
