Cypress.Commands.add('triggerImportVerification', () => {
  cy.get('[data-qa=import-new-verification-start]').should('exist').should('be.enabled').click();
});
