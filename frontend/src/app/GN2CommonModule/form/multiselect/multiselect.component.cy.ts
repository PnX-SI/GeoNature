import { MultiSelectComponent } from './multiselect.component';

describe('SelectSearchComponent', () => {
  it('show component', () => {
    cy.mount(MultiSelectComponent, {
      componentProperties: {},
      imports: [],
      declarations: [],
      providers: [],
    });
  });
});
