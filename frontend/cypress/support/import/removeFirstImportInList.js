Cypress.Commands.add('removeFirstImportInList', () => {
  cy.get('[data-qa="import-list-table-row-0-actions-delete"]').should('exist').click();
  cy.get('[data-qa="modal-delete-validate"]').should('exist').click();
});
