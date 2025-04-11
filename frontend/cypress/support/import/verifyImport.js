Cypress.Commands.add('verifyImport', () => {
  cy.get('[data-qa="import-new-verification-start"]').should('exist').click();
});
