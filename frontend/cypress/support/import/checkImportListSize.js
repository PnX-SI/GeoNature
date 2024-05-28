Cypress.Commands.add('checkImportListSize', (expectedLength) => {
  cy.get('[data-qa=import-list-table] datatable-body').within(() => {
    cy.get('datatable-body-row').should('have.length', expectedLength);
  });
});
