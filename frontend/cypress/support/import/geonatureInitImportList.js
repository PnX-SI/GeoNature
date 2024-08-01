Cypress.Commands.add('geonatureInitImportList', () => {
  cy.geonatureLogin();
  cy.visit('/#/import');
});
