Cypress.Commands.add("configureImportFieldMapping", () => {
  cy.get('[data-qa="mapping-selection"]').should("exist").click();
  cy.get('[data-qa="mapping-selection-1"]').should("exist").click();
  cy.get('[data-qa="import-new-fieldmapping-model-validate"]').should("exist").click();
});
