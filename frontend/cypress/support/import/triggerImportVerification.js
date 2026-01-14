Cypress.Commands.add('triggerImportVerification', () => {
  cy.intercept('POST', '**/imports/*/prepare').as('prepareImport');
  cy.intercept('GET', '**/imports/*/preview_valid_data').as('previewValidData');
  cy.get('[data-qa=import-new-verification-start]').should('exist').should('be.enabled').click();
  cy.wait('@prepareImport', { timeout: 60000 });
  cy.wait('@previewValidData', { timeout: 60000 });
});
