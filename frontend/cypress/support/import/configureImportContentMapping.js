Cypress.Commands.add('configureImportContentMapping', () => {
  cy.get('[data-qa="import-contentmapping-model-select"]')
    .should('exist')
    .select('Nomenclatures SINP (labels)');
  cy.get('[data-qa="import-contentmapping-model-validate"]').should('exist').click();
});
