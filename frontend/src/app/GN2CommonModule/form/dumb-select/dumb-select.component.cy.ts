import { DumbSelectComponent } from './dumb-select.component';

describe('Dumb Select Component', () => {
  it('show component', () => {
    cy.mount(DumbSelectComponent, {
      componentProperties: {
        items: 'test',
        comparedKey: 'test',
        titleKey: 'test',
        displayedKey: 'test',
        displayNullValue: true,
        nullValueLabel: 'test',
      },
    });
  });
});
