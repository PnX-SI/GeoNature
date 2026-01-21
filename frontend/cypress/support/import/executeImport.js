Cypress.Commands.add('executeImport', () => {
  cy.intercept('POST', '**/imports/*/import').as('finalizeImport');
  cy.get('[data-qa="import-recapitulatif"]', { timeout: 60000 }).should('exist');
  cy.get('[data-qa="import-new-execute-start"]', { timeout: 60000 })
    .should('exist')
    .should('be.enabled')
    .click();
  cy.wait('@finalizeImport');
  cy.get('[data-qa="import-report"]', { timeout: 60000 }).should('exist');
});
