Cypress.Commands.add('executeImport', () => {
  cy.get('[data-qa="import-new-execute-start"]').should('exist').click();
});
