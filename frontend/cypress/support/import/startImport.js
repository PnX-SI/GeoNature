Cypress.Commands.add('startImport', (expectedLength) => {
  cy.get('[data-qa="import-modal-destination-start"]').should('exist').click();
});
