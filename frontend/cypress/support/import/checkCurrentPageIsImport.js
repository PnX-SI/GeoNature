Cypress.Commands.add('checkCurrentPageIsImport', () => {
  // Check the url
  cy.url().should('be.equal', `${Cypress.config('baseUrl')}/#/import`);
  // Check that the main component is there
  cy.get('[data-qa=import-list]').should('exist');
});
